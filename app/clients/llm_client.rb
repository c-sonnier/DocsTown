class LlmClient
  MAX_RETRIES = 3

  TransientError = Class.new(StandardError)

  TRANSIENT_ERRORS = [
    Net::OpenTimeout,
    Net::ReadTimeout,
    Errno::ECONNRESET,
    JSON::ParserError,
    TransientError
  ].freeze

  def generate(prompt:)
    retries = 0
    begin
      response = Net::HTTP.post(
        URI(api_url),
        request_body(prompt).to_json,
        request_headers
      )

      body = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        message = "#{provider_name} API error (#{response.code}): #{body["error"]&.dig("message") || response.body}"
        raise TransientError, message
      end

      extract_content(body)
    rescue *TRANSIENT_ERRORS => e
      retries += 1
      if retries <= MAX_RETRIES
        sleep backoff_delay(retries)
        retry
      end
      raise
    end
  end

  private

  def backoff_delay(attempt)
    return 0 if Rails.env.test?
    5 ** (attempt - 1)
  end
end

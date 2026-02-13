class KimiClient
  API_URL = "https://api.moonshot.cn/v1/chat/completions"
  MAX_RETRIES = 3

  def generate(prompt:)
    retries = 0
    begin
      response = Net::HTTP.post(
        URI(API_URL),
        {
          model: "moonshot-v1-8k",
          messages: [ { role: "user", content: prompt } ],
          max_tokens: 1024
        }.to_json,
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{api_key}"
      )

      handle_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout, StandardError => e
      retries += 1
      if retries <= MAX_RETRIES
        sleep backoff_delay(retries)
        retry
      end
      raise
    end
  end

  private

  def handle_response(response)
    body = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Kimi API error (#{response.code}): #{body["error"]&.dig("message") || response.body}"
    end

    body.dig("choices", 0, "message", "content")
  end

  def api_key
    Rails.application.credentials.dig(:kimi, :api_key) || raise("Missing Kimi API key in credentials")
  end

  def backoff_delay(attempt)
    return 0 if Rails.env.test?
    5 ** (attempt - 1) # 1s, 5s, 25s
  end
end

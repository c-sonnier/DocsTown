class OpenaiClient < LlmClient
  API_URL = "https://api.openai.com/v1/chat/completions"

  private

  def api_url
    API_URL
  end

  def request_headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{Rails.application.credentials.dig(:openai, :api_key) || raise("Missing OpenAI API key in credentials")}"
    }
  end

  def request_body(prompt)
    { model: "gpt-4o", messages: [ { role: "user", content: prompt } ], max_tokens: 1024 }
  end

  def extract_content(body)
    body.dig("choices", 0, "message", "content")
  end

  def provider_name
    "OpenAI"
  end
end

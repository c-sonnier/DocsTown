require "test_helper"
require "support/client_interface_test"

class KimiClientTest < ActiveSupport::TestCase
  include ClientInterfaceTest

  setup do
    @client = KimiClient.new
  end

  test "generate parses successful response" do
    stub_request(:post, KimiClient::API_URL)
      .to_return(
        status: 200,
        body: { choices: [ { message: { content: "Generated documentation" } } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @client.generate(prompt: "Document this method")
    assert_equal "Generated documentation", result
  end

  test "generate raises on API error after retries" do
    stub_request(:post, KimiClient::API_URL)
      .to_return(
        status: 429,
        body: { error: { message: "Rate limited" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(LlmClient::TransientError) { @client.generate(prompt: "test") }
    assert_match(/Kimi API error/, error.message)
  end
end

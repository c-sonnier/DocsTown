module ClientInterfaceTest
  def test_responds_to_generate
    assert_respond_to @client, :generate
  end
end

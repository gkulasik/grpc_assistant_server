require 'test_helper'
class GrpcurlResultTest < ActiveSupport::TestCase

  test 'init parses response when proper' do
    example_result = build(:grpcurl_result_success)
    success_result = GrpcurlResult.new({ command: example_result.command, raw_output: example_result.raw_output, raw_errors: nil })
    assert_not_nil success_result.clean_response

    failure_result = GrpcurlResult.new({ command: example_result.command, raw_output: nil, raw_errors: "errors" })
    assert_nil failure_result.clean_response
  end

  test 'get response - success' do
    # using factory the clean_response is not populated so makes it possible to test this method
    result = build(:grpcurl_result_success)
    assert_nil result.clean_response
    assert_not_nil result.get_response
  end

  test 'get response - failure' do
    result = build(:grpcurl_result_failure)
    assert_nil result.clean_response
    assert_nil result.get_response
  end

  test 'is success' do
    success = build(:grpcurl_result_success)
    assert success.is_success?

    failure = build(:grpcurl_result_failure)
    assert_not failure.is_success?
  end

  test 'parse raw output' do
    result = build(:grpcurl_result_success)

    # Error cases
    assert_nil result.parse_raw_output(nil)
    assert_nil result.parse_raw_output("")
    assert_nil result.parse_raw_output("[\"foo\"]")
    assert_nil result.parse_raw_output("{}")

    # Success cases
    expected_one = "\n{\"test\":{\"foo\":\"bar\"}\n}\n"
    assert_equal expected_one, result.parse_raw_output("foo bar \n #{GrpcurlResult::GRPC_RESPONSE_START_MARKER}\n{\"test\":{\"foo\":\"bar\"}\n}\n#{GrpcurlResult::GRPC_RESPONSE_END_MARKER}")

    expected_two = "{\"foo\":  \n  \"bar\",   \"bar\":\"foo\",\"one\":1}"
    assert_equal expected_two, result.parse_raw_output("#{GrpcurlResult::GRPC_RESPONSE_START_MARKER}{\"foo\":  \n  \"bar\",   \"bar\":\"foo\",\"one\":1}#{GrpcurlResult::GRPC_RESPONSE_END_MARKER}    \n foobar")

    expected_three = "\n{\"test\":[\"foo\",\"bar\"], \"foo\":\"bar\"\n}\n"
    assert_equal expected_three, result.parse_raw_output("test test \ntest [] {test-data} \n #{GrpcurlResult::GRPC_RESPONSE_START_MARKER}\n{\"test\":[\"foo\",\"bar\"], \"foo\":\"bar\"\n}\n#{GrpcurlResult::GRPC_RESPONSE_END_MARKER}")
  end

  test 'parse raw output - streaming output' do
    result = build(:grpcurl_result_success)

    # Ensure 'Response Contents' is removed in streamed response
    input_text = "#{GrpcurlResult::GRPC_RESPONSE_START_MARKER}\n-1\n#{GrpcurlResult::GRPC_RESPONSE_START_MARKER}\n-2\n#{GrpcurlResult::GRPC_RESPONSE_START_MARKER}\n-3\n#{GrpcurlResult::GRPC_RESPONSE_END_MARKER}"
    expected = "\n-1\n\n-2\n\n-3\n"
    assert_equal expected, result.parse_raw_output(input_text)
  end

  test 'to text response - success' do
    min_success_response_string = "
        Response contents:
        {
            \"foo\": \"BAR\"
        }

        Response trailers received:
        "
    result = build(:grpcurl_result_success, raw_output: min_success_response_string, hints: ["foo-hint"])
    result_api_response = result.to_text_response
    assert result_api_response.include?("### Parsed Response ###"), "Got response: #{result_api_response}"
    assert result_api_response.include?("\"foo\": \"BAR\""), "Got response: #{result_api_response}"
    assert result_api_response.include?("### Command ###"), "Got response: #{result_api_response}"
    assert result_api_response.include?("test-command"), "Got response: #{result_api_response}"
    assert result_api_response.include?("\"foo\": \"BAR\""), "Got response: #{result_api_response}"
    assert result_api_response.include?("### Hints ###"), "Got response: #{result_api_response}"
    assert result_api_response.include?("- foo-hint"), "Got response: #{result_api_response}"
    assert result_api_response.include?("### Full Response ###"), "Got response: #{result_api_response}"
    assert result_api_response.include?("Response contents:"), "Got response: #{result_api_response}"
  end

  test 'to text response - failure' do
    result = build(:grpcurl_result_failure)
    expected = "### Error ###

errors
### Command ###

test-command

"
    assert_equal expected, result.to_text_response
  end

  test 'to json response - success' do
    min_success_response_string = "
        Response contents:
        {
            \"foo\": \"BAR\"
        }

        Response trailers received:
        "
    result = build(:grpcurl_result_success, raw_output: min_success_response_string, hints: ["foo-hint"])
    result_api_response = result.to_json_response
    expected_response = { "foo" => "BAR" }
    assert_equal expected_response, result_api_response
  end

  test 'to json response - failure' do
    result = build(:grpcurl_result_failure)
    expected = { :error => "errors" }
    assert_equal expected, result.to_json_response
  end
end
require 'test_helper'
class GrpcurlResultTest < ActiveSupport::TestCase

  test 'init parses response when proper' do
    example_result = build(:grpcurl_result_success)
    success_result = GrpcurlResult.new({command: example_result.command, raw_output: example_result.raw_output, raw_errors: nil})
    assert_not_nil success_result.clean_response

    failure_result = GrpcurlResult.new({command: example_result.command, raw_output: nil, raw_errors: "errors"})
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

    assert_nil result.parse_raw_output(nil)
    assert_nil result.parse_raw_output("")
    assert_nil result.parse_raw_output("[\"foo\"]")
    assert_nil result.parse_raw_output("{}")
    assert_not_nil result.parse_raw_output("{\"test\":{\"foo\":\"bar\"}")
    expected = {"test" => {"foo" => "bar"}}
    assert_equal expected, result.parse_raw_output("{\"test\":{\"foo\":\"bar\"}")
  end

  test 'to api response - success' do
    result = build(:grpcurl_result_success)
    expected = { success: true, response: result.get_response, command: result.command, full_output: result.raw_output }
    assert_equal expected, result.to_api_response
  end

  test 'to api response - failure' do
    result = build(:grpcurl_result_failure)
    expected = { success: false, errors: result.raw_errors, command: result.command }
    assert_equal expected, result.to_api_response
  end

end
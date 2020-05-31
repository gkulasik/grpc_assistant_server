require 'test_helper'

class ServiceControllerTest < ActionDispatch::IntegrationTest

  class TestGrpcController < ServiceController
  end

  SUCCESS_MOCK_COMMAND = "grpcurl  -import-path '/import/path'  -proto 'some/example/examples.proto'  -H 'AUTHORIZATION:auth-token'  -plaintext  -v  -d '{\"field_one\":1,\"field_two\":\"two\",\"field_three\":true}'  example.com:443  com.example.proto.ExampleService/ExampleMethod "
  SUCCESS_MOCK_RESPONSE = "\nResolved method descriptor:\n// Test method ( .com.example.proto.ExampleMethod ) returns ( .com.example.proto.ExampleResponse );\n\nRequest metadata to send:\nauthorization: auth-token\n\nResponse headers received:\naccess-control-expose-headers: X-REQUEST-UUID\ncontent-type: application/grpc+proto\ndate: Fri, 17 Apr 2020 00:58:49 GMT\nserver: test\nx-request-uuid: 58e3a8c0-xxxx-xxxx-xxxx-e4fbcead7c00\n\nResponse contents:\n{\n  \"exampleResponse\": {\n    \"foo\": \"BAR\"\n  }\n}\n\nResponse trailers received:\ndate: Fri, 17 Apr 2020 19:34:42 GMT\nSent 1 request and received 1 response\n"

  DEFAULT_SERVICE_NAME = "com.example.proto.ExampleService"
  DEFAULT_METHOD_NAME = "ExampleMethod"
  DEFAULT_SUCCESS_BODY = {
      field_one: 1,
      field_two: "two",
      field_three: true
  }.to_json

  DEFAULT_SUCCESS_META_HEADERS = { "HTTP_GRPC_META_server_address": "example.com:443",
                                   "HTTP_GRPC_META_verbose": "true",
                                   "HTTP_GRPC_META_import_path": "/import/path",
                                   "HTTP_GRPC_META_service_proto_path": "some/example/examples.proto",
                                   "HTTP_GRPC_META_plaintext": "true" }

  DEFAULT_REQ_HEADERS = { "HTTP_NON_GRPC_OTHER": "some value",
                          "HTTP_GRPC_REQ_AUTHORIZATION": "auth-token" }

  DEFAULT_HEADERS = DEFAULT_SUCCESS_META_HEADERS.merge(DEFAULT_REQ_HEADERS)

  test "should get GRPC_META headers" do
    controller = TestGrpcController.new()
    grpc_meta_only_headers = controller.get_grpc_headers(ServiceController::GRPC_METADATA_PREFIX, { "HTTP_GRPC_META_test" => "foo",
                                                                                                    "HTTP_GRPC_REQ_test" => "fail",
                                                                                                    "HTTP_OTHER_HEADER" => "bar" })
    expected = { "test" => "foo" }
    assert_equal expected, grpc_meta_only_headers
  end

  test "should get GRPC_REQ headers" do
    controller = TestGrpcController.new()
    grpc_req_only_headers = controller.get_grpc_headers(ServiceController::GRPC_REQUEST_HEADER_PREFIX, { "HTTP_GRPC_META_test" => "fail",
                                                                                                         "HTTP_GRPC_REQ_test" => "foo",
                                                                                                         "HTTP_OTHER_HEADER" => "bar" })
    expected = { "test" => "foo" }
    assert_equal expected, grpc_req_only_headers
  end

  test "extract all headers - should get all grpc related headers" do
    controller = TestGrpcController.new()
    headers = { "HTTP_NON_GRPC_OTHER" => "some value",
                "HTTP_GRPC_REQ_TEST1" => "test1",
                "HTTP_GRPC_RPC_TEST2" => "test2",
                "HTTP_GRPC_REFLECT_TEST3" => "test3" }.merge({ "HTTP_GRPC_META_test" => "fail",
                                                             "HTTP_OTHER_HEADER" => "bar" })

    grpc_headers = controller.extract_all_headers(headers)
    expected = {"HTTP_GRPC_REQ_"=>{"TEST1"=>"test1"}, "HTTP_GRPC_RPC_"=>{"TEST2"=>"test2"}, "HTTP_GRPC_REFLECT_"=>{"TEST3"=>"test3"}}
    assert_equal expected, grpc_headers
  end

  test "should upcase sym headers when set" do
    controller = TestGrpcController.new()
    headers = controller.get_grpc_headers(ServiceController::GRPC_METADATA_PREFIX, { "HTTP_GRPC_META_test" => "foo",
                                                                                     "HTTP_GRPC_REQ_test" => "fail",
                                                                                     "HTTP_OTHER_HEADER" => "bar" }, true)
    expected = { "TEST": "foo" }
    assert_equal expected, headers
  end

  test "command - should succeed with correct call" do
    post command_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
         headers: DEFAULT_HEADERS,
         params: DEFAULT_SUCCESS_BODY

    assert_response :success
    expected_response = "grpcurl  -import-path '/import/path'  -proto 'some/example/examples.proto'  -H 'AUTHORIZATION:auth-token'  -plaintext  -v  -d '{\"field_one\":1,\"field_two\":\"two\",\"field_three\":true}'  example.com:443  com.example.proto.ExampleService/ExampleMethod "
    assert_equal expected_response, @response.body
  end

  test "command - should handle all the different header types" do
    headers = DEFAULT_SUCCESS_META_HEADERS.merge({ "HTTP_NON_GRPC_OTHER": "some value",
                                                   "HTTP_GRPC_REQ_TEST1": "test1",
                                                   "HTTP_GRPC_RPC_TEST2": "test2",
                                                   "HTTP_GRPC_REFLECT_TEST3": "test3" })
    post command_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
         headers: headers,
         params: DEFAULT_SUCCESS_BODY

    assert_response :success
    expected_response = "grpcurl  -import-path '/import/path'  -proto 'some/example/examples.proto'  -H 'TEST1:test1'  -rpc-header 'TEST2:test2'  -reflect-header 'TEST3:test3'  -plaintext  -v  -d '{\"field_one\":1,\"field_two\":\"two\",\"field_three\":true}'  example.com:443  com.example.proto.ExampleService/ExampleMethod "
    assert_equal expected_response, @response.body
  end

  test "command - should handle GAS options header" do
    # No timestamps
    post command_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
         headers: DEFAULT_HEADERS.merge({ "HTTP_GRPC_META_gas_options" => 'auto_format_dates:true' }),
         params: DEFAULT_SUCCESS_BODY

    assert_response :success
    expected_response = "grpcurl  -import-path '/import/path'  -proto 'some/example/examples.proto'  -H 'AUTHORIZATION:auth-token'  -plaintext  -v  -d '{\"field_one\":1,\"field_two\":\"two\",\"field_three\":true}'  example.com:443  com.example.proto.ExampleService/ExampleMethod "
    assert_equal expected_response, @response.body

    # with timestamps
    post command_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
         headers: DEFAULT_HEADERS.merge({ "HTTP_GRPC_META_gas_options" => 'auto_format_dates:true' }),
         params: JSON.parse(DEFAULT_SUCCESS_BODY).merge({ 'field4' => '2020-01-01' }).to_json

    assert_response :success
    expected_response = "grpcurl  -import-path '/import/path'  -proto 'some/example/examples.proto'  -H 'AUTHORIZATION:auth-token'  -plaintext  -v  -d '{\"field_one\":1,\"field_two\":\"two\",\"field_three\":true,\"field4\":{\"year\":2020,\"month\":1,\"day\":1}}'  example.com:443  com.example.proto.ExampleService/ExampleMethod "
    assert_equal expected_response, @response.body
  end

  test "command - should fail with incorrect call" do
    # Empty request to trigger errors
    # Edit - due to new path information needing the service name and
    # method name all errors is not possible to trigger now
    post command_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
         headers: {},
         params: {}

    assert_response :bad_request
    json_response = JSON.parse(@response.body)
    expected_response = ["server_address is not set"]
    assert_equal expected_response, json_response["errors"]
  end

  test 'execute - should handle success response' do
    executor_mock = MiniTest::Mock.new
    executor_mock.expect :call, GrpcurlResult.new({ command: SUCCESS_MOCK_COMMAND, raw_output: SUCCESS_MOCK_RESPONSE, raw_errors: "", hints: ["foo-hint1", "foo-hint2"] }), [GrpcurlBuilder]

    GrpcurlExecutor.stub :execute, executor_mock do
      post execute_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
           headers: DEFAULT_HEADERS,
           params: DEFAULT_SUCCESS_BODY

      assert_response :success
      expected_response = "{\"exampleResponse\":{\"foo\":\"BAR\"}}"
      assert @response.body.include?(GrpcurlResult::RESPONSE_PARSED_HEADER), 'Response is missing the parsed response header'
      assert_not @response.body.include?(GrpcurlResult::ERROR_HEADER), 'Response contains the error header'
      assert @response.body.include?(GrpcurlResult::HINTS_HEADER), 'Response is missing the hints header'
      # For reliability remove formatting white space
      assert @response.body.gsub(/\s+/, "").include?(expected_response), 'Response did not contain the parsed response'
      assert @response.body.include?(SUCCESS_MOCK_COMMAND), 'Response did not contain the command used'
      assert @response.body.include?(SUCCESS_MOCK_RESPONSE), 'Response did not contain the full output'
      assert @response.body.include?("- foo-hint1"), 'Response is missing a hint'
      assert @response.body.include?("- foo-hint2"), 'Response is missing a hint'
    end

    assert_mock executor_mock
  end

  test 'execute - should handle all request header types' do

    modified_command = "grpcurl  -import-path '/import/path'  -proto 'some/example/examples.proto'  -H 'TEST1:test1'  -H 'TEST2:test2'  -H 'TEST3:test3'  -plaintext  -v  -d '{\"field_one\":1,\"field_two\":\"two\",\"field_three\":true}'  example.com:443  com.example.proto.ExampleService/ExampleMethod "
    executor_mock = MiniTest::Mock.new
    executor_mock.expect :call, GrpcurlResult.new({ command: modified_command, raw_output: SUCCESS_MOCK_RESPONSE, raw_errors: "", hints: ["foo-hint1", "foo-hint2"] }), [GrpcurlBuilder]

    headers = DEFAULT_SUCCESS_META_HEADERS.merge({ "HTTP_NON_GRPC_OTHER": "some value",
                                                   "HTTP_GRPC_REQ_TEST1": "test1",
                                                   "HTTP_GRPC_RPC_TEST2": "test2",
                                                   "HTTP_GRPC_REFLECT_TEST3": "test3" })
    GrpcurlExecutor.stub :execute, executor_mock do
      post execute_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
           headers: headers,
           params: DEFAULT_SUCCESS_BODY

      assert_response :success
      expected_response = "{\"exampleResponse\":{\"foo\":\"BAR\"}}"
      assert @response.body.include?(GrpcurlResult::RESPONSE_PARSED_HEADER), 'Response is missing the parsed response header'
      assert_not @response.body.include?(GrpcurlResult::ERROR_HEADER), 'Response contains the error header'
      assert @response.body.include?(GrpcurlResult::HINTS_HEADER), 'Response is missing the hints header'
      # For reliability remove formatting white space
      assert @response.body.gsub(/\s+/, "").include?(expected_response), 'Response did not contain the parsed response'
      assert @response.body.include?(modified_command), 'Response did not contain the command used'
      assert @response.body.include?(SUCCESS_MOCK_RESPONSE), 'Response did not contain the full output'
      assert @response.body.include?("- foo-hint1"), 'Response is missing a hint'
      assert @response.body.include?("- foo-hint2"), 'Response is missing a hint'
    end

    assert_mock executor_mock
  end

  test "execute - should handle GAS options header - no date" do
    executor_mock = MiniTest::Mock.new
    executor_mock.expect :call, GrpcurlResult.new({ command: SUCCESS_MOCK_COMMAND, raw_output: SUCCESS_MOCK_RESPONSE, raw_errors: "", hints: ["foo-hint1", "foo-hint2"] }), [GrpcurlBuilder]

    GrpcurlExecutor.stub :execute, executor_mock do
      # No timestamps
      post execute_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
           headers: DEFAULT_HEADERS.merge({ "HTTP_GRPC_META_gas_options" => 'auto_format_dates:true' }),
           params: DEFAULT_SUCCESS_BODY

      assert_response :success
      expected_response = "{\"exampleResponse\":{\"foo\":\"BAR\"}}"
      assert @response.body.include?(GrpcurlResult::RESPONSE_PARSED_HEADER), 'Response is missing the parsed response header'
      assert_not @response.body.include?(GrpcurlResult::ERROR_HEADER), 'Response contains the error header'
      assert @response.body.include?(GrpcurlResult::HINTS_HEADER), 'Response is missing the hints header'
      # For reliability remove formatting white space
      assert @response.body.gsub(/\s+/, "").include?(expected_response), 'Response did not contain the parsed response'
      assert @response.body.include?(SUCCESS_MOCK_COMMAND), 'Response did not contain the command used'
      assert @response.body.include?(SUCCESS_MOCK_RESPONSE), 'Response did not contain the full output'
      assert @response.body.include?("- foo-hint1"), 'Response is missing a hint'
      assert @response.body.include?("- foo-hint2"), 'Response is missing a hint'
    end
    assert_mock executor_mock
  end

  test "execute - should handle GAS options header - with date" do
    executor_mock = MiniTest::Mock.new
    expected_command_with_date = "grpcurl  -import-path '/import/path'  -proto 'some/example/examples.proto'  -H 'AUTHORIZATION:auth-token'  -plaintext  -v  -d '{\"field_one\":1,\"field_two\":\"two\",\"field_three\":true,\"field4\":{\"seconds\":1588462761,\"nanos\":560000000}}'  example.com:443  com.example.proto.ExampleService/ExampleMethod "
    executor_mock.expect :call, GrpcurlResult.new({ command: expected_command_with_date, raw_output: SUCCESS_MOCK_RESPONSE, raw_errors: "", hints: ["foo-hint1", "foo-hint2"] }), [GrpcurlBuilder]

    GrpcurlExecutor.stub :execute, executor_mock do
      # with timestamps
      post execute_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
           headers: DEFAULT_HEADERS.merge({ "HTTP_GRPC_META_gas_options" => 'auto_format_dates:true' }),
           params: JSON.parse(DEFAULT_SUCCESS_BODY).merge({ 'field4' => '2020-05-02T23:39:21.560Z' }).to_json

      assert_response :success
      expected_response = "{\"exampleResponse\":{\"foo\":\"BAR\"}}"
      body = @response.body
      assert body.include?(GrpcurlResult::RESPONSE_PARSED_HEADER), 'Response is missing the parsed response header'
      assert_not body.include?(GrpcurlResult::ERROR_HEADER), 'Response contains the error header'
      assert body.include?(GrpcurlResult::HINTS_HEADER), 'Response is missing the hints header'
      # For reliability remove formatting white space
      assert body.gsub(/\s+/, "").include?(expected_response), 'Response did not contain the parsed response'
      assert body.include?(expected_command_with_date), 'Response did not contain the command used'
      assert body.include?(SUCCESS_MOCK_RESPONSE), 'Response did not contain the full output'
      assert body.include?("- foo-hint1"), 'Response is missing a hint'
      assert body.include?("- foo-hint2"), 'Response is missing a hint'
    end
    assert_mock executor_mock
  end

  # Should be able to use as: :json here instead of appending .json but that isn't working for some reason.
  test 'execute - should handle json format' do
    executor_mock = MiniTest::Mock.new
    executor_mock.expect :call, GrpcurlResult.new({ command: SUCCESS_MOCK_COMMAND, raw_output: SUCCESS_MOCK_RESPONSE, raw_errors: "", hints: ["foo-hint1", "foo-hint2"] }), [GrpcurlBuilder]

    GrpcurlExecutor.stub :execute, executor_mock do
      post execute_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME) + ".json",
           headers: DEFAULT_HEADERS,
           params: DEFAULT_SUCCESS_BODY

      assert_response :success
      expected_response = "{\"exampleResponse\":{\"foo\":\"BAR\"}}"
      assert_equal expected_response, @response.body, 'Response is not matching expected JSON or does not contain only json'
    end
    assert_mock executor_mock
  end

  # Should be able to use as: :json here instead of appending .json but that isn't working for some reason.
  test 'execute - should handle json format error in response' do
    stream_response_example = "\nResolved method descriptor:\n// Test method ( .com.example.proto.ExampleMethod ) returns ( .com.example.proto.ExampleResponse );\n\nRequest metadata to send:\nauthorization: auth-token\n\nResponse headers received:\naccess-control-expose-headers: X-REQUEST-UUID\ncontent-type: application/grpc+proto\ndate: Fri, 17 Apr 2020 00:58:49 GMT\nserver: test\nx-request-uuid: 58e3a8c0-xxxx-xxxx-xxxx-e4fbcead7c00\n\nResponse contents:\n-1\nResponse contents:\n-2\nResponse contents:\n-3\n\nResponse trailers received:\ndate: Fri, 17 Apr 2020 19:34:42 GMT\nSent 1 request and received 1 response\n"
    executor_mock = MiniTest::Mock.new
    executor_mock.expect :call, GrpcurlResult.new({ command: SUCCESS_MOCK_COMMAND, raw_output: stream_response_example, raw_errors: "", hints: ["foo-hint1", "foo-hint2"] }), [GrpcurlBuilder]

    GrpcurlExecutor.stub :execute, executor_mock do
      post execute_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME) + ".json",
           headers: DEFAULT_HEADERS,
           params: DEFAULT_SUCCESS_BODY

      assert_response :bad_request
      body = @response.body
      assert body.include?('Response parsing error. Response is not JSON. Original response:'), "Response did not contain incorrect JSON format warning: \n#{body}"
      assert body.include?("### Parsed Response ### \n\n-1\n\n-2\n\n-3"), "Response did not contain parsed response: \n#{body}"
    end
    assert_mock executor_mock
  end

  test 'execute - should handle failure response' do
    error_string = "Test-Error"
    executor_mock = MiniTest::Mock.new
    executor_mock.expect :call, GrpcurlResult.new({ command: SUCCESS_MOCK_COMMAND, raw_output: "", raw_errors: error_string, hints: ['foo-error-hint'] }), [GrpcurlBuilder]

    GrpcurlExecutor.stub :execute, executor_mock do
      post execute_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
           headers: DEFAULT_HEADERS,
           params: DEFAULT_SUCCESS_BODY

      assert_response :bad_request
      body = @response.body
      assert_not body.include?(GrpcurlResult::RESPONSE_PARSED_HEADER), "Response contains the parsed response header when it should not. Body: #{body}"
      assert body.include?(GrpcurlResult::ERROR_HEADER), "Response did not contain the error header (should have been a failed request). Body: #{body}"
      assert body.include?(GrpcurlResult::HINTS_HEADER), "Response is missing the hints header. Body: #{body}"
      assert body.include?(error_string), "Response did not contain the expected error text. Body: #{body}"
      assert body.include?(SUCCESS_MOCK_COMMAND), "Response did not contain the command used. Body: #{body}"
      assert body.include?("- foo-error-hint"), "Response is missing a hint. Body: #{body}"
    end

    assert_mock executor_mock
  end

  test 'execute - should handle bad input' do
    executor_mock = MiniTest::Mock.new

    GrpcurlExecutor.stub :execute, executor_mock do
      post execute_path(service_name: DEFAULT_SERVICE_NAME, method_name: DEFAULT_METHOD_NAME),
           headers: { "HTTP_NON_GRPC_OTHER": "some value",
                      "HTTP_GRPC_AUTHORIZATION": "auth-token" },
           params: {
               options: {},
               data: {}
           }

      assert_response :bad_request
      json_response = JSON.parse(@response.body)
      expected_response = ["server_address is not set"]
      assert_equal expected_response, json_response["errors"]
    end

    assert_mock executor_mock
  end
end

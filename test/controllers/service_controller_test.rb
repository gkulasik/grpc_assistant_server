require 'test_helper'

class ServiceControllerTest < ActionDispatch::IntegrationTest

  class TestGrpcController < ServiceController
  end

  SUCCESS_MOCK_COMMAND = "grpcurl  -import-path /import/path  -proto some/example/examples.proto  -H 'AUTHORIZATION:auth-token'  -plaintext  -v  -d {\"field_one\":\"1\",\"field_two\":\"two\",\"field_three\":\"true\"}  example.com:443  com.example.proto.ExampleService/ExampleMethod "
  SUCCESS_MOCK_RESPONSE = "\nResolved method descriptor:\n// Test method ( .com.example.proto.ExampleMethod ) returns ( .com.example.proto.ExampleResponse );\n\nRequest metadata to send:\nauthorization: auth-token\n\nResponse headers received:\naccess-control-expose-headers: X-REQUEST-UUID\ncontent-type: application/grpc+proto\ndate: Fri, 17 Apr 2020 00:58:49 GMT\nserver: test\nx-request-uuid: 58e3a8c0-xxxx-xxxx-xxxx-e4fbcead7c00\n\nResponse contents:\n{\n  \"exampleResponse\": {\n    \"foo\": \"BAR\"\n  }\n}\n\nResponse trailers received:\ndate: Fri, 17 Apr 2020 19:34:42 GMT\nSent 1 request and received 1 response\n"

  DEFAULT_SUCCESS_PARAMS = {
      options: {
          verbose: true,
          import_path: "/import/path",
          service_proto_path: "some/example/examples.proto",
          insecure: false
      },
      server_address: "example.com:443",
      service_name: "com.example.proto.ExampleService",
      method_name: "ExampleMethod",
      data: {
          field_one: 1,
          field_two: "two",
          field_three: true
      }
  }

  test "should get GRPC headers" do
    controller = TestGrpcController.new()
    grpc_only_headers = controller.get_grpc_headers({ "HTTP_GRPC_test" => "foo", "HTTP_OTHER_HEADER" => "bar" })
    expected = { "test" => "foo" }
    assert_equal expected, grpc_only_headers
  end

  test "command - should succeed with correct call" do
    post service_command_path,
         headers: { "HTTP_NON_GRPC_OTHER": "some value",
                    "HTTP_GRPC_AUTHORIZATION": "auth-token" },
         params: {
             options: {
                 verbose: true,
                 import_path: "/import/path",
                 service_proto_path: "some/example/examples.proto",
                 insecure: false
             },
             server_address: "example.com:443",
             service_name: "com.example.proto.ExampleService",
             method_name: "ExampleMethod",
             data: {
                 field_one: 1,
                 field_two: "two",
                 field_three: true
             }
         }

    assert_response :success
    json_response = JSON.parse(@response.body)
    expected_response = "grpcurl  -import-path /import/path  -proto some/example/examples.proto  -H 'AUTHORIZATION:auth-token'  -plaintext  -v  -d {\"field_one\":\"1\",\"field_two\":\"two\",\"field_three\":\"true\"}  example.com:443  com.example.proto.ExampleService/ExampleMethod "
    assert_equal expected_response, json_response["command"]
  end

  test "command - should fail with incorrect call" do
    # Empty request to trigger errors
    post service_command_path,
         headers: {},
         params: {
             options: {},
             data: {}
         }

    assert_response :bad_request
    json_response = JSON.parse(@response.body)
    expected_response = ["method_name is not set", "service_name is not set", "server_address is not set"]
    assert_equal expected_response, json_response["errors"]
  end

  test 'execute - should handle success response' do
    executor_mock = MiniTest::Mock.new
    executor_mock.expect :call, GrpcurlResult.new({command: SUCCESS_MOCK_COMMAND, raw_output: SUCCESS_MOCK_RESPONSE, raw_errors: ""}), [GrpcurlBuilder]

    GrpcurlExecutor.stub :execute, executor_mock do
      post service_execute_path,
           headers: { "HTTP_NON_GRPC_OTHER": "some value",
                      "HTTP_GRPC_AUTHORIZATION": "auth-token" },
           params: DEFAULT_SUCCESS_PARAMS

      assert_response :success
      json_response = JSON.parse(@response.body)
      assert json_response["success"]
      assert_equal SUCCESS_MOCK_COMMAND, json_response["command"]
      assert_equal SUCCESS_MOCK_RESPONSE, json_response["full_output"]
      expected_response = {"exampleResponse"=>{"foo"=>"BAR"}}
      assert_equal expected_response, json_response["response"]
    end

    assert_mock executor_mock
  end

  test 'execute - should handle failure response' do
    error_string = "Test-Error"
    executor_mock = MiniTest::Mock.new
    executor_mock.expect :call, GrpcurlResult.new({command: SUCCESS_MOCK_COMMAND, raw_output: "", raw_errors: error_string}), [GrpcurlBuilder]

    GrpcurlExecutor.stub :execute, executor_mock do
      post service_execute_path,
           headers: { "HTTP_NON_GRPC_OTHER": "some value",
                      "HTTP_GRPC_AUTHORIZATION": "auth-token" },
           params: DEFAULT_SUCCESS_PARAMS

      assert_response :bad_request
      json_response = JSON.parse(@response.body)
      assert_not json_response["success"]
      assert_equal error_string, json_response["errors"]
      assert_equal SUCCESS_MOCK_COMMAND, json_response["command"]
    end

    assert_mock executor_mock
  end

  test 'execute - should handle bad input' do
    executor_mock = MiniTest::Mock.new

    GrpcurlExecutor.stub :execute, executor_mock do
      post service_execute_path,
           headers: { "HTTP_NON_GRPC_OTHER": "some value",
                      "HTTP_GRPC_AUTHORIZATION": "auth-token" },
           params: {
               options: {},
               data: {}
           }

      assert_response :bad_request
      json_response = JSON.parse(@response.body)
      expected_response = ["method_name is not set", "service_name is not set", "server_address is not set"]
      assert_equal expected_response, json_response["errors"]
    end

    assert_mock executor_mock
  end
end

require 'test_helper'

class ServiceControllerTest < ActionDispatch::IntegrationTest

  class TestGrpcController < ServiceController
  end

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
                 insecure: false,
                 server_address: "example.com:443",
                 service_name: "com.example.proto.ExampleService",
                 method_name: "ExampleMethod"
             },
             data: {
                 field_one: 1,
                 field_two: "two",
                 field_three: true
             }
         }

    assert_response :success
    json_response = JSON.parse(@response.body)
    expected_response = "grpcurl  -import-path /import/path  -proto some/example/examples.proto  -H 'AUTHORIZATION:auth-token'  -plaintext  -v  -d {\"field_one\"=>\"1\", \"field_two\"=>\"two\", \"field_three\"=>\"true\"}  example.com:443  com.example.proto.ExampleService/ExampleMethod "
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
end

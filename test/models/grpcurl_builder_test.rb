require 'test_helper'

class GrpcurlBuilderTest < ActiveSupport::TestCase

  DEFAULT_IMPORT_PATH = '/import/path'
  DEFAULT_PROTO_PATH = 'proto/path/example.proto'
  DEFAULT_DATA = { test: "json data" }
  DEFAULT_SERVER_ADDRESS = 'test.example.com:443'
  DEFAULT_SERVICE_NAME = "com.example.protos.test.ExampleService"
  DEFAULT_METHOD_NAME = 'FooMethod'
  DEFAULT_HEADERS = { "Authorization" => "auth-token" }

  DEFAULT_PRESENT_ERROR = 'Option PRESENT did not return expected result'
  DEFAULT_OMITTED_ERROR = 'Option OMITTED did not return expected result'

  test "Init via constructor" do
    builder = GrpcurlBuilder.new(import_path: DEFAULT_IMPORT_PATH,
                                 service_proto_path: DEFAULT_PROTO_PATH,
                                 data: DEFAULT_DATA,
                                 insecure: false,
                                 server_address: DEFAULT_SERVER_ADDRESS,
                                 service_name: DEFAULT_SERVICE_NAME,
                                 method_name: DEFAULT_METHOD_NAME,
                                 verbose_output: true,
                                 headers: DEFAULT_HEADERS)
    assert_equal DEFAULT_IMPORT_PATH, builder.import_path
    assert_equal DEFAULT_PROTO_PATH, builder.service_proto_path
    assert_equal DEFAULT_DATA, builder.data
    assert_equal DEFAULT_SERVER_ADDRESS, builder.server_address
    assert_equal DEFAULT_SERVICE_NAME, builder.service_name
    assert_equal DEFAULT_METHOD_NAME, builder.method_name
    assert_equal DEFAULT_HEADERS, builder.headers
    assert_equal false, builder.insecure
    assert_equal true, builder.verbose_output
    assert_equal [], builder.hints
  end

  test "init via from_params" do
    headers = DEFAULT_HEADERS
    params = {
        "options" => {
            "import_path" => DEFAULT_IMPORT_PATH,
            "service_proto_path" => DEFAULT_PROTO_PATH,
            "insecure" => true,
            "verbose" => false
        },
        "server_address" => DEFAULT_SERVER_ADDRESS,
        "service_name" => DEFAULT_SERVICE_NAME,
        "method_name" => DEFAULT_METHOD_NAME,
        "data" => DEFAULT_DATA,
        "headers" => DEFAULT_HEADERS
    }
    builder = GrpcurlBuilder.from_params(headers, params)

    assert_equal DEFAULT_IMPORT_PATH, builder.import_path
    assert_equal DEFAULT_PROTO_PATH, builder.service_proto_path
    assert_equal DEFAULT_DATA, builder.data
    assert_equal DEFAULT_SERVER_ADDRESS, builder.server_address
    assert_equal DEFAULT_SERVICE_NAME, builder.service_name
    assert_equal DEFAULT_METHOD_NAME, builder.method_name
    assert_equal DEFAULT_HEADERS, builder.headers
    assert_equal true, builder.insecure
    assert_equal false, builder.verbose_output
    assert_equal [], builder.hints
  end

  test "should handle import path" do
    # Option present
    builder = build(:grpcurl_builder, import_path: 'foobar')
    expected = "grpcurl  -import-path 'foobar'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, import_path: nil)
    expected = "grpcurl  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "import path handles difference between command and execute" do
    # Slash present command
    builder = build(:grpcurl_builder, import_path: '/foobar')
    expected = "grpcurl  -import-path '/foobar'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build(BuilderMode::COMMAND), DEFAULT_PRESENT_ERROR

    # Slash omitted command
    builder = build(:grpcurl_builder, import_path: 'foobar')
    expected = "grpcurl  -import-path 'foobar'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build(BuilderMode::COMMAND), DEFAULT_OMITTED_ERROR

    # Slash present execute
    builder = build(:grpcurl_builder, import_path: '/foobar')
    expected = "grpcurl  -import-path 'foobar'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build(BuilderMode::EXECUTE), DEFAULT_PRESENT_ERROR

    # Slash omitted execute
    builder = build(:grpcurl_builder, import_path: 'foobar')
    expected = "grpcurl  -import-path 'foobar'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build(BuilderMode::EXECUTE), DEFAULT_OMITTED_ERROR
  end

  test 'import path hints' do
    builder = build(:grpcurl_builder, import_path: '/foobar')
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert builder.hints.include?(BuilderHints::IMPORT_PATH_LEADING), "Proper hint for build not present: #{builder.hints}"

    builder = build(:grpcurl_builder, import_path: 'foobar')
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert_not builder.hints.include?(BuilderHints::IMPORT_PATH_LEADING), "Did not expect hint to be present: #{builder.hints}"
  end

  test "should handle service proto path path" do
    # Option present
    builder = build(:grpcurl_builder, service_proto_path: 'foobar')
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'foobar'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, service_proto_path: nil)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'service proto path hints' do
    builder = build(:grpcurl_builder, service_proto_path: '/foobar')
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert builder.hints.include?(BuilderHints::SERVICE_PROTO_PATH_LEADING), "Proper hint for build not present: #{builder.hints}"

    builder = build(:grpcurl_builder, service_proto_path: 'foobar')
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert_not builder.hints.include?(BuilderHints::SERVICE_PROTO_PATH_LEADING), "Did not expect hint to be present: #{builder.hints}"
  end

  test "should handle insecure flag" do
    # Option present
    builder = build(:grpcurl_builder, insecure: true)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -plaintext  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, insecure: false)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'insecure hints' do
    builder = build(:grpcurl_builder, insecure: true)
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert builder.hints.include?(BuilderHints::INSECURE_FLAG), "Proper hint for build not present: #{builder.hints}"

    builder = build(:grpcurl_builder, insecure: false)
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert_not builder.hints.include?(BuilderHints::INSECURE_FLAG), "Did not expect hint to be present: #{builder.hints}"
  end

  test "should handle data" do
    # Option present
    builder = build(:grpcurl_builder, data: DEFAULT_DATA)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, data: nil)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should handle server address" do
    # Option present
    builder = build(:grpcurl_builder, server_address: DEFAULT_SERVER_ADDRESS)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  #{DEFAULT_SERVER_ADDRESS}  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, server_address: nil)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should fail with missing server address" do
    builder = build(:grpcurl_builder)
    assert builder.valid?
    assert_empty builder.errors

    builder = build(:grpcurl_builder, server_address: nil)
    assert_not builder.valid?
    assert_not_empty builder.errors
    assert_equal builder.errors.first, "server_address is not set"
  end

  test "should handle service name" do
    # Option present
    builder = build(:grpcurl_builder, service_name: DEFAULT_SERVICE_NAME)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  #{DEFAULT_SERVICE_NAME}/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, service_name: nil)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443 /ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should fail with missing service name" do
    builder = build(:grpcurl_builder)
    assert builder.valid?
    assert_empty builder.errors

    builder = build(:grpcurl_builder, service_name: nil)
    assert_not builder.valid?
    assert_not_empty builder.errors
    assert_equal builder.errors.first, "service_name is not set"
  end

  test "should handle method name" do
    # Option present
    builder = build(:grpcurl_builder, method_name: DEFAULT_METHOD_NAME)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/#{DEFAULT_METHOD_NAME} "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, method_name: nil)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService"
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should accept leading / or . on method name" do
    # With leading /
    builder = build(:grpcurl_builder, method_name: '/MethodName')
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/MethodName "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # with leading .
    builder = build(:grpcurl_builder, method_name: '.MethodName')
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService.MethodName "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should fail with missing method name" do
    builder = build(:grpcurl_builder)
    assert builder.valid?
    assert_empty builder.errors

    builder = build(:grpcurl_builder, method_name: nil)
    assert_not builder.valid?
    assert_not_empty builder.errors
    assert_equal builder.errors.first, "method_name is not set"
  end

  test 'method name hints' do
    builder = build(:grpcurl_builder, method_name: '/MethodName')
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert builder.hints.include?(BuilderHints::METHOD_NAME_LEADING), "Proper hint for build not present: #{builder.hints}"

    builder = build(:grpcurl_builder, method_name: '.MethodName')
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert builder.hints.include?(BuilderHints::METHOD_NAME_LEADING), "Proper hint for build not present: #{builder.hints}"

    builder = build(:grpcurl_builder, method_name: 'MethodName')
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert_not builder.hints.include?(BuilderHints::METHOD_NAME_LEADING), "Did not expect hint to be present: #{builder.hints}"
  end

  test "should handle headers" do
    # Option present
    builder = build(:grpcurl_builder, headers: DEFAULT_HEADERS)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -H 'Authorization:auth-token'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option present - multiple headers
    # Header order should be retained - if this assumption changes we can simply adjust this assertion to check for both headers being present
    builder = build(:grpcurl_builder, headers: { "Authorization" => "auth-token", "OtherHeader" => "FooBar" })
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -H 'Authorization:auth-token'  -H 'OtherHeader:FooBar'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, headers: nil)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

end
require 'test_helper'

class GrpcurlBuilderTest < ActiveSupport::TestCase

  DEFAULT_IMPORT_PATH = '/import/path'
  DEFAULT_PROTO_PATH = 'proto/path/example.proto'
  DEFAULT_DATA = { test: 'json data' }
  DEFAULT_SERVER_ADDRESS = 'test.example.com:443'
  DEFAULT_SERVICE_NAME = 'com.example.protos.test.ExampleService'
  DEFAULT_METHOD_NAME = 'FooMethod'
  DEFAULT_HEADERS = {}
  DEFAULT_HEADERS[ServiceController::GRPC_REQUEST_HEADER_PREFIX] = {'Authorization' => 'auth-token' }

  DEFAULT_PRESENT_ERROR = 'Option PRESENT did not return expected result'
  DEFAULT_OMITTED_ERROR = 'Option OMITTED did not return expected result'

  test 'Init via constructor' do
    builder = GrpcurlBuilder.new(import_path: DEFAULT_IMPORT_PATH,
                                 service_proto_path: DEFAULT_PROTO_PATH,
                                 data: DEFAULT_DATA,
                                 plaintext: false,
                                 server_address: DEFAULT_SERVER_ADDRESS,
                                 service_name: DEFAULT_SERVICE_NAME,
                                 method_name: DEFAULT_METHOD_NAME,
                                 max_message_size: 15,
                                 connect_timeout: 10,
                                 max_time: 5,
                                 verbose_output: true,
                                 headers: DEFAULT_HEADERS,
                                 assistant_options: 'auto_format_dates:true;test_option:false')
    assert_equal DEFAULT_IMPORT_PATH, builder.import_path
    assert_equal DEFAULT_PROTO_PATH, builder.service_proto_path
    assert_equal DEFAULT_DATA, builder.data
    assert_equal DEFAULT_SERVER_ADDRESS, builder.server_address
    assert_equal DEFAULT_SERVICE_NAME, builder.service_name
    assert_equal DEFAULT_METHOD_NAME, builder.method_name
    assert_equal DEFAULT_HEADERS, builder.headers
    assert_equal false, builder.plaintext
    assert_equal 15, builder.max_message_size
    assert_equal 10, builder.connect_timeout
    assert_equal 5, builder.max_time
    assert_equal true, builder.verbose_output
    assert_equal [], builder.hints
    default_assist_options = { 'auto_format_dates' => 'true', 'test_option' => 'false' }
    assert_equal default_assist_options, builder.assistant_options
  end

  test 'assistant options populate correctly on init' do
    no_options = nil
    no_options_expected = {}
    blank_options = ''
    blank_options_expected = {}
    one_option = 'auto_format_dates:true'
    one_option_expected = {'auto_format_dates' => 'true'}
    many_options = 'option1:true;option2:false;option3:1'
    many_options_expected = {'option1' => 'true', 'option2' => 'false', 'option3' => '1'}

    no_options_builder = GrpcurlBuilder.new(assistant_options: no_options)
    assert_equal no_options_expected, no_options_builder.assistant_options

    blank_options_builder = GrpcurlBuilder.new(assistant_options: blank_options)
    assert_equal blank_options_expected, blank_options_builder.assistant_options

    one_option_builder = GrpcurlBuilder.new(assistant_options: one_option)
    assert_equal one_option_expected, one_option_builder.assistant_options

    many_options_builder = GrpcurlBuilder.new(assistant_options: many_options)
    assert_equal many_options_expected, many_options_builder.assistant_options
  end

  test 'init via from_params' do
    DEFAULT_SUCCESS_META_HEADERS = { 'SERVER_ADDRESS': DEFAULT_SERVER_ADDRESS,
                                     'VERBOSE': 'false',
                                     'IMPORT_PATH': DEFAULT_IMPORT_PATH,
                                     'SERVICE_PROTO_PATH': DEFAULT_PROTO_PATH,
                                     'PLAINTEXT': 'true',
                                     'GAS_OPTIONS': 'option1:true;option2:1',
                                     'MAX_MESSAGE_SIZE': '15',
                                     'MAX_TIME': '10',
                                     'CONNECT_TIMEOUT': '5'}
    params = {
        'service_name' => DEFAULT_SERVICE_NAME,
        'method_name' => DEFAULT_METHOD_NAME,
    }
    builder = GrpcurlBuilder.from_params(DEFAULT_SUCCESS_META_HEADERS, DEFAULT_HEADERS, params, DEFAULT_DATA)

    assert_equal DEFAULT_IMPORT_PATH, builder.import_path
    assert_equal DEFAULT_PROTO_PATH, builder.service_proto_path
    assert_equal DEFAULT_DATA, builder.data
    assert_equal DEFAULT_SERVER_ADDRESS, builder.server_address
    assert_equal DEFAULT_SERVICE_NAME, builder.service_name
    assert_equal DEFAULT_METHOD_NAME, builder.method_name
    assert_equal DEFAULT_HEADERS, builder.headers
    assert_equal true, builder.plaintext
    assert_equal '15', builder.max_message_size
    assert_equal '10', builder.max_time
    assert_equal '5', builder.connect_timeout
    assert_equal false, builder.verbose_output
    assert_equal [], builder.hints
    expected_options = {'option1' => 'true', 'option2' => '1'}
    assert_equal expected_options, builder.assistant_options
  end

  test 'should handle import path' do
    # Option present
    builder = build(:grpcurl_builder, import_path: 'foobar')
    expected = 'grpcurl  -import-path \'foobar\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, import_path: nil)
    expected = 'grpcurl  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'import path handles difference between command and execute' do
    # Slash present command
    builder = build(:grpcurl_builder, import_path: '/foobar')
    expected = 'grpcurl  -import-path \'/foobar\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build(BuilderMode::COMMAND), DEFAULT_PRESENT_ERROR

    # Slash omitted command
    builder = build(:grpcurl_builder, import_path: 'foobar')
    expected = 'grpcurl  -import-path \'foobar\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build(BuilderMode::COMMAND), DEFAULT_OMITTED_ERROR

    # Slash present execute
    builder = build(:grpcurl_builder, import_path: '/foobar')
    expected = 'grpcurl  -import-path \'foobar\'  -proto \'path/to/main/service/proto/file.proto\'  -v  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build(BuilderMode::EXECUTE), DEFAULT_PRESENT_ERROR

    # Slash omitted execute
    builder = build(:grpcurl_builder, import_path: 'foobar')
    expected = 'grpcurl  -import-path \'foobar\'  -proto \'path/to/main/service/proto/file.proto\'  -v  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
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

  test 'should handle service proto path path' do
    # Option present
    builder = build(:grpcurl_builder, service_proto_path: 'foobar')
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'foobar\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, service_proto_path: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
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

  test 'should handle plaintext flag' do
    # Option present
    builder = build(:grpcurl_builder, plaintext: true)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -plaintext  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, plaintext: false)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'plaintext hints' do
    builder = build(:grpcurl_builder, plaintext: true)
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert builder.hints.include?(BuilderHints::PLAINTEXT_FLAG), "Proper hint for build not present: #{builder.hints}"

    builder = build(:grpcurl_builder, plaintext: false)
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert_not builder.hints.include?(BuilderHints::PLAINTEXT_FLAG), "Did not expect hint to be present: #{builder.hints}"
  end

  test 'should handle verbose flag' do
    # Option present
    builder = build(:grpcurl_builder, verbose_output: true)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -v  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, verbose_output: false)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should handle verbose flag differently for execute and command' do
    # Command
    builder = build(:grpcurl_builder, verbose_output: false)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build(BuilderMode::COMMAND), DEFAULT_PRESENT_ERROR

    # Execute - always enabled to execute for additional debugging and parsing output
    builder = build(:grpcurl_builder, verbose_output: false)
    expected = 'grpcurl  -import-path \'path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -v  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build(BuilderMode::EXECUTE), DEFAULT_OMITTED_ERROR
  end

  test 'should handle max message size flag' do
    # Option present
    builder = build(:grpcurl_builder, max_message_size: 25)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -max-msg-sz 25  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, max_message_size: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should handle max time flag' do
    # Option present
    builder = build(:grpcurl_builder, max_time: 25)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -max-time 25  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, max_time: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should handle connect timeout flag' do
    # Option present
    builder = build(:grpcurl_builder, connect_timeout: 25)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -connect-timeout 25  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, max_time: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should handle data' do
    # Option present - hash data
    builder = build(:grpcurl_builder, data: DEFAULT_DATA)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # String data
    builder = build(:grpcurl_builder, data: DEFAULT_DATA.to_json)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, data: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should handle gas options (dates) in data' do
    builder = build(:grpcurl_builder, assistant_options: {'auto_format_dates' => true}, data: DEFAULT_DATA.merge({timestamp: '2020-05-02T23:39:21Z', date: '2009-06-06'}))
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data","timestamp":{"seconds":1588462761,"nanos":0},"date":{"year":2009,"month":6,"day":6}}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR
  end

  test 'should not handle gas options (dates) in data if turned off' do
    builder = build(:grpcurl_builder, assistant_options: {'auto_format_dates' => false}, data: DEFAULT_DATA.merge({timestamp: '2020-05-02T23:39:21Z', date: '2009-06-06'}))
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data","timestamp":"2020-05-02T23:39:21Z","date":"2009-06-06"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR
  end

  test 'data hints' do
    # Valid JSON body
    builder = build(:grpcurl_builder, data: DEFAULT_DATA)
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert_not builder.hints.include?(BuilderHints::INVALID_JSON), "Hint that should not be present is: #{builder.hints}"

    # invalid json body
    builder = build(:grpcurl_builder, data: "[sdfsadf][- - - {}[")
    assert_empty builder.hints
    builder.build(BuilderMode::COMMAND)
    assert builder.hints.include?(BuilderHints::INVALID_JSON), "Proper hint for build not present: #{builder.hints}"
  end

  test 'should handle server address' do
    # Option present
    builder = build(:grpcurl_builder, server_address: DEFAULT_SERVER_ADDRESS)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  #{DEFAULT_SERVER_ADDRESS}  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, server_address: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should fail with missing server address' do
    builder = build(:grpcurl_builder)
    assert builder.valid?
    assert_empty builder.errors

    builder = build(:grpcurl_builder, server_address: nil)
    assert_not builder.valid?
    assert_not_empty builder.errors
    assert_equal builder.errors.first, 'server_address is not set'
  end

  test 'should handle service name' do
    # Option present
    builder = build(:grpcurl_builder, service_name: DEFAULT_SERVICE_NAME)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  #{DEFAULT_SERVICE_NAME}/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, service_name: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443 /ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should fail with missing service name' do
    builder = build(:grpcurl_builder)
    assert builder.valid?
    assert_empty builder.errors

    builder = build(:grpcurl_builder, service_name: nil)
    assert_not builder.valid?
    assert_not_empty builder.errors
    assert_equal builder.errors.first, 'service_name is not set'
  end

  test 'should handle method name' do
    # Option present
    builder = build(:grpcurl_builder, method_name: DEFAULT_METHOD_NAME)
    expected = "grpcurl  -import-path '/path/to/importable/protos'  -proto 'path/to/main/service/proto/file.proto'  -d '{\"test\":\"json data\"}'  example.com:443  com.example.protos.ExampleService/#{DEFAULT_METHOD_NAME} "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, method_name: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService'
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should accept leading / or . on method name' do
    # With leading /
    builder = build(:grpcurl_builder, method_name: '/MethodName')
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/MethodName '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # with leading .
    builder = build(:grpcurl_builder, method_name: '.MethodName')
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService.MethodName '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should fail with missing method name' do
    builder = build(:grpcurl_builder)
    assert builder.valid?
    assert_empty builder.errors

    builder = build(:grpcurl_builder, method_name: nil)
    assert_not builder.valid?
    assert_not_empty builder.errors
    assert_equal builder.errors.first, 'method_name is not set'
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


  # Note on header testing. Headers are automatically upcased and convert all underscores to hyphens. The service
  # controller will automatically revert this change as it is typical to use hyphens when adding custom
  # headers (underscores are not handled by all servers). Therefore the regular header tests ensure that nothing is
  # changed while the underscore_override header tests ensure that the underscores are put back where they should be.


  test 'should handle -H headers' do
    # Option present
    builder = build(:grpcurl_builder, headers: DEFAULT_HEADERS)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -H \'Authorization:auth-token\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option present - multiple headers
    # Header order should be retained - if this assumption changes we can simply adjust this assertion to check for both headers being present
    multiple_headers = {}
    multiple_headers[ServiceController::GRPC_REQUEST_HEADER_PREFIX] = { 'Authorization' => 'auth-token', 'Other-Header' => 'FooBar' }
    builder = build(:grpcurl_builder, headers: multiple_headers)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -H \'Authorization:auth-token\'  -H \'Other-Header:FooBar\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, headers: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should handle rpc headers' do

    # Option present - multiple headers
    # Header order should be retained - if this assumption changes we can simply adjust this assertion to check for both headers being present
    multiple_headers = {}
    multiple_headers[ServiceController::GRPC_RPC_HEADER_PREFIX] = { 'Authorization' => 'auth-token', 'rpcHeader-Example' => 'FooBar' }
    builder = build(:grpcurl_builder, headers: multiple_headers)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -rpc-header \'Authorization:auth-token\'  -rpc-header \'rpcHeader-Example:FooBar\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, headers: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test 'should handle reflect headers' do

    # Option present - multiple headers
    # Header order should be retained - if this assumption changes we can simply adjust this assertion to check for both headers being present
    multiple_headers = {}
    multiple_headers[ServiceController::GRPC_REFLECT_HEADER_PREFIX] = { 'Authorization' => 'auth-token', 'reflect-Header_Example' => 'FooBar' }
    builder = build(:grpcurl_builder, headers: multiple_headers)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -reflect-header \'Authorization:auth-token\'  -reflect-header \'reflect-Header_Example:FooBar\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, headers: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  # Handle headers with underscore options - basically it does not modify the headers at all
  test 'should handle underscore override -H headers' do
    UNDERSCORE_HEADERS = {}
    UNDERSCORE_HEADERS[ServiceController::GRPC_REQUEST_HEADER_PREFIX] = {'Authorization' => 'auth-token', 'Other-Header-Test' => 'foo' }
    builder = build(:grpcurl_builder, headers: UNDERSCORE_HEADERS, assistant_options: 'use_header_underscores:true')
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -H \'Authorization:auth-token\'  -H \'Other_Header_Test:foo\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR
  end

  test 'should handle underscore override rpc headers' do
    UNDERSCORE_HEADERS = {}
    UNDERSCORE_HEADERS[ServiceController::GRPC_RPC_HEADER_PREFIX] = {'Authorization' => 'auth-token', 'Other-Header_Test' => 'foo' }
    builder = build(:grpcurl_builder, headers: UNDERSCORE_HEADERS, assistant_options: 'use_header_underscores:true')
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -rpc-header \'Authorization:auth-token\'  -rpc-header \'Other_Header_Test:foo\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR
  end

  test 'should handle underscore override reflect headers' do
    UNDERSCORE_HEADERS = {}
    UNDERSCORE_HEADERS[ServiceController::GRPC_REFLECT_HEADER_PREFIX] = {'Authorization' => 'auth-token', 'Other_Header_Test' => 'foo' }
    builder = build(:grpcurl_builder, headers: UNDERSCORE_HEADERS, assistant_options: 'use_header_underscores:true')
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -reflect-header \'Authorization:auth-token\'  -reflect-header \'Other_Header_Test:foo\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR
  end
end
require 'test_helper'

class GrpcurlBuilderTest < ActiveSupport::TestCase

  DEFAULT_IMPORT_PATH = '/import/path'
  DEFAULT_PROTO_PATH = 'proto/path/example.proto'
  DEFAULT_DATA = { test: 'json data' }
  DEFAULT_SERVER_ADDRESS = 'test.example.com:443'
  DEFAULT_SERVICE_NAME = 'com.example.protos.test.ExampleService'
  DEFAULT_METHOD_NAME = 'FooMethod'
  DEFAULT_HEADERS = { 'Authorization' => 'auth-token' }

  DEFAULT_PRESENT_ERROR = 'Option PRESENT did not return expected result'
  DEFAULT_OMITTED_ERROR = 'Option OMITTED did not return expected result'

  test 'Init via constructor' do
    builder = GrpcurlBuilder.new(import_path: DEFAULT_IMPORT_PATH,
                                 service_proto_path: DEFAULT_PROTO_PATH,
                                 data: DEFAULT_DATA,
                                 insecure: false,
                                 server_address: DEFAULT_SERVER_ADDRESS,
                                 service_name: DEFAULT_SERVICE_NAME,
                                 method_name: DEFAULT_METHOD_NAME,
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
    assert_equal false, builder.insecure
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
                                     'INSECURE': 'true',
                                     'GAS_OPTIONS': 'option1:true;option2:1'}
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
    assert_equal true, builder.insecure
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
    expected = 'grpcurl  -import-path \'foobar\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build(BuilderMode::EXECUTE), DEFAULT_PRESENT_ERROR

    # Slash omitted execute
    builder = build(:grpcurl_builder, import_path: 'foobar')
    expected = 'grpcurl  -import-path \'foobar\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
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

  test 'should handle insecure flag' do
    # Option present
    builder = build(:grpcurl_builder, insecure: true)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -plaintext  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, insecure: false)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
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

  test 'should handle headers' do
    # Option present
    builder = build(:grpcurl_builder, headers: DEFAULT_HEADERS)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -H \'Authorization:auth-token\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option present - multiple headers
    # Header order should be retained - if this assumption changes we can simply adjust this assertion to check for both headers being present
    builder = build(:grpcurl_builder, headers: { 'Authorization' => 'auth-token', 'OtherHeader' => 'FooBar' })
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -H \'Authorization:auth-token\'  -H \'OtherHeader:FooBar\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, headers: nil)
    expected = 'grpcurl  -import-path \'/path/to/importable/protos\'  -proto \'path/to/main/service/proto/file.proto\'  -d \'{"test":"json data"}\'  example.com:443  com.example.protos.ExampleService/ExampleMethod '
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end
end
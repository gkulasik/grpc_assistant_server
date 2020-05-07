FactoryBot.define do
  factory :grpcurl_builder, class: GrpcurlBuilder do
    import_path '/path/to/importable/protos'
    service_proto_path 'path/to/main/service/proto/file.proto'
    data {{test: "json data"}}
    plaintext false
    server_address 'example.com:443'
    service_name 'com.example.protos.ExampleService'
    method_name 'ExampleMethod'
    verbose_output false
    headers {{}}
    assistant_options 'auto_format_dates:true;test_option:false'
  end
end
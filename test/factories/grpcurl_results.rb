FactoryBot.define do

  factory :grpcurl_result_success, class: GrpcurlResult do
    command "test-command"
    raw_output "\nResolved method descriptor:\n// Test method ( .com.example.proto.ExampleMethod ) returns ( .com.example.proto.ExampleResponse );\n\nRequest metadata to send:\nauthorization: auth-token\n\nResponse headers received:\naccess-control-expose-headers: X-REQUEST-UUID\ncontent-type: application/grpc+proto\ndate: Fri, 17 Apr 2020 00:58:49 GMT\nserver: test\nx-request-uuid: 58e3a8c0-xxxx-xxxx-xxxx-e4fbcead7c00\n\nResponse contents:\n{\n  \"exampleResponse\": {\n    \"foo\": \"BAR\"\n  }\n}\n\nResponse trailers received:\ndate: Fri, 17 Apr 2020 19:34:42 GMT\nSent 1 request and received 1 response\n"
    raw_errors nil
    hints Array.new
  end

  factory :grpcurl_result_failure, class: GrpcurlResult do
    command "test-command"
    raw_output nil
    raw_errors "errors"
    hints Array.new
  end
end
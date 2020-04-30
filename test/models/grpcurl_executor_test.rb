require 'test_helper'
require 'open3'
class GrpcurlExecutorTest < ActiveSupport::TestCase

  # Tedious workaround test to ensure the proper methods are being called by this method
  test "executor should make appropriate calls" do
    # Mimic Open3 syntax
    module TestOpen3
      def popen3(*cmd, **opts, &block)
        yield TestReadable.new("stdin"), TestReadable.new("stdout"), TestReadable.new("stderr"), TestReadable.new("wait_thr")
      end

      module_function :popen3
    end

    # Mimic stdout, stderr, etc.
    class TestReadable
      attr_accessor :to_read

      def initialize(to_read)
        @to_read = to_read
      end

      def read
        @to_read
      end
    end

    builder = build(:grpcurl_builder)
    result = GrpcurlExecutor.execute(builder, TestOpen3)
    expected = GrpcurlResult.new({command: builder.build, raw_output: "stdout", raw_errors: "stderr", hints: builder.hints})
    # Use API response was way to ensure the same object is generated/returned
    assert_equal expected.to_api_response, result.to_api_response
  end

end
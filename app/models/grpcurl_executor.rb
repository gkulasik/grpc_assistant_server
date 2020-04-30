require 'open3'

class GrpcurlExecutor

  # Interface with system to execute grpcurl commands and capture response
  # @param [GrpcurlBuilder] grpcurl_builder
  # @param [Module] module to use for execution - used for test injection
  # @return [GrpcurlResult] command result
  def self.execute(grpcurl_builder, execution_module = Open3)
    command = grpcurl_builder.build(BuilderMode::COMMAND)
    execute = grpcurl_builder.build(BuilderMode::EXECUTE)
    puts "Command being executed: #{execute}"
    execution_module.popen3(execute) do |stdin, stdout, stderr, wait_thr|
      output = stdout.read
      errors = stderr.read
      puts "Output received: #{output}"
      puts "Errors received: #{errors}"
     GrpcurlResult.new({command: command, raw_output: output, raw_errors: errors})
    end
  end

end
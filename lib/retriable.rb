module Retriable
  # retriable_run(2) {|arg| some_method }
  def retriable_run(limit=3, &block)
    begin
      yield
    rescue => e
      retry if 0 < (limit -= 1)

      raise Errors::RetryLimitOverError.new("無念。最後のエラーメッセージはこちら「#{e.message}」")
    end
  end
end

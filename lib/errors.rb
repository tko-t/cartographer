# エラー系は全部ココにまとめる
class Errors
  class RetryLimitOverError < StandardError; end
  class NoElmError < StandardError; end
  class ClickError < StandardError; end
end

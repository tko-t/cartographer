# ルーズに押せる機能を追加する
# includeすると、例外を握りつぶしてnilを返すメソッドを生やす
# 対象は"xxx!"。すでに "xxx" が存在する場合は何もしない
module Looseable
  def self.included(base)
    base.instance_methods.select do |m|
      # "!" もメソッドなのでend_with?は使えない
      m =~ /^.+!\z/
    end.each do |origin_method|
      # 末尾の "!" を削除
      loose_method = origin_method.to_s.strip.chop
      # 同じ名前のメソッドがあるならスキップ
      next if base.methods.include?(loose_method)

      # xxx! で例外を握りつぶすメソッド追加する
      base.define_method(loose_method) do |*args|
        method(origin_method).call(*args)
      rescue
        nil # 例外はnilを返す
      end
    end
  end 
end

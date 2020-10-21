# Gaze
#   -> "視線、凝視、見つめる" など
# 自身を引数としたブロックの結果を返り値とできる
# .e.g: User.find(user_id).gaze {|user| [user.first_name, user.last_name].join(' ') }
#       即席メソッドを生やせるイメージ
# .e.g: URI('http://foo.com:3000/bar').extend(Gaze).gaze {|uri| [uri.scheme, uri.host, uri.path, uri.query] }
#       => ['http','foo.com', 'bar', nil]
#       既存のモジュールにはextendで
module Gaze
  def gaze(&block)
    block.call(self)
  end

  def self.gaze(&block)
    block.call(self)
  end
end

require 'digest'
class Route
  attr_accessor *%i[clazz comment href id elm_name name routes root src ss state title type from to]

  def self.build(json:nil)
    src = JSON.parse(json, symbolize_names: true)
    # routeはRouteオブジェクトにしてから渡したいので除外する
    route = new(**src.except(:routes))

    # routesツリーを生成
    make_routes(route, src)

    return route
  end

  # routeを起点にツリーを生成
  def self.make_routes(route, src)
    route.routes = src[:routes].map do |src_route|
      r = new(**src_route.except(:routes))
      make_routes(r, src_route)
      r
    end
  end

  def initialize(elm: {}, routes: [], **args)
    @clazz    = args[:clazz] || elm[:class]
    @comment  = args[:comment]
    @href     = args[:href]  || elm[:href]            # リンク先
    @id       = args[:id] || elm[:id]
    @label    = (args[:label] || elm[:innerText] || elm[:alt])&.strip&.gsub(/[\r\n]/, '') # anchorかbuttonの表示ラベル(innerText)
    @elm_name = args[:node_name] || elm[:name]        # 
    @name     = args[:name]                           # リンク先を一意に識別できるように
    @routes   = routes                                # 自分から直接つながってるリンク先一覧
    @root     = args[:root]  || :false                # ready(未探索), done(探索済), fail(エラー)
    @src      = args[:src]   || elm[:src]             # imgのsrc(imgなら必須)
    @ss       = args[:ss]                             # スクリーンショットのファイル名
    @state    = args[:state]&.to_sym || :ready        # ready(未探索), done(探索済), fail(エラー)
    @title    = args[:title] || elm[:title]           # ページのタイトル
    @type     = (args[:type] || elm[:tagName])&.upcase # :button || :anchor || :image (何をクリックするのか
    @from     = args[:from]
    @to       = nil                                   # 移動してから設定する
    @name   ||= route_name                            # nameが渡されなかったら作る

    @href = URI(self.from).extend(Gaze).gaze do |uri|
      "#{uri.scheme}://#{uri.host}:#{uri.port}"
    end + @href if @href && @href&.match?(/^http[s]*:\/\/.+/) == false
  end

  def label
    @label.presence || [url_to_path(from), 'to', url_to_path(to), type, id, elm_name, clazz]
      .map(&:presence)
      .compact
      .join('_')
      .gsub(/[\r\n]/, '')
  end

  def to_json
    to_hash.to_json
  end

  def to_hash
    {
      href:     href,
      type:     type,
      label:    label,
      src:      src,
      ss:       ss,
      name:     name,
      state:    state,
      title:    title,
      root:     root,
      routes:   routes.map(&:to_hash),
      from:     from,
      to:       to,
      clazz:    clazz,
      id:       id,
      elm_name: elm_name
    }
  end

  # 名前でrouteを探す
  def find(name)
    res = routes.find do |route|
      route.name == name
    end

    return res if res.present?

    routes.each do |route|
      res = route.find(name)
      break if res.present?
    end
    res
  end

  # Anchorでrouteを探す
  def find_anchor(href)
    res = routes.find do |route|
      route.type == "A" && route.href == href
    end

    return res if res.present?

    routes.each do |route|
      res = route.find_anchor(href)
      break if res.present?
    end
    res
  end

  # 最初の
  def first_ready
    return self if done? == false && ready?

    res = routes.find do |route|
      done? == false && ready?
    end

    return res if res.present?

    routes.each do |route|
      res = route.first_ready
      break if res.present?
    end
    res
  end

  # スクショの名前
  def ss_name
    URI(to).extend(Gaze).gaze do |uri|
      [uri.path, uri.fragment, name]
    end.map(&:presence).compact.join('_').gsub(/(\A[_]*|[_]*\z)/, '')
  end

  # route識別名
  def route_name
    Digest::MD5.hexdigest(
      [type, from, id, elm_name, clazz, label, src]
        .map(&:presence)
        .compact
        .map(&:strip)
        .join
        .gsub(/[\r\n]/, ''))
  end

  # 渡されたURLをパスとフラグだけにする
  # http://foo.com/path/to#flag
  # => path_to_flag
  def url_to_path(url)
    return "" unless url.present?

    URI(url).extend(Gaze).gaze do |uri|
      [uri.path, uri.fragment].map{|str| str&.gsub('/', '_') }
    end.join('_')
      .gsub(/[_]+/, '_')
      .gsub(/(\A[_]*|[_]*\z)/, '')
  end

  # routeツリーを見たいとき
  def listing
    [state, name].concat(
      routes.map do |r|
        r.listing
      end).flatten
  end

  def a_tag?
    self.type.upcase == "A"
  end

  def done!
    self.state = :done
  end

  # self以下全部doneにする
  def force_done!
    self.done!
    (self.routes || []).each do |r|
      r.force_done!
    end
  end

  def ready?
    self.state == :ready
  end

  def done?
    routes.each do |route|
      return false unless route.done?
    end
    self.state == :done
  end
end

require 'digest'
class Route
  attr_accessor *%i[comment href label routes name root src ss state title type url]

  def self.build(json:nil)
    src = JSON.parse(json, symbolize_names: true)
    route = new(**src.except(:routes))

    make_routes(route, src)

    return route
  end

  def self.make_routes(route, src)
    route.routes = src[:routes].map do |src_route|
      r = new(**src_route.except(:routes))
      make_routes(r, src_route)
      r
    end
  end

  def initialize(url: nil, elm: {}, routes: [], **args)
    @comment = args[:comment]
    @href    = args[:href]  || elm[:href]            # リンク先
    @label   = args[:label] || elm[:innerText] || elm[:alt] # anchorかbuttonの表示ラベル(innerText)
    @routes  = routes                                # 自分から直接つながってるリンク先一覧
    @name    = args[:name]                           # リンク先を一意に識別できるように
    @root    = args[:root]  || :false                # ready(未探索), done(探索済), fail(エラー)
    @src     = args[:src]   || elm[:src]             # imgのsrc(imgなら必須)
    @ss      = args[:ss]                             # スクリーンショットのファイル名
    @state   = args[:state]&.to_sym || :ready        # ready(未探索), done(探索済), fail(エラー)
    @title   = args[:title] || elm[:title]           # ページのタイトル
    @type    = args[:type]  || elm[:tagName]&.upcase # :button || :anchor || :image (何をクリックするのか
    @url     = url                                   # リンクのあるURL
    @name  ||= route_name # nameが渡されなかったら作る
  end

  def to_json
    to_hash.to_json
  end

  def to_hash
    {
      url:    url,
      href:   href,
      type:   type,
      label:  label,
      src:    src,
      ss:     ss,
      name:   name,
      state:  state,
      title:  title,
      root:   root,
      routes: routes.map(&:to_hash)
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
    URI(url).extend(Gaze).gaze do |uri|
      [uri.path, uri.fragment, name]
    end.map(&:presence).compact.join('_')
  end

  def route_name
    name = [type, url_to_path(url)]
    case type
    when "A"
      name << (label || '').extend(Gaze).gaze do |text|
        text = url_to_path(href || '')     unless text.present?
        text = Digest::MD5.hexdigest(text) if 50 < text.length
        text
      end
    when "BUTTON"
      name << (label || '').extend(Gaze).gaze do |text|
        text = Digest::MD5.hexdigest(text) if 50 < text.length
        text
      end
    when "IMG"
      name << (label.presence || Digest::MD5.hexdigest(src || ""))
    end
    name.map(&:presence).compact.join('_').gsub(/[\r\n]/, '')
  end

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

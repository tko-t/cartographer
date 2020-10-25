# 指定したURLをルートとして同じドメインのページを探し続ける
# 参照したページのルートとスクリーンショットを記録してまわる
class Exploration
  EXPLORATIONS = 'explorations'

  attr_accessor *%i[root_url work_name b routes]

  def self.init!(work_name)
    # 結果を吐き出すディレクトリ作成
    FileUtils.mkdir_p(File.join(EXPLORATIONS, work_name, 'images'))
  end

  def self.start!(url, work_name, browser_type=:firefox)
    new(url, work_name, browser_type)
  end

  private

  def initialize(url, work_name, browser_type)
    @b         = Browser.get(browser_type)
    @root_url  = url
    @work_name = work_name
    @route     = nil
    @b_type    = browser_type

    FileUtils.mkdir_p(image_dir)

    goto_root
  rescue => e
    binding.pry
  ensure
    b.close
  end

  # でちゃった？
  def outside?
    URI(b.location).host != URI(root_url).host
  end

  # 止める？
  def debug?
    File.exists?('debug')
  end

  def interval
    @interval ||= 1
  end

  # 履歴
  def histories
    @histories ||= []
  end

  def set_history(route)
    histories << { url: route.url, name: route.name, ss_path: route.ss }
  end

  def search(target_route)
    # リンクの一覧取得
    links = self.links

    # target_route.routesがなければ作る
    if target_route.routes.blank?
      target_route.routes = new_routes(links).reject do |r|
        # 同じ名前のrouteがあったら除外
        @route.find(r.name).present?
      end
    end

    # routes.doneじゃないroute
    next_route = target_route.routes.find do |route|
      route.done? == false
    end

    # なければrootからやり直す
    if next_route.blank?
      save_and_goto_root(target_route, comment: 'ルートがない')
      return
    end

    # 次に押すリンク
    next_link = links.find do |link|
      link_to_route(b.location, link)&.name == next_route.name
    end

    # なければrootからやり直す
    binding.pry if debug?
    if next_link.blank?
      next_route.done!
      save_and_goto_root(target_route, comment: '押せるリンクがない')
      return
    end

    # リンクを踏めた判定
    linked = false

    # クリック
    begin
      linked = click_and_ss!(next_link, next_route)
    rescue Errors::ClickError => click_error
      puts click_error.inspect
    end

    # クリックでコケたAタグはgoto
    if linked.blank? && next_route.a_tag? && next_route.href.present?
      begin
        linked = goto_and_ss!(next_route)
      rescue Errors::GotoError => goto_error
        puts goto_error.inspect
      end
    end

    binding.pry if debug?
    # リンク踏めたらsave
    if linked
      if outside?
        save_and_goto_root(next_route, comment: '出ちゃった', dead_end: true)
        return
      end
      save(next_route, dead_end: target_route.url == b.location)
    # 踏めなかったらsaveしてgoto_root
    else
      save_and_goto_root(next_route, comment: 'クリックでエラー', dead_end: true)
      return
    end

    search(next_route)
  end

  # routeのhrefに直接ジャンプしてSS
  def goto_and_ss!(route)
    begin
      binding.pry if debug?
      b.goto(route.href)
    rescue => e
      raise Errors::GotoError.new("#{e.message}: #{route.href}")
    end
    puts 'goto! ' + route.href
    sleep interval
    route.ss = File.basename(ss(route.ss_name)) unless route.ss
    true
  end

  # 要素をクリックしてSS
  def click_and_ss!(link, route)
    begin
      link.click
    rescue => e
      raise Errors::ClickError.new("#{e.message}: #{route.name}")
    end
    puts 'click! ' + route.name
    # タブ複数あったら古いタブ全部閉じる
    b.clean_tab!
    sleep interval
    route.ss = File.basename(ss(route.ss_name)) unless route.ss
    true
  end

  def save(route, comment: '', dead_end: false)
    if route.ready?
      route.title  = b.title
      route.comment = comment

      set_history(route)
      route.done!
    end
  end

  def save_and_goto_root(route, comment: '', dead_end: false)
    save(route, comment: comment, dead_end: dead_end)

    route_to_json
    down if @route.done?

    puts '/'
    goto_root
  end

  def route_to_json
    File.open(File.join(dir, 'route.json'), 'wb') do |f|
      f.puts @route.to_json
    end
  end

  def down
    File.open(File.join(dir, 'history.json'), 'wb') do |f|
      f.puts histories.to_json
    end

    File.open(File.join(dir, 'history.html'), 'wb') do |f|
      f.puts '<html>'
        histories.each do |history|
          f.puts "<p class='url'>#{history[:url]}</p>"
          f.puts "<p class='name'>#{history[:name]}</p>"
          f.puts "<img class='ss' src='images/#{history[:ss_path]}'/>"
        end
      f.puts '</html>'
    end

    puts '終了'
    exit
  end

  # root_urlからやり直します
  def goto_root
    b.goto(root_url)

    if @route.present?
      sleep interval
    else
      # 初回はrouteがないので作る
      @route = Route.new(url: b.location, name: 'root', title: b.title, root: true)
      # 初回だけちょっと長く待つ
      sleep 2
    end

    save(@route)

    progress

    search(@route)
  end


  def progress
    list  = @route.listing.group_by(&:itself)
    ready = list[:ready]&.count || 0
    done  = list[:done]&.count || 0

    binding.pry if debug?

    puts "progress: #{ready}/#{ready + done}"
  end

  # linkからrouteを取得
  def link_to_route(url, link)
    @route.find(Route.new(url: url, elm: link).name)
  end

  # 今いるページのリンクから[Route]を作る
  def new_routes(links=nil)
    routes = (links || self.links).map do |link|
      Route.new(url: b.location, elm: link)
    end.reject do |route|
      @route.find(route.name).present?
    end
  end

  def dir
    File.join(EXPLORATIONS, work_name)
  end

  def image_dir
    @image_dir ||= File.join(dir, "images")
  end

  # スクリーンショット撮る
  def ss(name=nil)
    b.ss!(image_dir, name)
  end

  # ページのリンクを取得
  def links
    [get_buttons, get_anchors].flatten
  end

  # ボタン一覧。見えて、アクティブで、ラベルがあるやつ
  def get_buttons
    b.find_elements(:tag_name, :button).select do |button|
      button.displayed? && button.enabled? && button[:innerText].presence
    end
  end

  # リンク一覧。見えて、アクティブで、ラベル or hrefがあるやつ
  # hrefがなくてもボタンやイメージをクリックで発火することもあるかと
  def get_anchors
    b.find_elements(:tag_name, :a).select do |a|
      flg = true
      flg = false if a[:innerText].presence.nil? && a[:href].presence.nil?
      flg = false if a[:href]&.match?(/\.(pdf|zip|xlsx|xls|doc|ppt|gz|tar)\z/)
      flg = false if a[:target] == '_blank' # 別タブ開くのはヤメて
      flg = false if a.displayed? == false
      flg = false if a.enabled? == false
      flg
    end
  rescue => e
    puts "[Error!]get_anchors: #{e.inspect}"
    return []
  end
end

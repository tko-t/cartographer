# 指定したURLをルートとして同じドメインのページを探し続ける
# 参照したページのルートとスクリーンショットを記録してまわる
class Exploration
  EXPLORATIONS = 'explorations'

  attr_accessor *%i[b work_name root histories]

  def self.init(work_name)
    # 結果を吐き出すディレクトリ作成
    FileUtils.mkdir_p(File.join(EXPLORATIONS, work_name, 'images'))
  end

  def self.start!(route, work_name, histories, browser_type=:firefox)
    exploration = new(route, work_name, histories, browser_type)
    exploration.search
  ensure
    exploration.b.quit
  end

  # target_routeのroutesを作る
  # next_route(doneじゃないroutes)を探す
  #   なければdoneにして終了
  # next_link(next_routeと同じ名前になるlink)
  #   なければdoneにして終了
  # next_linkをクリックする
  def search(target_route=nil)
    binding.pry if debug?

    target_route ||= @root

    # リンクの一覧取得
    links = self.links

    # target_route.routesがなければ作る
    target_route.routes = new_routes(links) if target_route.routes.blank?

    # routes.doneじゃないroute
    next_route = target_route.routes.find do |route|
      route.done? == false
    end

    # なければrootからやり直す
    if next_route.blank?
      return save_and_down(target_route, comment: '知らないルートがない')
    end

    # 次に押すリンク
    next_link = links.find do |link|
      link_to_route(b.location, link)&.name == next_route.name
    end

    # なければrootからやり直す
    if next_link.blank?
      next_route.comment = 'リンクが見つからないのでこのルートは閉じます'
      next_route.force_done!
      return save_and_down(target_route, comment: 'クリック可能なリンクがない')
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

    # リンク踏めたらsave
    if linked
      # 外出ちゃってたらルート閉じる
      if outside?
        next_route.force_done!
        return save_and_down(next_route, comment: '出ちゃった')
      end
      save(next_route)
    else
      # 踏めないときもルート閉じる
      next_route.force_done!
      return save_and_down(next_route, comment: 'クリックできず。gotoもできず')
    end

    # 次のルート探しに行こう
    search(next_route)
  rescue => e
    if next_route
      next_route.comment = e.message
      next_route.done!
    end

    if target_route
      target_route.comment = e.message
      target_route.done!
    end

    raise e
  end

  # routeとhistoryをjson出力して終了
  def down
    history_to_json
    route_to_json

    progress
  end

  private

  def initialize(route, work_name, histories, browser_type)
    @b         = Browser.get(browser_type)
    @work_name = work_name
    @root      = route
    @histories = histories

    goto_and_ss!(route)
  end

  # routeのhrefに直接ジャンプしてSS
  def goto_and_ss!(route)
    url = route.href || route.from
    puts "goto! #{url}: #{route.label}"

    begin
      b.goto(url)
      interval
      route.title  = b.title
      route.to     = b.location
      route.ss     = File.basename(ss(route.ss_name)) unless route.ss
    rescue => e
      raise Errors::GotoError.new("#{e.message}: #{url}")
    end
    true
  end

  # 要素をクリックしてSS
  def click_and_ss!(link, route)
    puts "click! #{route.label}"
    begin
      link.click
      # タブ複数あったら古いタブ全部閉じる
      b.clean_tab!
      interval
      route.title  = b.title
      route.to     = b.location
      route.ss     = File.basename(ss(route.ss_name)) unless route.ss
    rescue => e
      raise Errors::ClickError.new("#{e.message}: #{route.name}")
    end
    true
  end

  # routeをjsonにして保存
  def route_to_json
    File.open(File.join(dir, 'route.json'), 'wb') do |f|
      f.puts @root.to_json
    end
  end

  # historyをjsonにして保存
  def history_to_json
    File.open(File.join(dir, 'history.json'), 'wb') do |f|
      f.puts histories.to_json
    end
  end

  # 保存
  def save(route, comment: '')
    if route.ready?
      route.comment = comment
      route.done!

      set_history(route)
    end
  end

  def save_and_down(route, comment: '')
    save(route, comment: comment)
    down
  end

  # でちゃった？
  def outside?
    binding.pry if debug?
    URI(b.location).host != URI(@root.from).host
  end

  # 止める？
  def debug?
    File.exists?('debug')
  end

  # 待ち時間
  def interval
    sleep(1)
  end

  # 履歴追加
  def set_history(route)
    histories << { url: route.from, name: route.name, ss_path: route.ss }
  end

  def progress
    list  = @root.listing.group_by(&:itself)
    ready = list[:ready]&.count || 0
    done  = list[:done]&.count || 0

    puts "progress: #{done}/#{ready + done}"
  end

  # linkからrouteを取得
  def link_to_route(url, link)
    @root.find(Route.new(from: url, elm: link).name)
  end

  # 今いるページのリンクから[Route]を作る
  def new_routes(links=nil)
    links ||= self.links()
    routes = links.map do |link|
      Route.new(from: b.location, elm: link)
    end.reject do |route|
      check = @root.find(route.name).present?
      unless check
        binding.pry if debug? && route.a_tag?
        check = route.a_tag? &&
          route.href.present? &&
          root.find_anchor(route.href).present?
      end
      check
    end
  end

  def dir
    File.join(EXPLORATIONS, work_name)
  end

  def image_dir
    @image_dir ||= File.join(dir, 'images')
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
      # clickable があるらしい？
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

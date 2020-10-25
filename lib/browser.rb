# ブラウザ操作クライアント的なもの
class Browser
  include Retriable

  attr_accessor :driver

  def self.get(browser=:chrome, container=:selenium, port=24444)
    return Chrome.new(container, port) if browser == :chrome

    Firefox.new(container, port)
  end

  def make_arg(key, value)
    arg = {}
    arg[key]    = value                        if %i[id name css tag_name xpath].include?(key.to_sym)
    arg[:xpath] = "//input[@value='#{value}']" if key.to_sym == :value # valueってinputしかない？
    arg[:xpath] = "//img[@src='#{value}']"     if key.to_sym == :image # とりあえずimgで
    arg[:xpath] = "//*[text()='#{value}']"     if key.to_sym == :label
    arg
  end

  # 要素を配列で
  def find_elements(key, value)
    driver.find_elements(make_arg(key, value))
  end

  # 要素を一つだけ
  # ない場合はエラー
  # エラー無視したいときはfind_elementで
  def find_element!(key, value)
    driver.find_element(make_arg(key, value))
  end

  # 指定したURLへ遷移
  def goto(url)
    url = "http://#{url}" unless url.start_with?(/http[s]*:\/\//)
    driver.navigate.to(url)
  end

  # navigete.toと何が違うんだ？
  def get(url)
    url = "http://#{url}" unless url.start_with?(/http[s]*:\/\//)
    driver.get(url)
  end

  # 一つ前のページへ戻る
  def goback
    driver.navigate.back
  end

  # 現在のURL
  def location
    driver.current_url
  end

  # ページのタイトル
  def title
    driver.title
  end

  # find_elementでcssを渡したいときに
  # css(tag: "a", classes: "class_a class_b")
  # => "a.class_a.class_b"
  def css(tag: '', classes: '')
    [tag, classes.split(' ')].flatten.join('.')
  end

  # find_element().clickと一緒
  # エラーを無視したいときはclick
  def click!(key, value)
    elm = find_element(key, value)
    raise Errors::NoElmError.new("[#{location}][#{key}=#{value}]が見つからない") unless elm

    begin
      elm.click
    rescue
      raise Errors::ClickError.new("[#{location}][#{elm[:innerText]}]クリックエラー")
    end
  end

  def ss_name(name=nil)
    # 記号は使わせない
    "#{( name || title || location.gsub(/(^http[s]*?:\/\/)/, '')).gsub(/[!-\/:-@\[-`{-~ \-]/, '_')}.png"
  end

  # スクリーンショット
  def ss!(dir='./', name=nil)
    driver.save_screenshot(File.join(dir, ss_name(name)))
  end

  def displayed?(elm)
    elm.displayed?
  end

  def enabled?(elm)
    elm.enabled?
  end

  # alertのOK押す
  def accept
    driver.switch_to.alert.accept
  end

  # ブラウザを閉じる
  def close
    driver.quit
  end

  # タブが複数あるときは最後のタブ以外を閉汁
  def clean_tab!
    if 1 < driver.window_handles.count
      while driver.window_handles.count == 1
        driver.switch_to.window(driver.window_handles[0])
        driver.close
      end
    end
    driver.switch_to.window(driver.window_handles[0])
  end

  # xxx! のメソッドをdefineするので最後にincludeする
  include Looseable

  class Chrome < Browser
    def initialize(container, port)
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--no-sandbox")
      options.add_argument("--headless")
      @driver = Selenium::WebDriver.for(:remote, url: "http://#{container}:#{port}/wd/hub", desired_capabilities: :chrome)
    end
  end

  class Firefox < Browser
    def initialize(container, port)
      options = Selenium::WebDriver::Firefox::Options.new
      options.add_argument("--no-sandbox")
      options.add_argument("--headless")
      @driver = Selenium::WebDriver.for(:remote, url: "http://#{container}:#{port}/wd/hub", desired_capabilities: :firefox)
    end
  end
end

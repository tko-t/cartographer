class Browser::Chrome
  def initialize(url)
    options = Selenium::WebDriver::Chrome::Options.new
    #options = Selenium::WebDriver::Firefox::Options.new
    options.add_argument("--no-sandbox")
    options.add_argument("--headless")
    #options.add_argument("--dns-prefetch-disable")
    #options.add_argument("--test-type=webdriver")

    session = Selenium::WebDriver.for :chrome, options: options
    #session = Selenium::WebDriver.for :firefox, options: options

    session.navigate.to(url)

    session.find_element(:css, :html)
    session.find_element(:css, :html)[:innerHTML]
    session.quit
  end
end

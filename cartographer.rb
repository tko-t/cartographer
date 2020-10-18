$: << './'
$: << './lib'

require 'selenium-webdriver'                                                                                                                                                                            
require 'webdrivers'
require 'pry'

require 'errors'
require 'retriable'
require 'looseable'

Dir['./lib/**/*.rb'].sort.each do |f|
  require f
end

#Browser::Chrome.new('https://google.co.jp/')
begin
  @browser = Browser.get(:firefox)
  binding.pry
ensure
  @browser.close
end

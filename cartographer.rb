require 'selenium-webdriver'                                                                                                                                                                            
require 'webdrivers'
require 'pry'

Dir['./lib/**/*.rb'].sort.each do |f|
  require f
end

Browser::Chrome.new('https://google.co.jp/')

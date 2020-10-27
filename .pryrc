# ロードパス追加
$: << './'
$: << './lib'

# よそ様
require 'active_support/all'
require 'selenium-webdriver'
require 'webdrivers'
require 'json'
require 'pry-byebug'

# 自前
require 'errors'
require 'retriable'
require 'looseable'
require 'exploration'
require 'browser'

# lib配下の順番どうでもいい系
Dir['./lib/**/*.rb'].sort.each do |f|
  require f
end

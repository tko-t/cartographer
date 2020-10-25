# ロードパス追加
$: << './'
$: << './lib'

# よそ様
require 'active_support/all'
require 'selenium-webdriver'
require 'webdrivers'
require 'json'
require 'pry'

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

work_name = ARGV[0] || Time.now.strftime('%Y%m%d_%H%M%S')

begin
  Exploration.init(work_name)
  Exploration.start!('http://localhost:3000/send/contract_estimates', work_name, :firefox)
end

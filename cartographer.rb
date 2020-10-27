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
url = 'http://localhost:3000/send/contract_estimates'

Exploration.init(work_name)
route_dump   = File.join(Exploration::EXPLORATIONS, work_name, 'route.json')
history_dump = File.join(Exploration::EXPLORATIONS, work_name, 'history.json')
histories    = JSON.parse(File.read(history_dump)) if File.exists?(history_dump)
histories  ||= []
root        = Route.build(json: File.read(route_dump)) if File.exists?(route_dump)
root      ||= Route.new(from: url, name: 'root', root: true)

begin
  while true do
    begin
      t = Thread.new do
        Exploration.start!(root, work_name, histories, :firefox)
      end.join
    rescue => e
      puts e.inspect
    end
    break if root.done?
  end
ensure
  puts "complete"
end

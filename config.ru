require 'bundler'

Bundler.require

require "./app.rb"

if File.exists?(File.join(Rally_Metrics::App.root_path,'tmp', 'ruby-debug.txt'))
  require 'ruby-debug19'
  Debugger.wait_connection = true
  Debugger.start_remote
  File.delete(File.join(Rally_Metrics::App.root_path,'tmp', 'ruby-debug.txt'))
end

if File.exists?(File.join(Rally_Metrics::App.root_path,'tmp', 'debug.txt'))
  log = File.new("./log/debug.log", "a")
  STDOUT.reopen(log)
  STDERR.reopen(log)
  File.delete(File.join(Rally_Metrics::App.root_path,'tmp', 'debug.txt'))
end

run Rally_Metrics::App
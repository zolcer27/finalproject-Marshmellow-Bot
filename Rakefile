require "sinatra"
require 'twilio-ruby'
require 'giphy'

configure :development do
  require 'dotenv'
  Dotenv.load
end

desc 'outputs hello world to the terminal'
task :hello_world do
  puts "Hello World from Rake!"
end

desc 'sends a test SMS to your twilio number'
task :send_sms do
  puts "Send and SMS"
end

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

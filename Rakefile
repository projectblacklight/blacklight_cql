require 'rake'
require 'bundler'
require 'rspec/core/rake_task'

require 'engine_cart/rake_task'

desc "Run specs"
RSpec::Core::RakeTask.new do |t|

end

Bundler::GemHelper.install_tasks

desc "Create dummy app and run tests"
task :ci => ['engine_cart:clean', 'engine_cart:generate', 'spec'] do
end

task :default => [:ci]
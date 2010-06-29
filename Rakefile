require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the blacklight_cql plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the blacklight_cql plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Blacklight-cql'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "blacklight_cql"
    gemspec.summary = "Add CQL query support to a Blacklight app"
    gemspec.description = "May have parts that can be used outside a Blacklight app too with a big of refactoring, let me know if interested."
    gemspec.email = "rochkind@jhu.edu"
    gemspec.homepage = "http://github.com/projectblacklight/blacklight_cql"
    gemspec.authors = ["Jonathan Rochkind"]
    
    gemspec.add_dependency("cql-ruby", ">=0.8.1")
    
    gemspec.add_development_dependency("markup_validity")
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end


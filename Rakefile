require 'bundler'
require 'bundler/gem_tasks'
require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  # Specify the files we will look at
  t.patterns = [File.join('{lib}', '**', '*.rb'), 'Rakefile', '*.gemspec']

  # Do not fail on error
  t.fail_on_error = false
end

desc 'Run RSpec code examples'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = FileList['spec/**/*_spec.rb']
end

task default: [:spec]

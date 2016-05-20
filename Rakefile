require 'bundler'
require 'bundler/gem_tasks'
require 'rake'

# We use this function to redirect outout to dev_null
def dev_null(&_block)
  orig_stdout = $stdout.dup # does a dup2() internally
  $stdout.reopen('/dev/null', 'w')
  yield
ensure
  $stdout.reopen(orig_stdout)
end

begin
  if Rake.application.top_level_tasks.include? 'version'
    dev_null do
      Bundler.setup(:default, :development)
    end
 else
   Bundler.setup(:default, :development)
 end
 rescue Bundler::BundlerError => e
   $stderr.puts e.message
   $stderr.puts 'Run `bundle install` to install missing gems'
   exit e.status_code
end

require 'rspec/core'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

desc 'Bump the PATCH version for DrTeeth'
task :bump do
  version_file = 'lib/kitchen/driver/marathon_version.rb'

  # Read the file, bump the PATCH version
  contents = File.read(version_file).gsub(/(PATCH = )(\d+)/) { |_| Regexp.last_match[1] + (Regexp.last_match[2].to_i + 1).to_s }

  # Write the new contents of the file
  File.open(version_file, 'w') { |file| file.puts contents }
end

desc 'Run RSpec with code coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].execute
end

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

desc 'Retrieve the current version'
task :version do
  require 'kitchen/driver'
  puts Kitchen::Driver::Version.json_version
end

task default: [:spec]

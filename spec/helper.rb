$TESTING = true

if RUBY_VERSION >= "1.9"
  require "simplecov"
  require "coveralls"

  SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

  SimpleCov.start do
    add_filter "/spec"
    minimum_coverage(90)
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require "thor"
require "thor/group"
require "stringio"

require "rdoc"
require "rspec"
require "diff/lcs" # You need diff/lcs installed to run specs (but not to run Thor).
require "webmock/rspec"

WebMock.disable_net_connect!(:allow => "coveralls.io")

# Set shell to basic
$0 = "thor"
$thor_runner = true
ARGV.clear
Encoding.default_external = Encoding::UTF_8 if RUBY_VERSION > '1.8.7'
Thor::Base.shell = Thor::Shell::Basic

# Load fixtures
load File.join(File.dirname(__FILE__), "fixtures", "enum.thor")
load File.join(File.dirname(__FILE__), "fixtures", "group.thor")
load File.join(File.dirname(__FILE__), "fixtures", "invoke.thor")
load File.join(File.dirname(__FILE__), "fixtures", "script.thor")
load File.join(File.dirname(__FILE__), "fixtures", "subcommand.thor")
load File.join(File.dirname(__FILE__), "fixtures", "command.thor")

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = \
    (Thor::ROOT / 'tmp' / '.rspec_status').to_s
  
  config.before do
    ARGV.replace []
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  def source_root
    File.join(File.dirname(__FILE__), "fixtures")
  end

  def destination_root
    File.join(File.dirname(__FILE__), "sandbox")
  end

  # This code was adapted from Ruby on Rails, available under MIT-LICENSE
  # Copyright (c) 2004-2013 David Heinemeier Hansson
  def silence_warnings
    old_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = old_verbose
  end

  alias silence capture
end

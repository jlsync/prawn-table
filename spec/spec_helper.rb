# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require "prawn"
require_relative "../lib/prawn/table"

require "pdf/reader"
require "pdf/inspector"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/extensions/ and its subdirectories.
Dir[File.join(__dir__, "extensions", "**", "*.rb")].sort.each { |f| require f }

Prawn.debug = true

RSpec.configure do |config|
  config.include(EncodingHelpers)
  config.include(FileFixtureHelper)

  # Run examples in random order, so order dependencies surface in CI.
  config.order = :random
  Kernel.srand(config.seed)

  # Do not add `should`, `stub` and friends to every object.
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
  end
end

def create_pdf(klass = Prawn::Document)
  @pdf = klass.new(margin: 0)
end

RSpec::Matchers.define(:have_parseable_xobjects) do
  match do |actual|
    expect { PDF::Inspector::XObject.analyze(actual.render) }.to_not(raise_error)
  end

  failure_message do |actual|
    "expected that #{actual}'s XObjects could be successfully parsed"
  end
end

# Make some methods public to assist in testing
module Prawn
  module Graphics
    public :map_to_absolute
  end
end

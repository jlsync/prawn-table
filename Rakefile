# frozen_string_literal: true

GEMSPEC = File.expand_path("prawn-table.gemspec", __dir__)
require "prawn/dev/tasks"

require "yard"

task default: %i[spec rubocop]

YARD::Rake::YardocTask.new do |t|
  t.options = ["--output-dir", "doc/html"]
end
task docs: :yard

desc "Generate the 'Prawn by Example' manual"
task :manual do
  puts "Building manual..."
  require_relative "manual/contents"
  puts "The Prawn::Table manual is available at manual.pdf. Happy Prawning!"
end

desc "Run a console with Prawn loaded"
task :console do
  require "irb"
  require "irb/completion"
  require "prawn"
  require_relative "lib/prawn/table"
  Prawn.debug = true

  ARGV.clear
  IRB.start
end

# frozen_string_literal: true

require_relative "lib/prawn/table/version"

Gem::Specification.new do |spec|
  spec.name = "prawn-table"
  spec.version = Prawn::Table::VERSION
  spec.summary = "Provides tables for PrawnPDF"
  spec.description = "Prawn::Table provides tables for the Prawn PDF toolkit"

  spec.files = Dir.glob("{lib,manual,spec}/**/**/*") +
    %w[
      prawn-table.gemspec Rakefile CHANGELOG.md README.md
      COPYING LICENSE GPLv2 GPLv3
    ]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.3"

  spec.authors = [
    "Gregory Brown", "Brad Ediger", "Daniel Nelson",
    "Jonathan Greenberg", "James Healy", "Hartwig Brandl",
  ]
  spec.email = [
    "gregory.t.brown@gmail.com", "brad@bradediger.com",
    "dnelson@bluejade.com", "greenberg@entryway.net",
    "jimmy@deefa.com", "mail@hartwigbrandl.at",
  ]
  spec.licenses = %w[Nonstandard GPL-2.0-only GPL-3.0-only]

  spec.homepage = "https://github.com/prawnpdf/prawn-table"
  spec.metadata = {
    "rubygems_mfa_required" => "true",
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "https://prawnpdf.org/prawn-table-manual.pdf",
  }

  spec.add_dependency("prawn", ">= 1.3.0", "< 3.0.0")

  spec.add_development_dependency("pdf-inspector", "~> 1.3")
  spec.add_development_dependency("pdf-reader", "~> 2.16")
  spec.add_development_dependency("prawn-dev", "~> 0.7.0")
  # 0.4.0 replaced the Example API used by manual/contents.rb with Manual and
  # dropped the bundled fonts, so building the manual needs the 0.3 series.
  spec.add_development_dependency("prawn-manual_builder", "~> 0.3.1")
  spec.add_development_dependency("rake", "~> 13.0")
  spec.add_development_dependency("rspec", "~> 3.13")
  spec.add_development_dependency("simplecov", "~> 1.3")
  spec.add_development_dependency("yard", "~> 0.9")
end

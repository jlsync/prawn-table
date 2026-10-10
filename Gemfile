# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Shared dev toolchain, consumed from the fork until it is released.
gem "prawn-dev", "~> 0.7.0", git: "https://github.com/jlsync/prawn-dev.git", branch: "main"

# Use the jlsync forks of prawn, pdf-core and ttfunk, which carry performance
# fixes not yet in a release.
#
# prawn is pinned to the fork's master branch explicitly. Without a branch or
# ref, Bundler follows whatever the remote HEAD resolves to, and a stale
# Bundler git mirror of this fork (whose cached HEAD pointed at an old "2009"
# branch) silently rolled the lockfile back to a revision that predates the
# "Center text boxes including their descenders" fix, failing the cell
# vertical-alignment specs.
gem "pdf-core", github: "jlsync/pdf-core", branch: "master"
gem "prawn", github: "jlsync/prawn", branch: "master"
gem "ttfunk", github: "jlsync/ttfunk", branch: "master"

# Evaluate Gemfile.local if it exists, so a checkout can add local overrides
# (a different prawn ref, for instance) without changing tracked files.
if File.exist?("#{__FILE__}.local")
  instance_eval(File.read("#{__FILE__}.local"), "#{__FILE__}.local")
end

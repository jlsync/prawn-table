# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Shared dev toolchain, consumed from the fork until it is released.
gem 'prawn-dev', git: 'https://github.com/jlsync/prawn-dev.git', branch: 'main'

# Use the jlsync forks of prawn, pdf-core and ttfunk, which carry performance
# fixes not yet in a release.
gem 'pdf-core', github: 'jlsync/pdf-core'
gem 'prawn', github: 'jlsync/prawn'
gem 'ttfunk', github: 'jlsync/ttfunk'

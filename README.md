# Prawn::Table

[![Gem Version](https://badge.fury.io/rb/prawn-table.png)](http://badge.fury.io/rb/prawn-table)
![Build Status](https://github.com/jlsync/prawn-table/actions/workflows/ci.yml/badge.svg)
![Maintained: PRs accepted](https://img.shields.io/badge/maintained-PRs_accepted-orange.png)

Provides table support for PrawnPDF.

Originally written by Brad Ediger with community contributions.

## Status

This gem is not actively maintained by the Prawn maintainers, though they are
happy to help integrate pull requests. The Prawn maintenance team would welcome
anyone interested in helping maintain it.

## Requirements

* Ruby 3.3 or later.
* Prawn. The `Gemfile` consumes the [jlsync fork of
  prawn](https://github.com/jlsync/prawn), along with its `pdf-core` and
  `ttfunk` forks, which carry performance fixes that are not yet in a release.
  Exact vertical alignment of `:center` and `:bottom` text cells relies on the
  fork's "Center text boxes including their descenders" fix (jlsync/prawn
  `0aee64c`). A released Prawn still centers `:center` cell text about half a
  descender low; the cells stay within their box, but they are not exactly
  centered. The gemspec's `prawn >= 1.3.0, < 3.0.0` constraint does not exclude
  such versions, since the library otherwise works with them.

## Documentation

A snapshot of Prawn::Table's manual can be found here:
http://prawnpdf.org/prawn-table-manual.pdf

You can also generate a manual yourself by cloning the repository, running
`bundle install`, then running `bundle exec rake manual`.

All the example files in the `manual` folder can be run individually.

## Development

Install the dependencies and run the test suite and the linter:

```sh
bundle install
bundle exec rake          # spec + rubocop
bundle exec rake spec
bundle exec rake rubocop
```

The Rakefile and both configurations are shared with the rest of the Prawn
toolchain through the `prawn-dev` gem.

## Feature requests

Additional features are welcome, but I won't find time to implement them myself
anytime soon. If you can implement them yourself simply send a pull request with
any new features. Please be sure to add extensive test cases and documentation
for the new feature.

In case of more complex features it probably would make sense to discuss them in
an issue before you go ahead and implement them.

## Bug reports

Please use the github issue tracker to file bug reports.

If possible include a failing rspec test case with a separate pull request and
tag it as unresolved and with the issue number. Example:

```` ruby
it 'illustrates my problem', :unresolved, issue: 1 do
  # test
end
````

This way anyone else fixing it will have a clearer understanding of the
problem and can be sure it's fixed.

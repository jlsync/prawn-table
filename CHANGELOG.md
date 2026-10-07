## Master

* Modernisation pass:
  - Refresh the lockfile against the latest `jlsync` commits of prawn, `pdf-core` and `ttfunk`, and take prawn (as before) and the shared dev toolchain from the `jlsync` forks.
  - Bring the gemspec up to current RubyGems standards: `require_relative` for the version, `require_paths`, string-valued `metadata` (MFA required, source, changelog, bug tracker and documentation URIs), no deprecated `test_files`, and no redundant `platform` or `required_rubygems_version`. File lists now include the manual, README and Rakefile.
  - Pin development dependencies to versions that are actually exercised, and keep `prawn-manual_builder` on the 0.3 series because 0.4 replaced the `Example` API that `manual/contents.rb` uses.
  - Adopt the spec conventions the rest of the toolchain uses: `.rspec` requires the spec helper, examples run in random order, monkey patching is disabled, and partial doubles are verified. Specs no longer load the library twice or rely on the RSpec 2 `failure_message_for_should` DSL.
  - Regenerate `.rubocop_todo.yml` against RuboCop 1.91 and autocorrect the library and specs, reducing the todo from 132 to 42 entries (1157 to 340 lines). The manual's example files are excluded from inspection so that reflowing them does not change the published manual. The remaining structural offenses (per-example instance variables and message expectations, mainly) are recorded in the todo rather than silenced.
  - CI installs through `ruby/setup-ruby`'s `bundler-cache`, drops the duplicate 3.3/4.0 matrix entries, adds Ruby 3.4, and cancels superseded runs.
  - Drop the `rake stats` task, which required the long-removed `code_statistics` library.
* Reduce object allocations and improve layout performance across table construction, sizing, and rendering:
  - Cache whether `draw_borders` is overridden per cell class, avoiding `Method` object allocations during batched border rendering.
  - Eliminate array allocations on text cell height cache hits via field-by-field short-circuiting.
  - Include `Cell::InTable` in `Cell` to avoid creating per-cell singleton classes and invalidating method caches via `extend`.
  - Use $O(1)$ coordinate grid mapping in `Cells#[]` instead of linear row/column scans.
  - Track table dimensions incrementally in `make_cells`, eliminating two full-table passes and intermediate array allocations.
  - Avoid redundant width recalculations in `Table#column_widths` and avoid $2(R + C)$ temporary `Cells` wrapper allocations during table layout.
  - Optimize `ColumnWidthCalculator` with direct `sum` lookups for colspans and skip dummy checks when tables contain no spans.
* Add `batch_borders: :by_style`, which strokes all borders of each style (line, width and color) as a single path per table page, thinnest first, so where borders of different styles meet the thicker one is on top, as with collapsed borders in HTML tables. Tables whose border style alternates, such as a thick outline around thin inner borders, then write two stroke operators instead of one per border or two: a timeline-style report of small outlined tables renders about 7% faster.
* Reuse cell height measurements between bounding boxes of the same size at different positions on the page. The cache compared each box's absolute position, which doesn't affect the measured height in a fixed-size box, so tables drawn in their own bounding boxes (one per section of a report, say) were measured again for every table.
* Bugfix: A table's height (and a row's `height_with_span`) now counts a cell with `colspan > 1` towards its own row. The height was short by the difference between that row and the next, so a subtable with such a row was squeezed into too small a cell and its last row spilled onto a new page. (issue [#10](https://github.com/prawnpdf/prawn-table/issues/10))
* Reuse cell height measurements for inline-formatted text too, when the document uses Prawn's own text formatter, and keep up to 2048 short strings per document instead of 256. Reports made of many small tables with repeated `inline_format` values measure each distinct string once instead of rendering every cell twice: a 231-page timeline-style report renders about 15% faster with identical output.
* Stroke the borders of all cells on a page together, as one path per run of same-styled borders, with edges shared by adjacent cells written once. Large tables render noticeably faster and produce smaller PDFs with the same appearance, except that overlapping border corners and shared edges are no longer painted twice (visible only with transparency). Pass `batch_borders: false` to a table to draw each cell's borders just before its content, as before. Cells that override `draw_borders` still have it called.
* Require Ruby 3.3 or later. CI tests MRI 3.3, 3.4, 4.0 and head, and JRuby 10.0 and 10.1, against the jlsync forks of prawn, pdf-core and ttfunk.
* Bugfix: Use a cell's custom style over table styles. (PR [#143](https://github.com/prawnpdf/prawn-table/pull/143), issue [#56](https://github.com/prawnpdf/prawn-table/issues/56))
* Bugfix: Use the cell's specified font to calculate the cell width. (Jesse Doyle, PR [#60](https://github.com/prawnpdf/prawn-table/pull/60), issue [#42](https://github.com/prawnpdf/prawn-table/issues/42))

## 0.2.3

* Allow padding of subtables to be configurable. PR #44

## 0.2.2

* Updated supported ruby versions to match Prawn. PR #47
* All cells in a rowspan use the background color of the master (i.e., first) cell (#45)

## 0.2.1

* Allow the use of Prawn `2.x`, as it should not break table behavior.

## 0.2.0

* Allow the use of any Prawn `1.x` release from `1.3` onwards.

## 0.1.2

* fixed unnecessary page breaks with centered tables (#22, #23, #24)
* fixed undefined method `y' for nil:NilClass error (#20, #21, #25)

## 0.1.1

* refactored table.rb to increase readability and lower overall code complexity (#15)
* Fixed multi line table headers that involve cells that span multiple columns (#8)
* respect an explicit set table width, given an header with rowspan across all cells (#6)

## 0.1.0

* Fix table wrapping when cells in the last row on a page have a rowpan > 1 (#3,#5)
* First official release after extraction. Based on the table code from Prawn 1.1.0


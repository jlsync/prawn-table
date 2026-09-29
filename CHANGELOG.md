## Master

* Bugfix: A table's height (and a row's `height_with_span`) now counts a cell with `colspan > 1` towards its own row. The height was short by the difference between that row and the next, so a subtable with such a row was squeezed into too small a cell and its last row spilled onto a new page. (issue [#10](https://github.com/prawnpdf/prawn-table/issues/10))
* Stroke the borders of all cells on a page together, as one path per run of same-styled borders, with edges shared by adjacent cells written once. Large tables render noticeably faster and produce smaller PDFs with the same appearance, except that overlapping border corners and shared edges are no longer painted twice (visible only with transparency). Pass `batch_borders: false` to a table to draw each cell's borders just before its content, as before. Cells that override `draw_borders` still have it called.
* Require Ruby 3.3 or later. CI tests MRI 3.3, 4.0 and head, and JRuby 10.0 and 10.1, against the jlsync forks of prawn, pdf-core and ttfunk.
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


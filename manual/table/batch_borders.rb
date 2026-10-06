# frozen_string_literal: true

# By default (<code>batch_borders: true</code>), Prawn strokes cell borders on each
# page together before any cell content is rendered. This writes far fewer PDF
# graphics operators and strokes edges shared by adjacent cells only once,
# which is much faster for large tables.
#
# When table borders alternate in style—such as a thick outer boundary surrounding
# thin inner grid lines—setting <code>batch_borders: :by_style</code> strokes all
# borders of each style (line style, width, and color) as a single path, thinnest
# first. Where different styles meet, the thicker border renders cleanly on top
# (similar to collapsed borders in HTML tables).
#
# If you need to revert to legacy drawing order (where each cell's borders are
# stroked immediately before its content), pass <code>batch_borders: false</code>.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data = [
    ["Item", "Quantity", "Price"],
    ["Apples", "5", "$2.50"],
    ["Pears", "3", "$3.00"],
    ["Total", "8", "$5.50"],
  ]

  text "Table with batch_borders: :by_style (thick outline, thin inner borders):"
  move_down 10

  table(data, batch_borders: :by_style,
              cell_style: { border_width: 0.5, border_color: "888888" }) do |t|
    t.row(0).style(border_top_width: 2, border_top_color: "000000")
    t.row(-1).style(border_bottom_width: 2, border_bottom_color: "000000")
    t.column(0).style(border_left_width: 2, border_left_color: "000000")
    t.column(-1).style(border_right_width: 2, border_right_color: "000000")
  end
end

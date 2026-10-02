# frozen_string_literal: true

# border_batch.rb: Strokes the borders of many cells at once.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  class Table
    # Strokes the borders of a group of cells with far fewer graphics state
    # changes and stroke operators than drawing each cell's borders in turn.
    #
    # By default borders are painted in the same order as drawing each cell's
    # borders in turn: consecutive borders that share a line style, width and
    # color are gathered into one path and stroked once, and a border with a
    # different style starts a new path, so where differently styled borders
    # overlap, the same one ends up on top.
    #
    # With +by_style+, all borders that share a style are gathered into one
    # path, however they are interleaved, and the paths are stroked from the
    # thinnest line to the thickest (in order of first appearance among equal
    # widths). Where borders of different styles meet or overlap, the thicker
    # one ends up on top, as with collapsed borders in HTML tables.
    #
    # Either way, a border identical to one already in its path, such as the
    # edge shared by two adjacent cells, is written only once.
    #
    # @private
    class BorderBatch
      LINE_STYLES = %i[solid dashed dotted].freeze

      def initialize(pdf, by_style: false)
        @pdf = pdf
        @by_style = by_style
        # A stamp's content stream inherits the graphics state of wherever it
        # is placed, so there every state operator is written. Elsewhere only
        # changes are written.
        @in_stamp = pdf.state.page.in_stamp_stream?
        @old_line_width = pdf.line_width
        @old_stroke_color = pdf.stroke_color
        @line = @width = @color = nil
        @segments = {}
        # [line, width, color] => segments, in order of first appearance.
        @paths = {}
      end

      # Adds the borders of +cell+, drawn at +point+ in the current bounds.
      #
      def add(cell, point)
        bounds = @pdf.bounds
        left = bounds.absolute_left
        bottom = bounds.absolute_bottom

        cell.each_border_segment(point) do |line, width, color, from, to|
          unless line == @line && width == @width && color == @color
            unless LINE_STYLES.include?(line)
              raise ArgumentError, 'border_line must be :solid, :dotted or :dashed'
            end

            start_path(line, width, color)
          end

          # The same operators Graphics#move_to and #line_to would write, so
          # the duplicate check compares exactly what ends up in the PDF.
          segment =
            "#{PDF::Core.real(left + from[0])} #{PDF::Core.real(bottom + from[1])} m\n" \
              "#{PDF::Core.real(left + to[0])} #{PDF::Core.real(bottom + to[1])} l"
          @segments[segment] = true
        end
      end

      # Restores the line width and stroke color in effect when the batch was
      # created. Call this even if adding or stroking raised.
      #
      def restore
        if @in_stamp || @pdf.line_width != @old_line_width
          @pdf.line_width = @old_line_width
        end
        if @in_stamp || @pdf.stroke_color != @old_stroke_color
          @pdf.stroke_color = @old_stroke_color
        end
      end

      # Strokes the borders gathered so far.
      #
      def stroke
        if @by_style
          # sort_by is not stable, so break ties by order of first appearance.
          @paths.each_with_index
            .sort_by { |((_, width, _), _), index| [width, index] }
            .each { |((line, width, color), segments), _| stroke_path(line, width, color, segments) }
          @paths.clear
          @line = @width = @color = nil
        else
          stroke_path(@line, @width, @color, @segments)
        end
      end

      private

      def start_path(line, width, color)
        if @by_style
          @segments = (@paths[[line, width, color]] ||= {})
        else
          stroke
        end
        @line = line
        @width = width
        @color = color
      end

      def stroke_path(line, width, color, segments)
        return if segments.empty?

        case line
        when :dashed
          @pdf.dash(width * 4)
        when :dotted
          @pdf.dash(width, space: width * 2)
        end
        @pdf.line_width = width if @in_stamp || @pdf.line_width != width
        @pdf.stroke_color = color if @in_stamp || @pdf.stroke_color != color

        @pdf.add_content(segments.keys.join("\n"))
        @pdf.stroke

        @pdf.undash if @in_stamp || @pdf.dashed?
        segments.clear
      end
    end
  end
end

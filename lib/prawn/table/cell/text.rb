# frozen_string_literal: true

# text.rb: Text table cells.
#
# Copyright December 2009, Gregory Brown and Brad Ediger. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
module Prawn
  class Table
    class Cell
      # A Cell that contains text. Has some limited options to set font family,
      # size, and style.
      #
      # @private
      class Text < Cell
        TextOptions = %i[
          inline_format kerning size align valign
          rotate rotate_around leading single_line skip_encoding
          overflow min_font_size
        ]

        TextOptions.each do |option|
          define_method("#{option}=") { |v| @text_options[option] = v }
          define_method(option) { @text_options[option] }
        end

        HEIGHT_CACHE_LIMIT = 2048
        HEIGHT_CACHE_MAX_TEXT_BYTES = 128
        # Keys in the one-line height cache (see #single_line_height_key) and
        # the option sets remembered per key. Keys are per font, size and frame
        # height, so a document needs very few; the limits only stop a
        # pathological one from growing.
        SINGLE_LINE_HEIGHT_CACHE_LIMIT = 128
        SINGLE_LINE_OPTION_SETS = 4
        # Characters Prawn's line wrapper treats specially and #one_line_width
        # does not model, so cells whose text contains either measure normally.
        SOFT_HYPHEN = "\u00AD"
        ZERO_WIDTH_SPACE = "\u200B"
        # The tokens Formatted::LineWrap#scan_pattern splits text into, short of
        # the soft-hyphen alternatives: words with any hyphens that follow them,
        # whitespace runs, and hyphen runs with the characters that follow them.
        TOKEN_PATTERN = /[^ \t-]+-*|[ \t]+|-+[^ \t-]*/
        # Options for selecting the font when the cell has no style of its own.
        # Prawn's #font neither mutates the options it is given nor treats an
        # empty Hash differently from `{ :style => :normal }`, so a single
        # frozen Hash can stand in for the fresh one built on every call.
        NO_FONT_OPTIONS = {}.freeze
        # Vertical alignments positioned by the text box itself, which centers
        # or bottoms the measured text out in the cell. The cell must not shift
        # the text first, or it offsets that positioning and lets the descender
        # escape through the bottom of the cell.
        TEXT_BOX_VALIGNS = [:center, :bottom].freeze
        private_constant :HEIGHT_CACHE_LIMIT, :HEIGHT_CACHE_MAX_TEXT_BYTES,
          :SINGLE_LINE_HEIGHT_CACHE_LIMIT, :SINGLE_LINE_OPTION_SETS,
          :SOFT_HYPHEN, :ZERO_WIDTH_SPACE, :TOKEN_PATTERN,
          :NO_FONT_OPTIONS, :TEXT_BOX_VALIGNS

        attr_writer :font
        attr_writer :text_color

        def initialize(pdf, point, options = {})
          @text_options = {}
          super
        end

        # Returns the font that will be used to draw this cell.
        #
        def font
          with_font { @pdf.font }
        end

        # Sets the style of the font in use. Equivalent to the Text::Box
        # +style+ option, but we already have a style method.
        #
        def font_style=(style)
          @text_options[:style] = style
        end

        # Returns the width of this text with no wrapping. This will be far off
        # from the final width if the text is long.
        #
        def natural_content_width
          @natural_content_width ||= [styled_width_of(@content), @pdf.bounds.width].min
        end

        # Returns the natural height of this block of text, wrapped to the
        # preset width.
        #
        def natural_content_height
          with_font do
            cache = natural_height_cache
            if cache && (entry = cache[@content])
              sig = entry[0]
              if sig[2] == spanned_content_width &&
                  sig[1] == @pdf.font_size &&
                  sig[0] == @pdf.font &&
                  sig[3] == @pdf.bounds.height &&
                  sig[4] == @pdf.character_spacing &&
                  sig[5] == @pdf.default_leading &&
                  sig[6] == @pdf.default_kerning? &&
                  sig[7] == @pdf.text_direction &&
                  sig[8] == @text_options
                return entry[1]
              end
            end

            # Checked only after the per-content cache, so that text seen before
            # keeps taking that single lookup: this path costs a key Array and
            # only pays off for text that has not been measured yet.
            single_line = single_line_height_key
            height =
              if single_line &&
                  (entries = single_line_heights[single_line]) &&
                  (entry = entries.find { |e| e[0] == @text_options })
                entry[1]
              else
                b = text_box(:width => spanned_content_width + FPTolerance)
                b.render(:dry_run => true)
                measured = b.height + b.line_gap
                store_single_line_height(single_line, measured) if single_line
                measured
              end

            # The result is recorded per content as well, whichever path
            # produced it, so that the next cell with this text takes the cheap
            # lookup above rather than rebuilding the one-line key.
            if cache
              signature = [
                @pdf.font, @pdf.font_size, spanned_content_width,
                @pdf.bounds.height, @pdf.character_spacing, @pdf.default_leading,
                @pdf.default_kerning?, @pdf.text_direction,
                @text_options.transform_values(&:dup),
              ]
              cache[@content] = [signature, height]
            end
            height
          end
        end

        # Draws the text content into its bounding box.
        #
        def draw_content
          with_font do
            # Prawn measures a text box's height from the top of the first
            # line's ascender to the bottom of the last line's descender, and
            # cell heights add exactly one line gap to that. Splitting the gap
            # above and below therefore means moving down half of it. An
            # earlier version also counted half the descender, which is
            # already part of the measured height, pushing text down by half a
            # descender.
            #
            # :center and :bottom are positioned by the text box itself, which
            # centers (or bottoms out) the same measured height in the box.
            # Shifting them first would offset that positioning and let the
            # descender escape through the bottom of the cell.
            unless TEXT_BOX_VALIGNS.include?(@text_options[:valign])
              @pdf.move_down(@pdf.font.line_gap / 2)
            end
            with_text_color do
              text_box(
                :width => spanned_content_width + FPTolerance,
                :height => spanned_content_height + FPTolerance,
                :at => [0, @pdf.cursor],
              ).render
            end
          end
        end

        def set_width_constraints
          # Sets a reasonable minimum width. If the cell has any content, make
          # sure we have enough width to be at least one character wide. This is
          # a bit of a hack, but it should work well enough.
          unless defined?(@min_width) && @min_width
            # The natural width and the one-character minimum both need this
            # cell's font selected, and with_font is re-entrant, so they share
            # a single selection.
            min_content_width =
              with_font { [natural_content_width, styled_width_of_single_character].min }
            @min_width = padding_left + padding_right + min_content_width
            super
          end
        end

        protected

        def with_font
          # A measurement may need the font selected more than once; the
          # outermost call selects it and the inner ones reuse that selection
          # instead of saving and reselecting the same font.
          return yield if @font_selected

          @pdf.save_font do
            style = @text_options[:style] || @pdf.font.options[:style]
            options = style ? { :style => style } : NO_FONT_OPTIONS

            @pdf.font((defined?(@font) && @font) || @pdf.font.family, options)

            @font_selected = true
            begin
              yield
            ensure
              @font_selected = false
            end
          end
        end

        def with_text_color
          if defined?(@text_color) && @text_color
            begin
              old_color = @pdf.fill_color || '000000'
              @pdf.fill_color(@text_color)
              yield
            ensure
              @pdf.fill_color(old_color)
            end
          else
            yield
          end
        end

        def text_box(extra_options = {})
          if p = @text_options[:inline_format]
            p = [] unless p.is_a?(Array)
            options = @text_options.except(:inline_format)
            options.merge!(extra_options)
            options[:document] = @pdf

            array = @pdf.text_formatter.format(@content, *p)
            ::Prawn::Text::Formatted::Box.new(array, options)
          else
            options = @text_options.merge(extra_options)
            options[:document] = @pdf
            ::Prawn::Text::Box.new(@content, options)
          end
        end

        # Returns the width of +text+ under the given text options.
        #
        def styled_width_of(text)
          options = @text_options.except(:style)
          with_font { @pdf.width_of(text, options) }
        end

        private

        # Keep one measurement per short string on this document. Once full,
        # unseen text takes the normal path without allocating a signature.
        # Hash snapshots string keys; option snapshots protect against changes
        # to a cell after measurement. Fixed bounds make the available height
        # unambiguous: in them a text box's default height is the height of the
        # bounds, whatever their position on the page, so a measurement can be
        # reused in bounding boxes of the same size anywhere. Custom text
        # layout keeps its existing behavior.
        # Inline-formatted text is parsed by Prawn's own formatter from the
        # string and the :inline_format option alone, both part of the key.
        def natural_height_cache
          return unless instance_of?(Text)
          return if @content.bytesize > HEIGHT_CACHE_MAX_TEXT_BYTES
          return if @text_options[:inline_format] &&
            !@pdf.text_formatter.equal?(::Prawn::Text::Formatted::Parser)

          cache = @pdf.instance_variable_get(:@prawn_table_text_heights) ||
            @pdf.instance_variable_set(:@prawn_table_text_heights, {})
          return if cache.size >= HEIGHT_CACHE_LIMIT && !cache.key?(@content)
          return if @pdf.bounds.stretchy? || !@pdf.fallback_fonts.empty? ||
            !::Prawn::Text::Box.extensions.empty? ||
            !::Prawn::Text::Formatted::Box.extensions.empty?

          cache
        end

        # Everything a single line's height depends on except the characters in
        # it, or nil when this cell's content is not known to be one line.
        #
        # Prawn takes the height of a line from the metrics of the fonts on it
        # -- their line height, ascender and descender -- and lays a string out
        # on one line whenever all of it fits the box. So for text that fits,
        # those metrics, and therefore the measured height, are the same
        # whatever the string is, and one measurement can answer for every such
        # cell in the document. That matters because measuring a cell costs a
        # full text layout, and a table with short cells asks for one per cell.
        #
        # The value is taken from a real measurement rather than derived from
        # font metrics (see #store_single_line_height), so it stays correct if
        # Prawn changes how a line's height is obtained. Anything that could
        # make the layout differ from a plain single line -- wrapping, a
        # different frame, options this cell lays text out with but does not
        # report a width for -- falls through to the full measurement.
        #
        def single_line_height_key
          # A subclass may override #text_box or the measurement around it, so
          # only cells that measure exactly as this class does may skip the
          # measurement. (The same guard appears in #natural_height_cache.)
          #
          # The option checks come first because they are a Hash lookup each,
          # and :inline_format is by far the most common reason to decline.
          # :character_spacing, :direction and :fallback_fonts have no setter on
          # this class today, so they cannot appear in @text_options; they are
          # checked so that adding one later cannot silently opt a cell into
          # the fast path.
          return unless instance_of?(Text)
          return if @text_options[:inline_format]
          return if @text_options[:character_spacing]

          # These all change what a line costs or where it is placed: :overflow
          # may shrink the text to fit, :rotate rotates it, :valign moves it
          # within the cell, and fallback fonts change which font draws it.
          rotate = @text_options[:rotate]
          return if @text_options[:overflow]
          return if rotate && rotate != 0
          return if @text_options[:fallback_fonts] &&
            !@text_options[:fallback_fonts].empty?

          valign = @text_options[:valign]
          return if valign && valign != :top
          return unless (@text_options[:direction] || @pdf.text_direction) == :ltr

          # An empty cell measures zero, which is not the height of a line.
          return if @content.empty?

          # Text that is not ASCII-only is searched below with UTF-8 literals,
          # which raises for content in any other encoding (ASCII-compatible or
          # not), and Prawn converts such content while laying it out; measure
          # it normally instead. ASCII-only text keeps the fast path whatever
          # its encoding.
          unless @content.ascii_only?
            return unless @content.encoding == ::Encoding::UTF_8

            return if @content.include?(SOFT_HYPHEN) ||
              @content.include?(ZERO_WIDTH_SPACE)
          end

          # Newlines start a second line.
          return if @content.include?("\n") || @content.include?("\r")

          # A stretchy bounding box takes its text box height from the nearest
          # fixed box, and Prawn's layout hooks replace the wrapping entirely.
          return if @pdf.bounds.stretchy? || !@pdf.fallback_fonts.empty?
          return if !::Prawn::Text::Box.extensions.empty? ||
            !::Prawn::Text::Formatted::Box.extensions.empty?

          # Cheap first pass: text that does not fit even without kerning
          # cannot be one line. Kerning can narrow a line, so this is only a
          # filter -- a stale width can only make it decline a cell that would
          # have qualified, never accept one -- and #one_line_width below makes
          # the decision from the current content.
          return if natural_content_width >= spanned_content_width
          return if one_line_width(@content) >= spanned_content_width

          [
            @pdf.font, @pdf.font_size, @pdf.bounds.height,
            @pdf.character_spacing, @pdf.default_leading,
            @pdf.default_kerning?, @pdf.text_direction,
          ]
        end

        # The width Prawn's line wrapper accumulates for +text+ on one line.
        #
        # The wrapper splits text into words, hyphen runs and whitespace runs
        # (see Formatted::LineWrap#scan_pattern) and adds each token's width
        # with kerning and the document's character spacing in effect, so both
        # are counted within a token but not across tokens. Measuring the
        # string as a whole instead would differ from it by the kerning and
        # spacing it skips, which can make the string look narrower than it is
        # laid out, and would let text that wraps pass as one line. This
        # mirrors the wrapper's arithmetic rather than reimplementing its line
        # breaking, so it is exact -- or over-estimates, since the wrapper
        # strips leading whitespace from the first fragment and this does not
        # -- for any text that has no soft hyphen or zero-width space (both
        # declined by the caller) and no newline (also declined).
        #
        def one_line_width(text)
          # The same options #styled_width_of measures with -- including a
          # :size option, which the wrapper applies through the document's
          # font size while it lays the line out -- minus :style, which
          # #with_font has already selected a font for.
          options = @text_options.except(:style)
          kerning = options[:kerning]
          kerning = @pdf.default_kerning? if kerning.nil?
          kerning &&= @pdf.font.has_kerning_data?

          # With neither kerning nor character spacing applied between
          # characters, a string's width is the sum of its parts, so one
          # measurement of the whole string gives the wrapper's number. Either
          # one otherwise needs the per-token sum: the wrapper counts kerning
          # and spacing once per token, not once per line.
          if !kerning && @pdf.character_spacing.zero?
            return @pdf.width_of(text, options)
          end

          options[:kerning] = true if kerning
          text.scan(TOKEN_PATTERN).sum { |token| @pdf.width_of(token, options) }
        end

        # Remembers +height+ as the height of one line under the font, frame
        # and text options in +key+. The key holds no text, so the cache stays
        # as small as the number of fonts, sizes and frame heights in play.
        # Each key keeps a few option sets, so that columns alternating between
        # them (say one right-aligned, one not) can both be served; a key whose
        # slots are full simply stops accepting new option sets.
        #
        # The options are snapshotted (values duplicated, Hash frozen) so that
        # a later change to the cell cannot alter what an entry stands for.
        #
        def store_single_line_height(key, height)
          cache = single_line_heights
          entries = cache[key]

          if entries.nil?
            return if cache.size >= SINGLE_LINE_HEIGHT_CACHE_LIMIT

            entries = cache[key] = []
          end
          return if entries.size >= SINGLE_LINE_OPTION_SETS

          entries << [@text_options.transform_values(&:dup).freeze, height]
        end

        def single_line_heights
          @pdf.instance_variable_get(:@prawn_table_line_heights) ||
            @pdf.instance_variable_set(:@prawn_table_line_heights, {})
        end

        # Returns the greatest possible width of any single character
        #   under the given text options.
        # (We use this to determine the minimum width of a table cell)
        # (Although we currently determine this by measuring "M", it should really
        #   use whichever character is widest under the current font)
        #
        def styled_width_of_single_character
          styled_width_of("M")
        end
      end
    end
  end
end

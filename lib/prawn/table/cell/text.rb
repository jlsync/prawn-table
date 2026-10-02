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

        TextOptions = [:inline_format, :kerning, :size, :align, :valign,
          :rotate, :rotate_around, :leading, :single_line, :skip_encoding,
          :overflow, :min_font_size]

        TextOptions.each do |option|
          define_method("#{option}=") { |v| @text_options[option] = v }
          define_method(option) { @text_options[option] }
        end

        HEIGHT_CACHE_LIMIT = 2048
        HEIGHT_CACHE_MAX_TEXT_BYTES = 128
        private_constant :HEIGHT_CACHE_LIMIT, :HEIGHT_CACHE_MAX_TEXT_BYTES

        attr_writer :font, :text_color

        def initialize(pdf, point, options={})
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

            b = text_box(:width => spanned_content_width + FPTolerance)
            b.render(:dry_run => true)
            height = b.height + b.line_gap

            if cache
              signature = [@pdf.font, @pdf.font_size, spanned_content_width,
                @pdf.bounds.height, @pdf.character_spacing, @pdf.default_leading,
                @pdf.default_kerning?, @pdf.text_direction,
                @text_options.transform_values(&:dup)]
              cache[@content] = [signature, height]
            end
            height
          end
        end

        # Draws the text content into its bounding box.
        #
        def draw_content
          with_font do
            @pdf.move_down((@pdf.font.line_gap + @pdf.font.descender)/2)
            with_text_color do
              text_box(:width => spanned_content_width + FPTolerance,
                       :height => spanned_content_height + FPTolerance,
                       :at => [0, @pdf.cursor]).render
            end
          end
        end

        def set_width_constraints
          # Sets a reasonable minimum width. If the cell has any content, make
          # sure we have enough width to be at least one character wide. This is
          # a bit of a hack, but it should work well enough.
          unless defined?(@min_width) && @min_width
            min_content_width = [natural_content_width, styled_width_of_single_character].min
            @min_width = padding_left + padding_right + min_content_width
            super
          end
        end

        protected

        def with_font
          @pdf.save_font do
            options = {}
            options[:style] = @text_options[:style] if @text_options[:style]
            options[:style] ||= @pdf.font.options[:style] if @pdf.font.options[:style]

            @pdf.font(defined?(@font) && @font || @pdf.font.family, options)

            yield
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

        def text_box(extra_options={})
          if p = @text_options[:inline_format]
            p = [] unless p.is_a?(Array)
            options = @text_options.except(:inline_format)
            options.merge!(extra_options)
            options[:document] = @pdf

            array = @pdf.text_formatter.format(@content, *p)
            ::Prawn::Text::Formatted::Box.new(array, options)
          else
            ::Prawn::Text::Box.new(@content,
              @text_options.merge(extra_options, :document => @pdf))
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

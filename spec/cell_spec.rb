# encoding: utf-8

require File.join(File.expand_path(File.dirname(__FILE__)), "spec_helper")
require_relative "../lib/prawn/table"

module CellHelpers

  # Build, but do not draw, a cell on @pdf.
  def cell(options={})
    at = options[:at] || [0, @pdf.cursor]
    Prawn::Table::Cell::Text.new(@pdf, at, options)
  end

end

describe "Prawn::Table::Cell" do
  before(:each) do
    @pdf = Prawn::Document.new
  end

  describe "Prawn::Document#cell" do
    include CellHelpers

    it "should draw the cell" do
      expect_any_instance_of(Prawn::Table::Cell::Text).to receive(:draw).once
      @pdf.cell(:content => "text")
    end

    it "should return a Cell" do
      expect(@pdf.cell(:content => "text")).to be_a_kind_of Prawn::Table::Cell
    end

    it "accepts :content => nil in a hash" do
      expect(@pdf.cell(:content => nil)).to be_a_kind_of(Prawn::Table::Cell::Text)
      expect(@pdf.make_cell(:content => nil)).to be_a_kind_of(Prawn::Table::Cell::Text)
    end

    it "should convert nil, Numeric, and Date values to strings" do
      [nil, 123, 123.45, Date.today, Time.new].each do |value|
        c = @pdf.cell(:content => value)
        expect(c).to be_a_kind_of Prawn::Table::Cell::Text
        expect(c.content).to eq value.to_s
      end
    end

    it "should convert nil, Numeric, and Date values to strings when value is extracted from options" do
      [nil, 123, 123.45, Date.today, Time.new].each do |value|
        c = Prawn::Table::Cell.make(@pdf, {}, { :content => value })
        expect(c).to be_a_kind_of Prawn::Table::Cell::Text
        expect(c.content).to eq value.to_s
      end
    end

    it "should allow inline styling with a hash argument" do
      # used for table([[{:text => "...", :font_style => :bold, ...}, ...]])
      c = Prawn::Table::Cell.make(@pdf,
                                  {:content => 'hello', :font_style => :bold})
      expect(c).to be_a_kind_of Prawn::Table::Cell::Text
      expect(c.content).to eq "hello"
      expect(c.font.name).to eq 'Helvetica-Bold'
    end

    it "should draw text at the given point plus padding, with the given " +
       "size and style" do
      expect(@pdf).to receive(:bounding_box).and_yield
      expect(@pdf).to receive(:move_down)
      expect(@pdf).to receive(:draw_text!).with("hello world", anything)

      @pdf.cell(:content => "hello world",
                :at => [10, 20],
                :padding => [30, 40],
                :size => 7,
                :font_style => :bold)
    end
  end

  describe "Prawn::Document#make_cell" do
    it "should not draw the cell" do
      expect_any_instance_of(Prawn::Table::Cell::Text).to_not receive(:draw)
      @pdf.make_cell("text")
    end

    it "should return a Cell" do
      expect(@pdf.make_cell("text", :size => 7)).to be_a_kind_of Prawn::Table::Cell
    end
  end

  describe "#style" do
    include CellHelpers

    it "should set each property in turn" do
      c = cell(:content => "text")

      expect(c).to receive(:padding=).with(50)
      expect(c).to receive(:size=).with(7)

      c.style(:padding => 50, :size => 7)
    end

    it "ignores unknown properties" do
      c = cell(:content => 'text')

      c.style(:foobarbaz => 'frobnitz')
    end
  end

  describe "cell width" do
    include CellHelpers

    it "should be calculated for text" do
      c = cell(:content => "text")
      expect(c.width).to eq @pdf.width_of("text") + c.padding[1] + c.padding[3]
    end

    it "should be overridden by manual :width" do
      c = cell(:content => "text", :width => 400)
      expect(c.width).to eq 400
    end

    it "should incorporate padding when specified" do
      c = cell(:content => "text", :padding => [1, 2, 3, 4])
      expect(c.width).to be_within(0.01).of(@pdf.width_of("text") + 6)
    end

    it "should allow width to be reset after it has been calculated" do
      # to ensure that if we memoize width, it can still be overridden
      c = cell(:content => "text")
      c.width
      c.width = 400
      expect(c.width).to eq 400
    end

    it "should return proper width with size set" do
      text = "text " * 4
      c = cell(:content => text, :size => 7)
      expect(c.width).to eq @pdf.width_of(text, :size => 7) + c.padding[1] + c.padding[3]
    end

    it "content_width should exclude padding" do
      c = cell(:content => "text", :padding => 10)
      expect(c.content_width).to eq @pdf.width_of("text")
    end

    it "content_width should exclude padding even with manual :width" do
      c = cell(:content => "text", :padding => 10, :width => 400)
      expect(c.content_width).to be_within(0.01).of(380)
    end

    it "should have a reasonable minimum width that can fit @content" do
      c = cell(:content => "text", :padding => 10)
      min_content_width = c.min_width - c.padding[1] - c.padding[3]

      expect(@pdf.height_of("text", :width => min_content_width)).to be <
        (5 * @pdf.height_of("text"))
    end

    it "should defer min_width's evaluation of padding" do
      c = cell(:content => "text", :padding => 100)
      c.padding = 0

      # Make sure we use the new value of padding in calculating min_width
      expect(c.min_width).to be < 100
    end

    it "should defer min_width's evaluation of size" do
      c = cell(:content => "text", :size => 50)
      c.size = 8
      c.padding = 0
      expect(c.min_width).to be < 10
    end

  end

  describe "cell height" do
    include CellHelpers

    it "should be calculated for text" do
      c = cell(:content => "text")
      expect(c.height).to eq(
        @pdf.height_of("text", :width => @pdf.width_of("text")) +
        c.padding[0] + c.padding[3]
      )
    end

    it "should be overridden by manual :height" do
      c = cell(:content => "text", :height => 400)
      expect(c.height).to eq 400
    end

    it "should incorporate :padding when specified" do
      c = cell(:content => "text", :padding => [1, 2, 3, 4])
      expect(c.height).to be_within(0.01).of(1 + 3 +
        @pdf.height_of("text", :width => @pdf.width_of("text")))
    end

    it "should allow height to be reset after it has been calculated" do
      # to ensure that if we memoize height, it can still be overridden
      c = cell(:content => "text")
      c.height
      c.height = 400
      expect(c.height).to eq 400
    end

    it "should return proper height for blocks of text" do
      content = "words " * 10
      c = cell(:content => content, :width => 100)
      expect(c.height).to eq @pdf.height_of(content, :width => 100) +
        c.padding[0] + c.padding[2]
    end

    it "should return proper height for blocks of text with size set" do
      content = "words " * 10
      c = cell(:content => content, :width => 100, :size => 7)

      correct_content_height = nil
      @pdf.font_size(7) do
        correct_content_height = @pdf.height_of(content, :width => 100)
      end

      expect(c.height).to eq correct_content_height + c.padding[0] + c.padding[2]
    end

    it "content_height should exclude padding" do
      c = cell(:content => "text", :padding => 10)
      expect(c.content_height).to eq @pdf.height_of("text")
    end

    it "content_height should exclude padding even with manual :height" do
      c = cell(:content => "text", :padding => 10, :height => 400)
      expect(c.content_height).to be_within(0.01).of(380)
    end
  end

  describe "cell padding" do
    include CellHelpers

    it "should default to zero" do
      c = cell(:content => "text")
      expect(c.padding).to eq [5, 5, 5, 5]
    end

    it "should accept a numeric value, setting all padding" do
      c = cell(:content => "text", :padding => 10)
      expect(c.padding).to eq [10, 10, 10, 10]
    end

    it "should accept [v,h]" do
      c = cell(:content => "text", :padding => [20, 30])
      expect(c.padding).to eq [20, 30, 20, 30]
    end

    it "should accept [t,h,b]" do
      c = cell(:content => "text", :padding => [10, 20, 30])
      expect(c.padding).to eq [10, 20, 30, 20]
    end

    it "should accept [t,l,b,r]" do
      c = cell(:content => "text", :padding => [10, 20, 30, 40])
      expect(c.padding).to eq [10, 20, 30, 40]
    end

    it "should reject other formats" do
      expect {
        cell(:content => "text", :padding => [10])
      }.to raise_error(ArgumentError)
    end
  end

  describe "background_color" do
    include CellHelpers

    it "should fill a rectangle with the given background color" do
      allow(@pdf).to receive(:mask).and_yield
      expect(@pdf).to receive(:mask).with(:fill_color).and_yield

      allow(@pdf).to receive(:fill_color)
      expect(@pdf).to receive(:fill_color).with('123456')
      expect(@pdf).to receive(:fill_rectangle).with([0, @pdf.cursor], 29.344, 23.872)
      @pdf.cell(:content => "text", :background_color => '123456')
    end

    it "should draw the background in the right place if cell is drawn at a " +
       "different location" do
      allow(@pdf).to receive(:mask).and_yield
      expect(@pdf).to receive(:mask).with(:fill_color).and_yield

      allow(@pdf).to receive(:fill_color)
      expect(@pdf).to receive(:fill_color).with('123456')
      expect(@pdf).to receive(:fill_rectangle).with([12.0, 34.0], 29.344, 23.872)
      #  .checking do |(x, y), w, h|
      #  expect(x).to be_within(0.01).of(12.0)
      #  expect(y).to be_within(0.01).of(34.0)
      #  expect(w).to be_within(0.01).of(29.344)
      #  expect(h).to be_within(0.01).of(23.872)
      #end
      c = @pdf.make_cell(:content => "text", :background_color => '123456')
      c.draw([12.0, 34.0])
    end
  end

  describe "color" do
    it "should set fill color when :text_color is provided" do
      pdf = Prawn::Document.new
      allow(pdf).to receive(:fill_color)
      expect(pdf).to receive(:fill_color).with('555555')
      pdf.cell :content => 'foo', :text_color => '555555'
    end

    it "should reset the fill color to the original one" do
      pdf = Prawn::Document.new
      pdf.fill_color = '333333'
      pdf.cell :content => 'foo', :text_color => '555555'
      expect(pdf.fill_color).to eq '333333'
    end
  end

  describe "Borders" do
    it "should draw all borders by default" do
      expect(@pdf).to receive(:stroke_line).exactly(4).times
      @pdf.cell(:content => "text")
    end

    it "should draw all borders when requested" do
      expect(@pdf).to receive(:stroke_line).exactly(4).times
      @pdf.cell(:content => "text", :borders => [:top, :right, :bottom, :left])
    end

    # Only roughly verifying the integer coordinates so that we don't have to
    # do any FP closeness arithmetic. Can plug in that math later if this goes
    # wrong.
    it "should draw top border when requested" do
      expect(@pdf).to receive(:stroke_line)
        .and_wrap_original do |original_method, *args, &block|
          from, to, = args
          expect(@pdf.map_to_absolute(from).map{|x| x.round}).to eq [36, 756]
          expect(@pdf.map_to_absolute(to).map{|x| x.round}).to eq [65, 756]

          original_method.call(*args, &block)
        end
      @pdf.cell(:content => "text", :borders => [:top])
    end

    it "should draw bottom border when requested" do
      expect(@pdf).to receive(:stroke_line)
        .and_wrap_original do |original_method, *args, &block|
          from, to, = args
          expect(@pdf.map_to_absolute(from).map{|x| x.round}).to eq [36, 732]
          expect(@pdf.map_to_absolute(to).map{|x| x.round}).to eq [65, 732]

          original_method.call(*args, &block)
        end
      @pdf.cell(:content => "text", :borders => [:bottom])
    end

    it "should draw left border when requested" do
      expect(@pdf).to receive(:stroke_line)
        .and_wrap_original do |original_method, *args, &block|
          from, to, = args
          expect(@pdf.map_to_absolute(from).map{|x| x.round}).to eq [36, 756]
          expect(@pdf.map_to_absolute(to).map{|x| x.round}).to eq [36, 732]

          original_method.call(*args, &block)
        end
      @pdf.cell(:content => "text", :borders => [:left])
    end

    it "should draw right border when requested" do
      expect(@pdf).to receive(:stroke_line)
        .and_wrap_original do |original_method, *args, &block|
          from, to, = args
          expect(@pdf.map_to_absolute(from).map{|x| x.round}).to eq [65, 756]
          expect(@pdf.map_to_absolute(to).map{|x| x.round}).to eq [65, 732]

          original_method.call(*args, &block)
        end
      @pdf.cell(:content => "text", :borders => [:right])
    end

    it "should draw borders at the same location when in or out of bbox" do
      expect(@pdf).to receive(:stroke_line)
        .and_wrap_original do |original_method, *args, &block|
          from, to, = args
          expect(@pdf.map_to_absolute(from).map{|x| x.round}).to eq [36, 756]
          expect(@pdf.map_to_absolute(to).map{|x| x.round}).to eq [65, 756]

          original_method.call(*args, &block)
        end
      @pdf.bounding_box([0, @pdf.cursor], :width => @pdf.bounds.width) do
        @pdf.cell(:content => "text", :borders => [:top])
      end
    end

    it "should set border color with :border_..._color" do
      allow(@pdf).to receive(:stroke_color=).with("000000")
      expect(@pdf).to receive(:stroke_color=).with("ff0000")

      c = @pdf.cell(:content => "text", :border_top_color => "ff0000")
      expect(c.border_top_color).to eq "ff0000"
      expect(c.border_colors[0]).to eq "ff0000"
    end

    it "should set border colors with :border_color" do
      allow(@pdf).to receive(:stroke_color=).with("000000")
      expect(@pdf).to receive(:stroke_color=).with("ff0000")
      expect(@pdf).to receive(:stroke_color=).with("00ff00")
      expect(@pdf).to receive(:stroke_color=).with("0000ff")
      expect(@pdf).to receive(:stroke_color=).with("ff00ff")

      c = @pdf.cell(:content => "text",
                    :border_color => %w[ff0000 00ff00 0000ff ff00ff])

      expect(c.border_colors).to eq %w[ff0000 00ff00 0000ff ff00ff]
    end

    it "border_..._width should return 0 if border not selected" do
      c = @pdf.cell(:content => "text", :borders => [:top])
      expect(c.border_bottom_width).to eq 0
    end

    it "should set border width with :border_..._width" do
      allow(@pdf).to receive(:line_width=).with(1)
      expect(@pdf).to receive(:line_width=).with(2)

      c = @pdf.cell(:content => "text", :border_bottom_width => 2)
      expect(c.border_bottom_width).to eq 2
      expect(c.border_widths[2]).to eq 2
    end

    it "should set border widths with :border_width" do
      allow(@pdf).to receive(:line_width=).with(1)
      expect(@pdf).to receive(:line_width=).with(2)
      expect(@pdf).to receive(:line_width=).with(3)
      expect(@pdf).to receive(:line_width=).with(4)
      expect(@pdf).to receive(:line_width=).with(5)

      c = @pdf.cell(:content => "text",
                    :border_width => [2, 3, 4, 5])
      expect(c.border_widths).to eq [2, 3, 4, 5]
    end

    it "should set default border lines to :solid" do
      c = @pdf.cell(:content => "text")
      expect(c.border_top_line).to eq :solid
      expect(c.border_right_line).to eq :solid
      expect(c.border_bottom_line).to eq :solid
      expect(c.border_left_line).to eq :solid
      expect(c.border_lines).to eq [:solid] * 4
    end

    it "should set border line with :border_..._line" do
      c = @pdf.cell(:content => "text", :border_bottom_line => :dotted)
      expect(c.border_bottom_line).to eq :dotted
      expect(c.border_lines[2]).to eq :dotted
    end

    it "should set border lines with :border_lines" do
      c = @pdf.cell(:content => "text",
                    :border_lines => [:solid, :dotted, :dashed, :solid])
      expect(c.border_lines).to eq [:solid, :dotted, :dashed, :solid]
    end
  end






  describe "Text cell attributes" do
    include CellHelpers

    it "should pass through text options like :align to Text::Box" do
      c = cell(:content => "text", :align => :right)

      box = Prawn::Text::Box.new("text", :document => @pdf)

      expect(Prawn::Text::Box).to receive(:new).with("text", hash_including(align: :right))
        .at_least(:once).and_return(box)

      c.draw
    end

    it "should use font_style for Text::Box#style" do
      c = cell(:content => "text", :font_style => :bold)

      box = Prawn::Text::Box.new("text", :document => @pdf)

      expect(Prawn::Text::Box).to receive(:new).with("text", hash_including(style: :bold))
        .at_least(:once).and_return(box)

      c.draw
    end

    it "supports variant styles of the current font" do
      @pdf.font "Courier"

      c = cell(:content => "text", :font_style => :bold)

      box = Prawn::Text::Box.new("text", :document => @pdf)
      expect(Prawn::Text::Box).to receive(:new)
        .and_wrap_original do |original_method, *args, &block|
          text, options, = args
          expect(text).to eq "text"
          expect(options[:style]).to eq :bold
          expect(@pdf.font.family).to eq 'Courier'
          box
        end.at_least(:once)

      c.draw
    end


    it "uses the style of the current font if none given" do
      @pdf.font "Courier", :style => :bold

      c = cell(:content => "text")

      box = Prawn::Text::Box.new("text", :document => @pdf)
      expect(Prawn::Text::Box).to receive(:new)
        .and_wrap_original do |original_method, *args, &block|
          text = args.first
          expect(text).to eq "text"
          expect(@pdf.font.family).to eq 'Courier'
          expect(@pdf.font.options[:style]).to eq :bold
          box
        end.at_least(:once)

      c.draw
    end

    it "should allow inline formatting in cells" do
      c = cell(:content => "foo <b>bar</b> baz", :inline_format => true)

      box = Prawn::Text::Formatted::Box.new([], :document => @pdf)

      expect(Prawn::Text::Formatted::Box).to receive(:new).with(
        [
          hash_including(text: "foo ", styles: []),
          hash_including(text: "bar", styles: [:bold]),
          hash_including(text: " baz", styles: [])
        ],
        kind_of(Hash)
      ).at_least(:once).and_return(box)

      c.draw
    end

    [false, true].each do |inline_format|
      it "preserves option precedence and cell formatting with inline_format=#{inline_format}" do
        c = cell(:content => "text", :align => :right,
                 :font_style => :bold)
        c.inline_format = true if inline_format
        extra_options = {:align => :left, :width => 100, :document => nil}.freeze
        box_class = inline_format ? Prawn::Text::Formatted::Box : Prawn::Text::Box

        expect(box_class).to receive(:new).with(anything,
          hash_including(:align => :left, :width => 100,
                         :style => :bold, :document => @pdf)).and_call_original
        c.__send__(:text_box, extra_options)

        expect(c.align).to eq :right
        expect(c.inline_format).to eq(inline_format ? true : nil)
        expect(c.font.name).to eq 'Helvetica-Bold'

        expect(box_class).to receive(:new).with(anything,
          hash_including(:align => :right, :style => :bold,
                         :document => @pdf)).and_call_original
        c.__send__(:text_box)
      end
    end

  end

  describe "text height cache" do
    include CellHelpers

    def uncached_height(text_cell)
      text_cell.__send__(:with_font) do
        box = text_cell.__send__(:text_box,
          :width => text_cell.spanned_content_width + Prawn::Table::Cell::FPTolerance)
        box.render(:dry_run => true)
        box.height + box.line_gap
      end
    end

    def height_cell(options={})
      cell({:content => "Some text that wraps onto several lines", :width => 100}.merge(options))
    end

    it "reuses a measurement between cells and tables on the same document" do
      first = height_cell
      height = first.natural_content_height
      second = height_cell
      expect(second).to_not receive(:text_box)
      expect(second.natural_content_height).to eq height

      expect(Prawn::Text::Box).to_not receive(:new)
      @pdf.make_table([[first.content]], :column_widths => [100])
    end

    it "does not share measurements between documents" do
      height_cell.natural_content_height
      @pdf = Prawn::Document.new
      c = height_cell
      expected = uncached_height(c)
      expect(c).to receive(:text_box).and_call_original
      expect(c.natural_content_height).to eq expected
    end

    [
      {:width => 45}, {:padding => 20}, {:size => 18}, {:font => 'Courier'},
      {:font_style => :bold}, {:leading => 5}, {:kerning => false},
      {:single_line => true}, {:align => :justify}, {:valign => :bottom},
      {:overflow => :shrink_to_fit, :min_font_size => 6}
    ].each do |options|
      it "remeasures when cell options change to #{options.inspect}" do
        c = height_cell
        c.natural_content_height
        c.style(options)
        expected = uncached_height(c)
        expect(c).to receive(:text_box).and_call_original
        expect(c.natural_content_height).to eq expected
      end
    end

    [
      [:font, 'Courier'], [:font_size, 18], [:default_leading, 5],
      [:default_kerning, false], [:text_direction=, :rtl]
    ].each do |method, value|
      it "remeasures when the document's #{method} changes" do
        c = height_cell
        c.natural_content_height
        @pdf.public_send(method, value)
        expected = uncached_height(c)
        expect(c).to receive(:text_box).and_call_original
        expect(c.natural_content_height).to eq expected
      end
    end

    it "remeasures with different character spacing" do
      c = height_cell
      c.natural_content_height
      @pdf.character_spacing(3) do
        expected = uncached_height(c)
        expect(c).to receive(:text_box).and_call_original
        expect(c.natural_content_height).to eq expected
      end
    end

    it "remeasures when the available height changes" do
      c = height_cell
      full_height = c.natural_content_height
      @pdf.bounding_box([0, 100], :width => 100, :height => 15) do
        expected = uncached_height(c)
        expect(expected).to be < full_height
        expect(c.natural_content_height).to eq expected
      end
    end

    it "reuses a measurement in bounding boxes of the same size at other positions" do
      height = nil
      @pdf.bounding_box([0, 700], :width => 300, :height => 200) do
        height = height_cell.natural_content_height
      end
      @pdf.bounding_box([50, 400], :width => 300, :height => 200) do
        c = height_cell
        expected = uncached_height(c)
        expect(expected).to eq height
        expect(c).to_not receive(:text_box)
        expect(c.natural_content_height).to eq expected
      end
    end

    it "snapshots content so later mutations cannot corrupt earlier entries" do
      text = 'Short'
      original_height = height_cell(:content => text).natural_content_height
      text.replace('Some text that wraps onto several lines')
      changed = height_cell(:content => text)
      expect(changed.natural_content_height).to eq uncached_height(changed)
      expect(changed.natural_content_height).to be > original_height
      original = height_cell(:content => 'Short')
      expect(original).to_not receive(:text_box)
      expect(original.natural_content_height).to eq original_height
    end

    it "bounds storage and keeps repeated labels after many unique values" do
      c = height_cell(:content => 'Label')
      height = c.natural_content_height
      2100.times { |i| height_cell(:content => "Unique #{i}").natural_content_height }
      cache = @pdf.instance_variable_get(:@prawn_table_text_heights)
      expect(cache.size).to eq 2048
      expect(c).to_not receive(:text_box)
      expect(c.natural_content_height).to eq height
      unseen = height_cell(:content => 'Unseen')
      2.times do
        expect(unseen).to receive(:text_box).and_call_original
        unseen.natural_content_height
      end
      expect(cache.size).to eq 2048
    end

    it "does not retain long text" do
      c = height_cell(:content => 'long text ' * 20)
      expect(c).to receive(:text_box).twice.and_call_original
      2.times { c.natural_content_height }
      expect(@pdf.instance_variable_get(:@prawn_table_text_heights)).to be_nil
    end

    it "reuses a measurement of inline formatted text" do
      options = {
        :content => '<b>Some</b> text that <i>wraps</i> onto several lines',
        :inline_format => true,
      }
      first = height_cell(options)
      height = first.natural_content_height
      second = height_cell(options)
      expect(second).to_not receive(:text_box)
      expect(second.natural_content_height).to eq height
      expect(height).to eq uncached_height(height_cell(options))
    end

    it "keeps inline formatted and plain measurements of the same text apart" do
      text = '<b>Some</b> text <b>that</b> wraps'
      formatted = height_cell(:content => text, :inline_format => true)
      formatted_height = formatted.natural_content_height
      plain = height_cell(:content => text)
      expected = uncached_height(plain)
      expect(expected).to_not eq formatted_height
      expect(plain).to receive(:text_box).and_call_original
      expect(plain.natural_content_height).to eq expected
    end

    it "bypasses the cache for inline formatting with a custom text formatter" do
      formatter =
        Class.new do
          def self.format(string, *args)
            Prawn::Text::Formatted::Parser.format(string, *args)
          end
        end
      @pdf = Prawn::Document.new(:text_formatter => formatter)
      c = height_cell(:content => '<b>Label</b>', :inline_format => true)
      expect(c).to receive(:text_box).twice.and_call_original
      2.times { c.natural_content_height }
      expect(@pdf.instance_variable_get(:@prawn_table_text_heights)).to be_nil
    end

    it "bypasses the cache when fallback fonts are active" do
      c = height_cell
      c.natural_content_height
      @pdf.fallback_fonts = ['Courier']
      expected = uncached_height(c)
      expect(c).to receive(:text_box).and_call_original
      expect(c.natural_content_height).to eq expected
    end

    it "bypasses the cache in stretchy bounds" do
      c = height_cell
      c.natural_content_height
      @pdf.bounding_box([0, 100], :width => 100) do
        expected = uncached_height(c)
        expect(c).to receive(:text_box).and_call_original
        expect(c.natural_content_height).to eq expected
      end
    end

    it "bypasses the cache when text box extensions are active" do
      c = height_cell
      c.natural_content_height
      extension = Module.new
      Prawn::Text::Box.extensions << extension
      expect(c).to receive(:text_box).and_call_original
      c.natural_content_height
    ensure
      Prawn::Text::Box.extensions.delete(extension)
    end

    it "bypasses the cache when formatted text box extensions are active" do
      c = height_cell(:content => '<b>Label</b>', :inline_format => true)
      c.natural_content_height
      extension = Module.new
      Prawn::Text::Formatted::Box.extensions << extension
      expect(c).to receive(:text_box).and_call_original
      c.natural_content_height
    ensure
      Prawn::Text::Formatted::Box.extensions.delete(extension)
    end

    it "preserves custom text cell measurement hooks" do
      klass = Class.new(Prawn::Table::Cell::Text)
      c = klass.new(@pdf, [0, @pdf.cursor], :content => 'Label', :width => 100)
      expect(c).to receive(:text_box).twice.and_call_original
      2.times { c.natural_content_height }
    end
  end

  describe "Font handling" do
    include CellHelpers

    it "should allow only :font_style to be specified, defaulting to the " +
       "document's font" do
      c = cell(:content => "text", :font_style => :bold)
      expect(c.font.name).to eq 'Helvetica-Bold'
    end

    it "should accept a font name for :font" do
      c = cell(:content => "text", :font => 'Helvetica-Bold')
      expect(c.font.name).to eq 'Helvetica-Bold'
    end

    it "should use the specified font to determine font metrics" do
      c = cell(:content => 'text', :font => 'Courier', :font_style => :bold)
      font = @pdf.find_font('Courier-Bold')
      expect(c.content_width).to eq font.compute_width_of("text")
    end

    it "should allow style to be changed after initialize" do
      c = cell(:content => "text")
      c.font_style = :bold
      expect(c.font.name).to eq 'Helvetica-Bold'
    end

    it "should default to the document's font, if none is specified" do
      c = cell(:content => "text")
      expect(c.font).to eq @pdf.font
    end

    it "should use the metrics of the selected font (even if it is a variant " +
       "of the document's font) to calculate width" do
      c = cell(:content => "text", :font_style => :bold)
      font = @pdf.find_font('Helvetica-Bold')
      expect(c.content_width).to eq font.compute_width_of("text")
    end

    it "should properly calculate inline-formatted text" do
      c = cell(:content => "<b>text</b>", :inline_format => true)
      font = @pdf.find_font('Helvetica-Bold')
      expect(c.content_width).to eq font.compute_width_of("text")
    end
  end
end

describe "Image cells" do
  before(:each) do
    create_pdf
  end

  describe "with default options" do
    before(:each) do
      @cell = Prawn::Table::Cell.make(@pdf,
                                      { :image => file_fixture("prawn.png").to_s })
    end

    it "should create a Cell::Image" do
      expect(@cell).to be_a_kind_of(Prawn::Table::Cell::Image)
    end

    it "should pull the natural width and height from the image" do
      expect(@cell.natural_content_width).to eq 141
      expect(@cell.natural_content_height).to eq 142
    end
  end

  describe "hash syntax" do
    before(:each) do
      @table = @pdf.make_table([[{
        :image => file_fixture("prawn.png").to_s,
        :scale => 2,
        :fit => [100, 200],
        :image_width => 123,
        :image_height => 456,
        :position => :center,
        :vposition => :center
      }]])
      @cell = @table.cells[0, 0]
    end


    it "should create a Cell::Image" do
      expect(@cell).to be_a_kind_of(Prawn::Table::Cell::Image)
    end

    it "should pass through image options" do
      expect(@pdf).to receive(:embed_image).with(
        anything, anything,
        hash_including(
          scale: 2,
          fit: [100, 200],
          width: 123,
          height: 456,
          position: :center,
          vposition: :center
        )
      )

      @table.draw
    end
  end

  describe "Performance and allocation optimizations" do
    it "includes Cell::InTable on Cell" do
      c = @pdf.make_cell("hello")
      expect(c).to be_a(Prawn::Table::Cell::InTable)
    end
  end

end

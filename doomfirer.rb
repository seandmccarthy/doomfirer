require "ffi-ncurses"

module Doomfirer
  class Flamer
    # A screen 4 times the height of the palette size works best
    SCALE_FACTOR = 4
    attr_reader :image, :palette

    def initialize(w, h, palette)
      @width = w
      @height = h
      @palette = build_sampled_palette(palette)
      @fire_source = @height - 1
      @black_index = 0
      @white_index = @palette.size - 1
      @image = init_image
    end

    def update
      (1 .. @fire_source).each do |y|
        @width.times do |x|
          spreadFire(y * @width + x);
        end
      end
      yield @image
    end

    def extinguish
      @width.times do |x|
        @image[@fire_source * @width + x] = @black_index
      end
    end

    private

    def init_image
      Array.new(@width * @height, @black_index).tap do |image|
        # Bottom line
        @width.times do |i|
          image[@fire_source * @width + i] = @white_index
        end
      end
    end

    def build_sampled_palette(palette)
      sampled_palette_size = @height / SCALE_FACTOR
      sample_factor = (palette.size / sampled_palette_size.to_f).ceil
      [
        palette.first,
        palette[1...-1].select.with_index { |_, i| i % sample_factor == 0 },
        palette.last
      ].flatten
    end

    def spreadFire(pixel_index)
      src_palette_index = @image[pixel_index]
      if src_palette_index == @black_index
        @image[pixel_index - @width] = @black_index
      else
        decay = (rand * 2.0).to_i
        x_offset_randomness = (rand * 3.0).to_i - 1
        dst_palette_index = src_palette_index - decay
        dst_palette_index = @black_index if dst_palette_index < @black_index
        dst_index = [0, (pixel_index - x_offset_randomness - @width)].max
        @image[dst_index] = dst_palette_index
      end
    end
  end

  class NCurses
    attr_reader :width, :height, :palette
    BLOCK = "\u2588" # Unicode block character

    def initialize
      @window = prepare_screen
      @width = FFI::NCurses.getmaxx(@window)
      @height = FFI::NCurses.getmaxy(@window)
      @palette = FIRE_RGBS #build_sampled_palette(@height)
    end

    def render(image, palette)
      @height.times do |y|
        FFI::NCurses.wmove(@window, y, 0)
        @width.times do |x|
          image_index = y * @width + x
          palette_index = image[image_index]
          FFI::NCurses.wattr_set(@window, FFI::NCurses::A_NORMAL, palette[palette_index], nil)  # change colors
          FFI::NCurses.waddstr(@window, BLOCK)
        end
      end
      FFI::NCurses.wattr_set(@window, FFI::NCurses::A_NORMAL, 0, nil)
      FFI::NCurses.wrefresh(@window)
    end

    def finish
      FFI::NCurses.endwin
    end

    private

    def prepare_screen
      scr = FFI::NCurses.initscr
      FFI::NCurses.curs_set(0)
      FFI::NCurses.cbreak
      FFI::NCurses.noecho
      FFI::NCurses.start_color                    # turn colors on
      FFI::NCurses.assume_default_colors(-1, -1)  # make color pair 0 the defaults
      create_color_pairs
      scr
    end

    def create_color_pairs
      (1..256).each { |i| FFI::NCurses.init_pair(i+1, i+1, -1) }
    end

    # Approximation of the Doom palette colours matched to NCurses palette
    FIRE_RGBS = [
      16,  # Black
      233,
      234,
      52,
      52,
      52,
      88,
      88,
      124,
      166,
      166,
      166,
      202,
      202,
      202,
      202,
      208,
      208,
      208,
      209,
      130,
      130,
      172,
      172,
      179,
      179,
      178,
      178,
      178,
      178,
      178,
      178,
      184,
      184,
      185,
      185,
      230,
      15   # White
    ]
  end
end

screen = Doomfirer::NCurses.new
firer = Doomfirer::Flamer.new(screen.width, screen.height, Doomfirer::NCurses::FIRE_RGBS)
begin
  100.times do
    firer.update do |image|
      screen.render(image, firer.palette)
    end
    sleep 0.1
  end
  firer.extinguish
  screen.height.times do
    firer.update do |image|
      screen.render(image, firer.palette)
    end
    sleep 0.05
  end
ensure
  screen.finish
end

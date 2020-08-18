require "ffi-ncurses"

begin
  block = "\u2588" # Full block character in Unicode
  stdscr = FFI::NCurses.initscr
  FFI::NCurses.curs_set(0)
  FFI::NCurses.cbreak
  FFI::NCurses.noecho
  FFI::NCurses.start_color                    # turn colors on
  FFI::NCurses.assume_default_colors(-1, -1)  # make color pair 0 the defaults
  FFI::NCurses.COLORS.times do |i|
    FFI::NCurses.init_pair(i+1, i+1, -1)
  end
  FFI::NCurses.COLORS.times do |i|
    FFI::NCurses.wmove(stdscr, i % 30, i / 30 * 10)
    num = sprintf("%3d", i)
    FFI::NCurses.waddstr(stdscr, num)
    FFI::NCurses.wattr_set(stdscr, FFI::NCurses::A_NORMAL, i, nil)  # change colors
    5.times { FFI::NCurses.waddstr(stdscr, block) }
    FFI::NCurses.wattr_set(stdscr, FFI::NCurses::A_NORMAL, 0, nil)
  end
  FFI::NCurses.wrefresh(stdscr)
  FFI::NCurses.getch
ensure
  FFI::NCurses.endwin
end

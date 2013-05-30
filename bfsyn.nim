# syntax highlighter for brainfuck in nimrod
# http://en.wikipedia.org/wiki/Brainfuck

# ansi colors:
# http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
# k = black, r = red, rr = bright red, etc
type TColor = enum
  k,  r,  g,  y,  b,  m,  c,  w,
  kk, rr, gg, yy, bb, mm, cc, ww


# fg() emits the ansi code to set the foreground color
var lastColor = TColor.k
proc fg(c : TColor) =
  var shade : string
  if c != lastColor:
    if ord(c) <= 8 : shade = "0;3" & $(ord(c))
    else: shade = "01;3" & $(ord(c) - 8)
    write(stdout, chr(27),'[',shade,'m')
  lastColor = c


# main routine:
var ch = ' '
while not EndOfFile(stdin):
  ch = readChar(stdin)
  case ch
  of '<' : fg(gg)
  of '>' : fg(gg)
  of '+' : fg(y)
  of '-' : fg(y)
  of '.' : fg(c)
  of ',' : fg(c)
  of '[' : fg(bb)
  of ']' : fg(bb)
  else   : fg(w)
  write(stdout, ch)
fg(w)



# brainfuck interpreter in nimrod
# http://en.wikipedia.org/wiki/Brainfuck
import os, unsigned, terminal, unittest

const
  kRamSize = 64
  kOpcodes = {'<','>','+','-','.',',','[',']'}

type
  TCode = string
  TData = array[0..kRamSize, byte]

proc emit(x:char) =
  write(stdout,x)

var
  data   : TData
  ip     : int = 0 # instruction pointer
  dp     : int = 0 # data pointer
  output : string = ""
  code   : TCode

proc fwd =
  var bal : int = 0; var done : bool
  while ip < len(code) and not done:
    if code[ip] == '[': inc(bal)
    elif code[ip] == ']':
      dec(bal)
      done = bal == 0
    inc(ip)
  if not done: raise newException(E_base, "No matching ] found.")

proc bak =
  var bal : int = 0; var done : bool
  while not done:
    if code[ip] == ']': inc(bal)
    elif code[ip] == '[':
      dec(bal)
      done = bal == 0
    if ip == 0: raise newException(E_base, "No matching [ found.")
    else: dec(ip)


proc runTime(code:string) =
  ip = 0
  while ip < len(code):
    if code[ip] in kOpcodes:
      case code[ip]
      of '>' : inc dp
      of '<' : dec dp
      of '+' : inc data[dp]
      of '-' : dec data[dp]
      of '.' : output = output & chr(data[dp])
      of ',' : data[dp] = ord(readChar(stdin))
      of '[' :
        if data[dp]!=0: fwd()
      of ']' :
        if data[dp]==0: bak()
      else   : nil
      #     draw()
      #     discard readChar(stdin)
    else:nil
    inc(ip)

# replace ascii control codes with the
# equivalent caret representation
# proc drawOutput() =
#   for i in countup(0, len(output)):
#     if ord(output[i]) == 0:
#       setForegroundColor(fgBlack, true)
#       emit('.')
#       resetAttributes()
#     elif ord(output[i]) < 32:
#       setForegroundColor(fgRed, true)
#       emit('^'); emit( chr(ord(output[i]) + ord('@')))
#       resetAttributes()
#     else: emit(output[i])
#   echo()

# proc draw =
#   EraseScreen()
#   setCursorPos(0,0)
#   # TODO drawData()
#   # show the code, but ignore comment chars
#   for i in countup(0, len(code)):
#     if i == ip: setStyle({styleReverse})
#     emit(code[i])
#     if i == ip: resetAttributes()
#   drawOutput()
# echo "--"

proc main(path:string) =
  runTime readFile(path)
  echo(output)

proc runTests =
  test "> increments dp":
    dp = 0
    runTime(">")
    check dp == 1

  test "< decrements dp":
    dp = 1
    runTime("<")
    check dp == 0

  test "+ increments data":
    data[dp] = 0
    runTime("+")
    check data[dp] == 1

  test "- decrements  data":
    data[dp] = 1
    runTime("-")
    check data[dp] == 0

  test ". outputs char":
    output = ""
    data[dp] = ord('a')
    runTime(".")
    check output == "a"


# command line interface:
when isMainModule:

  if paramcount() == 1:
    if paramstr(1) == "-t": runTests()
    else: main(paramstr(1))
  else: echo("usage: bfrun [-t|PATH]")

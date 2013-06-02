#
# brainf*** interpreter and debugger in nimrod
#
# https://github.com/tangentstorm/grimspike
#
# copyright (c) 2013 Michal J Wallace and Taylor Skidmore
# available for use under the MIT/X11 license
#
import os, unsigned, terminal, unittest

const
  kRamSize = 30000
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

# -- debug routines ----------------------------

proc colored(fg:TForegroundColor, s:string) =
  setForegroundColor(fg, true)
  stdout.write(s)
  resetAttributes()

# replace ascii control codes with the
# equivalent caret representation
proc drawCarets(output:string) =
  for i in countup(0, len(output)):
    if ord(output[i]) == 0:
      colored(fgBlack, ".")
    elif ord(output[i]) < 32:
      colored(fgRed, "" &  chr(ord(output[i]) + ord('@')))
    elif ord(output[i]) > 0x7F:
      colored(fgBlue, "?")
    else: emit(output[i])
  echo() # newline

proc hex(b:byte):string =
  let hexits = "0123456789ABCDEF"
  result = hexits[int(b div 16)] & hexits[b mod 16]

proc hexDump(data:TData; w:byte=16; h:byte=8) =
  for y in countup(0, h):
    for x in countup(0, w): stdout.write hex(data[y * w + x]), ' '
    var short = ""
    for x in countup(0, w): short = short & chr(data[y * w + x])
    drawCarets(short)

proc drawCode() =
  # show the code, but ignore comment chars
  for i in countup(0, len(code)):
    case code[i]
    of '<' : setForegroundColor(fgGreen, true)
    of '>' : setForegroundColor(fgGreen, true)
    of '+' : setForegroundColor(fgYellow)
    of '-' : setForegroundColor(fgYellow)
    of '.' : setForegroundColor(fgCyan)
    of ',' : setForegroundColor(fgCyan)
    of '[' : setForegroundColor(fgBlue, true)
    of ']' : setForegroundColor(fgBlue, true)
    else   : setForegroundColor(fgWhite)
    if i == ip: setStyle({styleReverse})
    emit(code[i])
    if i == ip: resetAttributes()


proc head(s:string)=
  var res = "--| "  & s & " |--"
  while len(res) < 70 : res = res & '-'
  setStyle({styleReverse})
  stdout.writeln res
  ResetAttributes()

proc draw =
  setCursorPos(0,0)
  head "data"
  hexDump(data)
  head "code"
  drawCode()
  head "output"
  EraseLine()
  drawCarets(output)
  echo ""


# -- interpreter ------------------------------------

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
  while ip >= 0 and not done:
    if code[ip] == ']': inc(bal)
    elif code[ip] == '[':
      dec(bal)
      done = bal == 0
    if ip == 0: raise newException(E_base, "No matching [ found.")
    else: dec(ip)

proc runCode(src:string, debugFlag:bool=false) =
  code = src
  ip = 0
  while ip < len(code):
    if code[ip] in kOpcodes:
      if debugFlag:
        draw()
        discard readChar(stdin)
      case code[ip]
      of '>' : inc dp
      of '<' : dec dp
      of '+' : inc data[dp]
      of '-' : dec data[dp]
      of '.' : output = output & chr(data[dp])
      of ',' : data[dp] = ord(readChar(stdin))
      of '[' :
        if data[dp]==0: fwd()
      of ']' :
        if data[dp]!=0: bak()
      else   : nil
    else:nil
    inc(ip)

proc resetVm =
  output = ""
  dp = 0
  ip = 0
  for i in countup(0,high(data)):
    data[i] = 0


proc runFile(path:string, debugFlag:bool) =
  resetVm()
  runCode readFile(path), debugFlag
  drawCarets(output)


# -- tests -----------------------------------------------

proc runUnitTests =
  test "> increments dp":
    dp = 0
    runCode(">")
    check dp == 1

  test "< decrements dp":
    dp = 1
    runCode("<")
    check dp == 0

  test "+ increments data":
    data[dp] = 0
    runCode("+")
    check data[dp] == 1

  test "- decrements  data":
    data[dp] = 1
    runCode("-")
    check data[dp] == 0

  test ". outputs char":
    output = ""
    data[dp] = ord('a')
    runCode(".")
    check output == "a"


proc runAcceptanceTests =
  test "ascii A":
    resetVm()
    output = ""
    runCode(
      """
      +++++ +++++ # 5 plus 5 = 10
      +++++ +++++ # 20
      +++++ +++++ # 30
      +++++ +++++ # 40
      +++++ +++++ # 50
      +++++ +++++ # 60
      +++++ .     # 65 so should emit ascii  'A'
      """)
    check output == "A"

# -- command line interface: ----------------------------

when isMainModule:
  var debugFlag = false
  if paramcount() == 0:
    echo("usage: bfrun ( -t | -d | PATH )+")
  else:
    for i in countup(1, paramcount()):
      case paramstr(i)
      of "-t":
        runUnitTests()
        runAcceptanceTests()
      of "-d": debugFlag = true
      else: runFile(paramstr(i), debugFlag)

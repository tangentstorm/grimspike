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


# -- debug routines ----------------------------

# replace ascii control codes with the
# equivalent caret representation
proc drawOutput() =
  for i in countup(0, len(output)):
    if ord(output[i]) == 0:
      setForegroundColor(fgBlack, true)
      emit('.')
      resetAttributes()
    elif ord(output[i]) < 32:
      setForegroundColor(fgRed, true)
      emit('^'); emit( chr(ord(output[i]) + ord('@')))
      resetAttributes()
    else: emit(output[i])
  echo() # newline

proc drawCode() =
  # show the code, but ignore comment chars
  for i in countup(0, len(code)):
    if i == ip: setStyle({styleReverse})
    emit(code[i])
    if i == ip: resetAttributes()

proc draw =
  EraseScreen()
  setCursorPos(0,0)
  # TODO drawData()
  drawCode()
  echo "-- output: -----"
  drawOutput()


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
  drawOutput()


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

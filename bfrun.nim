# brainfuck interpreter in nimrod
# http://en.wikipedia.org/wiki/Brainfuck
import os, unsigned

const
  kRamSize = 30000

type
  TCode = string
  TData = array[0..kRamSize, byte]

proc main(path:string) =
  var
    code : TCode
    data : TData
    ip  : int = 0 # instruction pointer
    dp  : int = 0 # data pointer

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

  code = readFile(path)
  while ip < len(code):
    case code[ip]
    of '>' : inc dp
    of '<' : dec dp
    of '+' : inc data[dp]
    of '-' : dec data[dp]
    of '.' : write stdout, chr(data[dp])
    of ',' : data[dp] = ord(readChar(stdin))
    of '[' :
      if data[dp]!=0: fwd()
    of ']' :
      if data[dp]==0: bak()
    else   : nil
    inc(ip)
  echo()

# command line interface:
if paramcount() == 1: main(paramstr(1))
else: echo("usage: bfrun PATH")

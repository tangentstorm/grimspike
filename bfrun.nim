# brainfuck interpreter in nimrod
# http://en.wikipedia.org/wiki/Brainfuck
import os, unsigned

const
  kRamSize = 30000

type
  TRam = array[0..kRamSize, byte]

var
  ram : TRam

proc readCode(path:string) =
  var
    f  : TFile = open(path)
    i  : int = 0
  while i < kRamSize and not EndOfFile(f):
    ram[i] = ord(readChar(f))
    inc(i)

proc main(path:string) =
  var
    ip  : int = 0 # instruction pointer
    dp  : int = 0 # data pointer

  proc fwd =
    var bal : int = 0; var done : bool
    while ip < kRamSize and not done:
      if chr(ram[ip]) == '[': inc(bal)
      elif chr(ram[ip]) == ']':
        dec(bal)
        done = bal == 0
      inc(ip)
    if not done: raise newException(E_base, "No matching ] found.")

  proc bak =
    var bal : int = 0; var done : bool
    while ip >= 0 and not done:
      if chr(ram[ip]) == ']': inc(bal)
      elif chr(ram[ip]) == '[':
        dec(bal)
        done = bal == 0
      dec(ip)
    if not done: raise newException(E_base, "No matching [ found.")

  readCode(path)
  while ip < kRamSize:
    case chr(ram[ip])
    of '>' : inc dp
    of '<' : dec dp
    of '+' : inc ram[dp]
    of '-' : dec ram[dp]
    of '.' : write stdout, chr(ram[dp])
    of ',' : ram[dp] = ord(readChar(stdin))
    of '[' :
      if ram[dp]!=0: fwd()
    of ']' :
      if ram[dp]==0: bak()
    else   : nil
    inc(ip)
  echo()

# command line interface:
if paramcount() == 1: main(paramstr(1))
else: echo("usage: bfrun PATH")

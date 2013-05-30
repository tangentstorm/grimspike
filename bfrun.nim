# brainfuck interpreter in nimrod
# http://en.wikipedia.org/wiki/Brainfuck
import os

var ch : char

proc main(path:string) =
  var 
    ram : array[0..29999, byte]
    ip : int = 0
    dp : int = 0
  let code = readFile(path)
  while not EndOfFile(stdin):
    case ch
    of '<' : nil
    of '>' : nil
    of '+' : nil
    of '-' : nil
    of '.' : nil
    of ',' : nil
    of '[' : nil
    of ']' : nil
    else   : nil

# command line interface:
if paramcount() == 1: main(paramstr(1))
else: echo("usage: bfrun PATH")

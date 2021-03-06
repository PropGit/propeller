''***************************
''*  Bitwise Manipulators   *
''*  Author: Peter Quello   *
''*  Started: 28 JUL 2010   *
''*  Updated:               *
''***************************

''┌──────────────────────────────────────────┐
''│ Copyright (c) <2010> <Peter Quello>      │
''│ See end of file for terms of use.        │
''└──────────────────────────────────────────┘

PUB GetBitLong(variableAddr,index) | localcopy

  localcopy := long[variableAddr]

  return ((localcopy & (1<<index)) >> index)

PUB SetBitLong(variableAddr,index)

  long[variableAddr] := long[variableAddr] | (1<<index)
  return

PUB ClrBitLong(variableAddr,index)

  long[variableAddr] := long[variableAddr] & (!(1<<index))
  return

PUB ToggleBitLong(variableAddr,index)

  if (getBitlong(variableAddr,index) == 0)
    setBitlong(variableAddr,index)
  else
    clrBitlong(variableAddr,index)
  return

PUB GetBitByte(variableAddr,index) | localcopy

  localcopy := byte[variableAddr]

  return ((localcopy & (1<<index)) >> index)

PUB SetBitByte(variableAddr,index)

  byte[variableAddr] := byte[variableAddr] | (1<<index)
  return

PUB ClrBitByte(variableAddr,index)

  byte[variableAddr] := byte[variableAddr] & (!(1<<index))
  return

PUB ToggleBitByte(variableAddr,index)

  if (getBitbyte(variableAddr,index) == 0)
    setBitbyte(variableAddr,index)
  else
    clrBitbyte(variableAddr,index)
  return


DAT

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}

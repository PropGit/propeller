{{
  Prop Bus, Test Driver
  File: PropBusTest.spin
  Version: 1.0
  Copyright (c) 2014 Mike Christle
}}

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  BUF_SIZE = 10
  CYCLE_FREQ = 1000
  MSG_COUNT = 2
  BUS_BIT_RATE = 1_100_000
  TEST_DELAY = 3
  
VAR

  byte  StrBuf[10]
  byte  OnOff, Cog
  word  BCBuf1[BUF_SIZE], BCBuf2[BUF_SIZE], BCBuf3[BUF_SIZE]
  long  One_mSec, ErrCnt
   
OBJ

  pst : "Parallax Serial Terminal"
  bc  : "PropBusBC"
  
PUB MainRoutine | I, J, V

  pst.Start(115200)

  repeat until pst.CharIn == pst#NL

  pst.Clear                
  pst.Str(@Header)

  OnOff := 0
  One_mSec := clkfreq / 1000

  repeat
    pst.Str(@Prompt0)
    pst.StrIn(@StrBuf)
    case StrBuf[0]

      ' Toggle the Cogs on and off
      "t":
        OnOff := OnOff ^ 1
        if (OnOff == 1)
          bc.AddBuffer(1, @BCBuf1, BUF_SIZE, bc#TRANSMIT_BUFFER)
          bc.AddBuffer(2, @BCBuf2, BUF_SIZE, bc#RECEIVE_BUFFER)
          bc.AddBuffer(3, @BCBuf3, BUF_SIZE, bc#RECEIVE_BUFFER)
          bc.SetBitRate(BUS_BIT_RATE)

          ' Single Wire
          bc.Start(0, 0, -1, CYCLE_FREQ, MSG_COUNT)

          ' Two Wire
'          bc.Start(16, 18, -1, CYCLE_FREQ, MSG_COUNT)

          ' Three Wire
'          bc.Start(2, 4, 6, CYCLE_FREQ, MSG_COUNT)
          
          pst.Str(@OnMsg)
        else
          bc.Stop
          pst.Str(@OffMsg)

      ' Perform data transfer reliability test
      ' To use this, start BC with BCount = 2
      "l":
        LoopTest
        pst.Str(@DoneMsg)

      "i":
        TagWordTest
        pst.Str(@DoneMsg)

      "a":
        VerifyAsyncCmnd
        pst.Str(@DoneMsg)

      other:                 
         pst.Str(@Menu)

PRI VerifyAsyncCmnd | I, J
{
 Send an asyncronous command
 Verify the timing is ~50uSec
 To use this, start BC with BCount = 0
}
  I := cnt
  bc.SendCommand(3)
  J := cnt - I
  pst.Dec(J / 80)' Display in uSec
  pst.Char(" ")
  pst.Hex(BCBuf3[0], 4)

PRI TagWordTest | I

  pst.Char(pst#CS)
  repeat
    if pst.RXCount > 0
      return
    waitcnt(cnt + 800_000)
    bc.SendCommand(3)
    pst.Char(pst#HM)
    repeat I from 0 to BUF_SIZE - 1
      pst.Dec(BCBuf3[I])
      pst.Str(@ClrMsg)

PRI LoopTest | I, J, V
{
    Each buffer is filled with a test pattern.
    Wait for 60mSec because the BC is cycleing at 20Hz or 50mSec.
    Then the receive buffer contents are verified.    
}
  ErrCnt := 0
  pst.Char(pst#CS)
  repeat I from 1 to 1_000_000_000

      ' Fill buffers with test patterns
      FillTestBufs(I)

      ' Wait for at least one cycle
      repeat TEST_DELAY
        waitcnt(cnt + One_mSec)

      ' Verify recieve buffers
      VerifyTestBufs(I)
      if ErrCnt > 0
        return

      ' Abort if any key pressed
      if pst.RxCount > 0
        return

      ' Display loop count
      if (i // 20) == 0
        pst.Char(pst#HM)
        pst.Dec(I)  
        pst.Char(" ")
        pst.Dec(ErrCnt)  

PRI FillTestBufs(Val) | I

  repeat I from 0 to BUF_SIZE - 1
    BCBuf1[I] := I + Val + $1000
    BCBuf2[I] := $99

PRI VerifyTestBufs(Val) | I

  repeat I from 0 to BUF_SIZE - 1
    if BCBuf2[I] <> BCBuf1[I]
      ErrCnt++
      pst.Char(pst#NL)
      pst.Hex(BCBuf1[I], 4)
      pst.Char(" ")
      pst.Hex(BCBuf2[I], 4)

DAT

Header        byte  pst#NL, "Prop Bus Test", pst#NL, 0
Prompt0       byte  pst#NL, "Cmd >>> ", 0
Prompt1       byte  pst#NL, "Hex Word >>> ", 0
Prompt2       byte  pst#NL, "BCount Value >>> ", 0
Prompt3       byte  pst#NL, "Bit Rate Value >>> ", 0
Menu          byte  pst#NL, "t : Toggle On/Off"
              byte  pst#NL, "l : Send Words in Loop"
              byte  pst#NL, "a : Verify Asyncrnous Command"
              byte  pst#NL, "i : Verify Tag WOrd Increment", 0
OnMsg         byte  pst#NL, "ON", 0
OffMsg        byte  pst#NL, "OFF", 0
DoneMsg       byte  pst#NL, "Done", 0
FailMsg       byte  pst#NL, "   FAIL", 0
ClrMsg        byte  "    ", pst#NL, 0
{{
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}                        
{{
┌────────────────────────────────┐
│ 16x1 LCD Driver Demo Program   │
├────────────────────────────────┴────────────────────┐
│  Version : 1.3                                      │
│  By      : Tom Dinger                               │   
│            propeller@tomdinger.net                  │
│  Date    : 2010-11-14                               │
│  (c) Copyright 2010 Tom Dinger                      │
│  See end of file for terms of use.                  │
└─────────────────────────────────────────────────────┘
}}
{
  Version History:
  1.0 -- 2010-09-16 -- Initial release.

  1.3 -- 2010-11-14 -- Changes to pin variable names to allow for
                       use of either 4-bit or 8-bit interface.
}
{{

This program demonstrates some of the functions of the 16x1 display
driver for the Ampire Co. Ltd. LCD display AC-161B, although it should
work (for some definition of "work") on all HD44780-compatible displays.

Tests:
- short string output
- longer string output
- demonstration of the "split" nature of the display memory,
  using disply shifts.
- Cursor types
- random addressing, both shifted and unshifted display
- user-defined characters, with spinning hourglass

If you want to see how the "memory-management" for this display
really works, use a 20x4 character display, because that has a
display position for each character in the controller memory. It
will look strange, but it provides lots of feedback about the cursor
movement and how memory is used for this 16x1 display.

}}

CON
  _CLKMODE      = XTAL1 + PLL16X                        
  _XINFREQ      = 5_000_000

  ' Pin assignments
  ' For the Propeller Demo Board, these are the RGB signals
  ' on the VGA connector -- I need P0 to P7 for the 8-bit
  ' wide data bus
  RS = 19      ' 1                   
  RW = 21      ' 2                    
  E  = 23      ' 3

  ' These must be four (or 8) consecutive pins
  ' The pins used depends on which lowest-level component is used:
  ' either the 4-bit or the 8-bit interface.
  DBLow  = 4   ' 0
  DBHigh = 7

  ' ASCII codes.
  CR  = 13
  LF  = 10
  PSTClearScreen = 16
  

OBJ
  LCD : "LCD_16x1_SxS"
  DBG : "SimpleDebug"
  
PUB Demo | t, n, i, tests, failures 
  DBG.start(9600)
  LCD.usDelay( 5_000_000 ) ' time enough to switch to PST
  
  DBG.str(string(PSTClearScreen,"Starting test program -- LCD Init",CR))

  LCD.Init( E, RS, RW, DBHigh, DBLow )

{
The following code shows an issue for this display and controller
immediately following a Clear instruction to the controller:
the next PrintChr() does not always work correctly, specifically,
the second write of data, which is supposed to go to address $60,
is not done correctly. A small delay after issuing the Clear
instruction seems to solve the problem. That delay is now in
the Clear() method of the LCD_16x1_SxS object. To test it, comment
the delay out there, uncomment this test, and run it. With the current
test, I see from 100 to 460 failures in 1000 tests. When the 5 us delay
is added back in, the number of failures goes to 0 out of 1000 tests.
}
{
  ' Perform the Clear reliability test
  tests := 0
  failures := 0

  repeat 10000
    LCD.RawWriteStr( string("Now") )
    LCD.Clear
    'LCD.usDelay( $10 ) ' $10 ok $0F not ok -- now done in the Clear() method
    if ( LCD.GetDisplayAddr <> 0 )
      ++failures
    ++tests
  DBG.dec( failures )
  DBG.str( string(" failures out of "))
  DBG.dec( tests )
  DBG.str( string(" tests"))
  repeat ' stall here
}

  ' Test simple output
  ' This assumes that the display has been cleared by the Init()
  ' The text is short, and fits within the left half of the display
  
  DBG.str(string("Simple string output",CR))
  LCD.PrintStr( string("Hello") )
  LCD.usDelay( 2_000_000 )


  ' Test Clear screen
  DBG.str(string("Clear screen test",CR))
  LCD.Clear
  LCD.usDelay( 2_000_000 )


  ' This tests writing to the display, and crossing over the halfway
  ' point of the screen.
  DBG.str(string("Longer string test",CR))
  LCD.PrintStr( string("Hello everyone") )
  LCD.usDelay( 2_000_000 )

  ' Split Display Memory Demonstration
  ' This test loads the display RAM for the left half of the display
  ' with the upper-case alphabet, and the display RAM for the right
  ' half with matching lower-case letters. Then, the display is shifted
  ' left repeatedly, making it seem as if the letters change case
  ' as they move from the right half to the left half of the display.
  
  DBG.str(string("Split display memory demo",CR))
  LCD.Clear
  LCD.RawSetPos( $00 ) ' "first" line
  LCD.RawWriteStr( string("ABCDEFGHIJKLMNOPQRSTUVWXYZYXWVUTSRQPONML") )
  LCD.RawSetPos( $40 ) ' "second" line
  LCD.RawWriteStr( string("ijklmnopqrstuvwxyzyxwvutsrqponmlabcdefgh") )
  LCD.usDelay( 2_000_000 )

  repeat 40
    LCD.usDelay( 500_000 ) ' 1/2 second
    LCD.ShiftDisplayLeft
  LCD.usDelay( 2_000_000 )


  ' Display scrolling test
  ' This fills the "virtual" 40-character line with text, then
  ' shifts the display right repeatedly so the text scrolls uniformly.
  ' This exercises the logic in PrintChr() that writes all characters
  ' to both halves of the display RAM, so that display scrolling
  ' seems to work properly.

  DBG.str(string("Display scrolling test",CR))
  LCD.Clear
  LCD.PrintStr( string("Now is the time for all good men to act!") )
  LCD.usDelay( 2_000_000 )
  repeat 40
    LCD.usDelay( 500_000 ) ' 1/2 second
    LCD.ShiftDisplayRight
  LCD.usDelay( 2_000_000 )


  ' Test cursor types
  DBG.str(string("Cursor types test",CR))
  LCD.Clear
  LCD.PrintStr( string("Steady -->"))
  LCD.CursorSteady
  LCD.usDelay( 4_000_000 )
  LCD.Clear
  LCD.PrintStr( string("Blink -->"))
  LCD.CursorBlink
  LCD.usDelay( 4_000_000 )
  LCD.Clear
  LCD.PrintStr( string("No Cursor -->"))
  LCD.CursorOff
  LCD.usDelay( 4_000_000 )


  ' test cursor shift routines -- bounce the cursor right and left
  DBG.str( string("Cursor shift test",CR))
  LCD.Clear
  LCD.CursorSteady
  repeat 2
    repeat 15
      LCD.usDelay( 250_000 )
      LCD.ShiftCursorRight
    repeat 15
      LCD.usDelay( 250_000 )
      LCD.ShiftCursorLeft


  ' Test cursor addressing: write every char position, but
  ' not in order.
  Dbg.str( string("Cursor addressing test, no shift", CR) )
  LCD.Clear   ' no shift in the display
  LCD.CursorSteady
  repeat i from 0 to 45 step 3
    t := i & $0F
    LCD.usDelay( 250_000 )
    LCD.SetRowCol( 0, t )
    LCD.PrintChr( byte[ @RandMsg1 + t ] )
  LCD.usDelay( 4_000_000 )


  ' Test cursor addressing, with a shifted display.
  Dbg.str( string("Cursor addressing test, shifted", CR) )
  LCD.Clear   ' no shift in the display yet
  LCD.CursorSteady
  LCD.ShiftDisplayRight ' shifted 4 to the right
  LCD.ShiftDisplayRight
  LCD.ShiftDisplayRight
  LCD.ShiftDisplayRight
  repeat i from 0 to 45 step 3
    t := i & $0F
    LCD.usDelay( 250_000 )
    LCD.SetRowCol( 0, t )
    LCD.PrintChr( byte[ @RandMsg1 + t ] )
  LCD.usDelay( 4_000_000 )


  ' Test user defined character:
  ' Use a spinning hourglass pattern, 8 characters in 0..7
  Dbg.str( string("User defined character: hourglass", CR) )
  LCD.Clear
  LCD.WriteCharGen( 0, @HourglassChar0 ) ' writes all 8 characters.
  LCD.PrintStr( string("Please Wait ") )
  repeat 8
    repeat i from 0 to 7
      LCD.usDelay( 200_000 )
      LCD.SetRowCol( 0, 12 )       
      LCD.PrintChr( i )
  LCD.Home
  LCD.PrintStr( string("All finished 1  ") ) ' 16 characters long
  LCD.usDelay( 4_000_000 )


  ' Test user defined character:
  ' Use a spinning hourglass pattern, 8 characters in 0..7
  ' But perform the animation by redefining a single character,
  ' instead of changing the character in Display Memory
  
  Dbg.str( string("User defined character: hourglass", CR) )
  LCD.Clear
  LCD.WriteCharGenCnt( 0, 0, @EmptyChar, 8 ) ' clear char 0
  LCD.PrintStr( string("Please Wait ") )
  LCD.PrintChr( 0 ) ' cannot be part of a string()
  ' show the 8 characters 8 times each
  t := @HourglassChar7
  repeat 64
    if ( t == @HourglassChar7 )
      t := @HourglassChar0 ' wrap back to start
    else
      t += 8               ' advance to next char
    LCD.usDelay( 200_000 )
    LCD.WriteCharGenCnt( 0, 0, t, 8 )
  LCD.Home
  LCD.PrintStr( string("All finished 2  ") ) ' 16 characters long
  LCD.usDelay( 4_000_000 )
  

  DBG.str(string("done",CR))
  
  repeat   ' stall here...

PRI dbgDisplayAddr | t
  ' Send the current Display RAM address to DBG output, just to check...
  t := LCD.GetDisplayAddr
  DBG.str(string("Current display address: "))
  DBG.hex(t,4)
  DBG.str(string(CR))


DAT
RandMsg1 byte "0123456789ABCDEF"

' define the 8 characters that show a spinning hourglass, when shown
' at a single character position, in sequence.

HourglassChar0 byte %00011111
               byte %00011111
               byte %00001110
               byte %00000100
               byte %00001010
               byte %00010001
               byte %00011111
               byte %00000000 ' cursor row

HourglassChar1 byte %00011111
               byte %00011011
               byte %00001110
               byte %00000100
               byte %00001010
               byte %00010101
               byte %00011111
               byte %00000000 ' cursor row

HourglassChar2 byte %00011111
               byte %00010011
               byte %00001110
               byte %00000100
               byte %00001010
               byte %00010111
               byte %00011111
               byte %00000000 ' cursor row

HourglassChar3 byte %00011111
               byte %00010001
               byte %00001110
               byte %00000100
               byte %00001010
               byte %00011111
               byte %00011111
               byte %00000000 ' cursor row

HourglassChar4 byte %00011111
               byte %00010001
               byte %00001010
               byte %00000100
               byte %00001110
               byte %00011111
               byte %00011111
               byte %00000000 ' cursor row

HourglassChar5 byte %00000111
               byte %00000101
               byte %00000100
               byte %00011111
               byte %00011100
               byte %00011100
               byte %00001100
               byte %00000000 ' cursor row

HourglassChar6 byte %00000000
               byte %00010001
               byte %00011010
               byte %00011100
               byte %00011010
               byte %00010001
               byte %00000000
               byte %00000000 ' cursor row

HourglassChar7 byte %00001100
               byte %00011100
               byte %00011100
               byte %00011111
               byte %00000100
               byte %00000101
               byte %00000110
               byte %00000000 ' cursor row

HourglassEnd   byte %11111111 ' ends data for transfer.

EmptyChar      byte %00000000
               byte %00000000
               byte %00000000
               byte %00000000
               byte %00000000
               byte %00000000
               byte %00000000
               byte %00000000


{{

  (c) Copyright 2010 Tom Dinger

┌────────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                           │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a     │
│copy of this software and associated documentation files (the               │
│"Software"), to deal in the Software without restriction, including         │
│without limitation the rights to use, copy, modify, merge, publish,         │
│distribute, sublicense, and/or sell copies of the Software, and to          │
│permit persons to whom the Software is furnished to do so, subject to       │
│the following conditions:                                                   │
│                                                                            │
│The above copyright notice and this permission notice shall be included     │
│in all copies or substantial portions of the Software.                      │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS     │
│OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                  │
│MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.      │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, │
│DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR       │
│OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE   │
│USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└────────────────────────────────────────────────────────────────────────────┘
}}
  
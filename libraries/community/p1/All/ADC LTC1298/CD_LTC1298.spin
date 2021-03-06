{{ CD_LTC1298.spin }}
{
*************************************************
    ADC0834 Interface Object
*************************************************
    Charlie Dixon  2007 
*************************************************
Parts of this program were adapted from programs
from other users.  Why reinvent the wheel?  :^)
*************************************************

  start(pin)                   : to be called first, pin = first pin, 4 pins are needed  
  CH0, CH1                     : two ADC channels  
  ReadConv()                   : get 12 bits of data MSB first

Test connections to Propeller Demo Board with "start(pin)" = 0

      Vcc(+5V)                     Vcc(+5V)
      │         LTC1298CN8        │
      │    ┌──────────────────────┼─┐
  ┌───┫    │ ┌────────────────┐   │ └────── P0
  │   │    └─┤1 !cs     Vcc  8├───┘               Vcc      = 5V
  │   ─────┤2 CH0     CLK  7├──────────── P1    MAX ADx  = 5V
  ──┼──────┤3 CH1     Dout 6├──────┐            CLK      = 200kHz MAX, HIGH/LOW time = 2µS MIN
  │   │    ┌─┤4 GND     Din  5├──────┻─── P2    
  └───╋────┘ └────────────────┘                   1LSB     = Vcc/4096 = 0.00122V
      │                                            Pots are 10K and resisters are 1K
      Vss                                          as per 5V to 3.3V interface thread.

Notes:

}

CON

' data for Din to start conversion for each ADx channel

  CH0 = %1011          ' Note: Shift LSB first so bits are reversed from Datasheet
  CH1 = %1111          ' Note: See Datasheet MUX Addressing for more details
  
VAR

  byte ADC             ' Analog to Digital Channel Din Value.  Set using CON values.
  word pin             ' Received PINs from other .spin object
  word dataio          ' Din, Dout Pins  - input/output.  High impedance protects Dout pin while writing Din
  word cs              ' Chip Enable Pin - output
  word clk             ' Chip Clock Pin  - output
  long datar           ' 12 Bit return value from conversion

PUB start( pin_ )

  pin := pin_
  init(pin, pin+1, pin+2)
  
PUB GetADC( chan ) : adcr | ADC_Val

  if (chan == 0)
    ADC_Val := convert(0)
  if (chan == 1)
    ADC_Val := convert(1)
  return ADC_Val

PRI init( cs_, clk_, dataio_ )

  cs      := cs_
  clk     := clk_
  dataio  := dataio_


  dira[clk]  := 1                   ' set clk pin to output
  outa[clk]  := 0                   ' Set clk to Low
  dira[cs]   := 1                   ' set Chip Select to output
  outa[cs]   := 1                   ' set Chip Select High


PRI convert( ad_chan ) : datar_val

  if (ad_chan == 0)
    ADC := CH0
  if (ad_chan == 1)
    ADC := CH1

  dira[dataio] := 1                ' Set Din/Dout to output
  outa[dataio] := 0                ' Set Din (output) Low
  
  datar := write(ADC)              ' write MUX Address to start conversion for SDC channel (delay needed???)
  return datar

PRI write( cmd ) : datar_val | i  

  datar := 0                    ' Clear the data storage LONG

  outa[cs] := 0                 ' set Chip Select Low          
  writeByte( cmd )              ' Write the command to start conversion for X port
  dira[dataio] := 0             ' set data pin to input
  delay_us(2)                   ' Clock delay
  
 ' Ok now get the Conversion for this channel  
  repeat i from 12 to 0         ' read 12 bits 11-0 for MSB
    outa[clk] := 1              ' toggle clk pin High
'    delay_us(2)                 ' Clock delay
    if ina[dataio] == 1         
      datar |= |< i             ' set bit i HIGH
    else
      datar &= !|< i            ' set bit i LOW
    outa[clk] := 0              ' toggle clk pin Low
'    delay_us(2)                 ' Clock delay

  outa[cs] := 1                 ' set Chip Select High
            
  return datar

PRI writeByte( cmd ) | i  

  repeat i from 0 to 3          ' LTC1298 has 1 start bit and 3 data bits    
    outa[dataio] := cmd         ' send LSB bit
    outa[clk] := 1              ' toggle clk pin High, Chip reads on rising edge. 
'    delay_us(2)                 ' Clock delay
    outa[clk] := 0              ' toggle clk pin Low
'    delay_us(2)                 ' Clock delay
    cmd >>= 1                   ' shift to next bit

PRI delay_us( period )
' CLK HIGH/LOW time = 2µS MIN
  waitcnt((clkfreq / 100000 * period) + cnt)   ' Wait for designated time

DAT
     {<end of object code>}
     
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
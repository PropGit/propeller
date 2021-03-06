
{
  ColorPALDemo
  
  Version 1.0
  Author: George Collins
          www.backyardrobots.com
          georgeecollins@yahoo.com

  This demo lets you scan a surface with the ColorPAL.
  The ColorPAL will then echo back the color with its own LED
  for five seconds.  See below for more details.  


}


CON
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000


OBJ
  CP     : "ColorPAL"

  
VAR
  long red, green, blue


PUB Main
  CP.Init(8) ' 8 is the Prop pin connected to the ColorPAL signal pin
              ' Change this to match your hardware setup.
                                 
  repeat
  
    red:=CP.GetRed
    red:=red ' Get a number for the amount of Red in the current sample

    green:=CP.GetGreen
    green:=green

    blue:=CP.GetBlue
    blue:=blue

    CP.LEDColor(red/2, green/2, blue/2)  ' divide by 2 to avoid LED saturation
                                          ' The LED is 8 bit, so > 255 = saturation
                                          ' The colorPAL is 10 bit (with 8 bit accuracy)              
                
    waitcnt(cnt+ CLKFREQ* 5)             ' wait 5 seconds
    
     
{
  In order to use this program, hold the ColorPAL against or very close to the
  surface you want to color scan.  The ColorPAL will flicker momentarily and then
  the LED should mimic the color of the scanned surface for five seconds.  

  You can better see differences in the LED color by holding it over a white
  piece of paper.  For example, you can hold the ColorPAL over a surface to scan
  and then after it flickers hold it close to a white piece of paper.

  This program has no calibration.  Adding calibration would improve the accuracy.
  You can also get a more accurate reading by comparing the measured color to a
  previous scan.   
}

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

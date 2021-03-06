{{
***************************************
*    dualPing))) Driver Object V3.2   *
*      (C) 2006 Parallax, Inc.        *
*      (C) 2008 BR                    *
* Author:  Chris Savage & Jeff Martin *
* See end of file for terms of use.   *    
* Started: 05-08-2006                 *
* Updated: 8Nov08, BR                 *
***************************************

Interface to Ping))) sensor and measure its ultrasonic travel time.
Measurements can be in units of time or distance. Each method requires
one parameter, Pin, that is the I/O pin that is connected to the
Ping)))'s signal line.

  ┌───────────────────┐
  │┌───┐         ┌───┐│    Connection To Propeller
  ││ ‣ │ PING))) │ ‣ ││    Remember PING))) Requires
  │└───┘         └───┘│    +5V Power Supply
  │    GND +5V SIG    │
  └─────┬───┬───┬─────┘
        │  │    1K
          └┘   └ Pin

--------------------------REVISION HISTORY--------------------------
 v1.1 - Updated 03/20/2007 to change SIG resistor from 10K to 1K
 V2.0 - Modified to utilize CTRA for time-of-flight measurement (fire&forget)
        Maintains backwards compatibility with original
 V3.0 - Added support for dual simultaneous ping measurements (one per counter)
 V3.1 - Update constants to reflect 1976 standard atmosphere assumptions,
        Add calibration to adjust for ambient temperature impact on speed of sound
 V3.2 - re-implement using SPR+offset to select A vs B ctrs
 
}}

CON

  TO_IN_std = 74_641  ' std atmosphere speed of sound, us per inch traveled @ 59F air temperature
  TO_CM_std = 29_386  ' std atmosphere speed of sound, us per cm traveled @ 59F air temperature
                                                                                 
                                                                                 
PUB calibrate(Tamb)
''Adjust Ping))) calibration constants to reflect ambient 
''temperature impact on speed of sound (temperature assumed to be °F)

  Tamb += 460
  TO_IN := TO_IN_std * (^^(Tamb * 1_000_000)) / (^^518_690_000)
  TO_CM := TO_IN * TO_CM_std / TO_IN_std


PUB selectAB(AorB)
''select which counter to use for Ping))) measurement, A=0 B=1

  AB := AorB <# 1
  AB #>= 0

  
PUB Ticks(Pin) : uS
''Return Ping))) one-way ultrasonic travel time in microseconds
''(cog is paused until measurement cycle is complete)
                                                                                 
  FirePing(Pin)
  waitpne(0, |< Pin, 0)                                                         ' Wait For Pin To Go HIGH
  waitpeq(0, |< Pin, 0)                                                         ' Wait For Pin To Go LOW 
  uS := ReadPing                                                                ' Return Time in µs
  

PUB Inches(Pin) : Distance
''Measure object distance in inches (cog waits for measurement)

  Distance := Ticks(Pin) * 1_000 / TO_IN                                        ' Distance In Inches
                                                                                 
                                                                                 
PUB Tenths(Pin) : Distance
''Measure object distance in tenths of an inch (cog waits for measurement)

  Distance := Ticks(Pin) * 10_000 / TO_IN                                       ' Distance In Tenths
                                                                                 
                                                                                 
PUB Centimeters(Pin) : Distance                                                  
''Measure object distance in centimeters (cog waits for measurement)
                                              
  Distance := Millimeters(Pin) / 10                                             ' Distance In Centimeters
                                                                                 
                                                                                 
PUB Millimeters(Pin) : Distance                                                  
''Measure object distance in millimeters (cog waits for measurement)
                                              
  Distance := Ticks(Pin) * 10_000 / TO_CM                                       ' Distance In Millimeters

  
Pub FirePing(Pin)
''Activate Ping))) and set counter A to measure time of flight
''then return control to calling routine (no cog pause)

  outa[Pin]~                                                                    ' Clear I/O Pin
'                mode        BPIN      APIN                                     ' Set CNTA to "POS detector"
  spr[8+AB]:= %010_00 << 26 + 0 << 9 + Pin                                      ' and set APIN (BPIN is ignored)
  spr[10+AB] := 1                                                               ' FRQA to increment phsa by 1 per clock
  dira[Pin]~~                                                                   ' Make Pin Output
  outa[Pin]~~           'WARNING: this pulse width tested @ 80MHz               ' Set I/O Pin
  outa[Pin]~            'may not work right at other frequencies                ' Clear I/O Pin (> 2 µs pulse)
  dira[Pin]~                                                                    ' Make I/O Pin Input
  spr[12+AB]~                                                                   ' Initialize phsa register and return

  
Pub ReadPing :  uS |temp
''Retrieve one-way echo time measurement (uS) from previous FirePing call
''Returns 0 if counter still running (i.e. msmnt cycle not complete)
''Returns 0 if measurement cycle hasn't started yet

  temp := spr[12+AB]
  uS := temp / (2 * clkfreq / 1_000_000)
  temp := spr[12+AB]
  if uS<>(temp / (2 * clkfreq / 1_000_000))                                     'check if ctra still running
    uS:=0                                                                       'if running, return 0
  else
    spr[12+AB]~                                                                 'else return measurement and
    spr[8+AB]~                                                                  'clear counter
 
  
PUB ReadPingIn : Distance
''Retrieve object distance in inches (assumes FirePing already called)
                                               
  Distance := ReadPing * 1_000 / TO_IN                                         ' Distance In Inches

                                                                                 
PUB ReadPingTenths : Distance
''Retrieve object distance in tenths of an inch (assumes FirePing already called)
                                               
  Distance := ReadPing * 10_000 / TO_IN                                        ' Distance In tenths

                                                                                 
PUB ReadPingCm : Distance                                                  
''Retrieve object distance in centimeters (assumes FirePing already called)
                                              
  Distance := ReadPingMm / 10                                                  ' Distance In Centimeters

                                                                           
PUB ReadPingMm : Distance                                                  
''Retrieve object distance in millimeters (assumes FirePing already called)
                                              
  Distance := ReadPing * 10_000 / TO_CM                                        ' Distance In Millimeters


DAT
'-----------[ Predefined variables and constants ]-----------------------------
 TO_IN         long      74_641                  '
 TO_CM         long      29_386                  '
 AB            long      0

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}  
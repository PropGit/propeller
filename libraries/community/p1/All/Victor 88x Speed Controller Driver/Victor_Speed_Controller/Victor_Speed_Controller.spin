{{
*********************************************************
*      Victor 88x series Speed Controller Object        *
*  Modified by Bryan K., written by Andy Lindsay, 2007  *
*********************************************************

This code, developed by Andy Lindsay (Parallax), was modefied from the
Servos object of the PEKbot to interface to the Victor 88x series speed
controllers from IFI Robotics.  Instead of the pulse period being 20ms,
this object creates pulses with ~25ms periods to drive the signal lines
of the PWM connector. I have recieved really good results with higher clock
speeds (<20MHz)

**Note: the Victor 88x means that this object can be used and was tested for the following
Speed Controllers:
-Victor 883
-Victor 884
-Victor 885
*It also can be used for the Thor Series speed controllers, but I have not tested them with the object.

Hookup and Pinout for the Victor 88x:
W: White/Yellow wire - signal pin (place a 1k resistor in line from the Propeller to the signal pin!)
R: Red wire - This wire is optional, but I used 5 volts to drive the optoisolators on the controller board.
B: Black wire - Connect this wire to ground, and make sure that the same gound is used from the Propeller Chip
               (common ground)

Example Schematic:
                      P8X32A-D40
        Vdd (opt.)     ┌───┬┬────┐          
                      ┤0      31├         
           │     1k    ┤1      30├         
     W─────┼─────────┤2      29├
     R─────┘           ┤3      28├           
     B─────┐           ┤4      27├          
           │           ┤5      26├              
   PWM     │           ┤6      25├        
           │           ┤7      24├         
           ┣───────────┤VSS   VDD├          
           │           ┤BOEn   XO├                             
                      ┤RESn   XI├                
          Gnd.         ┤VDD   VSS├                
                       ┤8      23├                
                       ┤9      22├               
                       ┤10     21├               
                       ┤11     20├            
                       ┤12     19├ 
                       ┤13     18├ 
                       ┤14     17├ 
                       ┤15     16├ 
                       └─────────┘ 


The top level program stores the pulse width information in a variable
(or an array of variables for multiple servos).  This object checks the
variable value (or each array element) and updates the pulse widths
transmitted to each servo every 20 ms.

v1.1 updated 2/27/06

Fixed glitch at 2.5 ms pulses.
Added support for up to 14 servos with 1 cog.
Added comments to servos method
}}

var

  ' Order matters for declarations of sPin, ePin, and address
  ' because of longmove in start method.
  long sPin, ePin, address, pulseCnt  
  long stack[30], cog

pub start(_sPin, _ePin, _address) : okay

  {{ Starts the servos cog.
     _sPin and _ePin are the endpoints of the contiguous group of servos.
     _address is the address of the variable/array that contains the servo
                pulse values.
     Returns t/f for success.
     IMPORTANT: Make sure to set your servo control variable/array in your the
                parent object before starting this the object.
  }}
  
  longmove(@sPin, @_sPin, 3)
  okay := cog := cognew(servos, @stack) + 1
  if okay
    okay := @pulseCnt

pub stop

  '' Stop servos object and free the cog

  if cog
    cogstop(cog~ - 1)

PUB GetPulseCnt

  result := pulseCnt

PUB WaitPulseCnt(target)

  repeat until pulseCnt => target

pri servos | pin, tHi, frame, T, mark, t1us, center

  dira[sPin..ePin]~~                         ' pins -> output

  frqa := frqb := 1                          ' freq increments phs by 1
  phsa := phsb := 0                          ' clear phs -> .bit31 pins low
  ctra[30..26] := ctrb[30..26] := %00100     ' Config counters to NCO

  frame  := clkfreq / 350                    ' Pulse frame to 20/7 ms  270
  t1us   := clkfreq / 1_000_000              ' 1 microsecond
  center := clkfreq / 650                    ' Center pulse = 1.5 ms 667

  T := cnt                                   ' Mark current cnt

  repeat                                     ' Outer loop
    mark := T                                ' Start period at mark
    ' Deliver two pulses at a time every 20/7 ms, up to 14. 
    repeat pin from sPin to ePin step 2      ' Inner loop
      'Get array variable from parent object and caluclate high time.
      tHi := long[address][pin - sPin] * t1us + center
      ctra[8..0] := pin                      ' Tie pin to PHSA.bit31
      phsa := -tHi                           ' Start pulse, ends in tHi clocks
      ' second servo during frame on cog coutner b; same process as counter a.
      if pin < ePin                          
        tHi := long[address][pin + 1 - sPin] * t1us + center
        ctrb[8..0] := pin + 1
        phsb := -tHi
      waitcnt(mark += frame)                 ' Wait until end of pulse frame
    ' Commands below are in outer loop,not inner loop.
    ' Wait until end of 20 ms period (T) before repeating outer loop.
    T += frame * 7
    if ||(sPin - ePin) < 12
      waitcnt(T)
    pulseCnt++ 
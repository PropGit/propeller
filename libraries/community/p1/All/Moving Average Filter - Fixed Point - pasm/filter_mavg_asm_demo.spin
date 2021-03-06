{{ filter_mavg_asm_demo.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ Moving Average Filter Demo (asm)    │ BR             │ (C)2009             │  10 Nov 2009  │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│                                                                                            │
│ Demo of a moving average filter.                                                           │
│                                                                                            │
│ Demo calculates filter frequency response via direct simulation with the help of the       │
│ prop's built-in math tables and a handy sin function courtesy of Ariba.  It also simulates │
│ filter impulse response and step response.                                                 │
│                                                                                            │
│ Debug setup to use PLX-DAQ (enables easy plot of raw data vs filtered output).  Works      │
│ fine with Parallax serial terminal, too...just not as easy to plot the data.               │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}
'I disdain emoticons as a rule; but I noticed that the Parallax font lends itself to a whole
'menagerie of the pesky buggers, viz:          
'        I dub thee:                           
' :)    comb-over                             
' :)    alfalfa                               
' :)    butch                                 
' :)    beanie                                
' √:)    sqrt                                  
' :∞)    burt                                  
' :◀)    ernie                                 
'[:)    top hat                               
' ±∞)    1-2-many                              
' :)    curly                                 
' (:Þ    nelson                                
' etc.                                         


CON
  _clkmode        = xtal1 + pll16x    ' System clock → 80 MHz
  _xinfreq        = 5_000_000

  
var
   long in,out                   'filter output must be located adjacent to input


OBJ   
  debug: "SerialMirror"           'Same as fullDuplexSerial, but can also call in subroutines
  filter: "filter_mavg_asm"       'Moving average filter object

  
PUB Init

  waitcnt(clkfreq * 5 + cnt)
  Debug.start(31, 30, 0, 57600)
  Debug.Str(String("MSG,Initializing...",13))
  Debug.Str(String("LABEL,x_meas,x_filt",13))
  Debug.Str(String("CLEARDATA",13))

  filter.start(@in,21)           
  
  main

Pub Main| iter, mark, xmeas, xfilt, value, sig_filt, random

'======================================================
'Filter response to sinusoidal inputs (poor man's Bode)
'======================================================
mark := random := cnt
repeat  iter from 1 to 40 step 2                 'simulate 20 frequencies, highest frequency is nearly Nyquist freq
  repeat value from 0 to 359 step 4              'take 90 samples per frequency
'   mark += clkfreq/32                           'output data at 32 samples/sec
    Debug.Str(String("DATA, "))                  'data header for PLX-DAQ
    xmeas := sin(value*iter,200)                 'thanks Ariba
'   xmeas += iter * random? >> 28                'add some noise to the measurements
    in := xmeas
    xfilt := out                                     
                                                     
    Debug.Dec(xmeas)                                 
    Debug.Str(String(", "))                          
    Debug.Dec(xfilt)                                 
    Debug.Str(String(13))                            
'   waitcnt(mark)                                    
                                                     
'=================================                   
'Filter impulse and step responses                   
'=================================                   
mark := random := cnt                                
repeat  iter from 1 to 150                           
'   mark += clkfreq/32                               
    Debug.Str(String("DATA, "))                      
    if iter < 50                                     
      xmeas := 1                                      'let the filter chill for a moment....
    elseif iter < 100
      xmeas := 1+ impulse_function(iter, 51, 200)     'input impulse function
    else
      xmeas := step_function(iter,101,200)            'input step function

    in := xmeas
    xfilt := out
'
    Debug.Dec(xmeas)
    Debug.Str(String(", "))
    Debug.Dec(xfilt)
    Debug.Str(String(13))
'   waitcnt(mark)                                


PUB sin(degree, mag) : s | c,z,angle
''Returns scaled sine of an angle: rtn = mag * sin(degree)
'Function courtesy of forum member Ariba
'http://forums.parallax.com/forums/default.aspx?f=25&m=268690

  angle //= 360
  angle := (degree*91)~>2 ' *22.75
  c := angle & $800
  z := angle & $1000
  if c
    angle := -angle
  angle |= $E000>>1
  angle <<= 1
  s := word[angle]
  if z
    s := -s
  return (s*mag)~>16       ' return sin = -range..+range


pub cos(degree, mag) : s
''Returns scaled cosine of an angle: rtn = mag * cos(degree)

  return sin(degree+90,mag)

  
pub impulse_function(i,trigger,mag):x_rtn
''Returns impulse function. i = current sample index
''                          trigger = sample index on which impulse is triggered
''                          mag = magnitude of impulse
    if i==trigger
      return mag
    else
      return 0


pub step_function(i,trigger,mag):x_rtn
''Returns step function. i = current sample index
''                       trigger = sample index on which step is triggered
''                       mag = magnitude of impulse
    if i < trigger
      return 0
    else
      return mag

      
'' =================================================================================================
''   Application: DMX_Dimmer24 10_8_21013
''   This was derived from File....... jm_dmx_monitor.spin
''   Purpose.... Simple program to monitor DMX channel values
''   Programmer - Rick G. Asche (Aging Beaver)
''   Author..... Jon "JonnyMac" McPhalen (aka Jon Williams)
''               Copyright (c) 2009 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 15 SEP 2009
''   Updated.... 21 JUL 2010
''   tested ......09 Oct 2013
'    expanded to 24 channels - Dec 8 2011     borrowed output from dta box 3 scheme
''   increased stacks to 75
''   12/18/11 deleted the longer output cog and shortened up program . Make the index on
''            output array 1 based. 
''       
''    12/19/12  Switch to phase modulation delay   and use the Channel Driver from DynmoBean
''              this uses a countdown loop after the Zero crossing detector starts.  It compares the countdown
''               value with the channel intensity.  If channel intensity is greater, that output turns on for rest
''               of the AC half wave cycle.
''     8/14/2013  more work on unit.             all outputs coming on full intensity?
''     10/08/13  replace dimmer module with new 24 channels base from Jon MacPhalen. 
''     10/09/13  solved the channel 1/2 writeover problem by rearranging the variable into long, word
''               byte order.  Put back to full speed interface. Clean up unused variables.
''               Remove terminal method calls - clean up documentation.  Flash EProm
''
''               Dimers are triac based - any 4-6A triac uill do, Use a MOC3023 for the gate trigger
''               180 ohm resiter in gate.  I use ULN2803s as a buffer between the Prop. Output
''               and the Optocoupler Output pin. This reduces the current being delivered by the
''               Quickstart or development board traces. 
'' ================================================================================================

con

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  
 'this code is to set ttype of dimmer used.  Not used in this version.    
 ' #1, HOME, #8, BKSP, TAB, LF, CLREOL, CLRDN, CR, #16, CLS      ' PST formmatting control
  
  
  'DMX_START = 1                  'monitor channels 50
  'DMX_END   = 40                'to 80 on terminal
  'NC1_4        = 2        ' set this to 0 fo NO, 1 for NC relays or 2 for dimable channel relays
  'NC5_8        = 2        ' set this to 0 fo NO, 1 for NC relays or 2 for dimable channel relays
  'NC9_12       = 2        ' set this to 0 fo NO, 1 for NC relays or 2 for dimable channel relays
  'NC13_16      = 2        ' set this to 0 fo NO, 1 for NC relays or 2 for dimable channel relays
  'NC17_20      = 2        ' set this to 0 fo NO, 1 for NC relays or 2 for dimable channel relays
  'NC21_24      = 2        ' set this to 0 fo NO, 1 for NC relays or 2 for dimable channel relays          

  UNIT_ADDR    = 1        'sets the first address of DMX channels
  nbr_chans    = 24       'total sequential number of channels on this controller
   
  'period  = 8333          'period of cycle in micro seconds (1/2 60hz)

   ' Dimmer Constants
  NumOfDimmers  = 224        '224 ' Number of Dimmers (NOTE: multiples of 32 only!)   
                             'this is the number DMX values to read to the buffer
                              'this could be as high as 512, but only test upto 256
  DMXrx         = 0              '24            ' DMX receive
  DMXrxLED      = 27            ' 22 DMX receive LED (GREEN)

  
 'for the dimmer pak. 
  CHANNELS = 24                   'physical channels are at Pin1 to 24 (24 channels)
    
  LAST_CH  = CHANNELS              
  zerocrosspin       = 26
  firstchanpin      = 1
  
Var
   
   ' from the dimmer pak code 
  long  cog                             ' cog running driver
  long  zcpin
  long  ch0pin                          ' io pins for AC
  long  brpntr                          ' pointer to brightness array
  long  hcpntr                          ' pointer to hctix

  long  hctix                          'cnt ticks in half cycle
  long dummy                           'just a place holder in memory to isolate
  long  IntsBffr[NumOfDimmers+1]       'byte array with current intensity values
                                       ' of the channels
  long  DMXptr                         ' DMX buffer pointer
  word  StartAddr                      ' DMX start Address                                                                                                               
  byte  brightness[25]               ' dimmer levels array, 0 to 255         
   
obj

  
  dmx   : "jm_dmxin"
  
' -------------------------code from propconntroller site ------------------------------------------

PUB Main | idx1, ch0val,    chan,indx, ok3  ,y ,j  ,firstpin

  StartAddr := 1                    ' DMX Start Address goes here

    
  ' Setup DMX input source for dimmer data
  dmx.init(DMXrx, DMXrxLED, 0, 0)     'starts the DMX serial port  
  DMXptr := dmx.address               '(dmx_in_pin,act_led_pin,start_byte,intial level)  
            
        firstpin := firstchanpin

        start (firstpin)          'pin 1 and 26
                                                
        bytefill(@Brightness,0,Channels)   'clear the brightness array  
        
        bytefill(@IntsBffr, 0, NumOfDimmers+1)     'Zero intensity buffer to
                                                   'stop lights from going to
                                                   'full at start 

      'intsBFFR is the DMX values received buffer
      'Brightness is the output channel intensity values
      
       'this is the loop that continuously updates the intensity data received
       'in the DMX buffer and loads it to the dimmer buffer                  
   repeat 
      
      j := 0                              'clear the index    
       repeat indx from 1 to 128          'this is the program loop that
         IntsBffr[indx] := dmx.read(indx) 'continuously fills the inputbuffer
          
         if indx => UNIT_ADDR                        'greater or equal

            if indx =< UNIT_ADDR + channels - 1        'less than
                
               brightness[j] := IntsBffr[indx] 'move the value from the DMX
                                              ' buffer to the output chan array               
                j:= j + 1                     'incr the brightness cells index
            else
                j:= 0                               'reset to out of band 
         else
             j := 0                       'clear the index to brightness array

  ' end of main loop
      '' ======================================================================
''   File .......RGA_24Chan_Dimmer_Pak_VerA
''   based on  . the Four Channel dimmer - jm_ac_dimmer.spin
''   Purpose.... AC dimming using phase-angle modulation from zero-cross
''   Author .... Rick Asche
''   Suggested by Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2012 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... rasche@opusnet.com
''               jon@jonmcphalen.com
''   Started....  
''   Updated.... orig by McPhalen - 30 MAR 2012
''               Orig by Asche - Oct 8, 2013
''  date         comment
''               all 24 channels are now working for dimmers. in two cogs 
''  10/8/13G     remove some of the fluff (extra demo routines that aren't used
''               this simple demo walks thru all 24 channels for testing
''               Take out the Main routine and include this as obj in a DMX
''               receiver program
''               to make a full featured 24Channel DMX controller.    
'' ============================================================================
{{

  This code relies on an active-high zero-cross input.  Line frequence is
  determined from this signal, allowing the code to work in 50Hz and 60Hz
  systems without any modifications.

  Phase delay is done by adding $FFFFFF00 to level value and then adding 1.
  If the carry flag sets, the channel turns on (255 +1) = carry.
  This repeats for each channel and the 256 increments in a half cycle. 

  Typical ZC detetion circuit (tested with this code)

  ────┳────────────────────────────── AC Hot
  ────┼─┳──────────────────────────── AC Neutral
       │ │               5v
       │ │               
       │ │               │
         15K, 1/2W      10K
       │ │               │
       │ │  ┌────────┐   │
       │ └──┤A/C    B├   │
       └────┤C/A    C├───┻──────── Zero Cross      Pin 26
            ┤NC     E├───┐
            └────────┘   │
              H11AA1     


    Outputs to channels start at Pin 1 thru Pin 24.
    SSR's arc triac based and use ULN2803 drivers.  A High on the output turns
    the channel ON.

 If you don't have a H11AA1, You can use a bridge rectifier in front of the
 Opto Coupler and use a standard optocoupler such as a 4N25 or 4N32 or similar.
 RGA
    
}}

     
pub start(ch0)   | zc

'' Start 4-channel AC dimmer
'' -- user responsible for correct pin assignments
''    * no error checking!
'' -- assumes ch0..ch23 are contiguous and in ascending order
                                                          
    return startx(ch0) 


pub startx(ch0) | ok ,ok2
'' Start 4-channel AC dimmer
'' -- user responsible for correct pin assignments
''    * no error checking!

  stop                                           ' stop if running now

  'longmove(@ch0pin, @ch0,1)                     ' copy pins
  brpntr := @brightness                          ' point to levels array
  hcpntr := @hctix                               ' point to half-cycle ticks value
  
  ok := cog := cognew(@dimmer, @ch0pin) + 1       ' start the dimmer cog
  ok2 := cognew(@dimmer2,@ch0pin) + 1             'start dimmer 2 cog
  return ok

  
pub stop

'' Stops AC dimmer; frees a cog

  set_all(0)                                              ' all off

  if (cog)                                                ' if running
    cogstop(cog - 1)                                      ' stop
    cog := 0                                              ' mark stopped
  

pub set(ch, level)

'' Sets channel to specified level

  if ((ch => 0) and (ch =< LAST_CH))                   ' valid channel?
    brightness[ch] := 0 #> level <# 255                ' limit to byte value 

  return brightness[ch]                                ' return actual ch level
    

pub set_all(level)

'' Set all channels to same level

  level := 0 #> level <# 255                                    
  bytefill(@brightness[0], level, CHANNELS)

  return level


pub high(ch)                              ' keep for testing purpose only

'' Sets channel to on

  if ((ch => 0) and (ch =< LAST_CH))
    brightness[ch] := 255


pub address

'' Returns hub address of brightness array

  return @brightness


pub hc_ticks

'' Returns cnt ticks in 1/2-cycle of AC

  return hctix

dat

                        org     0

dimmer                  xor    outa,outa           'clear output
                        mov     t1, par            ' start of structure
                        
                        OR     dira, OutMask12     'Output mask  
                       
                        mov     zcmask, #1
                        shl     zcmask,#26  
                       
                        andn    dira, zcmask       ' make input   

                        add     t1, #4
                        rdlong  hubch0, t1         ' read hub addr of levels array

                        add     t1, #4
                        rdlong  hubhc, t1           ' read hub addr of hctix                     


' This code debounces the ZC input to prevent noise from
' fouling the frequency detection
                        
waitlo1                 mov     t1, #10                   ' wait for ZC low
:loop                   test    zcmask, ina     wc
        if_c            jmp     #waitlo1
                        djnz    t1, #:loop

waithi1                 mov     t1, #10          ' wait for leading edge of ZC
:loop                   test    zcmask, ina     wc
        if_nc           jmp     #waithi1
                        djnz    t1, #:loop

                        neg     period, cnt          ' start period measurement

waitlo2                 mov     t1, #10            ' wait for falling edge of ZC
:loop                   test    zcmask, ina      wc
        if_c            jmp     #waitlo2
                        djnz    t1, #:loop

waithi2                 mov     t1, #10             ' wait for 2nd leading edge
:loop                   test    zcmask, ina     wc
        if_nc           jmp     #waithi2
                        djnz    t1, #:loop

                        add     period, cnt        ' stop timing
                        sub     period, #4         ' remove overhead

                        wrlong  period, hubhc      ' save to hub        
                        shr     period, #8         ' divide into 256 segments
        
waitzc0                 mov     t1, #10            ' wait for ZC low
:loop                   test    zcmask, ina     wc
        if_c            jmp     #waitzc0
                        djnz    t1, #:loop

waitzc1                 mov     t1, #10           ' wait for leading edge of ZC
:loop                   test    zcmask, ina     wc
        if_nc           jmp     #waitzc1
                        djnz    t1, #:loop

                        mov     outa, #0           ' outputs off  
                        mov     timer, period      ' start levels timer
                        add     timer, cnt

getlevels               mov     t1, hubch0         ' point to levels (in hub)

                        add     t1,#0               'add bytes to skip over channels
                        rdbyte  ch0level, t1        ' read channel
                        add     ch0level, HxFFFF_FF00   'adjust to use C flag

                        add     t1, #1                  'point to next level
                        rdbyte  ch1level, t1
                        add     ch1level, HxFFFF_FF00

                        add     t1, #1
                        rdbyte  ch2level, t1
                        add     ch2level, HxFFFF_FF00

                        add     t1, #1
                        rdbyte  ch3level, t1
                        add     ch3level, HxFFFF_FF00
                                                     
                        add     t1, #1                  'increment pntr
                        rdbyte  ch4level, t1
                        add     ch4level, HxFFFF_FF00
                        
                        add     t1, #1
                        rdbyte  ch5level, t1
                        add     ch5level, HxFFFF_FF00

                        add     t1, #1
                        rdbyte  ch6level, t1
                        add     ch6level, HxFFFF_FF00

                        add     t1, #1                  'channel 8
                        rdbyte  ch7level, t1
                        add     ch7level, HxFFFF_FF00

                                              
                        add     t1,#1                
                        rdbyte  ch8level, t1         ' read channel
                        add     ch8level, HxFFFF_FF00  ' adjust to use C flag

                        add     t1, #1                ' point to next level
                        rdbyte  ch9level, t1
                        add     ch9level, HxFFFF_FF00

                        add     t1, #1
                        rdbyte  ch10level, t1
                        add     ch10level, HxFFFF_FF00

                        add     t1, #1
                        rdbyte  ch11level, t1
                        add     ch11level, HxFFFF_FF00
                                                      
                        mov     idx, #255

dimloop                 add     ch0level, #1    wc      ' inc ch level
        if_c            or      outa, #$02       'Pin 1  if carry, turn on

                        add     ch1level, #1    wc
        if_c            or      outa, #$04           'Pin 2         

                        add     ch2level, #1    wc
        if_c            or      outa, #$08           'Pin 3   

                        add     ch3level, #1    wc
        if_c            or      outa, #$10           'Pin 4
                              
                        add     ch4level, #1    wc
        if_c            or      outa, #$20           'Pin 5
        
                        add     ch5level, #1    wc
        if_c            or      outa, #$40           'pin6

                        add     ch6level, #1    wc
        if_c            or      outa, #$80           'pin 7
         
                        add     ch7level, #1    wc
        if_c            or      outa, #$0100         'pin 8

                        add     ch8level, #1    wc      
        if_c            or      outa, Hex200         'Pin 9

                        add     ch9level, #1    wc
        if_c            or      outa, Hex400         'Pin 10      

                        add     ch10level, #1   wc
        if_c            or      outa, Hex800         'pin 11   

                        add     ch11level, #1   wc
        if_c            or      outa, Hex1000         'pin 12
    
        
                        waitcnt timer, period    ' let this period finish
                        djnz    idx, #dimloop
                        
                        jmp     #waitzc1          ' next cycle
'------------------------------------------------------------------------------

                        
' -----------------------------------------------------------------------------

HxFFFF_FF00       long    $FFFF_FF00                      
OutMask12         long  $0000_1FFE    '%0000_0000_0000_0000 _0001 1111_1111 1110                       

Hex200            long  $0000_0200           'constants  pin masks
Hex400            long  $0000_0400
Hex800            long  $0000_0800           
Hex1000           long  $0000_1000            'pin 11
Hex2000           long  $0000_2000            'pin 12 


ch0mask           res     1                   ' pin mask for channel 0 
                  
zcmask            res     1                  ' pin mask for zero cross
hubch0            res     1                  ' hub address of brightness array
hubhc             res     1                   ' hub address of hctix

period            res     1                  ' 1/256th of half-cycle
timer             res     1                  ' for period timing
                         'channel levels
ch0level          res     1                  ' channel levels
ch1level          res     1
ch2level          res     1
ch3level          res     1
ch4level          res     1                   ' channel levels
ch5level          res     1
ch6level          res     1
ch7level          res     1
ch8level          res     1                   ' channel levels
ch9level          res     1
ch10level         res     1
ch11level         res     1
                              ' channel levels

idx               res     1
t1                res     1
t2                res     1

                  fit     496                       'fit within Cog memory                     

'this is code to create a second dimmer cog.  for channels 13 - 24                        
dat
                        org     0

dimmer2            ' xor    outa,outa              'clear output
                        mov     t5, par            ' start of structure
                        
                        OR     dira, OutMask24     'Output mask  
                       
                        mov     zcmask2, #1
                        shl     zcmask2,#26  
                       
                        andn    dira, zcmask2       ' make input   

                        add     t5, #4
                        rdlong  hub2ch0, t5          ' read hub addr of levels array

                        add     t5, #4
                        rdlong  hub2hc, t5            ' read hub addr of hctix  

  ' This code debounces the ZC input to prevent noise from
' fouling the frequency detection
                        
waitlo12                 mov     t5, #10            ' wait for ZC low
:loop                   test    zcmask2, ina     wc
        if_c            jmp     #waitlo12
                        djnz    t5, #:loop

waithi12                 mov     t5, #10           'wait for leading edge of ZC
:loop                   test    zcmask2, ina     wc
        if_nc           jmp     #waithi12
                        djnz    t5, #:loop

                        neg     period2, cnt        ' start period measurement

waitlo22                 mov     t5, #10            'wait for falling edge of ZC
:loop                   test    zcmask2, ina     wc
        if_c            jmp     #waitlo22
                        djnz    t5, #:loop

waithi22                 mov     t5, #10             'wait for 2nd leading edge
:loop                   test    zcmask2, ina     wc
        if_nc           jmp     #waithi22
                        djnz    t5, #:loop

                        add     period2, cnt             ' stop timing
                        sub     period2, #4              ' remove overhead

                        wrlong  period2, hub2hc          ' save to hub        
                        shr     period2, #8              ' divide into 256 segments
        
waitzc02                 mov     t5, #10                  ' wait for ZC low
:loop                   test    zcmask2, ina     wc
        if_c            jmp     #waitzc02
                        djnz    t5, #:loop

waitzc12                 mov     t5, #10              ' wait for leading edge of ZC
:loop                   test    zcmask2, ina     wc
        if_nc           jmp     #waitzc12
                        djnz    t5, #:loop

                        mov     outa, #0                ' outputs off  
                        mov     timer2, period2         ' start levels timer
                        add     timer2, cnt

getlevels2              mov     t5, hub2ch0            ' point to levels (in hub)

                        add     t5,#12               'add 12 bytes to skip over
                                                     ' 12 channels
                        rdbyte  ch12level, t5           ' read channel
                        add     ch12level, HzFFFF_FF00  ' adjust to use C flag

                        add     t5, #1                  ' point to next level
                        rdbyte  ch13level, t5
                        add     ch13level, HzFFFF_FF00

                        add     t5, #1
                        rdbyte  ch14level, t5
                        add     ch14level, HzFFFF_FF00

                        add     t5, #1
                        rdbyte  ch15level, t5
                        add     ch15level, HzFFFF_FF00
                                                  'added code for channels >4
                        add     t5, #1               'increment pntr
                        rdbyte  ch16level, t5
                        add     ch16level, HzFFFF_FF00
                        
                        add     t5, #1
                        rdbyte  ch17level, t5
                        add     ch17level, HzFFFF_FF00

                        add     t5, #1
                        rdbyte  ch18level, t5
                        add     ch18level, HzFFFF_FF00

                        add     t5, #1                   'channel 8
                        rdbyte  ch19level, t5
                        add     ch19level, HzFFFF_FF00

                                              
                        add     t5,#1                 'add 1 long for test
                        rdbyte  ch20level, t5          ' read channel
                        add     ch20level, HzFFFF_FF00 'adjust to use C flag

                        add     t5, #1                  'point to next level
                        rdbyte  ch21level, t5
                        add     ch21level, HzFFFF_FF00

                        add     t5, #1
                        rdbyte  ch22level, t5
                        add     ch22level, HzFFFF_FF00

                        add     t5, #1
                        rdbyte  ch23level, t5
                        add     ch23level, HzFFFF_FF00
                                                     'add code for channels >4
                        mov     idx2, #255

dimloop2                add     ch12level, #1    wc      ' inc ch level
        if_c            or      outa, Hex2K           'pin 13 if carry, turn on

                        add     ch13level, #1    wc
        if_c            or      outa, Hex4K           'Pin 14       

                        add     ch14level, #1    wc
        if_c            or      outa, Hex8K           'Pin 15  

                        add     ch15level, #1    wc
        if_c            or      outa, Hex10K          'pin16
                      
                        add     ch16level, #1    wc
        if_c            or      outa, Hex20K          'pin17
        
                        add     ch17level, #1    wc
        if_c            or      outa, Hex40K           'pin18

                        add     ch18level, #1    wc
        if_c            or      outa, Hex80K            'pin 19
         
                        add     ch19level, #1    wc
        if_c            or      outa, Hex100K            'pin 20

                        add     ch20level, #1    wc      ' inc ch level
        if_c            or      outa, Hex200K            'Pin 21  

                        add     ch21level, #1    wc
        if_c            or      outa, Hex400K            'Pin 22      

                        add     ch22level, #1    wc
        if_c            or      outa, Hex800K            'pin 23   

                        add     ch23level, #1    wc
        if_c            or      outa, Hex1M              'pin 24
    
        
                        waitcnt timer2, period2    ' let this period finish
                        djnz    idx2, #dimloop2
                        
                        jmp     #waitzc12            ' next cycle
'------------------------------------------------------------------------------

                        
' -----------------------------------------------------------------------------

HzFFFF_FF00       long  $FFFF_FF00                      
OutMask24         long  $01FF_E000    '%0000_0001_1111_1111_1110_0000_0000_0000           

Hex2K             long  $0000_2000
Hex4K             long  $0000_4000
Hex8K             long  $0000_8000
Hex10K            long  $0001_0000
Hex20K            long  $0002_0000
Hex40K            long  $0004_0000
Hex80K            long  $0008_0000
Hex100K           long  $0010_0000
Hex200K           long  $0020_0000
Hex400K           long  $0040_0000
Hex800K           long  $0080_0000
Hex1M             long  $0100_0000
       
'ch0mask                 res     1            ' pin mask for channel 0 

zcmask2           res     1                        ' pin mask for zero cross
hub2ch0           res     1                        ' hub address of brightness array
hub2hc            res     1                        ' hub address of hctix
                                                
period2           res     1                        ' 1/256th of half-cycle
timer2            res     1                        ' for period timing

ch12level         res     1                        ' channel levels
ch13level         res     1
ch14level         res     1
ch15level         res     1
ch16level         res     1                       
ch17level         res     1
ch18level         res     1
ch19level         res     1
ch20level         res     1                     
ch21level         res     1
ch22level         res     1
ch23level         res     1
                              ' channel levels
idx2              res     1
t5                res     1

                  fit     496             'fit within COG memory                     

{{

  MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}  
             
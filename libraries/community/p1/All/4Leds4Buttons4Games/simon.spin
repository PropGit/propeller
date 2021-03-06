{{
This is the famous Simon memnory game

See the circuit in readme.spin
                    
  When the game starts, the 4 buttons will flash for 1 second, telling the player that the game started.
  When the player fails to follow the sequence, the LEDs will sweeping left and right, then they will light a
  binary number, for 5 seconds, that shows the player how many sequences they got correct. Then the lights flash
  again for 1 second and a new game starts.

}}
CON
  _xinfreq = 5_000_000
  _clkmode = xtal1 + pll16x 

OBJ

  dbg:    "debug_off" ' use debug to display msgs to serial terminal, debug off to stop msgs
  leds4:  "4LEDS"
  sw:     "4Switches"
  func:    "FunLib"

VAR
  byte sqnce[50]
  byte seqCount
  
pub main  | i, missed
init
repeat
  leds4.config(20,15)
  leds4.flash 
  seqCount := 0
   repeat
     sqnce[seqCount] := func.getRandomSeq(0,3) ' get random number between 0 and 3 and add it to the sequence
     playSequence
     missed := 0
     repeat i from 0 to seqCount
       if getInput <> sqnce[i]
          missed := 1
          quit
       
     if missed == 1
        quit
       
    seqCount++

   leds4.config(15,5)         
   leds4.side2side  ' end of game
   leds4.show(seqCount)
   waitcnt(clkfreq * 5 + cnt)

pri init
   dbg.init
   sw.pins(20,23)
   leds4.pins(7,4)
   seqCount  :=0
  
pri getInput : retVal | inval
   sw.wait
   retVal := sw.location
  
   leds4.show( 1 << retVal) 
   waitcnt(clkfreq /3 + cnt)
   leds4.off 
   dbg.print( string("input: "), retVal)  

pri playSequence | i
  leds4.off
  waitcnt(clkfreq /5 + cnt)
  dbg.print (string("seqCount:"), seqCount)
  repeat i from 0 to seqCount
     dbg.print2(string("play seq - i: "),i,string("sqnce: "),sqnce[i]) 

     leds4.show( 1 << sqnce[i] )
     waitcnt(clkfreq /2 + cnt)

 leds4.off
    
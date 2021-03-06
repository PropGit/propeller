{{Program       mcp41HV51_poc_
Date            20Apr19       
Purpose         Proof of Concept (poc) program to control high voltage digital pot
Developed from mcp41xxx, mcp4xxx_simple. Makes use of parallax SPI_Spin
Rev0;20Apr19;   Proof of concept. Success! Scematic, write up and screen shots in
folder 1904 Digital Pots and 1904 Digital Pots PropProgDev Log 
}}

CON
'Timing
    _clkmode = xtal1 + pll16x                           
    _xinfreq = 5_000_000
'MCP41HV51 commands
  CMD_READ      = %0000_0000    
  CMD_DECR      = %0000_1000
  CMD_INCR      = %0000_0100
'SPI operations from SPI_Spin  
    #0,MSBPRE,LSBPRE,MSBPOST,LSBPOST                    '' Used for SHIFTIN routines
''                           
''       =0      =1     =2      =3
''
'' MSBPRE   - Most Significant Bit first ; data is valid before the clock
'' LSBPRE   - Least Significant Bit first ; data is valid before the clock
'' MSBPOST  - Most Significant Bit first ; data is valid after the clock
'' LSBPOST  - Least Significant Bit first ; data is valid after the clock
'
    #4,LSBFIRST,MSBFIRST                                '' Used for SHIFTOUT routines
''              
''       =4      =5
''
'' LSBFIRST - Least Significant Bit first ; data is valid after the clock
'' MSBFIRST - Most Significant Bit first ; data is valid after the clock

VAR
'Dig Pot and SPI_Spin variables
  byte CS        ' Chip Select, no pull-up
  byte SCK       ' Serial Clock 
  byte SI        ' Serial Data Input 
  long ClockDelay,ClockState,_ClockDelay   'SPI_Spin variables
'Dig Pot variables
  word Cmd16Bit    'For 2 byte, 16 bit commands
  byte Cmd8Bit     'For 2 byte, 16 bit commands 
  byte potvalue
  
OBJ
  PST     :       "Parallax Serial Terminal" 
  
PUB Main | cntr, A_Char
'For poc include the demo statements in main program
'Start PST, wait 2 sec, any key to resume
  PST.Start (115_200)
  PST.Clear
  PST.Home
  waitcnt (clkfreq*2 + cnt)
  PST.str(string("press any key to resume. . . "))
  A_Char := PST.CharIn 
'initialize the pot and serial paramters
  init(4, 5, 3)
'Use mode 0,0 datasheet Pg 46. SCK idle state = low
'For Prop Shiftout, data is clocked in to the digpot SDI on rising edge of clock    
  Clockstate := 0
'Clock high and low times. Datasheet Pg 17. For Vl=3.3, 35nS, raising t0 120nS for Vl=2.7
'So use _ClockDelay of 140nS
  _ClockDelay := 140  
  ClockDelay := ((clkfreq / 100000 *_ClockDelay) - 4296) #> 381 
'Next prove all the functions with debug displays on PST
  potvalue := 0
  PST.Newline
  PST.str(string("potvalue-"))
  PST.Dec(potvalue)
  PST.str(string("   "))
  setpot (potvalue)
  waitcnt (clkfreq*5 + cnt)
  potvalue := 255
  PST.Newline
  PST.str(string("potvalue-"))
  PST.Dec(potvalue)
  PST.str(string("   "))
  setpot (potvalue)
  waitcnt (clkfreq*5 + cnt)
  potvalue := 127
  PST.Newline
  PST.str(string("potvalue-"))
  PST.Dec(potvalue)
  PST.str(string("   "))
  setpot (potvalue)
  waitcnt (clkfreq*5 + cnt)
  repeat cntr from 0 to 127
    PST.Newline
    PST.str(string("Incr  "))
    PotIncr
    waitcnt (clkfreq + cnt)
  repeat cntr from 0 to 127
    PST.Newline
    PST.str(string("Decr  "))
    PotDecr
    waitcnt (clkfreq + cnt)         
  repeat  potvalue from 0 to 255
    PST.Newline
    PST.str(string("potvalue-"))
    PST.Dec(potvalue)
    PST.str(string("   "))
    setpot (potvalue)
    waitcnt (clkfreq + cnt)   

PUB init(_CS, _SCK, _SI)
'' Initialise this module, set the pins for CS, SCK and SI
  CS := _CS
  SCK := _SCK
  SI := _SI
'now set all SCI pin to prop outputs  
  dira[CS]~~
  dira[SCK]~~
  dira[SI]~~
  outa[CS] := 1   'set CS high until data shiftout

PUB PotIncr
'This is only an 8 bit command
  Cmd8bit := CMD_INCR 
  PST.Bin(Cmd8Bit,8)
  PST.str(String("   "))
'SHIFTOUT (DataPin, ClkPin, Mode=5 for MSBFIRST, bits, value)   
  SHIFTOUT (3,5,5,8,Cmd8bit)

PUB PotDecr
'This is only an 8 bit command
  Cmd8bit := CMD_DECR 
  PST.Bin(Cmd8Bit,8)
  PST.str(String("   "))
'SHIFTOUT (DataPin, ClkPin, Mode=5 for MSBFIRST, bits, value)   
  SHIFTOUT (3,5,5,8,Cmd8bit)       
    
PUB setpot (databyte)
'This is a word, 16 bit, 2 byte command
'It must be shifted out MSB byte first, i.e. for pot value 255
'MSB-CMD_READ | LSB-pot value
'MSB-0000000 | LSB-11111111 
  Cmd16bit.byte[1] := CMD_READ   'MSB, shifted out first
  Cmd16bit.byte[0] := databyte   'LSB, shifted out last
  PST.Bin(Cmd16Bit,16)
  PST.str(String("   "))
'SHIFTOUT (DataPin, ClkPin, Mode=5 for MSBFIRST, bits, value)   
  SHIFTOUT (3,5,5,16,Cmd16bit)  

PUB SHIFTOUT(Dpin, Cpin, Mode, Bits, Value) | OutaDpin
'This is taken from Parallax object SPI_Spin
    dira[Dpin]~~                                         ' make Data pin output
'Use mode 0,0 datasheet Pg 46.
'For Prop Shiftout, data is clocked in to the digpot SDI on rising edge of clock     
    dira[Cpin]~~
    outa[Cpin] := ClockState  ' set initial clock state 0
    outa[CS] := 0    'Drop the CS pin
'Mode LSBFIRST
    if Mode == 4                
       Value <-= 1                                       ' pre-align lsb
       repeat Bits
         outa[Dpin] := (Value ->= 1) & 1                 ' output data bit                      
         PostClock(Cpin)         
'Mode MSBFIRST
    if Mode == 5                
       Value <<= (32 - Bits)                             ' pre-align msb
       repeat Bits
          OutaDpin  := (Value <-= 1) & 1
          outa[Dpin] := OutaDpin                 ' output data bit
         PostClock(Cpin)
         PST.Bin (OutaDpin, 1)
    outa[CS] := 1
             
PUB PostClock(_Cpin)
'Cpin value clock state = 0 entering here
    waitcnt(cnt+ClockDelay)
    !outa[_Cpin]  'Cpin = 1, data is clocked into DigPot on rising edge
    waitcnt(cnt+ClockDelay)
    !outa[_Cpin]   'Cpin = 0

PUB PreClock(_Cpin)
    !outa[_Cpin]
    waitcnt(cnt+ClockDelay)
    !outa[_Cpin]
    waitcnt(cnt+ClockDelay)



PRI write(Bits,Data) | temp                             ' Send DATA MSB first
'Use mode 0,0 datasheet Pg 46. SCK must be 0 when CS dropped to 0
  outa[SCK] := 0
  outa[CS] := 0                                         ' 
  temp := 1 << ( Bits - 1 )
  repeat Bits
    outa[SI] := (Data & temp)/temp   ' Set bit value
    outa[SCK] := 1   ' Set Clock bit high to read bit value
    outa[SCK] := 0   ' Clock bit
    temp := temp / 2
    outa[SI] := 0
  outa[CS] := 1        'finished input to mcp41  set CS to 1      
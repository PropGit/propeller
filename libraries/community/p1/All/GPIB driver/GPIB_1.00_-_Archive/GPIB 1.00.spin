{{┌──────────────────────────────────────────┐ 
  │ GPIB driver                              │ 
  │ Author: Chris Gadd                       │ 
  │ Copyright (c) 2017 Chris Gadd            │ 
  │ See end of file for terms of use.        │ 
  └──────────────────────────────────────────┘ 
  Spin-based GPIB driver, capable of ~6KBps -- largely dependent on instrument capability
  Communication is always between the Propeller and one other instrument at a time
   Transmitted messages are in the form of text strings
   Received messages are stored in a byte array, local to this object
  This GPIB driver has been tested on multiple instruments, including the Keithley 6512 and 6514 Electrometers, LeCroy WaveRunner oscilloscope,
   Leader LCR-745G, HP8116A Pulse Generator, and HP5334B and HP5335A Universal counters.
  This object is intended to be shared by all GPIB instruments, each instrument has access to the same shared registers

  PUBLIC METHODS
    init             : Initialize the driver with the IO pins, only needs to be called once even when using multiple instances of this object
    reset            : Drive IFC line to initialize the bus and become CIC     
    clearAll         : Clears the input and output buffers in all instruments on the bus
    clear(ID)        : Clears the input and output buffers in one selected instrument on the bus    
    send(ID,string)  : Transmits a string of one to many bytes to one listener, returns true if successful / false if timeout
    receive(ID)      ' Receives a string from one talker and stores in a local array, returns address of array if successful / -1 if timeout
    trigger          : Sends a Group-Execute-Trigger to all instruments on the bus
    unTalk           : Clear the bus of all talkers
    unListen         : Clear the bus of all listeners
    checkSRQ         : Returns true if SRQ set
    serialPoll       : Returns the ID and status of any instrument on the bus that has the SRQ bit set, excluding the HP5335A which appears non-standard

}}
CON

''Addressed commands (apply to listeners/talkers only)
  GTL  = $01    ' Go to local
  SDC  = $04    ' Selected device clear
  PPC  = $05    ' Parallel poll configure
  GET  = $08    ' Group execute trigger
  TCT  = $09    ' Take control
''Universal multiline commands (apply to all devices)
  LLO  = $11    ' Local lockout
  DCL  = $14    ' Device clear
  PPU  = $15    ' Parallel poll unconfigure
  SPE  = $18    ' Serial poll enable
  SPD  = $19    ' Serial poll disable
  UNL  = $3F    ' Unlisten      
  UNT  = $5F    ' Untalk

DAT Received_message                                                            '' 64-byte message buffer space - shared across all instances of object
array     byte          0[64]

DAT Pin_assignments                                                             '' I/O pin assignments
IFC       long          0-0                                                     '  These registers are populated by the init method,
REN       long          0-0                                                     '   and are shared across all instances of this object
ATN       long          0-0                                                     
SRQ       long          0-0 
EOI       long          0-0 
DAV       long          0-0 
NRFD      long          0-0 
NDAC      long          0-0 
DIO1      long          0-0 
DIO8      long          0-0 
GPIB_ADD  long          0-0

DAT Device_IDs                                                                  '' Talker and listener IDs
talker    long          -1                                                      '  Used for determining when new addressing is required
listener  long          -1  

PUB Null

PUB Init(_ifc,_ren,_atn,_srq,_eoi,_dav,_nrfd,_ndac,_dio1,_dio8,_gpib_add)       '' Initialize GPIB, only needs to be called once
  longmove(@ifc,@_ifc,11)
  dira[REN] := 1
  reset                                                                         

PUB clearAll                                            '' Device CLear: Clears the input and output buffers in all instruments on the bus
  dira[ATN] := 1
  result := tx(DCL)
  talker := -1
  dira[ATN] := 0

PUB goLocal
  dira[ATN] := 1
  result := tx(GTL)
  dira[ATN] := 0
  
PUB clear(_listener)                                    '' Selected Device Clear: Clears the input and output buffers in one selected instrument on the bus   
  listener := _listener
  talker := gpib_add
  dira[ATN] := 1
  if tx(UNL)
    if tx(listener + $20)
      if tx(talker + $40)
        if tx(SDC)
          result := true
  dira[ATN] := 0
                       
PUB getAdd                                              '' Return the address of the receive array
  return @array

PUB untalk                                              '' Clear the bus of all talkers
  dira[ATN] := 1
  result := tx(UNT)
  talker := -1
  dira[ATN] := 0
  
PUB unlisten                                            '' Clear the bus of all listeners
  dira[ATN] := 1
  result := tx(UNL)
  listener := -1     
  dira[ATN] := 0

PUB trigger                                             '' Group Execute Trigger: All instruments on the bus receive a trigger pulse    
  dira[ATN] := 1
  result := tx(GET)
  dira[ATN] := 0

PUB Send(_listener,strPtr)                              '' Transmits a string to one listener, returns true if successful / false if timeout
  dira[DAV] := dira[NDAC] := dira[NRFD] := 0            '  float DAV, allow listener to control NDAC and NRFD
  if listener <> _listener                              '  check if listener changed since last message
    listener := _listener                               '   only supports controller as talker, and a single listener at a time
    talker := gpib_add
    sendAddress                                         '  send UNL,listener_address,controller_address
  repeat strsize(strPtr)
    if byte[strPtr + 1] == 0                            '  assert EOI if sending final byte of message
      dira[EOI] := 1
    if (result := tx(byte[strPtr++])) == false
      quit
  dira[EOI] := dira[DIO8..DIO1] := 0

PUB Receive(_talker) | ptr, char                        '' Receives a string from one talker and stores in a local array, returns address of array if successful / -1 if timeout   
  if talker <> _talker                                  '  check if talker changed since last message  
    listener := gpib_add                                '   only supports controller as talker, and a single listener at a time
    talker := _talker
    sendAddress                                         '  send UNL,listener_address,controller_address
  dira[DIO8..DIO1] := 0                                 
  dira[NRFD] := dira[NDAC] := 1                         
  ptr := 0
  result := @array
  repeat
    if (char := Rx(clkfreq)) > -1
      array[ptr] := char
    else
      result := -1
      quit
  until ina[EOI] == 0 or array[ptr++] == $0A           
  array[ptr] := 0
  dira[NRFD] := dira[NDAC] := 0                           

PUB checkSRQ                                            '' Returns true if SRQ set
  return ina[SRQ] ^ 1

PUB serialPoll | t                                      '' Returns gpib address in byte[1] and status in byte[0]
  result := -1                                          '  Works with Keithley 6512 and 6514 electrometers                              
  dira[ATN] := 1                                        '  Works with Leader LCR-745G                                                   
  tx(UNL)                                               '  Works with HP8116A pulse generator                                           
  tx(SPE)                                               '  Works with HP5334B universal counter                                         
  repeat talker from 0 to 31                            '  Fails with HP5335A universal counter - never asserts DAV
    dira[ATN] := 1                                      
    tx(talker + $40)              
    dira[ATN] := 0
    dira[DIO8..DIO1] := 0                               
    dira[NRFD] := dira[NDAC] := 1
    t := Rx(clkfreq / 100)
    if t > -1 & %0100_0000
      result := talker << 8 | t
      quit
    dira[NDAC] := 0
  dira[NDAC] := 0
  dira[ATN] := 1
  tx(SPD)
  tx(UNT)
  tx(UNL)
  dira[ATN] := 0
  dira[DIO8..DIO1] := 0
  talker := listener := -1

PUB Reset                                               '' drive IFC line to initialize the bus and become CIC
  dira[IFC] := 1
  waitcnt(clkfreq / 10 + cnt)                           ' assert IFC for at least 100ms
  dira[IFC] := 0

PRI sendAddress
  dira[ATN] := 1                                      
  if Tx(UNL)
    if Tx(listener + $20)
      if Tx(talker + $40)
        result := true
  dira[ATN] := 0

PRI Tx(data) | t                                        '' Tx controls DAV and DIO8..DIO1, DAV float on exit

  if ina[NRFD] and ina[NDAC]
    return false
  dira[DIO8..DIO1] := data                              ' place new byte on data lines  
  t := clkfreq / 10 + cnt
  repeat until ina[NRFD] == 1                           ' wait for all listeners to signal readiness for new data
    if cnt - t > 0
      dira[DIO8..DIO1] := 0
      return false                       
  dira[DAV] := 1                                        ' signal data valid to all listeners                               
  t := clkfreq / 10 + cnt                                                                                                  
  repeat until ina[NDAC] == 1                           ' wait for all listeners to accept new data
    if cnt - t > 0
      dira[DAV] := 0
      return false
  dira[DAV] := 0                                        ' unassert data valid
  return true

PRI Rx(timeout) : data | t                              '' Rx controls NRFD and NDAC, NRFD float on exit, NDAC asserted low

  dira[NRFD] := 0                                       ' signal ready for data
  t := timeout + cnt
  repeat until ina[DAV] == 0                            ' wait for data valid signal
    if cnt - t > 0
      return -1
  dira[NRFD] := 1                                       ' signal not ready for data
  data := ina[DIO8..DIO1] ^ $FF                         ' read data
  dira[NDAC] := 0                                       ' signal data accepted                    
  t := timeout + cnt
  repeat until ina[DAV] == 1                            ' wait for data valid to go high
    if cnt - t > 0
      return -1
  dira[NDAC] := 1
  dira[NRFD] := 0                                       ' signal ready for data

CON                     
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
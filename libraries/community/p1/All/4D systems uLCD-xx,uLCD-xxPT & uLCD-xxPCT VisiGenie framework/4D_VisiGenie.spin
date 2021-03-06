{{
*****************************************
* 4D_VisiGenie.spin                     *
* Author: Mathew Brown                  *
***************************************** 
* Simple client framework for using     *
* 4D systems uLCD-xx 'non touchscreen'  *
* & uLCD-xxPT, uLCD-xxPCT 'touchscreen' *
* Intelegent LCD modules in VisiGenie   *
* mode.                                 *
*****************************************   
* Has method dependencies & calls to    *
* FullDuplexSerial, for host comms to   *
* LCD. Requires 1 cog for serial driver *
*                                       *
* All method calls for display access   *
* are blocking routines, pending reply  *
* from LCD module. Non blocking version *
* (using message queues + 1 helper cog) *
* which also handles animating user     *
* images, and handling async 'thrown'   *
* events to be shortly released on OBEX *
*                                       * 
* See end of file for terms of use.     *
*****************************************
}}

VAR 'Object scoped var space


  byte RxStrBuff[33] '32 data bytes + Z terminator string reply buffer for LCD returned replies to sent commands
  byte ChkSum

CON 'LCD Commands enumeration

  CmdReadValue = $00
  CmdWriteValue = $01
  CmdWriteString = $02
  CmdSetContrast = $04

  CmdObjEvent = $05
  CmdRaisedEvent = $07

CON 'LCD object type enumeration...

  ObjDipswitch = $00
  ObjKnob = $01
  ObjRockerSwitch = $02
  ObjRotarySwitch = $03
  ObjSlider = $04                                   
  ObjTrackBar = $05
  ObjWinButton = $06
  ObjAngularmeter = $07
  ObjCoolgauge = $08
  ObjCustomdigits = $09
  ObjForm = $0A
  ObjGauge    = $0B
  ObjImage = $0C
  ObjKeyboard = $0D
  ObjLed = $0E
  ObjLeddigits =$0F
  ObjMeter = $10
  ObjStrings = $11
  ObjThermometer  = $12
  ObjUserled = $13
  ObjVideo  = $14
  ''ObjStatictext = $15
  ObjSound = $16
  ObjTimer = $17

  ObjSpectrum = $18
  ObjScope = $19
  ObjUserImage = $1B
  ObjUserButton = $21

CON 'Ack Nak response codes

  AckResp = $06
  NakResp = $15
               
OBJ 'Included object referencing
      
  LcdSerial : "FullDuplexSerial"

PUB Init(rxpin, txpin) |Ctr

  'Init comm port
  LcdSerial.start(rxpin, txpin, 0, 115200) 'Set your baud of your display in 4D Workshop software

  'Ensure default form (form 0 is displayed)
  WriteObjValue(ObjForm,0,0)
  
PUB ReadObjValue(ObjectId,ObjectIndex) 'Reads the value of a displayed GUI object ...


  SendByte(CmdReadValue)        'Byte 1 is command byte 'CmdReadValue'
  SendByte(ObjectID)            'Byte 2 is ObjectID
  SendByte(ObjectIndex)         'Byte 3 is Object Index  
  SendChksum                    'Byte 4 is calculated checksum, of previous bytes

  'Wait for valid report object packet replt from LCD
  result := PollReportObj(True)

  'Return value truncated to the control value (0000-FFFF) only
  result &= $FFFF       


PUB PackSpectrumValue(BarIndex,BarValue) 'Special case of value for spectrum bars... 2x8 bit values passed are packed into 1x16 bit value

  return (BarIndex<<8) | BarValue
  
PUB WriteObjValue(ObjectId,ObjectIndex,Value) 'Sets the value of a displayed GUI object

  SendByte(CmdWriteValue)       'Byte 1 is command byte 'CmdReadValue'
  SendByte(ObjectID)            'Byte 2 is ObjectID
  SendByte(ObjectIndex)         'Byte 3 is Object Index
  Sendbyte(Value>>8)            'Byte 4 is value upper byte
  SendByte(Value & $FF)         'Byte 5 is value lower byte  
  SendChksum                    'Byte 6 is calculated checksum, of previous bytes
  
  return RtnBlnAck              'Look for ACK NAK response, and return as boolean.. False=NAK, True = ACK


PUB WriteString(ObjectIndex,StrPtr)

  
  SendByte(CmdWriteString)      'Byte 1 is command byte 'CmdWriteString'   
  SendByte(ObjectIndex)         'Byte 2 is Object Index  
  Sendbyte(StrSize(StrPtr))     'Byte 3 is size of string in characters (not including Z terminator)

  'Transmit the string (excluding Z terminator)
  repeat while byte[StrPtr]     'While not Z terminator
    SendByte(byte[StrPtr++])    'Transmit byte

  'Transmit the checksum, to finish the packet
  SendChksum                    'Last byte is calculated checksum, of previous bytes
    

  return RtnBlnAck              'Look for ACK NAK response, and return as boolean.. False=NAK, True = ACK   

PUB SetContrast(Value)

  SendByte(CmdSetContrast)      'Byte 1 is command byte 'CmdSetContrast'  
  SendByte(Value & $0F)         'Byte 2 is contrast value (AND'ed to range 0..15)
  SendChksum                    'Byte 3 is calculated checksum, of previous bytes   

  return RtnBlnAck              'Look for ACK NAK response, and return as boolean.. False=NAK, True = ACK

PUB PollReportObj(Wait)  'Looks for event generated messages in Rx queue

  ''Wait parameter = false, is used for polling async (event raised generated) codes..
  ''Doesnt wait, because an event may not have happen generating a comm event
  ''
  ''Wait parameter = true, is used for polling replies when requested.. needs to wait for LCD to reply

  'Get packet event header byte, with optional wait
  if Wait
    LcdSerial.Rx
  else
    if LcdSerial.RxCheck <0 'Recieve without wait .. If NOT Object raised event   
      return -1 'Return a default error code

  'Read in 4 bytes, and pack into long, in following format...
  'Byte 3 .. Object ID
  'Byte 2 .. Object Index
  'Byte 1 .. Object value MSB
  'Byte 0 .. Object value LSB
  repeat 4
    result <<= 8
    result |= LcdSerial.Rx

  'Read and discard checksum
  LcdSerial.Rx
    
PRI SendByte(DataByte) 'Local send byte routine, updates checksum, with each byte sent

  LcdSerial.Tx(DataByte)        'Transmit the byte
  Chksum ^= DataByte            'XOR with checksum value to update it

PRI SendChkSum 'Local send checksum routine, sends checksum, then resets it for next packet

  LcdSerial.Tx(ChkSum)          'Transmit the checksum value
  Chksum := 0                   'Reset it, for next transmitted packet

PRI RtnBlnAck  'Look for ACK NAK response, and return as boolean.. False=NAK, True = ACK       

  return  LcdSerial.Rx <> NakResp

DAT
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
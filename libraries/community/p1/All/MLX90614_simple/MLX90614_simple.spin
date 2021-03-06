{{ MLX90614_simple.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ MMLX90614 driver v1.0               │ BR             │ (C)2012             │  10Dec2012    │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│ A simple/lightweight driver object for interfacing with the Melexis MLX90614 non-contact   │
│ temperature sensor via the SMbus (pseudo-I2C) interface.  This object is for interfacing   │
│ to the raw sensor iself (not a breakout board version).                                    │
│                                                                                            │
│ IMPORTANT NOTE: this object works at 80MHz clock speed but may not work at lower clock     │
│ speeds. This is due toSMbus timing constraints (specifically SMbus timeout).  Spin is      │
│ barely fast enough to keep up at 80MHz, and isn't fast enough at lower speeds.             │
│                                                                                            │
│ This object shamelessly robs code snippets from two OBEX objects (thank-you Jon & Tim):    │
│  http://obex.parallax.com/objects/528/                                                     │
│  http://obex.parallax.com/objects/613/                                                     │
│                                                                                            │
│ Features include:                                                                          │
│ •A simple/minimal serial-terminal-based demo...                                            │
│ • ...that dumps EEPROM and RAM contents to terminal for user examination                   │ 
│ •Supports output in degrees °C and °F                                                      │
│ •Functions to provide low-level (register) read and write access                           │
│ •Small object code size                                                                    │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘

  REFERENCE CIRCUIT for connecting to raw MLX90614 sensor (3.3v version):

          3.3v     3.3v               3.3v
               │   │                   │
               │    4.7KΩ              4.7KΩ
               │   │                   │
  Prop pin29 ─│───┴───   2┌───┐1   ───┴── Prop pin28
               │           │TOP├
               ├───────   3└───┘4   ──────┐ GND
         0.1µF                           │
                         MLX90614        
                          Top view
          
  Pin 1 SCL -> Prop Pin (28 works), needs 4.7K pullup to 3.3V
  Pin 2 SDA -> Prop Pin (29 works), needs 4.7K pullup to 3.3V
  Pin 3 Vdd -> +3.3v
  Pin 4 Vss -> Gnd


  NOTES:
  •Locate 0.1µF capacitor as close to the power leads as possible
  •Tested with MLX90614ESF-BAA (3.3v) available from sparkfun: https://www.sparkfun.com/products/9570?
  •This object ONLY WORKS with 80MHz clock due to SMbus 45us Timeout_H timing constraint
  •This object does NOT actively drive the SDA or SCL lines high, the 4.7K pullup resistors are required

Future updates...maybe
FIXME: add support for PWM  mode
FIXME: add support for setting up thermal relay mode
FIXME: add support for sleep mode
FIXME: add support for reading flags
}}
con

  MLX_Adr = $B4                                         'Default MLX90614 SMS bus address

  'RAM Register addresses
  Ambient_Sensor_Data           = $03
  IR_Sensor1_Data               = $04
  IR_Sensor2_Data               = $05
  Ambient                       = $06
  Object1                       = $07                   'address containing Zone 1 temperature information
  Object2                       = $08
  Ta1_PKI                       = $0A
  Ta2_PKI                       = $0B
  Scale_Alpha_Ratio             = $13
  Scale_Alpha_Slope             = $14
  IIR_Filter                    = $15
  Ta1_PKI_Fraction              = $16
  ta2_PKI_Fraction              = $17
  FIR_Filter                    = $1B

  'EEPROM Register addresses
  TOmax                         = $00 + %10_0000
  TOmin                         = $01 + %10_0000
  PWMctrl                       = $02 + %10_0000
  Ta_Range                      = $03 + %10_0000
  Ke                            = $04 + %10_0000
  ConfigR1                      = $05 + %10_0000
  SMBus_Address                 = $0E + %10_0000
  ID_1                          = $1C + %10_0000
  ID_2                          = $1D + %10_0000
  ID_3                          = $1E + %10_0000
  ID_4                          = $1F + %10_0000

  'other commands
  read_flags = %1111_0000
  sleep = %1111_1111


pub readReg(reg)|hi,lo
''read value from MLX90614 register - simple, no error checking
''Example usage: result := instanceName.readReg(instanceName#Object1)
''where reg = the register to be read (in this example, the object temperature register)
''See constants section at top of this object for valid input values

  start                                     'send start sequence
  dira[SCL]~~                               'needed for finiky SMbus (45us Timeout_H)
  write(MLX_Adr)                            'send device address 
  write(reg)                                'send command (register address)
  start                                     'send start sequence
  dira[SCL]~~                               'needed for finiky SMbus (45us Timeout_H)
  write(MLX_Adr+1)                          'send device address (+ read bit set)
  lo := read(ACK)                           'read lo byte
  hi := read(ACK)                           'read hi byte
  stop                                      'throw away PEC byte
  return hi << 8 + lo


pub writeReg(regaddr,val)|tmp
''write a value to a MLX90614 register
''Example usage: acknowledge := instanceName.writeReg(instanceName#ConfigR1, val)
''where ConfigR1 = the register to be written to (in this example, configuration register)
''      val      = the value to be written to the register
''See constants section at top of this object for valid input values

  wrreg(regaddr,0)                          'write a 0 first (i.e. erase)
  waitcnt(clkfreq/20+cnt)                   'wait for eeprom to finish S-L-O-W!!
  tmp := wrreg(regaddr,val)                 'write new value to register
  waitcnt(clkfreq/20+cnt)                   'wait for eeprom to finish
  return tmp
  

pri wrReg(regaddr,val)|hi,lo,pec
''write a value to MLX90614 register

  if not(($19 < regaddr) and (regaddr <$2F)) 'simple bounds checking on address
    return -999
  hi := (val>>8) & %1111_1111
  lo := val      & %1111_1111
  pec := 0                                  'calculate CRC
  pec := CRC8smb(MLX_Adr, pec)                         
  pec := CRC8smb(regaddr, pec)
  pec := CRC8smb(lo, pec)
  pec := CRC8smb(hi, pec)
  start                                     'send start sequence
  dira[SCL]~~                               'needed for finiky SMbus (45us Timeout_H)
  write(MLX_Adr)                            'send device address 
  write(regaddr)                            'send EEPROM register address
  write(lo)                                 'write low byte
  write(hi)                                 'write high byte
  return write(pec)                         'write PEC
  

PRI CRC8smb(Data, CRC)                      'This funciton copied from Tim's object

  Data ^= CRC                               'xor new byte and old crc to get remainder + byte
  repeat 8                                  'check all 8 bits
    Data := Data << 1                       'shift it out
    if (Data & $100) <> 0                   'if bit 7 was a 1
      Data ^= $07                           'then xor with the polynomial
  Data &= $ff                               'remove the bit we shifted out
  return Data


PUB getTempC(register)
''get temperature measurement from specified register, return value in °C
''typical register values are: Ambient, Object1
''Example usage: result := instanceName.getTempC(instanceName#Object1)

  return readReg(register)/50-273


PUB getTempF(register)
''get temperature measurement from specified register, return value in °F
''typical register values are: Ambient, Object1
''Example usage: result := instanceName.getTempF(instanceName#Object1)

  return (getTempC(register)*9)/5+32


con
' *****************************************
' everything from this point on is code snippets from Jon's JM_I2C object
' *****************************************
con

   #0, ACK, NAK

  #28, BOOT_SCL, BOOT_SDA                                       ' Propeller I2C pins


dat

scl             long    -1                                      ' clock pin of i2c buss
sda             long    -1                                      ' data pin of i2c buss

devices         long    0                                       ' devices sharing driver


pub setup

'' Setup I2C using default (boot EEPROM) pins

  setupx(BOOT_SCL, BOOT_SDA)
         

pub setupx(sclpin, sdapin)

'' Define I2C SCL (clock) and SDA (data) pins
'' -- will not redefine pins once defined
''    * assumes all I2C devices on same pins

  if (devices == 0)                                             ' if not defined
    longmove(@scl, @sclpin, 2)                                  '  copy pins
    dira[scl] := 0                                              '  float to pull-up
    outa[scl] := 0                                              '  write 0 to output reg
    dira[sda] := 0
    outa[sda] := 0

  repeat 9                                                      ' reset device
    dira[scl] := 1
    dira[scl] := 0
    if (ina[sda])
      quit

  devices += 1                                                  ' increment device count


pub kill

'' Clear I2C pin definitions

  if (devices > 0)
    if (devices == 1)                                           ' if last device
      longfill(@scl, -1, 2)                                     ' undefine pins
      dira[scl] := 0                                            ' force to inputs
      dira[sda] := 0
    devices -= 1                                                ' decrement device count


con

  { ===================================== }
  {                                       }
  {  L O W   L E V E L   R O U T I N E S  }
  {                                       }
  { ===================================== }
  
        
pub start

'' Create I2C start sequence
'' -- will wait if I2C buss SDA pin is held low

  dira[sda] := 0                                                ' float SDA (1)
  dira[scl] := 0                                                ' float SCL (1)
  repeat while (ina[scl] == 0)                                  ' allow "clock stretching"

  outa[sda] := 0
  dira[sda] := 1                                                ' SDA low (0)

  
pub write(i2cbyte) | ackbit

'' Write byte to I2C buss

  outa[scl] := 0
  dira[scl] := 1                                                ' SCL low

  i2cbyte <<= constant(32-8)                                    ' move msb (bit7) to bit31
  repeat 8                                                      ' output eight bits
    dira[sda] := ((i2cbyte <-= 1) ^ 1)                          ' send msb first
    dira[scl] := 0                                              ' SCL high (float to p/u)
    dira[scl] := 1                                              ' SCL low

  dira[sda] := 0                                                ' relase SDA to read ack bit
  dira[scl] := 0                                                ' SCL high (float to p/u)  
  ackbit := ina[SDA] == 0                                            ' read ack bit
  dira[scl] := 1                                                ' SCL low

  return (ackbit)


pub read(ackbit) | i2cbyte

'' Read byte from I2C buss

  outa[scl] := 0                                                ' prep to write low
  dira[sda] := 0                                                ' make input for read

  repeat 8
    dira[scl] := 0                                              ' SCL high (float to p/u)
    i2cbyte := (i2cbyte << 1) | ina[sda]                        ' read the bit
    dira[scl] := 1                                              ' SCL low
                             
  dira[sda] := !ackbit                                          ' output ack bit 
  dira[scl] := 0                                                ' clock it
  dira[scl] := 1

  return (i2cbyte & $FF)


pub stop

'' Create I2C stop sequence 

  outa[sda] := 0
  dira[sda] := 1                                                ' SDA low
  
  dira[scl] := 0                                                ' float SCL
  repeat while (ina[scl] == 0)                                  ' hold for clock stretch
  
  dira[sda] := 0                                                ' float SDA


dat

{{

  Terms of Use: MIT License

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
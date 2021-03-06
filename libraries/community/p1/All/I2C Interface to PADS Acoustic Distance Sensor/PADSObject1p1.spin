'' ******************************************************************************
'' * P.A.D.S Interface Object                                                   *
'' * Ed Tye, Perbolia LLC August 2011  www.perbolia.com                         *
'' * Version 1.1                                                                *
'' * License  : MIT License. Please see end of this file for Terms of Use.      *
'' ******************************************************************************
''
'' Based On:
'' ******************************************************************************
'' * SRF08 Object                                                               *
'' * James Burrows Oct 07                                                       *
'' * Version 2.0                                                                *
'' ******************************************************************************
''
''  This object is for I2C communication with the P.A.D.S - Programmable
''  Acoustic Distance Sensor from Perbolia LLC.
''
'' this object provides the PUBLIC functions:
''  -> WritePADSCommand  - write to the PADS command register
''  -> WritePADSCommandSync  - write to the PADS command register then wait for data ready or 0.1 sec timeout
''  -> ChangePADSAddress - change the PADSs I2C address
''  -> getPADSPeakDistance - get distance to a peak (echo)
''  -> getPADSPeakValue - get the height of a peak (echo)
''  -> WritePADSReg - write to a PADS Register
''  -> getPADSReg - read one of the PADS registers
''  -> DataReady - is the measurement data ready.
''
'' this object provides the PRIVATE functions:
''  -> None
''
'' this object uses the following sub OBJECTS:
''  -> basic_i2c_driverTM
''
'' Revision History:
''  -> V1   - Initial Release
''  -> V1.1   - added support for 8V,16V output drive, read SWVersion
'' PADS from Perbolia LLC - www.Perbolia.com 
''
'' Method Parameters
''    _deviceAddress : The I2C address of the PADS device. The PADS device's default is %1110_0010
''    i2cSCL : The pin on your device that is used as the I2C SCL line. The SDA line must be on pin i2CSCL+1
''    _command : The command # for the PADS device to execute. See the list in the CON section
''    addrReg : The Register address on the PADS device. See the list of register definitions in the CON section
''
''  Hardware notes
''  The I2C SCL and SDA lines require 10k pullups to 3.3V or 5V
             
''  Sample usage in parent :change to I2C mode,apply changes
''OBJ
''      PADS:"PADSObject"
''VAR
''      long I2CAddr,SCLPin,startcnt1,Answer1
''PUB
''      I2CAddr := %1110_0010
''      SCLPin := 0
''      PADS.WritePADSReg(SCLPin,I2CAddr,SD#_Reg_TrigMode,SD#_Val_I2CMode)  'change to I2C Trigger Mode
''      PADS.writePADSCommand(SCLPin,I2CAddr,SD#_Cmd_ApplyConfig)           'apply config settings
''
''    Sample Usage: Trigger Reading and get resultant measurement
''        PADS.writePADSCommand(SCLPin,I2CAddr,SD#_Cmd_Trig)                'request measurement
''        startcnt1:=cnt
''        repeat while (PADS.dataReady(SCLPin,I2CAddr) == False)and (cnt-startcnt1)<clkfreq/10  'wait until data ready or timeout
''        Answer1 := PADS.getPADSPeakDistance(SCLPin,I2CAddr,1)             'read first range value

CON
' Register Definition(Bytes)
' Reg #              Read                 Write
_Reg_Cmd = 0    ' Current Cmd            Commands        If read = 250 then data is ready and can accept new command
'           1   1st peak distance high        
'           2   1st peak distance low
'           3   2nd peak distance high
'           4   2nd peak distance low
'           5   3rd peak distance high    
'           6   3rd peak distance low
'             .............
'           19  10th peak distance high    
'           20  10th peak distance low     
'           21   1st peak value high        
'           22   1st peak value low
'           23   2nd peak value high
'           24   2nd peak value low
'           25   3rd peak value high    
'           26   3rd peak value low
'             .............
'           39  10th peak value high    
'           40  10th peak value low 

_Reg_SWVersion  =  50   'Register that can be read to get Software Version of PADS Firmware

'Configuration Registers  Read                Write               Description (default value)
_Reg_MaxPulsemsec = 51  'Maxpulsemsec         Maxpulsemsec       'time in msecs the analyze cog will run looking for echo (20)
_Reg_LevelGain =    52  'LevelGain            LevelGain          'gain on trigger level/100_000 (20) 
_Reg_LevelDCOff =   53  'LevelDCOff           LevelDCOff         'DC Offset/100_000 (10) 
_Reg_BLCycles   =   54  'BLCycles             BLCycles           '# of 40kHz cycles to measure and subtract baseline from signal (80)
_Reg_hnumavg    =   55  'hnumavg              hnumavg            '# of 40kHz cycles over which to avg return signal in AsyMult COG (16)
_Reg_P1Count    =   56  'P1Count              P1Count            '# of Ultrasound cycle in main portion (16) 
_Reg_P2Count    =   57  'P2Count              P2Count            '# of Ultrasound cycle in out-of-phase "counter" portion (0)
_Reg_P3Count    =   58  'P3Count              P3Count            '# of Ultrasound cycle in in-phase "counter-counter" portion (0)
_Reg_AnaSelect  =   59  'AnaSelect            AnaSelect          '1 = sin, 2=cos, 3=sin^2 4=cos^2 5=avg(sin^2), 6=avg(cos^2), 7=5+6, 8=zero,9=first peak distance (9)
_Reg_TempDegC   =   60  'TempDegC             TempDegC           'temperature used to calc speed of sound used in time to distance conversion  (20)
_Reg_Volts      =   61  'Volts                Volts              'Net Voltage level driving Ultrasound out. Valid values: 0,8,16,20,40 (40)
  _val0Volts    =   0
  _val8Volts    =   8
  _val16Volts   =   16
  _val20Volts   =   20
  _val40Volts   =   40
_Reg_HVOnOffFlag=   62  'HVOnOffFlag          HVOnOffFlag        'Step up circuit on(1) or off(0) (1) 
_Reg_uoffset    =   63  'uoffset              uoffset            'user defined offset for sin value into multiplier/500 (0)
_Reg_uoffset2   =   64  'uoffset2             uoffset2           'user defined offset for cos value into multiplier/500 (0) 
_Reg_CalcNewOff =   65  'CalcNewOff           CalcNewOff         'calc new offsets at startup flag (1) or use user defined offsets(0) (if 1 then above 2 values are irrelevent) (1)
_Reg_TrigMode   =   66  'TrigMode             TrigMode           '0 = I2C, 1=Ping Trig, 2=Auto Trig at Fixed Rate (1)
  _Val_I2CMode  =   0
  _Val_PingMode =   1
  _Val_AutoMode =   2
_Reg_FirstPeakQuit= 67  'FirstPeakQuit        FirstPeakQuit      'quit analyzing when first peak exceeds threshold (0=No, 1=Yes) (0)  
_Reg_Rate       =   68  'Rate                 Rate               'Trigger Rate in AutoTrig Mode in Hz (10)
_Reg_I2C_Address=   69  'I2C Address                             'This devices I2C Address (0xE2)(see commands for changing this)
_Reg_LEDUse     =   70  'LEDUse               LEDUse             'Keep LED Off (0),flash with each trigger(1),flash with each detection (2),(1) not yet implemented 
_Reg_DistanceUOM=   71  'DistanceUOM          DistanceUOM        '0 = usec, 1 = mm, 2 = 1/10"
  _Val_usecUOM  =   0
  _Val_mmUOM    =   1
  _Val_tinchUOM =   2

'Commands                   'Description
_Cmd_Trig        =  1      'Trigger measurement
_Cmd_ApplyConfig =  2      'Apply config settings that have been written to registers
_Cmd_SaveConfig  =  3      'Save applied config settings to EEPROM
_Cmd_ClearConfig =  4      'Clear EEPROM settings from EEPROM (use defaults at next restart)
_Cmd_ApplySaveCfg=  5      'Apply and Save config settings to EEPROM
_Cmd_SetBaseline =  6      'Measure and set baseline signal
_Cmd_CfgToI2CReg =  7      'Get latest config values into I2C registers (done at startup)
_Cmd_ReInit      =  8      'ReInitialize (similar to power-on except uses current config settings not EEPROM or default)
_Cmd_RecalcOffsets= 9      'Recalc offsets
_Cmd_LoadConfig   = 10     'Load config from EEPROM
' 11
' 12
' AO,AA,A5 -  Change I2C Address to next value written to command register  

VAR
  long temp,n

OBJ
  i2cObject   : "basic_i2c_driverTM" 
    
PUB WritePADSCommand(i2cSCL,_deviceAddress,_command) 
  i2cObject.writeLocation(i2cSCL,_deviceAddress, _Reg_Cmd, _command)
  
PUB WritePADSCommandSync(i2cSCL,_deviceAddress,_command) |StCnt,Tout
  Tout :=Clkfreq/10
  i2cObject.writeLocation(i2cSCL,_deviceAddress, _Reg_Cmd, _command)
  Stcnt:=cnt
  repeat while (dataReady(i2cSCL,_deviceAddress)==false and (cnt-Stcnt<Tout))
    
PUB ChangePADSAddress(i2cSCL,_olddeviceAddress,_newdeviceAddress)|Startcnt,Timeout
  Timeout :=Clkfreq/10
  WritePADSCommand(i2cSCL,_olddeviceAddress,$A0)
  Startcnt := cnt
  repeat while (dataReady(i2cSCL,_olddeviceAddress)==false and (cnt-Startcnt<Timeout))
  'waitcnt(5*clkfreq+cnt)
  WritePADSCommand(i2cSCL,_olddeviceAddress,$AA)
  Startcnt := cnt
  repeat while (dataReady(i2cSCL,_olddeviceAddress)==false and (cnt-Startcnt<Timeout))
  'waitcnt(5*clkfreq+cnt)
  WritePADSCommand(i2cSCL,_olddeviceAddress,$A5)
  Startcnt := cnt
  repeat while (dataReady(i2cSCL,_olddeviceAddress)==false and (cnt-Startcnt<Timeout))
  'waitcnt(5*clkfreq+cnt)
  WritePADSCommand(i2cSCL,_olddeviceAddress,_newdeviceAddress)
  Startcnt := cnt
  repeat while (dataReady(i2cSCL,_newdeviceAddress)==false and ((cnt-Startcnt)<(10*Timeout)))    
  'waitcnt(5*clkfreq+cnt)
  
PUB WritePADSReg(i2cSCL,_deviceAddress,addrReg,value) 
  i2cObject.writeLocation(i2cSCL,_deviceAddress,addrReg,value)
  
PUB getPADSPeakDistance(i2cSCL,_deviceAddress,peaknum):value
  value:=getWord(i2cSCL,_deviceAddress,peaknum*2-1)

PUB getPADSPeakValue(i2cSCL,_deviceAddress,peaknum):value
  value:=getWord(i2cSCL,_deviceAddress,19+peaknum*2) 
  
PUB getPADSPVatRange(i2cSCL,_deviceAddress,tstart,tend):value |ln,ltemp
'This method finds the first Peak Value that is after distance tstart and before distance tend
'Be sure the uom of tstart and tend = the uom you have set (usec is default)
'Zero is returned if there is not a peak that meets the criteria
  value :=ltemp:=0
  ln:=1
  repeat 
    ltemp:=getPADSPeakDistance(i2cSCL,_deviceAddress,ln)
    ln:=ln+1
  until ((ln>10)  | (ltemp>tstart) | (ltemp==0))
  if ((ltemp>tstart) & (ltemp<tend))
    value:= getPADSPeakValue(i2cSCL,_deviceAddress,ln-1)
  return  
    
PUB getPADSPDatRange(i2cSCL,_deviceAddress,tstart,tend):value |ln,ltemp
'This method finds the first Peak Distance that is after distance tstart and before distance tend
'Be sure the uom of tstart and tend = the uom you have set (usec is default)
'Zero is returned if there is not a peak that meets the criteria
  value :=ltemp:=0
  ln:=1
  repeat 
    ltemp:=getPADSPeakDistance(i2cSCL,_deviceAddress,ln)
    ln:=ln+1
  until ((ln>10)  | (ltemp>tstart) | (ltemp==0))
  if ((ltemp>tstart) & (ltemp<tend))
    value:= ltemp
  return  
   
PUB WritePADSWord(i2cSCL,_deviceAddress,addrReg,value)|data 
  data:= (value>>8)&$FF
  i2cObject.WriteLocation(i2cSCL, _deviceAddress, addrReg, data)
  data:= (value&$FF)
  i2cObject.WriteLocation(i2cSCL, _deviceAddress, addrReg+1, data)
  
PUB getPADSReg(i2cSCL,_deviceAddress,addrReg):value  
  value := i2cObject.ReadLocation(i2cSCL, _deviceAddress, addrReg)
    
PUB getWord(i2cSCL,_deviceAddress,addrReg):Value  
  i2cObject.Start(i2cSCL)
  i2cObject.Write(i2cSCL,_deviceAddress | 0)
  i2cObject.Write(i2cSCL,addrReg) 'slave register for range = 2
  i2cObject.Start(i2cSCL)
  i2cObject.Write(i2cSCL,_deviceAddress | 1) 'tell it this is a read
  Value := 0
  Value := i2cObject.Read(i2cSCL,i2cObject#ACK) 'read first byte
  Value <<= 8
  Value := Value + i2cObject.Read(i2cSCL,i2cObject#NAK) 'slave auto-increments location
  i2cObject.Stop(i2cSCL)     

PUB dataReady(i2cSCL,_deviceAddress) :dev_ready
  ' if the PADS is ready it will return a command ==250 when read
  ' when it is<> 250 then the PADS is busy doing a measurement and data is not ready
  if getPADSReg(i2cSCL,_deviceAddress,0) == 250
    dev_ready := true
  else
    dev_ready := false      
CON

' *******************************************************************************************************
' *                                                                                                     *
' *     Terms of Use : MIT License                                                                      *
' *                                                                                                     *
' *******************************************************************************************************
'
' Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
' associated documentation files (the "Software"), to deal in the Software without restriction, including
' without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
' the following conditions:                                                                   
'
' The above copyright notice and this permission notice shall be included in all copies or substantial
' portions of the Software.                                                                                             
'                                                                                                                  
' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
' LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
' NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
' WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
' SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.  
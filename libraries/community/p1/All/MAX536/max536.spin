{
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ MAX536 driver                       │ Peter Thompson | (C) 2012            | 25 Mar 2012   |
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│                                                                                            │
│ A driver for the MAX536 4-channel 12 bit SPI DAC                                                     │
|                                                                                            |   
| See end of file for terms of use                                                           |
└────────────────────────────────────────────────────────────────────────────────────────────┘
 SCHEMATIC
                      ┌────┐      
               OutA │      │ OutC
               OutB │MAX536│ OutD
               Vss  │      │ Vdd
               AGND │      │ TP
              REFAB │      │ REFCD
               DGND │      │ SDO               
              !LDAC │      │ SCLK
                SDI │      │ !CS
                      └──────┘      
Assumptions:
+5V:  TP, RefAB, RefCD, Vdd
Gnd:  !LDAC, Vss, AGnd, DGnd

}

VAR
  long sdi, sclk, csl

{ Inputs:  SDI, Clock, ChipSelect }

PUB init(_sdi, _sclk, _csl )
  sdi := _sdi
  sclk := _sclk
  csl := _csl

  dira[sdi]~~
  dira[sclk]~~
  dira[csl]~~

  outa[csl]~~                                           ' make sure the chip is not selected right away


PUB out(value, pin) | temp
  temp := value & $fff                                  ' use only 12 bits of data
  temp := temp + (((pin & $3)) * $c000)                 ' put in the pin select
  temp := temp + $3000                                  ' command to immediately load DAC
    
  outa[sclk]~                                           ' make sure SCLK is low 
  outa[csl]~                                            ' tell chip to wake up (set to low)

  { Shift out the value, MSB first, with clock }
  repeat 16
    { Output data }
    outa[sdi] := temp & $8000 <> 0                      ' take topmost bit and ship it out SDI
    temp <<= 1                                          ' rotate left
      
    { Clock }
    outa[sclk]~~                                        ' toggle the clock
    outa[sclk]~ 
    
  { set CS high to finish operation - this loads the output immediately }
  outa[csl]~~



DAT
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
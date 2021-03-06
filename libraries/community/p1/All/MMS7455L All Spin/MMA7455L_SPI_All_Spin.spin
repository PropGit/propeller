{{
***************************************
* MMA7455L_SPI_All_Spin.spin  Ver 2   *
* Author: Mike Lord                   *
*                                     *
* Copyright (c) 2013 Mike Lord        *
* See end of file for terms of use.   *
***************************************

   History:
        Version 1 - Written from scratch all in spin to make easy modifications for other applications

                    This would make it easy to calculate average acceleration and such 

   Description:
        This program is a basic SPI driver specifically designed to operate with 
        the MMA7455L device for the Digital 3-Axis Accelerometer module.


        You will need the included data sheet to be able to configure the registers. dont be afraid to use it.



         MCTL - Mode control register
   ┌────┬────┬────┬────┬────┬────┬────┬────┐
   │ D7 │ D6 │ D5 │ D4 │ D3 │ D2 │ D1 │ D0 │
   ├────┼────┼────┼────┼────┼────┼────┼────┤
   │ -- │DRPD│SPI3│STON│GLVL│GLVL│MODE│MODE│
   └────┴────┴────┴────┴────┴────┴────┴────┘ 
  
   D7       - don't care          0

   D6(DRPD) - Data ready status   0 - output to INT1 pin
                                  1 - is not output to INT1 pin
                                 
   D5(SPI3W)- Wire Mode           0 - SPI is 4-wire mode
                                  1 - SPI is 3-wire mode
                                 
   D4(STON) - Self Test           0 - not enabled
                                  1 - enabled

   D3(GLVL[1]) - g-Select        00 - 8g ; 16 LSB/g in 8-bit format
   D2(GLVL[0]) - g-Select        10 - 4g ; 32 LSB/g in 8-bit format
                                 01 - 2g ; 64 LSB/g in 8-bit format

                                         ; Note: When reading g in 10-bit
                                         ;       format, resolution is fixed
                                         ;       at 64 LSB/g
                   10-bit g register
   ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
   │ D9 │ D8 │ D7 │ D6 │ D5 │ D4 │ D3 │ D2 │ D1 │ D0 │
   └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘ 
   │─────────────────────────────────────│            ; These 8 bits are read in 8g mode
        │─────────────────────────────────────│       ; These 8 bits are read in 4g mode
             │─────────────────────────────────────│  ; These 8 bits are read in 2g mode

   D1(MODE[1]) - Mode Select     00 - Standby
   D0(MODE[0]) - Mode Select     01 - Measurement
                                 10 - Level Detection
                                 11 - Pulse Detection
                                  

        
}}

CON


'Register definitions
  XOUTL         = $00           ' 10 bits output value X LSB             XOUT[7]  XOUT[6]  XOUT[5]  XOUT[4]  XOUT[3]  XOUT[2]  XOUT[1]  XOUT[0]
  XOUTH         = $01           ' 10 bits output value X MSB             --       --       --       --       --       --       XOUT[9]  XOUT[8]
  YOUTL         = $02           ' 10 bits output value Y LSB             YOUT[7]  YOUT[6]  YOUT[5]  YOUT[4]  YOUT[3]  YOUT[2]  YOUT[1]  YOUT[0]
  YOUTH         = $03           ' 10 bits output value Y MSB             --       --       --       --       --       --       YOUT[9]  YOUT[8]
  ZOUTL         = $04           ' 10 bits output value Z LSB             ZOUT[7]  ZOUT[6]  ZOUT[5]  ZOUT[4]  ZOUT[3]  ZOUT[2]  ZOUT[1]  ZOUT[0]
  ZOUTH         = $05           ' 10 bits output value Z MSB             --       --       --       --       --       --       ZOUT[9]  ZOUT[8]
  XOUT8         = $06           ' 8 bits output value X                  XOUT[7]  XOUT[6]  XOUT[5]  XOUT[4]  XOUT[3]  XOUT[2]  XOUT[1]  XOUT[0]
  YOUT8         = $07           ' 8 bits output value Y                  YOUT[7]  YOUT[6]  YOUT[5]  YOUT[4]  YOUT[3]  YOUT[2]  YOUT[1]  YOUT[0]
  ZOUT8         = $08           ' 8 bits output value Z                  ZOUT[7]  ZOUT[6]  ZOUT[5]  ZOUT[4]  ZOUT[3]  ZOUT[2]  ZOUT[1]  ZOUT[0]
  STATUS        = $09           ' Status registers                       --       --       --       --       --       PERR     DOVR     DRDY
  DETSRC        = $0A           ' Detection source registers             LDX      LDY      LDZ      PDX      PDY      PDZ      INT1     INT2
  TOUT          = $0B           ' "Temperature output value" (Optional)  TMP[7]   TMP[6]   TMP[5]   TMP[4]   TMP[3]   TMP[2]   TMP[1]   TMP[0]
'               = $0C           ' (Reserved)                             --       --       --       --       --       --       --       --
  I2CAD         = $0D           ' I2C device address I                   2CDIS    DAD[6]   DAD[5]   DAD[4]   DAD[3]   DAD[2]   DAD[1]   DAD[0]
  USRINF        = $0E           ' User information (Optional)            UI[7]    UI[6]    UI[5]    UI[4]    UI[3]    UI[2]    UI[1]    UI[0]
  WHOAMI        = $0F           ' "Who am I" value (Optional)            ID[7]    ID[6]    ID[5]    ID[4]    ID[3]    ID[2]    ID[1]    ID[0]
  XOFFL         = $10           ' Offset drift X value (LSB)             XOFF[7]  XOFF[6]  XOFF[5]  XOFF[4]  XOFF[3]  XOFF[2]  XOFF[1]  XOFF[0]
  XOFFH         = $11           ' Offset drift X value (MSB)             --       --       --       --       --       XOFF[10] XOFF[9]  XOFF[8]
  YOFFL         = $12           ' Offset drift Y value (LSB)             YOFF[7]  YOFF[6]  YOFF[5]  YOFF[4]  YOFF[3]  YOFF[2]  YOFF[1]  YOFF[0]
  YOFFH         = $13           ' Offset drift Y value (MSB)             --       --       --       --       --       YOFF[10] YOFF[9]  YOFF[8]
  ZOFFL         = $14           ' Offset drift Z value (LSB)             ZOFF[7]  ZOFF[6]  ZOFF[5]  ZOFF[4]  ZOFF[3]  ZOFF[2]  ZOFF[1]  ZOFF[0]
  ZOFFH         = $15           ' Offset drift Z value (MSB)             --       --       --       --       --       ZOFF[10] ZOFF[9]  ZOFF[8]
  MCTL          = $16           ' Mode control                           LPEN     DRPD     SPI3W    STON     GLVL[1]  GLVL[0]  MOD[1]   MOD[0]
  INTRST        = $17           ' Interrupt latch reset                  --       --       --       --       --       --       CLRINT2  CLRINT1
  CTL1          = $18           ' Control 1                              --       THOPT    ZDA      YDA      XDA      INTRG[1] INTRG[0] INTPIN
  CTL2          = $19           ' Control 2                              --       --       --       --       --       DRVO     PDPL     LDPL
  LDTH          = $1A           ' Level detection threshold limit value  LDTH[7]  LDTH[6]  LDTH[5]  LDTH[4]  LDTH[3]  LDTH[2]  LDTH[1]  LDTH[0]
  PDTH          = $1B           ' Pulse detection threshold limit value  PDTH[7]  PDTH[6]  PDTH[5]  PDTH[4]  PDTH[3]  PDTH[2]  PDTH[1]  PDTH[0]
  PW            = $1C           ' Pulse duration value                   PD[7]    PD[6]    PD[5]    PD[4]    PD[3]    PD[2]    PD[1]    PD[0]
  LT            = $1D           ' Latency time value                     LT[7]    LT[6]    LT[5]    LT[4]    LT[3]    LT[2]    LT[1]    LT[0]
  TW            = $1E           ' Time window for 2nd pulse value        TW[7]    TW[6]    TW[5]    TW[4]    TW[3]    TW[2]    TW[1]    TW[0]
'               = $1F           ' (Reserved)                             --       --       --       --       --       --       --       --

  G_RANGE_2g    = %01           ' 2g = %01
  G_RANGE_4g    = %10           ' 4g = %10
  G_RANGE_8g    = %00           ' 8g = %00

  G_MODE        = %01           ' 00 - Standby                                        
                                ' 01 - Measurement    
                                ' 10 - Level Detection
                                ' 11 - Pulse Detection



            CLKPIN       = 9 
            DATAPIN      = 8 
            CSPIN        = 7




                             
  
VAR


      Long  CogAcel
      Long   AcelStack[20]
      Long   NCounts       
                     
      

'===========================================================================================+============
Pub Acel_Start( XYZData_Adr, DecAcl_Adr        )
'===========================================================================================+============

   'dira[CSPIN] := 1     
   'outa[CSPIN] := 0     'this sets the chip to SPI mode 


   

   Acel_Stop 

     if  not CogAcel
          CogAcel := cognew( Acel_Run(  XYZData_Adr, DecAcl_Adr ,  NCounts , CLKPIN, DATAPIN , CSPIN  ) , @AcelStack  )                 


'===========================================================================================+============
Pub Acel_Stop
'===========================================================================================+============


  if CogAcel
    cogstop(CogAcel)






'===========================================================================================+============
Pub Acel_Run(  XYZData_Adr, DecAcl_Adr ,  NCounts_ , CLKPIN_ , DATAPIN_ , CSPIN_  )
'===========================================================================================+============
     
   'set mode to measurement
      dira[  CLKPIN_ ] := 1
      dira[  CSPIN_  ] := 1
      outa[  CSPIN_  ] := 1
      outa[ CLKPIN_  ] := 1

   'this set the configuration into the MCTL register
     'write( CLKPIN_ , DATAPIN_ , CSPIN_ , MCTL, %0110_0001      ) 'Initialize the Mode Control register
      write( CLKPIN_ , DATAPIN_ , CSPIN_ , $16, %0110_0001      ) 'Initialize the Mode Control register
               ''DRPD= 1 , SP13W=1(3WIRE), STON=0, GLVL1=0 & GLVL0=0(8G), MODE1=0 & MODE0=1 (Measurement Mode)
      
      repeat


        'x axis
          long[  XYZData_Adr ][0] :=   Read( CLKPIN_ , DATAPIN_ , CSPIN_ ,  $00   )     ' 
        'Y axis
          long[  XYZData_Adr ][1] :=   Read( CLKPIN_ , DATAPIN_ , CSPIN_ ,  $02   )       
         'Z axis
          long[  XYZData_Adr ][2] :=   Read( CLKPIN_ , DATAPIN_ , CSPIN_ ,  $04   )       
                                                                        
        waitcnt(clkfreq / 10000 + cnt)



    
'===========================================================================================+============
PUB read( CLKPIN_ , DATAPIN_ ,CSPIN_ , Addr  )    |  index  , BitOut
'===========================================================================================+============

    Addr <<= 1
    Addr &=  %0111_1111              '  $BF                 'clear the read/write bit

    outa[ CSPIN_    ] := 0  'starts SPI sequence
    outa[ CLKPIN_   ] := 0  'clk pin is low
    dira[ DATAPIN_  ] := 1

'this sends out the address of the register to read    
         Repeat  index from 7 to 0      ' from 7 to 0
         
               BitOut := Addr 
               BitOut >>=   Index       'rotate to right
               BitOut &=  %0000_0001
               outa[ DATAPIN_ ]  :=    BitOut
               waitcnt(clkfreq / 20_000 + cnt )
               
               outa[ CLKPIN_  ]  := 1 
               waitcnt(clkfreq / 20_000 + cnt )                '%0101_0110

               outa[ CLKPIN_  ]  := 0 


               
    ' outa[ CLKPIN_  ]  := 0  
    ' waitcnt(clkfreq / 4000 + cnt ) 

 
'this sends out the address of the register to read

      dira[ DATAPIN_ ] := 0
      BitOut := %0000_0000         ' %1111
      
      Repeat  index from 0 to 7      
      
               BitOut <-=   1      'rotate to left
               
               BitOut :=  BitOut |   Ina[ DATAPIN_ ]
                
               waitcnt(clkfreq / 20_000 + cnt )
               outa[ CLKPIN_  ]  := 1 
               waitcnt(clkfreq / 20_000 + cnt )

               outa[ CLKPIN_  ]  := 0  
              ' waitcnt(clkfreq / 4000 + cnt ) 
  
  
   outa[ CSPIN_  ] := 1  

   return (  BitOut )


 

'===========================================================================================+============
PUB write(  CLKPIN_ , DATAPIN_ , CSPIN_ ,  Addr, Value)   | index  , BitOut
'===========================================================================================+============

    Addr <<= 1
    Addr := Addr |  %1000_0000              '  $BF                 'clear the read/write bit

      dira[  CLKPIN_   ] := 1
      dira[  CSPIN_    ] := 1
      dira[  DATAPIN_  ] := 1



    
    outa[ CSPIN_     ] := 0  'starts SPI sequence
    outa[ CLKPIN_    ] := 0  'clk pin is low
    outa[ DATAPIN_   ] := 0  'data low





    

'this sends out the address of the register to Write    
         Repeat  index from 7 to 0      ' from 7 to 0


         
               BitOut := Addr 
               BitOut >>=   Index       'rotate to left
               
                  
               BitOut &=  %0000_0001


               
              outa[ DATAPIN_ ]  :=  BitOut
              waitcnt(clkfreq / 10000 + cnt )
              
              outa[ CLKPIN_  ]  := 1 
              waitcnt(clkfreq / 10000 + cnt )
              
              outa[ CLKPIN_  ]  := 0 
             ' waitcnt(clkfreq / 1000 + cnt ) 
              

'this sends out the data to  the register to Write    
      Repeat  index from 7 to 0      ' from 7 to 0


         
               BitOut := Value 
               BitOut >>=   Index       'rotate to left
               
                  
               BitOut &=  %0000_0001


               
              outa[ DATAPIN_ ]  :=  BitOut
              waitcnt(clkfreq / 10000 + cnt )
              
              outa[ CLKPIN_  ]  := 1
              waitcnt(clkfreq / 10000 + cnt )
              
              outa[ CLKPIN_  ]  := 0
              
    waitcnt(clkfreq / 20000 + cnt ) 
    outa[ CLKPIN_  ]  := 1  
    outa[ CSPIN_     ] := 1  'ends SPI sequence





'===========================================================================================+============
'===========================================================================================+============
'===========================================================================================+============
'===========================================================================================+============
'===========================================================================================+============
'===========================================================================================+============

     
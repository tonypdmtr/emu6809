*
* This program prints the hex values from 0 to FF
*
         org       $FF00
stacktop equ       *
         org       $1000
begin    lds       #stacktop           initialize stack
         ldx       #Msg1
         ldy       #Msg1Len
         lbsr      print
         clra
         ldx       #Msg2
         ldy       #Msg2Len
loop     pshs      y
         ldy       #Msg2Num
         lbsr      HexIt
         puls      y
         lbsr      print
         inca
         bne       loop                until it goes back to zero
         ldx       #Msg3
         ldy       #Msg3Len
         bsr       print
         tfr       pc,d
         ldy       #Msg4Num
         bsr       HexIt
         leay      2,y
         tfr       b,a
         bsr       HexIt
         ldx       #Msg4
         ldy       #Msg4Len
         bsr       print
         swi2
         fcb       $06                 exit program/emulator
Msg1     fcc       /OS-9 program running under the emulator/
         fcb       13,10
         fcc       /Press F10 to exit/
         fcb       13,10,10
Msg1Len  equ       *-Msg1
Msg2     fcc       / /
Msg2Num  fcc       /??/
         fcc       / /
Msg2Len  equ       *-Msg2
Msg3     fcb       13,10,10
         fcc       /Complete!/
         fcb       13,10
Msg3Len  equ       *-Msg3
Msg4     fcc       /PC: /
Msg4Num  fcc       /????/
         fcb       13,10
Msg4Len  equ       *-Msg4
***************************************
* Print string via OS-9
* X points to the string
* Y holds the length
print    pshs      d,cc
         lda       #1
         swi2
         fcb       $8A
         puls      d,cc,pc
***************************************
* Convert the value in A into 2-hex
* string and store it in where Y points
* A holds number to convert
* Y points to string location
HexIt    pshs      a
         sta       1,y
         anda      #$F0
         lsra
         lsra
         lsra
         lsra
         bsr       Hex2
         sta       ,y
         lda       1,y
         anda      #$0F
         bsr       Hex2
         sta       1,y
         puls      a
         rts
Hex2     cmpa      #9
         bgt       letter
         adda      #'0
         bra       exit
letter   suba      #10
         adda      #'A
exit     rts

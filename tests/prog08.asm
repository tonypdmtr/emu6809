*
* This program prints the ASCII table and their hex values
*
F_exit   equ     $06
I_write  equ     $8A
I_writln equ     $8C
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
loop     cmpa      #$1A                if 7,8,9,10,13,$1A convert to space
         beq       Convert
         cmpa      #7
         blt       GoOn
         cmpa      #13
         bgt       GoOn
         cmpa      #11
         beq       GoOn
         cmpa      #12
         beq       GoOn
Convert  ldb       #32                 get a space
         stb       Msg2Val
         bra       GoOn2
GoOn     sta       Msg2Val
GoOn2    pshs      y
         ldy       #Msg2Num
         lbsr      HexIt
         puls      y
         lbsr      print
         inca
         tsta
*        bpl       loop                until we are done (128 characters)
         bne       loop                until we are done (256 characters)
         ldx       #Msg3
         ldy       #Msg3Len
         lbsr      print
         swi2
         fcb       F_exit              exit program/emulator
Msg1     fcc       /Test program: SAMPLE2/
         fcb       13,10,10
         fcc       /ASCII characters and their hex values/
         fcb       13,10
         fcc       /Press F10 to exit at any time/
         fcb       10
Msg1Len  equ       *-Msg1
Msg2     fcc       /ASCII Character: /
Msg2Val  fcb       0                   put character here
         fcc       / --> $/
Msg2Num  fcc       /??/
Msg2Len  equ       *-Msg2
Msg3     fcb       13,10
         fcc       /(You are now back to MS-DOS)/
Msg3Len  equ       *-Msg3
***************************************
* Print string via OS-9
* X points to the string
* Y holds the length
print    pshs      d,cc
         lda       #1
         swi2
         fcb       I_writln
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

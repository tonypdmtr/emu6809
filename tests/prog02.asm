*
* Display the ASCII codes in ascending mode
*

*
* OS-9 mnemonics
*
StdOut   equ   $01
F_exit   equ   $06
I_write  equ   $8A
I_writln equ   $8C
         ldx   #data
         leax  255,x
         lda   #255
loop     sta   ,x
         leax  -1,x
         deca
         bne   loop
         ldx   #data
         ldy   #256
         lda   #StdOut
         swi2
         fcb   I_writln
         tfr   y,d
         ldy   #msgnum
         lbsr  HexIt
         leay  2,y
         exg   a,b
         lbsr  HexIt
         ldx   #msg
         ldy   #msglen
         lda   #StdOut
         swi2
         fcb   I_writln
         swi2
         fcb   F_exit
data     rmb   256
msg      fcc   /You wrote /
msgnum   fcc   /???? (hex) characters./
msglen   equ   *-msg
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
         end

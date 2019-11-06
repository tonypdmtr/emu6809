*
* Just print a little message
*

*
* OS-9 mnemonics
*
StdOut   equ   $01
F_exit   equ   $06
I_write  equ   $8A
I_writln equ   $8C
         org   $2000
         nop
         bsr   start
loop     lbra  loop
start    ldx   #data
         ldy   #1
         lda   ,x
         lda   1,x
         lda   ,x+
         ldx   #message
         ldy   #msglen
         lda   #StdOut
         swi2
         fcb   I_writln
         swi2
         fcb   F_exit
         rts
message  fcc   /This program simply prints this line!/
msglen   equ   *-message
data     equ   *
         fcb   1,121,3,4,5,6,7
         end

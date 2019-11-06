*
* Upper case letters within quotes
*
         lds   #stack
         ldb   #26           for all uppercase letters
         lda   #'A
         bsr   loop
halt     equ   *
         jmp   halt
data     equ   *
         fcc   /'/
var      equ   *
         fcb   0
         fcc   /' /
datalen  equ   4
loop     equ   *
         sta   var
         inca
         decb
         bsr   printit
         bne   loop          are we done yet?
         rts
printit  equ   *
         pshs  x,y,d,cc
         ldx   #data
         ldy   #datalen
         lda   #1
         swi2
         fcb   $8A
         puls  x,y,d,cc,pc   restore regs and return
         org   $F000         top of stack
         rmb   256           stack area
stack    equ   *
         end

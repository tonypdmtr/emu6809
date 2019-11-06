*
* Test for unimplemented OS/9 function calls
*
         swi2
         fcb   0
         ldx   #data
         leax  256,x
         lda   #255
loop     equ   *
         sta   ,x
         leax  -1,x
         deca
         bne   loop
         swi2
         fcb   0
exit     equ   *
         jmp   exit
data     equ   *
         rmb   256
         end

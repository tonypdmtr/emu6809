*
* This program inputs a string and then prints it out
*
StdInp   equ     $00
StdOut   equ     $01
F_exit   equ     $06
I_read   equ     $89
I_write  equ     $8A
I_readln equ     $8B
I_writln equ     $8C
         org       $FF00
stacktop equ       *
         org       $1000
begin    lds       #stacktop           initialize stack
         ldx       #Msg1
         ldy       #Msg1Len
         lbsr      print
         ldx       #Msg2
         ldy       #Msg2Len
         lda       #StdInp
         swi2
         fcb       I_readln
         pshs      y
         ldx       #Msg3
         ldy       #Msg3Len
         lda       #StdOut
         lbsr      print
         puls      y
         ldx       #Msg2
         lda       #StdOut
         swi2
         fcb       I_writln
         clrb
         swi2
         fcb       F_exit
Msg1     fcc       /This program demonstrates input-output under OS-9/
         fcb       13,10
         fcc       /as well as subroutine calling./
         fcb       13,10
         fcc       /Please enter a string > /
Msg1Len  equ       *-Msg1
Msg2     fcc       /................................................../
Msg2Len  equ       *-Msg2
Msg3     fcc       /You entered the string: /
Msg3Len  equ       *-Msg3
***************************************
* Print string via OS-9
* X points to the string
* Y holds the length
print    pshs      d,cc
         lda       #1
         swi2
         fcb       I_write
         puls      d,cc,pc

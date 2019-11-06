*
*
*
       org   $2000
       lbra  begin
Length rmb   2
Name   rmb   50
NamLen equ   *-Name
Ask    fcc   /This program inputs a string, counts up to $500 and prints the string/
       fcb   13,10
       fcc   /This illustrates the relative execution speed of a program running/
       fcb   13,10
       fcc   /under the emulator./
       fcb   13,10,13,10
       fcc   /Enter a string: /
AskLen equ   *-Ask
Msg    fcc   /Counting up to $500/
MsgLen equ   *-Msg
Msg1   fcb   7
       fcc   /Done counting to $500.  String: /
Ms1Len equ  *-Msg1
begin  lds   #Stack
       ldx   #Ask
       ldy   #AskLen
       lda   #1
       swi2
       fcb   $8a
       ldx   #Name
       ldy   #NamLen
       lda   #0
       swi2
       fcb   $89
       sty   Length
       ldx   #Msg
       ldy   #MsgLen
       lda   #1
       swi2
       fcb   $8c
       ldd   #0
       bsr   loop
       ldx   #Msg1
       ldy   #Ms1Len
       lda   #1
       swi2
       fcb   $8a
       ldx   #Name
       ldy   Length
       lda   #1
       swi2
       fcb   $8c
       swi2
       fcb   6
loop   cmpd  #$500
       beq   exit
       ldx   #addit
       jsr   ,x
       bra   loop
exit   rts
addit  addd  #1
       rts
       rmb   1000
Stack  equ   *
       end

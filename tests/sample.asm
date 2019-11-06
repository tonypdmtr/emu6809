**************************************************************
* Programmer: Tony Papadimitriou <tonyp@acm.org>             *
* Program   : SAMPLE                                         *
* Includes  : Nothing                                        *
* Links     : Nothing                                        *
* Created   : March 22, 1991                                 *
* Updated   : March 28, 1991                                 *
* Language  : (MSDOS/OS9) 6809 Assembler                     *
* Purpose   : Prove the functionality of the 6809/OS-9 prog. *
* -------------------- Version History --------------------- *
* 1.00      : Original                                       *
**************************************************************

********** OS-9 DEFINITIONS **********

F_Exit     equ     $06                 B=error code (no error, B=0)
I_Read     equ     $89                 A=handle, X->string, Y=length
I_Write    equ     $8A                 A=handle, X->string, Y=length
I_Readln   equ     $8B                 A=handle, X->string, Y=length
I_Writln   equ     $8C                 A=handle, X->string, Y=length

OS9_StdIn  equ     $00
OS9_StdOut equ     $01
OS9_StdErr equ     $02

********** PROGRAM DEFINITIONS **********

StackTop   equ     $F000
LowLimit   equ     $100
UpLimit    equ     $400

********** PROGRAM CODE **********

           org     $100
Begin      jmp     Start,pcr           skip data segment
********** DATA SEGMENT **********
Error      rmb     1                   error code
Counter    rmb     1                   buffer position counter
Buffer     rmb     75                  dump line
BufferLen  equ     *-Buffer
Msg000     fcb     $0d,$0a
           fcc     /OS-9 Memory Dumper ver. 1.00/
           fcb     $0d,$0a
           fcc     /Copyright (c) 1991 by Tony G. Papadimitriou/
           fcb     $0d,$0a
Len000     equ     *-Msg000
Msg001     fcc     /Addr 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F   0123456789ABCDEF/
           fcb     $0d,$0a
           fcc     /---- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --   ----------------/
Len001     equ     *-Msg001
ErrMsg     fcc     /*** Program terminated with error code /
ErrCode    fdb     ' '
ErrLen     equ     *-ErrMsg
********** CODE SEGMENT
Start      lds     #StackTop           initialize stack pointer
           lda     #0                  initialize exit error code
           sta     Error,pcr
           bsr     ShwCprght           print the copyright message
           bsr     DoWork              do the dumping
           ldb     Error,pcr
           tstb    #0                  do we have an error?
           beq     GetOut              no, exit
           tfr     b,a                 get error code in A
           leax    ErrCode,pcr         point to error display buffer
           lbsr    ToHex               convert to a hex string
           lbsr    Beep
           leax    ErrMsg,pcr          point to error message
           ldy     #ErrLen             and get its length
           lbsr    Writeln
GetOut     swi2
           fcb     F_Exit              exit to OS-9
ShwCprght  equ     *
           leax    Msg000,pcr
           ldy     #Len000
           lbsr    Writeln
           rts
DoWork     equ     *
* print the header
           leax    Msg001,pcr
           ldy     #Len001
           lbsr    Writeln
* first clear the buffer with spaces
           leax    Buffer,pcr
           ldy     #BufferLen
           lda     #' '
ClearLoop  sta     ,x+
           leay    -1,y
           bne     ClearLoop
* initialize memory address and buffer pointer
           ldu     #LowLimit           point to the starting point
           leax    Buffer,pcr          point to output buffer
           clr     Counter,pcr         zero buffer position counter
           lbsr    PutAddress
           leax    1,x                 skip a space
* start decoding
MainLoop   lda     ,u+                 get a bute in A
           bsr     ToHex               convert to hex string
           cmpa    #' '                change to dot characters below space
           bhs     skip
           lda     #'.'                unprintable character masking
skip       pshs    x,d
           leax    Buffer,pcr
           ldb     Counter,pcr
           abx
           sta     55,x
           puls    x,d
           leax    1,x                 skip a space
           inc     Counter,pcr         adjust counter
           lda     Counter,pcr
           cmpa    #16
           blo     GoOn
           leax    Buffer,pcr          reset pointer to buffer
           clr     Counter,pcr         reset buffer position counter
           pshs    y
           ldy     #BufferLen
           lbsr    Writeln             print buffer
           lbsr    PutAddress
           leax    1,x                 skip a space
           puls    y
GoOn       cmpu    #UpLimit            have we reached the end?
           bne     MainLoop            if not, go on
           rts
PutAddress equ     *                   U=address, X->4-byte output buffer
           pshs    d
           tfr     u,d
           bsr     ToHex
           tfr     b,a
           bsr     ToHex
           puls    d,pc
ToHex      equ     *                   A=byte, X->2-byte output buffer
           pshs    d                   save D and flags
           tfr     a,b                 save A in B
           lsra                        down 4 bits
           lsra
           lsra
           lsra
           bsr     ToLetter            convert to hex letter in A
           sta     ,x+                 put it in buffer
           tfr     b,a                 get back original value
           anda    #$0F                mask off MSN
           bsr     ToLetter            --- do the above for second nibble ---
           sta     ,x+
           puls    d,pc                restore D and return
ToLetter   equ     *                   A=[IN] value (LSN) [OUT] hex digit
           cmpa    #$0A                if less than 10, it's a number
           blo     ToNumber
           suba    #$0A
           adda    #'A'
           rts
ToNumber   adda    #'0'
           rts

********** SYSTEM SUBROUTINES **********

Beep       equ     *                   Ring the bell
           bra     Beeper
Bell       fcb     7
Beeper     pshs    x,y
           leax    Bell,pcr
           ldy     #1
           bsr     Write
           puls    x,y,pc

Writeln    equ     *                   Display a string followed by newline
           pshs    d
           lda     #OS9_StdOut
           swi2
           fcb     I_Writln
           puls    d,pc

Write      equ     *                   Display a string
           pshs    d
           lda     #OS9_StdOut
           swi2
           fcb     I_Write
           puls    d,pc

Readln     equ     *                   Read a string followed by newline
           pshs    d
           lda     #OS9_StdIn
           swi2
           fcb     I_Readln
           puls    d,pc

Read       equ     *                   Read a string
           pshs    d
           lda     #OS9_StdIn
           swi2
           fcb     I_Read
           puls    d,pc

           end     Begin

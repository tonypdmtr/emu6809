;*******************************************************************************
; Include: OPCODES2
; Version: 1.20
; Written: July 15, 1990
; Updated: Friday, August 12, 1994  7:52 pm
; Author : Tony G. Papadimitriou
; Purpose: This is an include file with half the opcode routines used by
;          the MC6809E.ASM program, an enhanced version of the MC6809E
;          emulator program originally written in Turbo Pascal.  Because
;          it is completely written in Assembly language there should be
;          a dramatic speed improvement over the Pascal version.
;*******************************************************************************

proc       mcSUBA
           call    GetEffAddr
           cmp     [OpCode],80h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[A]              ; swap with accumulator
           sub     al,[A]              ; and do the subtraction
           mov     [A],al              ; and save the result
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSUBA

proc       mcCMPA
           call    GetEffAddr
           cmp     [OpCode],81h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[A]              ; swap with accumulator
           cmp     al,[A]              ; and do the comparison
           xchg    al,[A]              ; and swap back
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcCMPA

proc       mcSBCA
           call    GetEffAddr
           cmp     [OpCode],82h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[A]              ; swap with accumulator
           sub     al,[A]              ; and do the subtraction
           test    [CC],CarryMask      ; is the carry flag set?
           jz      @@cont              ; no, go on
           dec     al                  ; else subtract one more
@@cont:    mov     [A],al              ; and save the result
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSBCA

proc       mcSUBD
           call    GetEffAddr
           cmp     [OpCode],83h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           xchg    ax,[D]              ; swap with accumulator
           sub     ax,[D]              ; and do the subtraction
           mov     [D],ax              ; and save the result
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSUBD

proc       mcANDA
           call    GetEffAddr
           cmp     [OpCode],84h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[A]              ; swap with accumulator
           and     al,[A]              ; and do the logical AND
           xchg    al,[A]              ; and swap back
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcANDA

proc       mcBITA
           call    GetEffAddr
           cmp     [OpCode],85h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           push    [D]
           xchg    al,[A]              ; swap with accumulator
           and     al,[A]              ; and do the logical AND
           pop     [D]
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcBITA

proc       mcLDA
           call    GetEffAddr
           cmp     [OpCode],86h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           mov     [A],al              ; put it in 6809 register
           cmp     al,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcLDA

proc       mcEORA
           call    GetEffAddr
           cmp     [OpCode],88h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xor     al,[A]              ; put it in 6809 register
           mov     [A],al              ; and save it after operation
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcEORA

proc       mcADCA
           call    GetEffAddr
           cmp     [OpCode],89h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[A]              ; swap with accumulator
           add     al,[A]              ; and do the addition
           test    [CC],CarryMask      ; is the carry flag set?
           jz      @@cont              ; no, go on
           inc     al                  ; else add one more
@@cont:    mov     [A],al              ; and save the result
           pushf                       ; first clear affected flags
           and     [CC],11010000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       lahf
           test    ah,00000100b        ; check auxiliary flag
           jz      @@4                 ; skip if clear
           SHalfCarry
@@4:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcADCA

proc       mcORA
           call    GetEffAddr
           cmp     [OpCode],8Ah        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           or      al,[A]              ; put it in 6809 register
           mov     [A],al              ; and save it after operation
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcORA

proc       mcADDA
           call    GetEffAddr
           cmp     [OpCode],8Bh        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[A]              ; swap with accumulator
           add     al,[A]              ; and do the addition
           mov     [A],al              ; and save the result
           pushf                       ; first clear affected flags
           and     [CC],11010000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       lahf
           test    ah,00000100b        ; check auxiliary flag
           jz      @@4                 ; skip if clear
           SHalfCarry
@@4:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcADDA

proc       mcCMPX
           call    GetEffAddr
           cmp     [OpCode],8Ch        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           xchg    ax,[X]              ; swap with accumulator
           cmp     ax,[X]              ; and do the comparison
           xchg    ax,[X]              ; and swap back
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcCMPX

proc       mcBSR
           call    GetEffAddr
           cmp     [OpCode],17h        ; is it a long or short branch?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@exit
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@exit:    dec     [S]
           dec     [S]
           mov     si,[S]
           push    ax
           mov     ax,[PC]
           PutWord
           pop     ax
           add     ax,[PC]
           mov     [PC],ax
           ret
endp       mcBSR

proc       mcLDX
           call    GetEffAddr
           cmp     [OpCode],8Eh        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           mov     [X],ax              ; put it in 6809 register
           cmp     ax,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcLDX

proc       mcSTA
           mov     al,[A]              ; get the 6809 register
           call    GetEffAddr
           PutByte
           cmp     al,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSTA

proc       mcSTX
           mov     ax,[X]              ; get the 6809 register
           call    GetEffAddr
           PutWord
           cmp     ax,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSTX

proc       mcJSR
           call    GetEffAddr
           push    si
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[PC]
           PutWord
           pop     si
           mov     [PC],si
           ret
endp       mcJSR

proc       mcSUBB
           call    GetEffAddr
           cmp     [OpCode],0C0h       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[B]              ; swap with accumulator
           sub     al,[B]              ; and do the subtraction
           mov     [B],al              ; and save the result
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSUBB

proc       mcCMPB
           call    GetEffAddr
           cmp     [OpCode],0C1h       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[B]              ; swap with accumulator
           cmp     al,[B]              ; and do the comparison
           xchg    al,[B]              ; and swap back
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcCMPB

proc       mcSBCB
           call    GetEffAddr
           cmp     [OpCode],0C2h       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[B]              ; swap with accumulator
           sub     al,[B]              ; and do the subtraction
           test    [CC],CarryMask      ; is the carry flag set?
           jz      @@cont              ; no, go on
           dec     al                  ; else subtract one more
@@cont:    mov     [B],al              ; and save the result
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSBCB

proc       mcADDD
           call    GetEffAddr
           cmp     [OpCode],0C3h       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           xchg    ax,[D]              ; swap with accumulator
           add     ax,[D]              ; and do the addition
           mov     [D],ax              ; and save the result
           pushf                       ; first clear affected flags
           and     [CC],11010000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       lahf
           test    ah,00000100b        ; check auxiliary flag
           jz      @@4                 ; skip if clear
           SHalfCarry
@@4:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcADDD

proc       mcANDB
           call    GetEffAddr
           cmp     [OpCode],0C4h       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[B]              ; swap with accumulator
           and     al,[B]              ; and do the logical AND
           xchg    al,[B]              ; and swap back
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcANDB

proc       mcBITB
           call    GetEffAddr
           cmp     [OpCode],0C5h       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           push    [D]
           xchg    al,[B]              ; swap with accumulator
           and     al,[B]              ; and do the logical AND
           pop     [D]
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcBITB

proc       mcLDB
           call    GetEffAddr
           cmp     [OpCode],0C6h       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           mov     [B],al              ; put it in 6809 register
           cmp     al,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcLDB

proc       mcSTB
           mov     al,[B]              ; get the 6809 register
           call    GetEffAddr
           PutByte
           cmp     al,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSTB

proc       mcEORB
           call    GetEffAddr
           cmp     [OpCode],0C8h       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xor     al,[B]              ; put it in 6809 register
           mov     [B],al              ; and save it after operation
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcEORB

proc       mcADCB
           call    GetEffAddr
           cmp     [OpCode],0C9h       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[B]              ; swap with accumulator
           add     al,[B]              ; and do the addition
           test    [CC],CarryMask      ; is the carry flag set?
           jz      @@cont              ; no, go on
           inc     al                  ; else add one more
@@cont:    mov     [A],al              ; and save the result
           pushf                       ; first clear affected flags
           and     [CC],11010000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       lahf
           test    ah,00000100b        ; check auxiliary flag
           jz      @@4                 ; skip if clear
           SHalfCarry
@@4:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcADCB

proc       mcORB
           call    GetEffAddr
           cmp     [OpCode],0CAh       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           or      al,[B]              ; put it in 6809 register
           mov     [B],al              ; and save it after operation
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcORB

proc       mcADDB
           call    GetEffAddr
           cmp     [OpCode],0CBh       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
@@0:       GetByte
           xchg    al,[B]              ; swap with accumulator
           add     al,[B]              ; and do the addition
           mov     [B],al              ; and save the result
           pushf                       ; first clear affected flags
           and     [CC],11010000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       lahf
           test    ah,00000100b        ; check auxiliary flag
           jz      @@4                 ; skip if clear
           SHalfCarry
@@4:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcADDB

proc       mcLDD
           call    GetEffAddr
           cmp     [OpCode],0CCh       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           mov     [D],ax              ; put it in 6809 register
           cmp     ax,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcLDD

proc       mcSTD
           mov     ax,[D]              ; get the 6809 register
           call    GetEffAddr
           PutWord
           cmp     ax,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSTD

proc       mcLDU
           call    GetEffAddr
           cmp     [OpCode],0CEh       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           mov     [U],ax              ; put it in 6809 register
           cmp     ax,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcLDU

proc       mcSTU
           mov     ax,[U]              ; get the 6809 register
           call    GetEffAddr
           PutWord
           cmp     ax,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSTU

proc       mcSWI2
           cmp     [OS9_On],1          ; is OS9 emulation active?
           jne     @@cont              ; no, continue
           jmp     OS9                 ; hook for OS/9 operating system
@@cont:    SEntireFlag
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[PC]
           PutWord
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[U]
           PutWord
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[Y]
           PutWord
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[X]
           PutWord
           dec     [S]
           mov     si,[S]
           mov     al,[DPR]
           PutByte
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[D]
           PutWord
           dec     [S]
           mov     si,[S]
           mov     al,[CC]
           PutByte
           mov     si,0FFF4h           ; point to 6809 interrupt vector
           GetWord                     ; get vector
           mov     [PC],ax             ; and put it in PC
           ret                         ; alternate exit
endp       mcSWI2

proc       mcCMPD
           call    GetEffAddr
           cmp     [OpCode],83h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           xchg    ax,[D]              ; swap with accumulator
           cmp     ax,[D]              ; and do the comparison
           xchg    ax,[D]              ; and swap back
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcCMPD

proc       mcCMPY
           call    GetEffAddr
           cmp     [OpCode],8Ch        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           xchg    ax,[Y]              ; swap with accumulator
           cmp     ax,[Y]              ; and do the comparison
           xchg    ax,[Y]              ; and swap back
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcCMPY

proc       mcSWI3
           SEntireFlag
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[PC]
           PutWord
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[U]
           PutWord
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[Y]
           PutWord
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[X]
           PutWord
           dec     [S]
           mov     si,[S]
           mov     al,[DPR]
           PutByte
           dec     [S]
           dec     [S]
           mov     si,[S]
           mov     ax,[D]
           PutWord
           dec     [S]
           mov     si,[S]
           mov     al,[CC]
           PutByte
           mov     si,0FFF2h           ; point to 6809 interrupt vector
           GetWord                     ; get vector
           mov     [PC],ax             ; and put it in PC
           ret
endp       mcSWI3

proc       mcCMPU
           call    GetEffAddr
           cmp     [OpCode],83h        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           xchg    ax,[U]              ; swap with accumulator
           cmp     ax,[U]              ; and do the comparison
           xchg    ax,[U]              ; and swap back
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcCMPU

proc       mcCMPS
           call    GetEffAddr
           cmp     [OpCode],8Ch        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           xchg    ax,[S]              ; swap with accumulator
           cmp     ax,[S]              ; and do the comparison
           xchg    ax,[S]              ; and swap back
           pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jno     @@1                 ; is it the overflow case?
           SOverflow
@@1:       jnz     @@2                 ; is it the zero case?
           SZero
@@2:       jnc     @@3                 ; is it the carry case?
           SCarry
@@3:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcCMPS

proc       mcSTY
           mov     ax,[Y]              ; get the 6809 register
           call    GetEffAddr
           PutWord
           cmp     ax,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSTY

proc       mcSTS
           mov     ax,[S]              ; get the 6809 register
           call    GetEffAddr
           PutWord
           cmp     ax,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcSTS

proc       mcLDY
           call    GetEffAddr
           cmp     [OpCode],8Eh        ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           mov     [Y],ax              ; put it in 6809 register
           cmp     ax,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcLDY

proc       mcLDS
           call    GetEffAddr
           cmp     [OpCode],0CEh       ; is it the immediate mode?
           jne     @@0
           inc     [PC]
           inc     [PC]
@@0:       GetWord
           mov     [S],ax              ; put it in 6809 register
           cmp     ax,0
           pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcLDS

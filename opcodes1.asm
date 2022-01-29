;*******************************************************************************
; Include: OPCODES1
; Version: 1.20
; Written: July 15, 1990
; Updated: Friday, August 12, 1994  7:52 pm
; Author : Tony G. Papadimitriou
; Purpose: This is an include file with half the opcode routines used by
;          the MC6809E.ASM program, an enhanced version of the MC6809E
;          emulator program originally written in Turbo Pascal.  Because
;          it is completely written in Assembly language there should be
;          a dramatic speed improvement over the Pascal version.
;          Note: SYNC instruction is currently not implemented
;*******************************************************************************

proc       mcERROR                     ; special routine to handle invalid ops
           mov     ax,130              ; invalid opcode error
           call    Errors
           ret
endp       mcERROR

;*******************************************************************************

proc       mcNEG
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    neg     [A]
           jmp     short @@flags
@@AccB:    neg     [B]
           jmp     short @@flags
@@Next:    call    GetEffAddr
           neg     [byte es:si]
@@flags:   pushf                       ; first clear affected flags
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
endp       mcNEG

;*******************************************************************************

proc       mcCOM
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    not     [A]
           jmp     short @@flags
@@AccB:    not     [B]
           jmp     short @@flags
@@Next:    call    GetEffAddr
           not     [byte es:si]
@@flags:   pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcCOM

;*******************************************************************************

proc       mcLSR
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    shr     [A],1
           jmp     short @@flags
@@AccB:    shr     [B],1
           jmp     short @@flags
@@Next:    call    GetEffAddr
           shr     [byte es:si],1
@@flags:   pushf                       ; first clear affected flags
           and     [CC],11110010b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jnc     @@exit              ; is it the Carry case?
           SCarry
@@exit:    ret
endp       mcLSR

;*******************************************************************************

proc       mcROR
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    ror     [A],1
           jmp     short @@flags
@@AccB:    ror     [B],1
           jmp     short @@flags
@@Next:    call    GetEffAddr
           ror     [byte es:si],1
@@flags:   pushf                       ; first clear affected flags
           and     [CC],11110010b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@2                 ; is it the negative case?
           SNegative
@@2:       jnc     @@exit              ; is it the Carry case?
           SCarry
@@exit:    ret
endp       mcROR

;*******************************************************************************

proc       mcASR
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    sar     [A],1
           jmp     short @@flags
@@AccB:    sar     [B],1
           jmp     short @@flags
@@Next:    call    GetEffAddr
           sar     [byte es:si],1
@@flags:   pushf                       ; first clear affected flags
           and     [CC],11110010b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@2                 ; is it the negative case?
           SNegative
@@2:       jnc     @@exit              ; is it the Carry case?
           SCarry
@@exit:    ret
endp       mcASR

;*******************************************************************************

proc       mcASL
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    sal     [A],1
           jmp     short @@flags
@@AccB:    sal     [B],1
           jmp     short @@flags
@@Next:    call    GetEffAddr
           sal     [byte es:si],1
@@flags:   pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@2                 ; is it the negative case?
           SNegative
@@2:       jno     @@3                 ; is it the overflow case?
           SOverflow
@@3:       jnc     @@exit              ; is it the Carry case?
           SCarry
@@exit:    ret
endp       mcASL

;*******************************************************************************

proc       mcROL
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    rol     [A],1
           jmp     short @@flags
@@AccB:    rol     [B],1
           jmp     short @@flags
@@Next:    call    GetEffAddr
           rol     [byte es:si],1
@@flags:   pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@2                 ; is it the negative case?
           SNegative
@@2:       jno     @@3                 ; is it the overflow case?
           SOverflow
@@3:       jnc     @@exit              ; is it the Carry case?
           SCarry
@@exit:    ret
endp       mcROL

;*******************************************************************************

proc       mcDEC
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    dec     [A]
           jmp     short @@flags
@@AccB:    dec     [B]
           jmp     short @@flags
@@Next:    call    GetEffAddr
           dec     [byte es:si]
@@flags:   pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@2                 ; is it the negative case?
           SNegative
@@2:       jno     @@exit              ; is it the overflow case?
           SOverflow
@@exit:    ret
endp       mcDEC

;*******************************************************************************

proc       mcINC
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    inc     [A]
           jmp     short @@flags
@@AccB:    inc     [B]
           jmp     short @@flags
@@Next:    call    GetEffAddr
           inc     [byte es:si]
@@flags:   pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@2                 ; is it the negative case?
           SNegative
@@2:       jno     @@exit              ; is it the overflow case?
           SOverflow
@@exit:    ret
endp       mcINC

;*******************************************************************************

proc       mcTST
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    test    [A],0FFh
           jmp     short @@flags
@@AccB:    test    [B],0FFh
           jmp     short @@flags
@@Next:    call    GetEffAddr
           test    [byte es:si],0FFh
@@flags:   pushf                       ; first clear affected flags
           and     [CC],11110001b
           popf
           jnz     @@1                 ; is it the zero case?
           SZero
@@1:       jns     @@exit              ; is it the negative case?
           SNegative
@@exit:    ret
endp       mcTST

;*******************************************************************************

proc       mcJMP
           call    GetEffAddr
           mov     [PC],si
           ret
endp       mcJMP

;*******************************************************************************

proc       mcCLR
           mov     al,[OpCode]
           shr     al,4                ; MSN -> LSN
           cmp     al,4                ; check it for accumulators
           je      @@AccA
           cmp     al,5
           je      @@AccB
           jmp     short @@Next
@@AccA:    mov     [A],0
           jmp     short @@flags
@@AccB:    mov     [B],0
           jmp     short @@flags
@@Next:    call    GetEffAddr
           mov     [byte es:si],0
@@flags:   pushf                       ; first clear affected flags
           and     [CC],11110000b
           popf
@@exit:    ret
endp       mcCLR

;*******************************************************************************

proc       mcNOP
           ret
endp       mcNOP

;*******************************************************************************

proc       mcSYNC                      ; not implemented at this time
           ret
endp       mcSYNC

;*******************************************************************************

proc       mcDAA
           mov     al,[A]
           daa
           mov     [A],al
           pushf
           and     [CC],11110010b
           popf
           jns     @@1
           SNegative
@@1:       jnz     @@2
           SZero
@@2:       jnc     @@exit
           SCarry
@@exit:    ret
endp       mcDAA

;*******************************************************************************

proc       mcORCC
           mov     si,[PC]
           GetByte
           inc     [PC]
           or      [CC],al
           ret
endp       mcORCC

;*******************************************************************************

proc       mcANDCC
           mov     si,[PC]
           GetByte
           inc     [PC]
           and     [CC],al
           ret
endp       mcANDCC

;*******************************************************************************

proc       mcSEX
           mov     al,[B]
           cbw
           mov     [D],ax
           CNegative
           CZero
           jns     @@1
           SNegative
@@1:       jnz     @@exit
           SZero
@@exit:    ret
endp       mcSEX

;*******************************************************************************
; General purpose procedure (see EXG and TFR instructions)

proc       GetRegister                 ; get the value of the register in AL/AX
           cmp     al,0                ; is it D?
           je      @@D
           cmp     al,1                ; is it X?
           je      @@X
           cmp     al,2                ; is it Y?
           je      @@Y
           cmp     al,3                ; is it U?
           je      @@U
           cmp     al,4                ; is it S?
           je      @@S
           cmp     al,5                ; is it PC?
           je      @@PC
           cmp     al,8                ; is it A?
           je      @@A
           cmp     al,9                ; is it B?
           je      @@B
           cmp     al,0Ah              ; is it CC?
           je      @@CC
           cmp     al,0Bh              ; is it DP?
           je      @@DP
           jmp     short @@exit        ; otherwise, undefined register, exit
; 16-bit registers
@@D:       mov     ax,[D]
           jmp     short @@exit
@@X:       mov     ax,[X]
           jmp     short @@exit
@@Y:       mov     ax,[Y]
           jmp     short @@exit
@@U:       mov     ax,[U]
           jmp     short @@exit
@@S:       mov     ax,[S]
           jmp     short @@exit
@@PC:      mov     ax,[PC]
           jmp     short @@exit
; 8-bit registers
@@A:       mov     al,[A]
           jmp     short @@exit
@@B:       mov     al,[B]
           jmp     short @@exit
@@CC:      mov     al,[CC]
           jmp     short @@exit
@@DP:      mov     al,[DPR]
@@exit:    ret
endp       GetRegister

;*******************************************************************************
; Purpose: General purpose procedure (see EXG and TFR instructions)

proc       PutRegister                 ; save the value of BL/BX in the register
           cmp     al,0                ; is it D?
           je      @@D
           cmp     al,1                ; is it X?
           je      @@X
           cmp     al,2                ; is it Y?
           je      @@Y
           cmp     al,3                ; is it U?
           je      @@U
           cmp     al,4                ; is it S?
           je      @@S
           cmp     al,5                ; is it PC?
           je      @@PC
           cmp     al,8                ; is it A?
           je      @@A
           cmp     al,9                ; is it B?
           je      @@B
           cmp     al,0Ah              ; is it CC?
           je      @@CC
           cmp     al,0Bh              ; is it DP?
           je      @@DP
           jmp     short @@exit        ; otherwise, undefined register, exit
; 16-bit registers
@@D:       mov     [D],bx
           jmp     short @@exit
@@X:       mov     [X],bx
           jmp     short @@exit
@@Y:       mov     [Y],bx
           jmp     short @@exit
@@U:       mov     [U],bx
           jmp     short @@exit
@@S:       mov     [S],bx
           jmp     short @@exit
@@PC:      mov     [PC],bx
           jmp     short @@exit
; 8-bit registers
@@A:       mov     [A],bl
           jmp     short @@exit
@@B:       mov     [B],bl
           jmp     short @@exit
@@CC:      mov     [CC],bl
           jmp     short @@exit
@@DP:      mov     [DPR],bl
@@exit:    ret
endp       PutRegister

;*******************************************************************************

proc       mcEXG
           mov     si,[PC]
           GetByte
           and     al,10001000b        ; are they both the same size?
           cmp     al,10001000b
           je      @@8bit
           cmp     al,00000000b
           je      @@16bit
           jmp     short @@exit        ; cannot transfer different sizes
@@16bit:   GetByte
           shr     al,4                ; figure out the first register
           call    GetRegister         ; in AX
           mov     bx,ax               ; and save it in BX
           GetByte
           and     al,0Fh              ; figure out the second register
           call    GetRegister         ; in AX
           xchg    ax,bx               ; swap the two registers
           mov     dx,ax               ; save AX in DX
           GetByte
           shr     al,4                ; figure out the first register
           call    PutRegister         ; BX
           GetByte                     ; figure out the second register
           and     al,0Fh
           mov     bx,dx               ; get saved AX
           call    PutRegister         ; BX
           jmp     short @@exit
@@8bit:    GetByte
           shr     al,4                ; figure out the first register
           call    GetRegister         ; in AL
           mov     bl,al               ; and save it in BL
           GetByte
           and     al,0Fh              ; figure out the second register
           call    GetRegister         ; in AL
           xchg    al,bl               ; swap the two registers
           mov     dl,al               ; save AL in DL
           GetByte
           shr     al,4                ; figure out the first register
           call    PutRegister         ; BL
           GetByte                     ; figure out the second register
           and     al,0Fh
           mov     bl,dl               ; get saved AL
           call    PutRegister         ; BL
@@exit:    inc     [PC]
           ret
endp       mcEXG

;*******************************************************************************

proc       mcTFR
           mov     si,[PC]
           GetByte
           and     al,10001000b        ; are they both the same size?
           cmp     al,10001000b
           je      @@8bit
           cmp     al,00000000b
           je      @@16bit
           jmp     short @@exit        ; cannot transfer different sizes
@@16bit:   GetByte
           shr     al,4                ; figure out the first register
           call    GetRegister         ; in AX
           mov     bx,ax               ; move it to BX
           GetByte                     ; figure out the second register
           and     al,0Fh
           call    PutRegister         ; BX
           jmp     short @@exit
@@8bit:    GetByte
           shr     al,4                ; figure out the first register
           call    GetRegister         ; in AL
           mov     bl,al               ; move it to BL
           GetByte                     ; figure out the second register
           and     al,0Fh
           call    PutRegister         ; BL
@@exit:    inc     [PC]
           ret
endp       mcTFR

;*******************************************************************************

proc       mcBRA
           call    GetEffAddr
           cmp     [OpCode],16h        ; is it a long or short branch?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@exit
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@exit:    add     [PC],ax
           ret
endp       mcBRA

;*******************************************************************************

proc       mcBRN
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           inc     [PC]
           jmp     short @@exit
@@16bit:   inc     [PC]
           inc     [PC]
@@exit:    ret
endp       mcBRN

;*******************************************************************************

proc       mcBHI
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    mov     bl,[CC]
           and     bl,CarryMask+ZeroMask
           jnz     @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBHI

;*******************************************************************************

proc       mcBLS
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    mov     bl,[CC]
           and     bl,CarryMask+ZeroMask
           jz      @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBLS

;*******************************************************************************

proc       mcBHS
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    test    [CC],CarryMask
           jnz     @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBHS

;*******************************************************************************

proc       mcBLO
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    test    [CC],CarryMask
           jz      @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBLO

;*******************************************************************************

proc       mcBNE
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    test    [CC],ZeroMask
           jnz     @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBNE

;*******************************************************************************

proc       mcBEQ
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    test    [CC],ZeroMask
           jz      @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBEQ

;*******************************************************************************

proc       mcBVC
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    test    [CC],OverflowMask
           jnz     @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBVC

;*******************************************************************************

proc       mcBVS
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    test    [CC],OverflowMask
           jz      @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBVS

;*******************************************************************************

proc       mcBPL
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    test    [CC],NegativeMask
           jnz     @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBPL

;*******************************************************************************

proc       mcBMI
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    test    [CC],NegativeMask
           jz      @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBMI

;*******************************************************************************

proc       mcBGE
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    mov     bl,[CC]
           and     bl,NegativeMask+OverflowMask
           jz      @@ok
           cmp     bl,NegativeMask+OverflowMask
           je      @@ok
           jmp     short @@exit
@@ok:      add     [PC],ax
@@exit:    ret
endp       mcBGE

;*******************************************************************************

proc       mcBLT
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    mov     bl,[CC]
           and     bl,NegativeMask+OverflowMask
           jz      @@exit
           cmp     bl,NegativeMask+OverflowMask
           je      @@exit
           add     [PC],ax
@@exit:    ret
endp       mcBLT

;*******************************************************************************

proc       mcBGT
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    mov     bl,[CC]
           test    bl,ZeroMask
           jnz     @@exit
           and     bl,NegativeMask+OverflowMask
           jz      @@ok
           cmp     bl,NegativeMask+OverflowMask
           je      @@ok
           jmp     short @@exit
@@ok:      add     [PC],ax
@@exit:    ret
endp       mcBGT

;*******************************************************************************

proc       mcBLE
           call    GetEffAddr
           mov     al,[Paged]          ; is it a long or short branch?
           cmp     al,10h              ; PAGE2?
           je      @@16bit
           GetByte
           inc     [PC]
           cbw
           jmp     short @@done
@@16bit:   GetWord
           inc     [PC]
           inc     [PC]
@@done:    mov     bl,[CC]
           test    bl,ZeroMask
           jnz     @@ok
           and     bl,NegativeMask+OverflowMask
           jz      @@exit
           cmp     bl,NegativeMask+OverflowMask
           je      @@exit
@@ok:      add     [PC],ax
@@exit:    ret
endp       mcBLE

;*******************************************************************************

proc       mcLEAX
           call    GetEffAddr
           mov     [X],si
           and     [CC],11111011b
           cmp     si,0
           jnz     @@exit
           or      [CC],00000100b
@@exit:    ret
endp       mcLEAX

;*******************************************************************************

proc       mcLEAY
           call    GetEffAddr
           mov     [Y],si
           and     [CC],11111011b
           cmp     si,0
           jnz     @@exit
           or      [CC],00000100b
@@exit:    ret
endp       mcLEAY

;*******************************************************************************

proc       mcLEAS
           call    GetEffAddr
           mov     [S],si
           ret
endp       mcLEAS

;*******************************************************************************

proc       mcLEAU
           call    GetEffAddr
           mov     [U],si
           ret
endp       mcLEAU

;*******************************************************************************

proc       mcPSHS
           mov     si,[PC]
           GetByte
           inc     [PC]
           test    al,10000000b        ; PC?
           jz      @@1
           dec     [S]
           dec     [S]
           mov     bx,[PC]
           xchg    bh,bl
           mov     si,[S]
           mov     [es:si],bx
@@1:       test    al,01000000b        ; U?
           jz      @@2
           dec     [S]
           dec     [S]
           mov     bx,[U]
           xchg    bh,bl
           mov     si,[S]
           mov     [es:si],bx
@@2:       test    al,00100000b        ; Y?
           jz      @@3
           dec     [S]
           dec     [S]
           mov     bx,[Y]
           xchg    bh,bl
           mov     si,[S]
           mov     [es:si],bx
@@3:       test    al,00010000b        ; X?
           jz      @@4
           dec     [S]
           dec     [S]
           mov     bx,[X]
           xchg    bh,bl
           mov     si,[S]
           mov     [es:si],bx
@@4:       test    al,00001000b        ; DP?
           jz      @@5
           dec     [S]
           mov     bl,[DPR]
           mov     si,[S]
           mov     [es:si],bl
@@5:       test    al,00000100b        ; B?
           jz      @@6
           dec     [S]
           mov     bl,[B]
           mov     si,[S]
           mov     [es:si],bl
@@6:       test    al,00000010b        ; A?
           jz      @@7
           dec     [S]
           mov     bl,[A]
           mov     si,[S]
           mov     [es:si],bl
@@7:       test    al,00000001b        ; CC?
           jz      @@exit
           dec     [S]
           mov     bl,[CC]
           mov     si,[S]
           mov     [es:si],bl
@@exit:    ret
endp       mcPSHS

;*******************************************************************************

proc       mcPULS
           mov     si,[PC]
           GetByte
           inc     [PC]
           test    al,00000001b        ; CC?
           jz      @@1
           mov     si,[S]
           mov     bl,[es:si]
           inc     [S]
           mov     [CC],bl
@@1:       test    al,00000010b        ; A?
           jz      @@2
           mov     si,[S]
           mov     bl,[es:si]
           inc     [S]
           mov     [A],bl
@@2:       test    al,00000100b        ; B?
           jz      @@3
           mov     si,[S]
           mov     bl,[es:si]
           inc     [S]
           mov     [B],bl
@@3:       test    al,00001000b        ; DP?
           jz      @@4
           mov     si,[S]
           mov     bl,[es:si]
           inc     [S]
           mov     [DPR],bl
@@4:       test    al,00010000b        ; X?
           jz      @@5
           mov     si,[S]
           mov     bx,[es:si]
           inc     [S]
           inc     [S]
           xchg    bh,bl
           mov     [X],bx
@@5:       test    al,00100000b        ; Y?
           jz      @@6
           mov     si,[S]
           mov     bx,[es:si]
           inc     [S]
           inc     [S]
           xchg    bh,bl
           mov     [Y],bx
@@6:       test    al,01000000b        ; U?
           jz      @@7
           mov     si,[S]
           mov     bx,[es:si]
           inc     [S]
           inc     [S]
           xchg    bh,bl
           mov     [U],bx
@@7:       test    al,10000000b        ; PC?
           jz      @@exit
           mov     si,[S]
           mov     bx,[es:si]
           inc     [S]
           inc     [S]
           xchg    bh,bl
           mov     [PC],bx
@@exit:    ret
endp       mcPULS

;*******************************************************************************

proc       mcPSHU
           mov     si,[PC]
           GetByte
           inc     [PC]
           test    al,10000000b        ; PC?
           jz      @@1
           dec     [U]
           dec     [U]
           mov     bx,[PC]
           xchg    bh,bl
           mov     si,[U]
           mov     [es:si],bx
@@1:       test    al,01000000b        ; S?
           jz      @@2
           dec     [U]
           dec     [U]
           mov     bx,[S]
           xchg    bh,bl
           mov     si,[U]
           mov     [es:si],bx
@@2:       test    al,00100000b        ; Y?
           jz      @@3
           dec     [U]
           dec     [U]
           mov     bx,[Y]
           xchg    bh,bl
           mov     si,[U]
           mov     [es:si],bx
@@3:       test    al,00010000b        ; X?
           jz      @@4
           dec     [U]
           dec     [U]
           mov     bx,[X]
           xchg    bh,bl
           mov     si,[U]
           mov     [es:si],bx
@@4:       test    al,00001000b        ; DP?
           jz      @@5
           dec     [U]
           mov     bl,[DPR]
           mov     si,[U]
           mov     [es:si],bl
@@5:       test    al,00000100b        ; B?
           jz      @@6
           dec     [U]
           mov     bl,[B]
           mov     si,[U]
           mov     [es:si],bl
@@6:       test    al,00000010b        ; A?
           jz      @@7
           dec     [U]
           mov     bl,[A]
           mov     si,[U]
           mov     [es:si],bl
@@7:       test    al,00000001b        ; CC?
           jz      @@exit
           dec     [U]
           mov     bl,[CC]
           mov     si,[U]
           mov     [es:si],bl
@@exit:    ret
endp       mcPSHU

;*******************************************************************************

proc       mcPULU
           mov     si,[PC]
           GetByte
           inc     [PC]
           test    al,00000001b        ; CC?
           jz      @@1
           mov     si,[U]
           mov     bl,[es:si]
           inc     [U]
           mov     [CC],bl
@@1:       test    al,00000010b        ; A?
           jz      @@2
           mov     si,[U]
           mov     bl,[es:si]
           inc     [U]
           mov     [A],bl
@@2:       test    al,00000100b        ; B?
           jz      @@3
           mov     si,[U]
           mov     bl,[es:si]
           inc     [U]
           mov     [B],bl
@@3:       test    al,00001000b        ; DP?
           jz      @@4
           mov     si,[U]
           mov     bl,[es:si]
           inc     [U]
           mov     [DPR],bl
@@4:       test    al,00010000b        ; X?
           jz      @@5
           mov     si,[U]
           mov     bx,[es:si]
           inc     [U]
           inc     [U]
           xchg    bh,bl
           mov     [X],bx
@@5:       test    al,00100000b        ; Y?
           jz      @@6
           mov     si,[U]
           mov     bx,[es:si]
           inc     [U]
           inc     [U]
           xchg    bh,bl
           mov     [Y],bx
@@6:       test    al,01000000b        ; S?
           jz      @@7
           mov     si,[U]
           mov     bx,[es:si]
           inc     [U]
           inc     [U]
           xchg    bh,bl
           mov     [S],bx
@@7:       test    al,10000000b        ; PC?
           jz      @@exit
           mov     si,[U]
           mov     bx,[es:si]
           inc     [U]
           inc     [U]
           xchg    bh,bl
           mov     [PC],bx
@@exit:    ret
endp       mcPULU

;*******************************************************************************

proc       mcRTS
           mov     si,[S]
           inc     [S]
           inc     [S]
           GetWord
           mov     [PC],ax
           ret
endp       mcRTS

;*******************************************************************************

proc       mcABX
           xor     ax,ax
           mov     al,[B]
           add     [X],ax
           ret
endp       mcABX

;*******************************************************************************

proc       mcRTI
           test    [CC],EntireFlagMask
           jz      @@short             ; entire state flag clear
           mov     si,[S]              ; get stack pointer
           GetWord
           mov     [D],ax
           inc     [S]
           inc     [S]
           mov     si,[S]              ; get stack pointer
           GetByte
           mov     [DPR],al
           inc     [S]
           mov     si,[S]              ; get stack pointer
           GetWord
           mov     [X],ax
           inc     [S]
           inc     [S]
           mov     si,[S]              ; get stack pointer
           GetWord
           mov     [Y],ax
           inc     [S]
           inc     [S]
           mov     si,[S]              ; get stack pointer
           GetWord
           mov     [U],ax
           inc     [S]
           inc     [S]
@@short:   mov     si,[S]              ; get stack pointer
           GetWord
           mov     [PC],ax
           inc     [S]
           inc     [S]
           ret
endp       mcRTI

;*******************************************************************************

proc       mcCWAI
           mov     si,[PC]
           GetByte
           inc     [PC]
           and     al,[CC]
           mov     [CC],al
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
           ret
endp       mcCWAI

;*******************************************************************************

proc       mcMUL
           mov     al,[A]              ; get first operand
           mul     [B]                 ; multiply with second operand
           mov     [D],ax              ; save result in accumulator D
           pushf                       ; reset affected flags
           and     [CC],11111010b
           popf
           jnz     @@1
           or      [CC],00000100b
@@1:       test    [B],10000000b       ; is bit 7 of B set?
           jz      @@exit              ; no, exit
           or      [CC],00000001b
@@exit:    ret
endp       mcMUL

;*******************************************************************************

proc       mcSWI
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
           SIRQ
           SFIRQ
           mov     si,0FFFAh           ; point to 6809 interrupt vector
           GetWord                     ; get vector
           mov     [PC],ax             ; and put it in PC
           ret
endp       mcSWI

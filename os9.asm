;*******************************************************************************
; Include: OS9
; Version: 1.00
; Written: August 13, 1990
; Updated: September 1, 1990
; Author : Tony G. Papadimitriou
; Purpose: This is an include file with code necessary to emulate the OS-9
;          operating system (Level One, Ver. 2.00.00)
; Note   : The OS-9 system is called through SWI2.  The byte following the
;          SWI2 instruction (what's pointed by [PC] for this program) holds
;          the function code for the OS-9 operation to be performed.
;          Parameters are function-dependent and are passed in the 6809
;          registers.  Function results are returned in the 6809 registers
;          B contains an error code if the Carry flag is set.
; 220129 : Removed redundant JMP instruction by reversing previous conditional jump
;*******************************************************************************

           DATASEG
OS9Table   dw      06h dup(OS9_Error)  ; unsupported/unknown function
           dw      F_exit              ; 06h
           dw      82h dup(OS9_Error)  ; unsupported/unknown function
           dw      I_read              ; 89h
           dw      I_write             ; 8Ah
           dw      I_readln            ; 8Bh
           dw      I_writln            ; 8Ch
           dw      73h dup(OS9_Error)  ; unsupported/unknown function

           CODESEG

;*******************************************************************************

proc       OS9
           mov     si,[PC]             ; get function code at PC
           GetByte                     ; in AL
           inc     [PC]                ; skip function byte
           mov     ah,0
           mov     bx,offset OS9Table
           shl     ax,1                ; multiply by 2 (size of entries)
           add     bx,ax
           jmp     [word bx]           ; call routine through table (indirect)
endp       OS9

;*******************************************************************************

proc       OS9_Error
           call    Beep
           push    ds
           push    cs
           pop     ds
           mov     dx,offset @@Msg
           mov     cx,@@MsgLen
           call    Write
           pop     ds
           ret
@@Msg      db      RETURN,LINEFEED
           db      "MC6809E/OS-9: Unimplemented OS-9 call",RETURN,LINEFEED
@@MsgLen   =       $ - @@Msg
endp       OS9_Error

;*******************************************************************************

proc       I_read
           xor     bx,bx
           mov     ah,DOS_READ_FROM_HANDLE
           mov     al,0
           mov     bl,[A]
           mov     dx,[X]
           mov     cx,[Y]
           push    ds
           push    es
           pop     ds
           int     DOS_FUNCTION
           pop     ds
           jc      @@Errors
           mov     [Y],ax
           mov     [B],0
           jmp     short @@exit
@@Errors:  SCarry
           mov     [B],al
@@exit:    ret
endp       I_read

;*******************************************************************************

proc       I_write
           xor     bx,bx
           mov     ah,DOS_WRITE_TO_HANDLE
           mov     al,0
           mov     bl,[A]
           mov     dx,[X]
           mov     cx,[Y]
           push    ds
           push    es
           pop     ds
           int     DOS_FUNCTION
           pop     ds
           jc      @@Errors
           mov     [Y],ax
           mov     [B],0
           jmp     short @@exit
@@Errors:  SCarry
           mov     [B],al
@@exit:    ret
endp       I_write

;*******************************************************************************

proc       I_readln
           xor     bx,bx
           mov     ah,DOS_READ_FROM_HANDLE
           mov     al,0
           mov     bl,[A]
           mov     dx,[X]
           mov     cx,[Y]
           push    ds
           push    es
           pop     ds
           int     DOS_FUNCTION
           pop     ds
           jc      @@Errors
           mov     [Y],ax
           mov     [B],0
           jmp     short @@exit
@@Errors:  SCarry
           mov     [B],al
@@exit:    ret
endp       I_readln

;*******************************************************************************

proc       I_writln
           xor     bx,bx
           mov     ah,DOS_WRITE_TO_HANDLE
           mov     al,0
           mov     bl,[A]
           mov     dx,[X]
           mov     cx,[Y]
           push    ds
           push    es
           pop     ds
           int     DOS_FUNCTION
           pop     ds
           jc      @@Errors
           mov     [Y],ax
           mov     [B],0
           mov     ah,DOS_WRITE_TO_HANDLE
           mov     al,0
           mov     dx,offset @@NewLine
           mov     cx,@@NewLineL
           push    ds
           push    cs
           pop     ds
           int     DOS_FUNCTION
           pop     ds
           jnc     @@exit
@@Errors:  SCarry
           mov     [B],al
@@exit:    ret
@@NewLine  db      RETURN,LINEFEED
@@NewLineL =       $ - @@NewLine
endp       I_writln

;*******************************************************************************

proc       F_exit
           mov     al,[B]
           mov     ah,DOS_TERMINATE_EXE
           int     DOS_FUNCTION
endp       F_exit

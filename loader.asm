;*******************************************************************************
; Include: LOADER
; Version: 1.00
; Written: July 15, 1990
; Updated: Sunday, August 14, 1994  4:38 am
; Author : Tony G. Papadimitriou
; Purpose: This is an include file with just the loader portion of the
;          emulator.  It may be replaced by a different loader without
;          affecting the functionality of the remaining program provided
;          the routine returns the same parameters to the caller.
;          This loader assumes that the first command line parameter is
;          a valid filename/path and that its contents are valid Motorola
;          S-19 records.  In any other case an error is returned and the
;          caller should terminate immediately.
; 940814 : Adjusted code for 386
;*******************************************************************************

           DATASEG

Handle     dw      ?                   ; input file handle
BufLen     equ     1024                ; size of input buffer
Buffer     db      BufLen dup(?)       ; input file buffer
StartAddr  dw      0                   ; address of first byte loaded
LoadPoint  dw      0                   ; address currently loading
EndAddr    dw      0                   ; address of last byte loaded
ExecAddr   dw      0                   ; execution address
ProgSize   dw      0                   ; program size
CheckSum   db      ?                   ; checksum used for each S19 line
Counter    dw      ?                   ; general purpose counter
LocalSize  dw      ?                   ; size of currently active buffer

           CODESEG

; Routine: UpCase
; Purpose: Convert a character to uppercase
; Input  : AL holds the character
; Output : AL holds the character in uppercase
proc       UpCase
           cmp     al,'a'
           jb      @@exit
           cmp     al,'z'
           ja      @@exit
           add     al,'A'-'a'
@@exit:    ret
endp       UpCase


; Routine: HexIt
; Purpose: Convert a 2-byte hex string in AX to its binary value in AL
; Input  : AX holds hex string to convert
; Output : AL holds binary value
; Note   : if there is an error, the value 0 is returned
proc       HexIt
           push    bx
           call    HexDigit
           mov     bl,al
           mov     al,ah
           call    HexDigit
           shl     al,4
           or      al,bl
           pop     bx
           ret
proc       HexDigit
           call    UpCase
           cmp     al,'0'
           jb      @@NoGood
           cmp     al,'F'
           ja      @@NoGood
           cmp     al,'9'
           jna     @@Number
           cmp     al,'A'
           jb      @@NoGood
           sub     al,'A'-10
           jmp     short @@exit
@@Number:  sub     al,'0'
           jmp     short @@exit
@@NoGood:  mov     al,0
@@exit:    ret
endp       HexDigit
endp       HexIt

; Routine: Convert
; Purpose: Convert an S19 formatted buffer to binary and load to memory
; Input  : AX holds number of butes read in buffer
; Output : CX holds number of characters to read next (1 -> BufLen)
;        : DX points to starting point in buffer for next read
;        : AX holds error code if any
proc       Convert
           mov     [LocalSize],ax      ; save size for later
           mov     [CheckSum],0        ; initialize CRC value
           push    bx                  ; save a few registers
           push    di
           push    si
           mov     si,offset Buffer    ; point to input buffer
           cld                         ; move upwards in buffer
           mov     al,[si]             ; get first byte from buffer in AL
           cmp     al,'S'              ; is it a valid Mototola S-record?
           je      @@GoOn              ; yes, continue
           mov     ax,128              ; "invalid S-record" error code
           jmp     @@exit              ; get out
@@hook:    jmp     @@setup
@@GoOn:    mov     al,[si+1]           ; get second byte from buffer in AL
           cmp     al,'9'              ; is it a 9 (end of file record)?
           mov     cx,0                ; in case we exit, CX = 0
           je      @@hook              ; yes, set up registers and exit
           mov     ax,[si+4]           ; get load address MSN in hex
           xchg    ah,al
           call    HexIt               ; convert AX hex string to value in AL
           mov     bh,al
           mov     bl,[CheckSum]       ; adjust CRC
           add     bl,al
           mov     [CheckSum],bl
           mov     ax,[si+6]           ; get load address LSN in hex
           xchg    ah,al
           call    HexIt               ; convert AX hex string to value in AL
           mov     bl,[CheckSum]       ; adjust CRC
           add     bl,al
           mov     [CheckSum],bl
           mov     ah,bh               ; now, AX holds load address
           mov     [LoadPoint],ax      ; save it
           cmp     [ProgSize],0        ; is this the first pass?
           jne     @@Skip1             ; no, go on
           mov     [StartAddr],ax      ; else save start address
@@Skip1:   mov     ax,[si+2]           ; get upper limit
           xchg    ah,al
           call    HexIt               ; convert AX hex string to value in AL
           mov     bl,al               ; adjust CRC
           add     bl,[CheckSum]
           mov     [CheckSum],bl
           mov     ch,0
           mov     cl,al               ; initialize inner loop
           sub     cl,3                ; UpperLimit - 3
           mov     di,[LoadPoint]      ; get loading point for this line
           add     si,8                ; point to first data byte
           mov     dx,10               ; initialize counter
           mov     [Counter],dx
@@loop:    lodsw                       ; get a hex 2-byte from buffer in AX
           inc     [Counter]           ; count bytes processed
           inc     [Counter]
           xchg    ah,al
           call    HexIt
           inc     [ProgSize]          ; just got one more character, count it
           stosb
           add     al,[CheckSum]       ; adjust CRC
           mov     [CheckSum],al
           loop    @@loop
           mov     [EndAddr],di        ; save ending address
           dec     [EndAddr]
           lodsw                       ; get CRC and increment SI
           xchg    ah,al
           call    HexIt
           not     al                  ; one's complement
           cmp     al,[CheckSum]       ; did we get the same CRC value?
           je      @@hook1             ; yes, continue
           mov     ax,129              ; checksum error
           jmp     @@exit
@@hook1:   inc     si                  ; skip over Carriage Return
           inc     si                  ; and Line Feed
           inc     [Counter]           ; also adjust counter
           inc     [Counter]
; let's move unused buffer to beginning of buffer
           push    es                  ; save 6809 segment
           push    ds                  ; copy DS to ES
           pop     es
           mov     di,offset Buffer    ; point to beginning of buffer
           mov     cx,BufLen           ; get buffer length
           sub     cx,[Counter]        ; figure out how many we must move
           cmp     cx,0                ; anything to move?
           je      @@last              ; no, go get more info into buffer
           push    cx
           rep movsb                   ; else, move it down
           pop     cx
           pop     es                  ; restore 6809 segment
           mov     ax,BufLen           ; how many do we load next?
           sub     ax,cx
           mov     cx,ax
           mov     dx,di               ; offset must be in DX
           xor     ax,ax               ; exit with no errors
           jmp     short @@exit        ; get out of here
@@last:    pop     es                  ; restore 6809 segment
           mov     cx,BufLen           ; fill buffer on next read
@@setup:   mov     dx,offset Buffer    ; point to buffer just in case
           xor     ax,ax               ; no error code
@@exit:    pop     si                  ; restore registers
           pop     di
           pop     bx
           ret
endp       Convert

; Routine: LoadProgram
; Purpose: Try loading the program passed as parameter #1
; Input  : None
; Output : ES:SI points to the execution address of the program
;        : AX holds a possible error code
;        : BX points to the beginning of the program
;        : DX points to the ending of the program
;        : CX holds the size of the program
proc       LoadProgram
           mov     [CheckSum],0        ; initialize checksum
           push    ds                  ; save current DS
           push    [PSP]               ; get the Program Segment Prefix
           pop     ds
           mov     dx,82h              ; offset 82h holds parameter list
           mov     bh,0
           mov     bl,[80h]            ; get parameter length
           test    bl,0FFh             ; check for zero length
           jz      @@nothing           ; get out without errors
           dec     bl                  ; exclude header space
           add     bx,dx
           mov     [byte bx],0         ; convert to ASCIIZ string
           mov     ah,DOS_OPEN_FILE
           mov     al,20h              ; sharing read mode with write denied
           int     DOS_FUNCTION
           pop     ds                  ; restore DS
           jc      @@errors            ; we got errors, AX has error code
           mov     [Handle],ax         ; save file handle
           jmp     short @@readit
@@errors:  jmp     @@exit              ; hook for long jump
@@readit:  mov     dx,offset LMsg      ; print "Loading..." message
           mov     cx,LMsgLen
           call    Write
           mov     cx,BufLen           ; initially fill the input buffer
           mov     dx,offset Buffer    ; initially at the start of buffer
@@loop:    mov     ah,DOS_READ_FROM_HANDLE
           mov     bx,[Handle]
           int     DOS_FUNCTION
           jc      @@exit
           cmp     ax,0                ; no more characters?
           je      @@close             ; yes, so close file, no errors
           call    Convert             ; convert S19 to binary and store it
           cmp     ax,0                ; did we get errors?
           jne     @@exit              ; yes, get out
           jmp     short @@loop        ; repeat until whole file is read
@@close:   call    Convert             ; convert the remaining of the buffer
           cmp     ax,0                ; did we get errors?
           jne     @@exit              ; yes, go print them
           cmp     cx,0                ; are we done yet?
           jne     @@close             ; no, go back and finish with buffer
           mov     ah,DOS_CLOSE_FILE
           mov     bx,[Handle]
           int     DOS_FUNCTION
           jc      @@exit              ; we got errors, AX has error code
           xor     ax,ax               ; else, make sure AX has no error code
           mov     bx,[StartAddr]
           mov     [ExecAddr],bx       ; assume start = execution address
           mov     dx,[ProgSize]
           add     dx,[StartAddr]      ; DX = EndAddr
           mov     [EndAddr],dx
           mov     cx,[ProgSize]
           mov     si,[ExecAddr]
           clc
@@exit:    ret
@@nothing: xor     ax,ax
           stc
           pop     ds
           jmp     short @@exit
endp       LoadProgram

;*******************************************************************************
; Program: MC6809E
; Version: 1.20
; Written: July 15, 1990
; Updated: Friday, August 12, 1994  7:52 pm
; Author : Tony G. Papadimitriou
; Purpose: This is an enhanced version of the MC6809E emulator program
;          originally written in Turbo Pascal.  Because it is completely
;          written in Assembly language there should be a dramatic speed
;          improvement over the Pascal version.
; Note   : This program requires DOS 3.x or later to run properly.
;          The program will abort if a lower version is found.
; Include: This file requires the following INCLUDE files to assemble
;          properly: DOS.INC BIOS.INC KBD.INC (originally supplied by Borland)
;          LOADER.ASM OPCODES1.ASM OPCODES2.ASM OS9.ASM (supplied by
;          Tony G. Papadimitriou)
; History: 940811 - Started 386 code optimization for speed
;                   The following optimizations were initiated:
;                   386 intructions that are shorter and run faster
;                   Consecutive ClearFlag macros optimized to single ANDs
;                   Consecutive SetFlag macros optimized to single ORs
;                   Where possible, operations performed directly on 6809 memory
;*******************************************************************************

           IDEAL
           %TITLE  "MC6809E Emulator ver. 1.20 (80386 Assembly Language)"
           MODEL   COMPACT
           STACK   4096
           P386

include    "dos.inc"
include    "bios.inc"
include    "kbd.inc"

CarryMask      = 01h
OverflowMask   = 02h
ZeroMask       = 04h
NegativeMask   = 08h
IRQMask        = 10h
HalfCarryMask  = 20h
FIRQMask       = 40h
EntireFlagMask = 80h

;*******************************************************************************
; Macro  : GetByte
; Purpose: Get a byte in AL from the 6809 memory pointed by ES:SI

macro      GetByte
           mov     al,[es:si]
endm       GetByte

;*******************************************************************************
; Macro  : GetWord
; Purpose: Get a word in AX from the 6809 memory pointed by ES:SI

macro      GetWord
           mov      ax,[es:si]
           xchg     ah,al
endm       GetWord

;*******************************************************************************
; Macro  : PutByte
; Purpose: Put a byte in AL to the 6809 memory pointed by ES:SI

macro      PutByte
           mov     [es:si],al
endm       PutByte

;*******************************************************************************
; Macro  : PutWord
; Purpose: Put a word in AX to the 6809 memory pointed by ES:SI

macro      PutWord
           xchg    ah,al
           mov     [es:si],ax
endm       PutWord

;*******************************************************************************
; Macro  : CCarry
; Purpose: Clear Carry Flag

macro      CCarry
           pushf
           and     [CC],11111110b
           popf
endm       CCarry

;*******************************************************************************
; Macro  : COverflow
; Purpose: Clear Overflow Flag

macro      COverflow
           pushf
           and     [CC],11111101b
           popf
endm       COverflow

;*******************************************************************************
; Macro  : CZero
; Purpose: Clear Zero Flag

macro      CZero
           pushf
           and     [CC],11111011b
           popf
endm       CZero

;*******************************************************************************
; Macro  : CNegative
; Purpose: Clear Negative Flag

macro      CNegative
           pushf
           and     [CC],11110111b
           popf
endm       CNegative

;*******************************************************************************
; Macro  : CIRQ
; Purpose: Clear IRQ Flag

macro      CIRQ
           pushf
           and     [CC],11101111b
           popf
endm       CIRQ

;*******************************************************************************
; Macro  : CHalfCarry
; Purpose: Clear Half Carry Flag

macro      CHalfCarry
           pushf
           and     [CC],11011111b
           popf
endm       CHalfCarry

;*******************************************************************************
; Macro  : CFIRQ
; Purpose: Clear Fast IRQ Flag

macro      CFIRQ
           pushf
           and     [CC],10111111b
           popf
endm       CFIRQ

;*******************************************************************************
; Macro  : CEntireFlag
; Purpose: Clear Entire Flag Flag

macro      CEntireFlag
           pushf
           and     [CC],01111111b
           popf
endm       CEntireFlag

;*******************************************************************************
; Macro  : SCarry
; Purpose: Set Carry Flag

macro      SCarry
           pushf
           or      [CC],00000001b
           popf
endm       SCarry

;*******************************************************************************
; Macro  : SOverflow
; Purpose: Set Overflow Flag

macro      SOverflow
           pushf
           or      [CC],00000010b
           popf
endm       SOverflow

;*******************************************************************************
; Macro  : SZero
; Purpose: Set Zero Flag

macro      SZero
           pushf
           or      [CC],00000100b
           popf
endm       SZero

;*******************************************************************************
; Macro  : SNegative
; Purpose: Set Negative Flag

macro      SNegative
           pushf
           or      [CC],00001000b
           popf
endm       SNegative

;*******************************************************************************
; Macro  : SIRQ
; Purpose: Set IRQ Flag

macro      SIRQ
           pushf
           or      [CC],00010000b
           popf
endm       SIRQ

;*******************************************************************************
; Macro  : SHalfCarry
; Purpose: Set Half Carry Flag

macro      SHalfCarry
           pushf
           or      [CC],00100000b
           popf
endm       SHalfCarry

;*******************************************************************************
; Macro  : SFIRQ
; Purpose: Set Fast IRQ Flag

macro      SFIRQ
           pushf
           or      [CC],01000000b
           popf
endm       SFIRQ

;*******************************************************************************
; Macro  : SEntireFlag
; Purpose: Set Entire Flag Flag

macro      SEntireFlag
           pushf
           or      [CC],10000000b
           popf
endm       SEntireFlag

           FARDATA                     ; 64K of emulator's main memory
Memory     equ     0
           db      0FF00h dup(?)
Ports      equ     0FF00h
           db      00100h dup(?)

;*******************************************************************************
; The following table is used to determine the entry point of each routine
;*******************************************************************************
           DATASEG

OpCodeAll  dw      mcNEG               ; 00 -- NEGate
           dw      mcERROR             ; 01 -- none
           dw      mcERROR             ; 02 -- none
           dw      mcCOM               ; 03 -- COMplement
           dw      mcLSR               ; 04 -- Logical Shift Right
           dw      mcERROR             ; 05 -- none
           dw      mcROR               ; 06 -- ROtate Right
           dw      mcASR               ; 07 -- Arithmetic Shift Right
           dw      mcASL               ; 08 -- Arithmetic Shift Left (LSL)
           dw      mcROL               ; 09 -- ROtate Left
           dw      mcDEC               ; 0A -- DECrement
           dw      mcERROR             ; 0B -- none
           dw      mcINC               ; 0C -- INCrement
           dw      mcTST               ; 0D -- TeST
           dw      mcJMP               ; 0E -- JuMP
           dw      mcCLR               ; 0F -- CLeaR
           dw      mcCASE10            ; 10 -- special case
           dw      mcCASE11            ; 11 -- special case
           dw      mcNOP               ; 12 -- No OPeration
           dw      mcSYNC              ; 13 -- SYNChronize
           dw      mcERROR             ; 14 -- none
           dw      mcERROR             ; 15 -- none
           dw      mcBRA               ; 16 -- Long BRanch Always
           dw      mcBSR               ; 17 -- Long Branch to SubRoutine
           dw      mcERROR             ; 18 -- none
           dw      mcDAA               ; 19 -- Decimal Addition Adjust
           dw      mcORCC              ; 1A -- OR Condition Codes
           dw      mcERROR             ; 1B -- none
           dw      mcANDCC             ; 1C -- AND Condition Codes
           dw      mcSEX               ; 1D -- Sign EXtend
           dw      mcEXG               ; 1E -- EXGhange
           dw      mcTFR               ; 1F -- TransFeR
           dw      mcBRA               ; 20 -- BRanch Always
           dw      mcBRN               ; 21 -- BRanch Never
           dw      mcBHI               ; 22 -- BRanch if HIgher
           dw      mcBLS               ; 23 -- BRanch if Less or Same
           dw      mcBHS               ; 24 -- BRanch if Higher or Same
           dw      mcBLO               ; 25 -- BRanch if LOwer
           dw      mcBNE               ; 26 -- BRanch if Not Equal
           dw      mcBEQ               ; 27 -- BRanch if EQual
           dw      mcBVC               ; 28 -- BRanch if oVerflow bit Clear
           dw      mcBVS               ; 29 -- BRanch if oVerflow bit Set
           dw      mcBPL               ; 2A -- BRanch on PLus sign
           dw      mcBMI               ; 2B -- BRanch on MInus sign
           dw      mcBGE               ; 2C -- BRanch if Greater than or Equal
           dw      mcBLT               ; 2D -- BRanch if Less Than
           dw      mcBGT               ; 2E -- BRanch if Greater Than
           dw      mcBLE               ; 2F -- BRanch if Less than or Equal
           dw      mcLEAX              ; 30 -- Load Effective Address into X
           dw      mcLEAY              ; 31 -- Load Effective Address into Y
           dw      mcLEAS              ; 32 -- Load Effective Address into S
           dw      mcLEAU              ; 33 -- Load Effective Address into U
           dw      mcPSHS              ; 34 -- PuSH onto System stack
           dw      mcPULS              ; 35 -- PULl from System stack
           dw      mcPSHU              ; 36 -- PuSH onto User stack
           dw      mcPULU              ; 37 -- PULl from User stack
           dw      mcERROR             ; 38 -- none
           dw      mcRTS               ; 39 -- ReTurn from Subroutine
           dw      mcABX               ; 3A -- Add B to X
           dw      mcRTI               ; 3B -- ReTurn from Interrupt
           dw      mcCWAI              ; 3C -- Clear flags and WAit for Interrupt
           dw      mcMUL               ; 3D -- MULtiply
           dw      mcERROR             ; 3E -- none
           dw      mcSWI               ; 3F -- SoftWare Interrupt
           dw      mcNEG               ; 40 -- NEGate
           dw      mcERROR             ; 41 -- none
           dw      mcERROR             ; 42 -- none
           dw      mcCOM               ; 43 -- COMplement
           dw      mcLSR               ; 44 -- Logical Shift Right
           dw      mcERROR             ; 45 -- none
           dw      mcROR               ; 46 -- ROtate Right
           dw      mcASR               ; 47 -- Arithmetic Shift Right
           dw      mcASL               ; 48 -- Arithmetic Shift Left (LSL)
           dw      mcROL               ; 49 -- ROtate Left
           dw      mcDEC               ; 4A -- DECrement
           dw      mcERROR             ; 4B -- none
           dw      mcINC               ; 4C -- INCrement
           dw      mcTST               ; 4D -- TeST
           dw      mcERROR             ; 4E -- none
           dw      mcCLR               ; 4F -- CLeaR
           dw      mcNEG               ; 50 -- NEGate
           dw      mcERROR             ; 51 -- none
           dw      mcERROR             ; 52 -- none
           dw      mcCOM               ; 53 -- COMplement
           dw      mcLSR               ; 54 -- Logical Shift Right
           dw      mcERROR             ; 55 -- none
           dw      mcROR               ; 56 -- ROtate Right
           dw      mcASR               ; 57 -- Arithmetic Shift Right
           dw      mcASL               ; 58 -- Arithmetic Shift Left (LSL)
           dw      mcROL               ; 59 -- ROtate Left
           dw      mcDEC               ; 5A -- DECrement
           dw      mcERROR             ; 5B -- none
           dw      mcINC               ; 5C -- INCrement
           dw      mcTST               ; 5D -- TeST
           dw      mcERROR             ; 5E -- none
           dw      mcCLR               ; 5F -- CLeaR
           dw      mcNEG               ; 60 -- NEGate
           dw      mcERROR             ; 61 -- none
           dw      mcERROR             ; 62 -- none
           dw      mcCOM               ; 63 -- COMplement
           dw      mcLSR               ; 64 -- Logical Shift Right
           dw      mcERROR             ; 65 -- none
           dw      mcROR               ; 66 -- ROtate Right
           dw      mcASR               ; 67 -- Arithmetic Shift Right
           dw      mcASL               ; 68 -- Arithmetic Shift Left (LSL)
           dw      mcROL               ; 69 -- ROtate Left
           dw      mcDEC               ; 6A -- DECrement
           dw      mcERROR             ; 6B -- none
           dw      mcINC               ; 6C -- INCrement
           dw      mcTST               ; 6D -- TeST
           dw      mcJMP               ; 6E -- JuMP
           dw      mcCLR               ; 6F -- CLeaR
           dw      mcNEG               ; 70 -- NEGate
           dw      mcERROR             ; 71 -- none
           dw      mcERROR             ; 72 -- none
           dw      mcCOM               ; 73 -- COMplement
           dw      mcLSR               ; 74 -- Logical Shift Right
           dw      mcERROR             ; 75 -- none
           dw      mcROR               ; 76 -- ROtate Right
           dw      mcASR               ; 77 -- Arithmetic Shift Right
           dw      mcASL               ; 78 -- Arithmetic Shift Left (LSL)
           dw      mcROL               ; 79 -- ROtate Left
           dw      mcDEC               ; 7A -- DECrement
           dw      mcERROR             ; 7B -- none
           dw      mcINC               ; 7C -- INCrement
           dw      mcTST               ; 7D -- TeST
           dw      mcJMP               ; 7E -- JuMP
           dw      mcCLR               ; 7F -- CLeaR
           dw      mcSUBA              ; 80 -- SUBtract A
           dw      mcCMPA              ; 81 -- CoMPare with A
           dw      mcSBCA              ; 82 -- SuBtract with Carry from A
           dw      mcSUBD              ; 83 -- SUBtract from D
           dw      mcANDA              ; 84 -- AND A
           dw      mcBITA              ; 85 -- BIT test A
           dw      mcLDA               ; 86 -- LoaD A
           dw      mcERROR             ; 87 -- none
           dw      mcEORA              ; 88 -- Exclusive OR A
           dw      mcADCA              ; 89 -- ADd with Carry to A
           dw      mcORA               ; 8A -- OR A
           dw      mcADDA              ; 8B -- ADD to A
           dw      mcCMPX              ; 8C -- CoMPare with X
           dw      mcBSR               ; 8D -- Branch to SubRoutine
           dw      mcLDX               ; 8E -- LoaD X
           dw      mcERROR             ; 8F -- none
           dw      mcSUBA              ; 90 -- SUBtract A
           dw      mcCMPA              ; 91 -- CoMPare with A
           dw      mcSBCA              ; 92 -- SuBtract with Carry from A
           dw      mcSUBD              ; 93 -- SUBtract from D
           dw      mcANDA              ; 94 -- AND A
           dw      mcBITA              ; 95 -- BIT test A
           dw      mcLDA               ; 96 -- LoaD A
           dw      mcSTA               ; 97 -- STore A
           dw      mcEORA              ; 98 -- Exclusive OR A
           dw      mcADCA              ; 99 -- ADd with Carry to A
           dw      mcORA               ; 9A -- OR A
           dw      mcADDA              ; 9B -- ADD to A
           dw      mcCMPX              ; 9C -- CoMPare with X
           dw      mcJSR               ; 9D -- Jump to SubRoutine
           dw      mcLDX               ; 9E -- LoaD X
           dw      mcSTX               ; 9F -- STore X
           dw      mcSUBA              ; A0 -- SUBtract A
           dw      mcCMPA              ; A1 -- CoMPare with A
           dw      mcSBCA              ; A2 -- SuBtract with Carry from A
           dw      mcSUBD              ; A3 -- SUBtract from D
           dw      mcANDA              ; A4 -- AND A
           dw      mcBITA              ; A5 -- BIT test A
           dw      mcLDA               ; A6 -- LoaD A
           dw      mcSTA               ; A7 -- STore A
           dw      mcEORA              ; A8 -- Exclusive OR A
           dw      mcADCA              ; A9 -- ADd with Carry to A
           dw      mcORA               ; AA -- OR A
           dw      mcADDA              ; AB -- ADD to A
           dw      mcCMPX              ; AC -- CoMPare with X
           dw      mcJSR               ; AD -- Jump to SubRoutine
           dw      mcLDX               ; AE -- LoaD X
           dw      mcSTX               ; AF -- STore X
           dw      mcSUBA              ; B0 -- SUBtract A
           dw      mcCMPA              ; B1 -- CoMPare with A
           dw      mcSBCA              ; B2 -- SuBtract with Carry from A
           dw      mcSUBD              ; B3 -- SUBtract from D
           dw      mcANDA              ; B4 -- AND A
           dw      mcBITA              ; B5 -- BIT test A
           dw      mcLDA               ; B6 -- LoaD A
           dw      mcSTA               ; B7 -- STore A
           dw      mcEORA              ; B8 -- Exclusive OR A
           dw      mcADCA              ; B9 -- ADd with Carry to A
           dw      mcORA               ; BA -- OR A
           dw      mcADDA              ; BB -- ADD to A
           dw      mcCMPX              ; BC -- CoMPare with X
           dw      mcJSR               ; BD -- Jump to SubRoutine
           dw      mcLDX               ; BE -- LoaD X
           dw      mcSTX               ; BF -- STore X
           dw      mcSUBB              ; C0 -- SUBtract B
           dw      mcCMPB              ; C1 -- CoMPare with B
           dw      mcSBCB              ; C2 -- SuBtract with Carry from B
           dw      mcADDD              ; C3 -- ADD to D
           dw      mcANDB              ; C4 -- AND B
           dw      mcBITB              ; C5 -- BIT test B
           dw      mcLDB               ; C6 -- LoaD B
           dw      mcERROR             ; C7 -- none
           dw      mcEORB              ; C8 -- Exclusive OR B
           dw      mcADCB              ; C9 -- ADd with Carry to B
           dw      mcORB               ; CA -- OR B
           dw      mcADDB              ; CB -- ADD to B
           dw      mcLDD               ; CC -- LoaD D
           dw      mcERROR             ; CD -- none
           dw      mcLDU               ; CE -- LoaD U
           dw      mcERROR             ; CF -- none
           dw      mcSUBB              ; D0 -- SUBtract B
           dw      mcCMPB              ; D1 -- CoMPare with B
           dw      mcSBCB              ; D2 -- SuBtract with Carry from B
           dw      mcADDD              ; D3 -- ADD to D
           dw      mcANDB              ; D4 -- AND B
           dw      mcBITB              ; D5 -- BIT test B
           dw      mcLDB               ; D6 -- LoaD B
           dw      mcSTB               ; D7 -- STore B
           dw      mcEORB              ; D8 -- Exclusive OR B
           dw      mcADCB              ; D9 -- ADd with Carry to B
           dw      mcORB               ; DA -- OR B
           dw      mcADDB              ; DB -- ADD to B
           dw      mcLDD               ; DC -- LoaD D
           dw      mcSTD               ; DD -- STore D
           dw      mcLDU               ; DE -- LoaD U
           dw      mcSTU               ; DF -- STore U
           dw      mcSUBB              ; E0 -- SUBtract B
           dw      mcCMPB              ; E1 -- CoMPare with B
           dw      mcSBCB              ; E2 -- SuBtract with Carry from B
           dw      mcADDD              ; E3 -- ADD to D
           dw      mcANDB              ; E4 -- AND B
           dw      mcBITB              ; E5 -- BIT test B
           dw      mcLDB               ; E6 -- LoaD B
           dw      mcSTB               ; E7 -- STore B
           dw      mcEORB              ; E8 -- Exclusive OR B
           dw      mcADCB              ; E9 -- ADd with Carry to B
           dw      mcORB               ; EA -- OR B
           dw      mcADDB              ; EB -- ADD to B
           dw      mcLDD               ; EC -- LoaD D
           dw      mcSTD               ; ED -- STore D
           dw      mcLDU               ; EE -- LoaD U
           dw      mcSTU               ; EF -- STore U
           dw      mcSUBB              ; F0 -- SUBtract B
           dw      mcCMPB              ; F1 -- CoMPare with B
           dw      mcSBCB              ; F2 -- SuBtract with Carry from B
           dw      mcADDD              ; F3 -- ADD to D
           dw      mcANDB              ; F4 -- AND B
           dw      mcBITB              ; F5 -- BIT test B
           dw      mcLDB               ; F6 -- LoaD B
           dw      mcSTB               ; F7 -- STore B
           dw      mcEORB              ; F8 -- Exclusive OR B
           dw      mcADCB              ; F9 -- ADd with Carry to B
           dw      mcORB               ; FA -- OR B
           dw      mcADDB              ; FB -- ADD to B
           dw      mcLDD               ; FC -- LoaD D
           dw      mcSTD               ; FD -- STore D
           dw      mcLDU               ; FE -- LoaD U
           dw      mcSTU               ; FF -- STore U

OpCode10   dw      33 dup(mcERROR)     ; 00 -> 20 -- none
           dw      mcBRN               ; 21 -- Long BRaNch
           dw      mcBHI               ; 22 -- Long BRanch if HIgher
           dw      mcBLS               ; 23 -- Long BRanch if Less or Same
           dw      mcBHS               ; 24 -- Long BRanch if Higher or Same
           dw      mcBLO               ; 25 -- Long BRanch if LOwer
           dw      mcBNE               ; 26 -- Long BRanch if Not Equal
           dw      mcBEQ               ; 27 -- Long BRanch if EQual
           dw      mcBVC               ; 28 -- Long BRanch if oVerflow bit Clear
           dw      mcBVS               ; 29 -- Long BRanch if oVerflow bit Set
           dw      mcBPL               ; 2A -- Long BRanch on PLus sign
           dw      mcBMI               ; 2B -- Long BRanch on MInus sign
           dw      mcBGE               ; 2C -- Long BRanch if Greater than or Equal
           dw      mcBLT               ; 2D -- Long BRanch if Less Than
           dw      mcBGT               ; 2E -- Long BRanch if Greater Than
           dw      mcBLE               ; 2F -- Long BRanch if Less than or Equal
           dw      15 dup(mcERROR)     ; 30 -> 3E -- none
           dw      mcSWI2              ; 3F -- SoftWare Interrupt 2
           dw      67 dup(mcERROR)     ; 40 -> 82 -- none
           dw      mcCMPD              ; 83 -- CoMPare with D
           dw      8 dup(mcERROR)      ; 84 -> 8B -- none
           dw      mcCMPY              ; 8C -- CoMPare with Y
           dw      mcERROR             ; 8D -- none
           dw      mcLDY               ; 8E -- LoaD Y
           dw      mcERROR             ; 8F -- none
           dw      3 dup(mcERROR)      ; 90 -> 92 none
           dw      mcCMPD              ; 93 -- CoMPare with D
           dw      8 dup(mcERROR)      ; 94 -> 9B -- none
           dw      mcCMPY              ; 9C -- CoMPare with Y
           dw      mcERROR             ; 9D -- none
           dw      mcLDY               ; 9E -- LoaD Y
           dw      mcSTY               ; 9F -- STore Y
           dw      3 dup(mcERROR)      ; A0 -> A2 none
           dw      mcCMPD              ; A3 -- CoMPare with D
           dw      8 dup(mcERROR)      ; A4 -> AB -- none
           dw      mcCMPY              ; AC -- CoMPare with Y
           dw      mcERROR             ; AD -- none
           dw      mcLDY               ; AE -- LoaD Y
           dw      mcSTY               ; AF -- STore Y
           dw      3 dup(mcERROR)      ; B0 -> B2 none
           dw      mcCMPD              ; B3 -- CoMPare with D
           dw      8 dup(mcERROR)      ; B4 -> BB -- none
           dw      mcCMPY              ; BC -- CoMPare with Y
           dw      mcERROR             ; BD -- none
           dw      mcLDY               ; BE -- LoaD Y
           dw      mcSTY               ; BF -- STore Y
           dw      14 dup(mcERROR)     ; C0 -> CD -- none
           dw      mcLDS               ; CE -- LoaD S
           dw      mcERROR             ; CF -- none
           dw      14 dup(mcERROR)     ; D0 -> DD -- none
           dw      mcLDS               ; DE -- LoaD S
           dw      mcSTS               ; DF -- STore S
           dw      14 dup(mcERROR)     ; E0 -> ED -- none
           dw      mcLDS               ; EE -- LoaD S
           dw      mcSTS               ; EF -- STore S
           dw      14 dup(mcERROR)     ; F0 -> FD -- none
           dw      mcLDS               ; FE -- LoaD S
           dw      mcSTS               ; FF -- STore S

OpCode11   dw      131 dup(mcERROR)    ; 00 -> 82 -- none
           dw      mcCMPU              ; 83 -- CoMPare with U
           dw      8 dup(mcERROR)      ; 84 -> 8B -- none
           dw      mcCMPS              ; 8C -- CoMPare with S
           dw      6 dup(mcERROR)      ; 8D -> 92 -- none
           dw      mcCMPU              ; 93 -- CoMPare with U
           dw      8 dup(mcERROR)      ; 94 -> 9B -- none
           dw      mcCMPS              ; 9C -- CoMPare with S
           dw      6 dup(mcERROR)      ; 9D -> A2 -- none
           dw      mcCMPU              ; A3 -- CoMPare with U
           dw      8 dup(mcERROR)      ; A4 -> AB -- none
           dw      mcCMPS              ; AC -- CoMPare with S
           dw      6 dup(mcERROR)      ; AD -> B2 -- none
           dw      mcCMPU              ; B3 -- CoMPare U
           dw      8 dup(mcERROR)      ; B4 -> BB -- none
           dw      mcCMPS              ; BC -- CoMPare with S
           dw      67 dup(mcERROR)     ; BD -> FF -- none

;*******************************************************************************
; Messages used by the Emulator
;*******************************************************************************

Copyright  db      "Motorola 6809E Emulator ver. 1.20 "
           db      "(Limited OS-9 Level One Ver. 2.00 Emulator)",RETURN,LINEFEED
           db      "Copyright (c) 1990-2022 by Tony G. Papadimitriou. "
           db      "All Rights Reserved.",RETURN,LINEFEED
           db      "(Assembled on: ",??date,")",RETURN,LINEFEED
           db      RETURN,LINEFEED
CprghtLen  =       $ - Copyright
LMsg       db      "Loading file",RETURN,LINEFEED
LMsgLen    =       $ - LMsg
EMsgG      db      "ERROR: "
EMsgGLen   =       $ - EMsgG
EMsg       db      "Unknown error code was returned by MS-DOS",RETURN,LINEFEED
EMsgLen    =       $ - EMsg
EMsg0      db      "Usage: MC6809E progname.s19",RETURN,LINEFEED
EMsg0Len   =       $ - EMsg0
EMsg1      db      "Invalid Motorola S19 file format",RETURN,LINEFEED
EMsg1Len   =       $ - EMsg1
EMsg2      db      "File not found",RETURN,LINEFEED
EMsg2Len   =       $ - EMsg2
EMsg3      db      "Path not found",RETURN,LINEFEED
EMsg3Len   =       $ - EMsg3
EMsg4      db      "MS-DOS reported an invalid DOS function",RETURN,LINEFEED
EMsg4Len   =       $ - EMsg4
EMsg5      db      "Can't open file, no file handles available",RETURN,LINEFEED
EMsg5Len   =       $ - EMsg5
EMsg6      db      "Access to file was denied",RETURN,LINEFEED
EMsg6Len   =       $ - EMsg6
EMsg7      db      "Internal error.  Please contact tonyp@ars.ath.forthnet.gr",RETURN,LINEFEED
EMsg7Len   =       $ - EMsg7
EMsg8      db      "Bad CRC while loading file, cannot run program",RETURN,LINEFEED
EMsg8Len   =       $ - EMsg8
EMsg9      db      "*** Invalid opcode encountered ***",RETURN,LINEFEED
EMsg9Len   =       $ - EMsg9
EMsg10     db      "Incorrect DOS version.  Must use DOS 3.x or greater",RETURN,LINEFEED
EMsg10Len  =       $ - EMsg10

;*******************************************************************************
; General Variables
;*******************************************************************************

PSP        dw      ?                   ; holds Program Segment Prefix
OS9_On     db      1                   ; flag to indicate OS9 emulation

;*******************************************************************************
; Variables used by the Emulator
;*******************************************************************************
;
; Global variables (other than the 6809 registers)
;
OpCode     db      ?                   ; Last OpCode fetched
Paged      db      ?                   ; Paged OpCode $10, or $11
PostCode   db      ?                   ; post-opcode for indexed etc.
Register   db      ?                   ; Register used as indexed (X,Y,U,S)
RegCont    dw      ?                   ; Contents of register
EffAdd     dw      ?                   ; Last calculated effective address
Timer      dw      ?                   ; Allows breakpoint setting
;
; Define the 6809 registers
;
DPR        db      ?                   ; Direct Page Register
CC         db      ?                   ; Condition Codes (flags)
label      XYUS    word
X          dw      ?                   ; primary index register
Y          dw      ?                   ; secondary index register
U          dw      ?                   ; User stack register
S          dw      ?                   ; System stack register
PC         dw      ?                   ; Program Counter
label      D       word                ; 16-bit accumulator (pair A,B)
B          db      ?                   ; secondary 8-bit Accumulator (low D)
A          db      ?                   ; primary 8-bit Accumulator (high D)

           CODESEG

;*******************************************************************************
; Routine: Init6809
; Purpose: Call the various functions of the program
; Input  : None
; Output : None

proc       Init6809
           mov     ax,@data            ; initialize DS
           mov     ds,ax
           mov     ah,DOS_GET_PSP      ; get Program Segment Prefix
           int     DOS_FUNCTION
           mov     [PSP],bx            ; save PSP for later
           call    ClrScr
           call    ShwCprght
           call    CheckVersion
           cmp     ax,0                ; wrong version?
           jne     @@errors            ; yes, report the problem
           call    ClearMemory
           call    Restart
           call    LoadProgram         ; load programs passed as parameters
           jc      @@errors            ; on carry set, we got errors
           cmp     ax,0
           jne     @@errors            ; or if AX <> 0, we got errors
           call    ClrScr
           mov     ax,[ExecAddr]       ; get the execution address
           mov     [PC],ax             ; into the PC register
           mov     [Timer],0           ; if Timer<>0 break in Timer cycles
           call    Emulator            ; else call the emulator
           cmp     ax,0                ; did we have errors?
           jne     @@errors            ; yes, take care of them
           mov     al,0                ; no errors
           jmp     short @@exit        ; and then exit program
@@errors:  call    Errors              ; display error message (AX=error code)
@@exit:    mov     ah,DOS_TERMINATE_EXE
           int     DOS_FUNCTION
endp       Init6809

;*******************************************************************************
; Routine: ClrScr
; Purpose: Clear the display and home the cursor
; Input  : None
; Output : None

proc       ClrScr
           push    ax                  ; save registers
           push    bx
           push    cx
           push    dx
           push    bp
           mov     ah,INT10_SCROLL_UP
           mov     al,0                ; entire window/screen
           mov     cx,0                ; start of screen
           mov     dx,0FFFFh           ; end of screen (maximum possible)
           mov     bh,7                ; character attribute normal
           int     VIDEO_SERVICE
           mov     ah,2                ; BIOS set cursor location function
           mov     dx,0                ; cursor coordinates (top left)
           mov     bh,0                ; current video page
           int     VIDEO_SERVICE
           pop     bp                  ; restore registers
           pop     dx
           pop     cx
           pop     bx
           pop     ax
           ret
endp       ClrScr

;*******************************************************************************
; Routine: ShwCprght
; Purpose: Display the program copyright message
; Input  : DS must point to the segment where the copyright is located
; Output : None

proc       ShwCprght
           mov     dx,offset Copyright
           mov     cx,CprghtLen
           call    Write
           ret
endp       ShwCprght

;*******************************************************************************
; Routine: CheckVersion
; Purpose: Check the DOS version
; Input  : None
; Output : If DOS version is < 3.x then AX = 131 (error code) else AX = 0

proc       CheckVersion
           push    bx
           push    cx
           mov     ah,DOS_GET_DOS_VERSION
           int     DOS_FUNCTION
           cmp     al,3                ; major = 3 ?
           jl      @@error             ; if less, get error code
           cmp     ah,0                ; minor = 0 ?
           jl      @@error             ; if less, get error code
           mov     ax,0                ; no error code
           jmp     short @@exit
@@error:   mov     ax,131              ; Invalid DOS version error code
@@exit:    pop     cx
           pop     bx
           ret
endp       CheckVersion

;*******************************************************************************
; Routine: ClearMemory
; Purpose: Fill 6809 segment with zeros
; Input  : None
; Output : None

proc       ClearMemory
           push    es                  ; save registers
           mov     ax,@fardata
           mov     es,ax
           mov     di,0
           mov     cx,0FFFFh           ; 65535 bytes
           mov     ax,0                ; initialization value
           rep stosb
           stosb                       ; one more for the last byte
           pop     es
           ret
endp       ClearMemory

;*******************************************************************************
; Routine: Restart
; Purpose: Initialize the 6809 registers
; Input  : None
; Output : None

proc       Restart
           push    ax                  ; save registers
           push    bx
           mov     ax,@fardata
           mov     es,ax
           mov     ax,0
           mov     [D],ax
           mov     [X],ax
           mov     [Y],ax
           mov     [U],ax
           mov     [S],ax
           mov     [U],ax
           mov     [CC],01010000b
           mov     [DPR],al
           mov     bx,0FFFEh
           mov     ax,[word es:Memory+bx]
           xchg    ah,al
           mov     [PC],ax
           pop     bx
           pop     ax
           ret
endp       Restart

;*******************************************************************************
include    "loader.asm"
;*******************************************************************************

;*******************************************************************************
; Routine: Errors
; Purpose: Display an error message based on the code in AX
; Input  : AX holds the error code
; Output : None

proc       Errors
           cmp     ax,0                ; do we have an error?
           jne     @@skip              ; error, go on and print it
           mov     dx,offset EMsg0     ; usage message
           mov     cx,EMsg0Len
           call    Write
           jmp     @@exit
@@skip:    ;call    Beep                ; beep on error
           mov     dx,offset EMsgG
           mov     cx,EMsgGLen
           call    Write
           cmp     ax,128              ; Invalid S format?
           jne     @@2
           mov     dx,offset EMsg1
           mov     cx,EMsg1Len
           call    Write
           jmp     @@exit
@@2:       cmp     ax,2                ; File not found?
           jne     @@3
           mov     dx,offset EMsg2
           mov     cx,EMsg2Len
           call    Write
           jmp     @@exit
@@3:       cmp     ax,3                ; Path not found?
           jne     @@4
           mov     dx,offset EMsg3
           mov     cx,EMsg3Len
           call    Write
           jmp     @@exit
@@4:       cmp     ax,1                ; Invalid DOS function?
           jne     @@5
           mov     dx,offset EMsg4
           mov     cx,EMsg4Len
           call    Write
           jmp     short @@exit
@@5:       cmp     ax,4                ; No handles available?
           jne     @@6
           mov     dx,offset EMsg5
           mov     cx,EMsg5Len
           call    Write
           jmp     short @@exit
@@6:       cmp     ax,5                ; Access denied?
           jne     @@7
           mov     dx,offset EMsg6
           mov     dx,EMsg6Len
           call    Write
           jmp     short @@exit
@@7:       cmp     ax,0Ch              ; Invalid access code, internal
           jne     @@8
           mov     dx,offset EMsg7
           mov     cx,EMsg7Len
           call    Write
           jmp     short @@exit
@@8:       cmp     ax,129              ; Bad CRC while loading
           jne     @@9
           mov     dx,offset EMsg8
           mov     cx,EMsg8Len
           call    Write
           jmp     short @@exit
@@9:       cmp     ax,130              ; Invalid opcode
           jne     @@10
           mov     dx,offset EMsg9
           mov     cx,EMsg9Len
           call    Write
           jmp     short @@exit
@@10:      cmp     ax,131              ; Invalid DOS version
           jne     @@11
           mov     dx,offset EMsg10
           mov     cx,EMsg10Len
           call    Write
           jmp     short @@exit
@@11:      ; ************* add more errors here if needed ***********
@@unknown: mov     dx,offset EMsg      ; unknown error
           mov     cx,EMsgLen
           call    Write
@@exit:    mov     ax,0                ; reset error code
           ret
endp       Errors

;*******************************************************************************
; Routine: DirMode
; Purpose: Calculate the effective address assuming direct mode
; Input  : None
; Output : SI holds the effective address in the ES segment (6809)

proc       DirMode
           push    ax
           mov     ah,[DPR]
           mov     si,[PC]
           GetByte
           inc     [PC]
           mov     si,ax
           pop     ax
           ret
endp       DirMode

;*******************************************************************************
; Routine: RelMode
; Purpose: Calculate the effective address assuming relative mode
; Input  : None
; Output : SI holds the effective address in the ES segment (6809)

proc       RelMode
           mov     si,[PC]
           ret
endp       RelMode

;*******************************************************************************
; Routine: IndMode
; Purpose: Calculate the effective address assuming indexed mode
; Input  : None
; Output : SI holds the effective address in the ES segment (6809)

proc       IndMode
           push    ax
           push    bx
           push    cx
           mov     si,[PC]             ; get post-opcode
           GetByte
           inc     [PC]
           mov     ah,al               ; get a copy in AH
           cmp     al,10011111b        ; special case (extended indirect)
           je      @@ExtIndH
           and     al,10011111b        ; remove the register info from AL
           mov     [PostCode],al       ; and save it for later
           and     ah,01100000b        ; and figure out the register from AH
           mov     cl,5
           shr     ah,cl               ; a number from 0 to 3 (X,Y,U,S)
           mov     [Register],ah       ; save it for later
           shl     ah,1                ; multiply by two (size of XYUS)
           xchg    ah,al
           cbw
           mov     bx,offset XYUS      ; point to XYUS registers
           add     bx,ax
           mov     bx,[bx]             ; get contents of register
           mov     [RegCont],bx        ; and save for later
           mov     al,[PostCode]       ; get postbyte
           and     al,11101111b        ; turn off indirect bit for now
           cmp     al,10000100b        ; is it no offset?
           je      @@noffset
           test    al,80h              ; is it 5-bit offset?
           jz      @@5bit
           cmp     al,10001000b        ; is it 8-bit offset?
           je      @@8bit
           cmp     al,10001001b        ; is it 16-bit offset?
           je      @@16bit
           cmp     al,10000110b        ; is it accumulator A offset?
           je      @@AoffH
           cmp     al,10000101b        ; is it accumulator B offset?
           je      @@BoffH
           cmp     al,10001011b        ; is it accumulator D offset?
           je      @@DoffH
           cmp     al,10000000b        ; is it auto increment by 1?
           je      @@Inc1H
           cmp     al,10000001b        ; is it auto increment by 2?
           je      @@Inc2H
           cmp     al,10000010b        ; is it auto decrement by 1?
           je      @@Dec1H
           cmp     al,10000011b        ; is it auto decrement by 2?
           je      @@Dec2H
           cmp     al,10001100b        ; is it 8-bit PCR?
           je      @@8PCRH
           cmp     al,10001101b        ; is it 16-bit PCR?
           je      @@16PCRH
           mov     al,[PostCode]
           jmp     @@Invalid           ; post byte is invalid
@@ExtIndH: jmp     @@ExtInd
@@AoffH:   jmp     @@Aoffset
@@BoffH:   jmp     @@Boffset
@@DoffH:   jmp     @@Doffset
@@Inc1H:   jmp     @@Inc1
@@Inc2H:   jmp     @@Inc2
@@Dec1H:   jmp     @@Dec1
@@Dec2H:   jmp     @@Dec2
@@8PCRH:   jmp     @@8PCR
@@16PCRH:  jmp     @@16PCR
@@noffset: mov     si,[RegCont]
           jmp     @@Indirec
@@5bit:    mov     si,[RegCont]
           mov     al,[PostCode]
           shl     al,1                ; "sign-extend" 5-bit offset
           shl     al,1
           shl     al,1
           sar     al,1
           sar     al,1
           sar     al,1
           cbw
           add     si,ax
           jmp     @@exit
@@8bit:    mov     si,[PC]             ; get offset and bump up PC by 1
           GetByte
           inc     [PC]
           cbw
           mov     si,[RegCont]
           add     si,ax
           jmp     @@Indirec
@@16bit:   mov     si,[PC]             ; get offset and bump up PC by 2
           GetWord
           inc     [PC]
           inc     [PC]
           mov     si,[RegCont]
           add     si,ax
           jmp     @@Indirec
@@Aoffset: mov     al,[A]
           jmp     short @@L1
@@Boffset: mov     al,[B]
@@L1:      mov     si,[RegCont]
           cbw
           add     si,ax
           jmp     @@Indirec
@@Doffset: mov     si,[RegCont]
           mov     ax,[D]
           add     si,ax
           jmp     @@Indirec
@@Inc1:    mov     si,[RegCont]
           mov     bx,offset XYUS
           mov     al,[Register]
           shl     al,1
           cbw
           add     bx,ax
           inc     [word bx]           ; post increment register by 1
           jmp     @@exit
@@Inc2:    mov     si,[RegCont]
           mov     bx,offset XYUS
           mov     al,[Register]
           shl     al,1
           cbw
           add     bx,ax
           inc     [word bx]           ; post increment register by 2
           inc     [word bx]
           jmp     short @@Indirec
@@Dec1:    mov     bx,offset XYUS
           mov     al,[Register]
           shl     al,1
           cbw
           add     bx,ax
           dec     [word bx]           ; post decrement register by 1
           mov     si,[word bx]
           jmp     short @@exit
@@Dec2:    mov     bx,offset XYUS
           mov     al,[Register]
           shl     al,1
           cbw
           add     bx,ax
           dec     [word bx]           ; post decrement register by 2
           dec     [word bx]
           mov     si,[word bx]
           jmp     short @@Indirec
@@8PCR:    mov     si,[PC]             ; get offset and bump up PC by 1
           GetByte
           inc     [PC]
           cbw
           mov     si,[PC]
           add     si,ax
           jmp     short @@Indirec
@@16PCR:   mov     si,[PC]             ; get offset and bump up PC by 2
           GetWord
           inc     [PC]
           inc     [PC]
           mov     si,[PC]
           add     si,ax
           jmp     short @@Indirec
@@ExtInd:  mov     si,[PC]
           GetByte
           inc     [PC]
           mov     ah,al
           mov     si,[PC]
           GetByte
           inc     [PC]
           mov     si,ax
           mov     si,[si]
           jmp     short @@exit
@@Indirec: mov     al,[PostCode]
           test    al,00010000b        ; is the indirect bit on?
           jz      @@exit              ; no, get out
           GetWord
           mov     si,ax
           jmp     short @@exit
@@Invalid: call    Beep                ; for now just beep
@@exit:    pop     cx
           pop     bx
           pop     ax
           ret
endp       IndMode

;*******************************************************************************
; Routine: ExtMode
; Purpose: Calculate the effective address assuming extended mode
; Input  : None
; Output : SI holds the effective address in the ES segment (6809)

proc       ExtMode
           push    ax
           mov     si,[PC]
           GetWord
           inc     [PC]
           inc     [PC]
           mov     si,ax
           pop     ax
           ret
endp       ExtMode

;*******************************************************************************
; Routine: ImmMode
; Purpose: Calculate the effective address assuming immediate mode
; Input  : None
; Output : SI holds the effective address in the ES segment (6809)

proc       ImmMode
           mov     si,[PC]
           ret
endp       ImmMode

;*******************************************************************************
; Routine: GetEffAddr
; Purpose: Get the effective address based on the MSN of the OpCode
; Input  : None
; Output : SI holds the effective address in the ES segment (6809)

proc       GetEffAddr
           push    ax
           mov     al,[OpCode]
           shr     al,1                ; move MSN to LSN
           shr     al,1                ;   making MSN = 0
           shr     al,1
           shr     al,1
           cmp     al,0                ; is it DIRECT mode?
           je      @@direct
           cmp     al,1                ; is it special mode 1 (relative)?
           je      @@mode1
           cmp     al,2                ; is it RELATIVE mode?
           je      @@relativ
           cmp     al,3                ; is it special mode 3 (indexed)?
           je      @@mode3
           cmp     al,6                ; is it INDEXED mode?
           je      @@indexed
           cmp     al,7                ; is it EXTENDED mode?
           je      @@extend
           cmp     al,8                ; is it IMMEDIATE mode?
           je      @@immed
           cmp     al,9                ; is it DIRECT mode?
           je      @@direct
           cmp     al,10               ; is it INDEXED mode?
           je      @@indexed
           cmp     al,11               ; is it EXTENDED mode?
           je      @@extend
           cmp     al,12               ; is it IMMEDIATE mode?
           je      @@immed
           cmp     al,13               ; is it DIRECT mode?
           je      @@direct
           cmp     al,14               ; is it INDEXED mode?
           je      @@indexed
           cmp     al,15               ; is it EXTENDED mode?
           je      @@extend
           jmp     short @@exit        ; other modes are done separately
@@direct:  call    DirMode
           jmp     short @@exit
@@mode1:   mov     al,[OpCode]         ; make sure it's a legal one
           cmp     al,16h              ; is it LBRA?
           je      @@relativ
           cmp     al,17h              ; is it LBSR
           je      @@relativ
           jmp     short @@exit
@@relativ: call    RelMode
           jmp     short @@exit
@@mode3:   mov     al,[OpCode]         ; make sure it's a legal one
           test    al,11000000b        ; 2 high bits are zero?
           jnz     @@exit
@@indexed: call    IndMode
           jmp     short @@exit
@@extend:  call    ExtMode
           jmp     short @@exit
@@immed:   call    ImmMode
@@exit:    pop     ax
           ret
endp       GetEffAddr

;*******************************************************************************
; Routine: Emulator
; Purpose: Perform the Fetch/Decode/Execute cycle until special key is pressed
;        : Special key should be one with extended code
;        : Currently the special key F10
; Input  : None
; Output : None

proc       Emulator
@@L0:      cmp     [Timer],0           ; check for breakpoints (Timer<>0)
           je      @@L1                ; no breakpoints, go on
           dec     [Timer]             ; breakpoint, count down time
           cmp     [Timer],0           ; are we done counting?
           jne     @@L1                ; no, go on
           jmp     @@EXIT              ; exit because of breakpoint
@@L1:      mov     ah,0Bh              ; check for key pressed
           int     21h
           cmp     al,0                ; is there a key waiting?
           je      @@L2                ; no key waiting, go on
           mov     ah,08h              ; read key
           int     21h
           cmp     al,0                ; is it an extended key?
           je      @@L1A               ; if so, go get second character
           jmp     short @@L2          ; key can be ignored
@@L1A:     mov     ah,08h              ; read character
           int     21h
           cmp     al,68               ; is it the special key <F10> ?
           je      @@EXIT              ; yes, exit
@@L2:      mov     si,[PC]
           GetByte                     ; fetch the instruction OpCode
           inc     [PC]
           mov     [OpCode],al
           mov     [Paged],al
           mov     ah,0
           mov     bx,offset OpCodeAll
           shl     ax,1                ; multiply by 2 (size of entries)
           add     bx,ax
           call    [word bx]           ; call routine through table (indirect)
           jmp     short @@L0          ; repeat loop for ever!
@@EXIT:    xor     ax,ax               ; no errors
           ret
endp       Emulator

;*******************************************************************************
; Routine: mcCASE10
; Purpose: Preprocess instruction prefix 10h
; Input  : None
; Output : None

proc       mcCASE10
           mov     si,[PC]
           GetByte                     ; fetch additional OpCode
           inc     [PC]
           mov     [OpCode],al
           mov     ah,0
           mov     bx,offset OpCode10
           shl     ax,1                ; multiply by 2 (size of entries)
           add     bx,ax
           jmp     [word bx]           ; go to routine through table (indirect)
endp       mcCASE10

;*******************************************************************************
; Routine: mcCASE11
; Purpose: Preprocess instruction prefix 11h
; Input  : None
; Output : None

proc       mcCASE11
           mov     si,[PC]
           GetByte                     ; fetch additional OpCode
           inc     [PC]
           mov     [OpCode],al
           mov     ah,0
           mov     bx,offset OpCode11
           shl     ax,1                ; multiply by 2 (size of entries)
           add     bx,ax
           jmp     [word bx]           ; go to routine through table (indirect)
endp       mcCASE11

;*******************************************************************************
; OPCODE ROUTINES
;*******************************************************************************

include    "opcodes1.asm"                ; in separate files :-)
include    "opcodes2.asm"
include    "os9.asm"                     ; OS-9 emulation routines

;*******************************************************************************
; S U B R O U T I N E S
;*******************************************************************************

;*******************************************************************************
; Routine: Write
; Purpose: Write a string to standard output
; Input  : DS:DX points to string to print
;        : CX holds string's length
; Output : None

proc       Write
           push    ax                  ; save registers
           push    bx
           mov     ah,DOS_WRITE_TO_HANDLE
           mov     bx,STDOUT
           int     DOS_FUNCTION
           pop     bx                  ; restore registers
           pop     ax
           ret
endp       Write

;*******************************************************************************
; Routine: Beep
; Purpose: Sound the beeper
; Input  : None
; Output : None

proc       Beep
           push    ax                  ; save registers
           push    bx
           mov     ah,INT10_WRITE_TTY
           mov     al,BELL
           mov     bx,0
           int     VIDEO_SERVICE
           pop     bx                  ; restore registers
           pop     ax
           ret
endp       Beep

;*******************************************************************************
           end     Init6809
;*******************************************************************************

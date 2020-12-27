; ===============
; Project defines
; ===============

; Hardware defines
include "hardware.inc"

; ================
; Global constants
; ================

btnA            =   0
btnB            =   1
btnSelect       =   2
btnStart        =   3
btnRight        =   4
btnLeft         =   5
btnUp           =   6
btnDown         =   7

_A              =   %00000001
_B              =   %00000010
_Select         =   %00000100
_Start          =   %00001000
_Right          =   %00010000
_Left           =   %00100000
_Up             =   %01000000
_Down           =   %10000000

Carillon_Init   =   $4000
Carillon_Load   =   $4003
Carillon_Stop   =   $4006
Carillon_Play   =   $4100

; ======
; Macros
; ======

; Defines a Game Boy Color RGB palette.
; USAGE: RGB    <red>,<green>,<blue>
RGB:                    macro
    dw      \1+(\2<<5)+(\3<<10)
    endm

; Loads a palette color to HL.
; USAGE: LRGB   <red>,<green>,<blue>
LRGB:                   macro
    ld      hl,\1+(\2<<5)+(\3<<10)
    endm

; Wait for VRAM accessibility.
WaitForVRAM:            macro
    ldh     a,[rSTAT]
    and     2
    jr      nz,@-4
    endm

line:                   macro
    ld      de,$9800+(\1<<5)
    endm

wline:                  macro
    ld      de,$9C00+(\1<<5)
    endm

str:                    macro
    db      \1,0
    endm

farcall:                macro
    ld      a,bank(\1)
    ld      [rROMB0],a
    call    \1
    endm

; =========
; Variables
; =========

OAMDMA          = $ff80
TrainerFlags    = $ff90

section "Intro OAM buffer",wram0,align[8]
SpriteBuffer:       ds  40*4

section "Intro red buffer",wram0,align[8]
Intro_RedBuffer:    ds  144
section "Intro green buffer",wram0,align[8]
Intro_GreenBuffer:  ds  144
section "Intro blue buffer",wram0,align[8]
Intro_BlueBuffer:   ds  144

section "Intro general vars",wram0,align[8]
sys_btnHold:        db
sys_btnPress:       db
sys_CurrentFrame:   db
sys_VBlankFlag:     db
Intro_GBCFlag:      db
Intro_MenuItem:     db
Intro_MenuLast:     db
Intro_MapTemp:      db
Intro_MapTemp2:     db
MarqueeMessage:     db
MarqueeTimer:       db
MarqueePos:         db
MarqueeScroll:      db
ScrollerPos:        dw
ScrollerOffset:     db
Intro_MenuMax       = 5
IntroRunning        = 7

section "Carillon Player reserved",wram0[$c7c0]
CarillonReserved:   ds  $40

; subroutines and variables used by the game
if !def(nogame)
DisableLCD          = $0262
_OAMDMA2            = $0279
Unk_020D            = $020D
Unk_021F            = $021F
UnkTable0248        = $0248
UnkTable0283        = $0283
GameInit            = $31e7
Joypad              = $386d
GBCFlag             = $c0a0
endc
_OAMDMASize         = 10

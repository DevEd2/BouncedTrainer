; ===============
; Bounced trainer
; ===============

; Defines
include "Defines.inc"
include "Trainer.inc"

; ===========
; Reset vectors
; ===========

if !def(nogame)
section "Reset 00",rom0[$0]
Reset00:
    ret   ; wtf? if this is all Reset00 is why is it called by GameStart?
    ds    $10-@,0

section "GBDK thumbprint",rom0[$10]
GBDKThumbprint:
    db    $80,$40,$20,$10,$08,$04,$02,$01,$01,$02,$04,$08,$10,$20,$40,$80
    ds    $40-@,0
endc

; ================================================================

; ==================
; Interrupt handlers
; ==================

section "VBlank IRQ",rom0[$40]
IRQ_VBlank::
    jp      DoVBlank
    ds      $48-@,0

section "STAT IRQ",rom0[$48]
IRQ_STAT::
    jp      DoScanline
    ds      $50-@,0

if !def(nogame)
section "Timer IRQ",rom0[$50]
IRQ_Timer::
    push    hl
    ld      hl,$c0c6
    jp      DoInterrupt
    ds      $58-@,0

section "Serial IRQ",rom0[$58]
IRQ_Serial::
    push    hl
    ld      hl,$c0d6
    jp      DoInterrupt
    ds      $60-@,0

section "Joypad IRQ",rom0[$60]
IRQ_Joypad::
    push    hl
    ld      hl,$c0e6
    jp      DoInterrupt    ; wtf?

DoInterrupt:
    push    af
    push    bc
    push    de
.loop
    ld      a,[hl+]
    or      [hl]
    jr      z,.skipint
    push    hl
    ld      a,[hl-]
    ld      l,[hl]
    ld      h,a
    call    Sys_JPHL
    pop     hl
    inc     hl
    jr      .loop
.skipint
    pop     de
    pop     bc
    pop     af
    pop     hl
    reti
Sys_JPHL:
    jp      hl
    ds      $100-@,0
endc

; ================================================================

section "ROM header",rom0[$100]

EntryPoint::
    nop
    jp    ProgramStart
NintendoLogo:    ; DO NOT MODIFY OR ROM WILL NOT BOOT!!!
    db    $ce,$ed,$66,$66,$cc,$0d,$00,$0b,$03,$73,$00,$83,$00,$0c,$00,$0d
    db    $00,$08,$11,$1f,$88,$89,$00,$0e,$dc,$cc,$6e,$e6,$dd,$dd,$d9,$99
    db    $bb,$bb,$67,$63,$6e,$0e,$ec,$cc,$dd,$dc,$99,$9f,$bb,$b9,$33,$3e
ROMTitle:       db    "BOUNCED!   AUDP" ; ROM title (15 chars) 
GBCSupport:     db    $C0               ; GBC support (0 = DMG only, $80 = DMG/GBC, $C0 = GBC only)
NewLicenseCode: db    "6N"              ; new license code (2 bytes)
SGBSupport:     db    0                 ; SGB support
CartType:       db    $19               ; Cart type, see hardware.inc for a list of values
ROMSize:        db    $05               ; ROM size (handled by post-linking tool)
RAMSize:        db    $00               ; RAM size
DestCode:       db    $01               ; Destination code (0 = Japan, 1 = All others)
OldLicenseCode: db    $33               ; Old license code (if $33, check new license code)
ROMVersion:     db    $00               ; ROM version
HeaderChecksum: db                      ; Header checksum (handled by post-linking tool)
ROMChecksum:    dw                      ; ROM checksum (2 bytes) (handled by post-linking tool)

; ================================================================

if !def(nogame)
GameStart:
    di
    ld      d,a

    xor     a
    ld      sp,$e000
    ld      hl,$dfff
    ld      c,$20
.clrRAM_loop
    ld      [hl-],a
    dec     b
    jr      nz,.clrRAM_loop
    dec     c
    jr      nz,.clrRAM_loop

    ld      hl,$feff
    ld      b,0
.clrOAM_loop:
    ld      [hl-],a
    dec     b
    jr      nz,.clrOAM_loop

    ; clear HRAM routine removed

    ; register init
    ld      a,d
    ld      [GBCFlag],a
    call    DisableLCD
    xor     a
    ldh     [rSCY],a
    ldh     [rSCX],a
    ldh     [rSTAT],a       ; wtf?
    ldh     [rWY],a
    ld      a,7
    ldh     [rWX],a
    ; copy OAM DMA routine
    ld      bc,$ff80
    ld      hl,_OAMDMA2
    ld      b,_OAMDMASize
.copyOAMDMALoop
    ld      a,[hl+]
    ld      [c],a
    inc     c
    dec     b
    jr      nz,.copyOAMDMALoop
    ld      bc,UnkTable0248
    call    Unk_020D
    ld      bc,UnkTable0283
    call    Unk_021F

    ld      a,%11100100     ; 3 2 1 0
    ldh     [rBGP],a        ; DMG background palette
    ld      [rOBP0],a       ; DMG object palette 1
    ld      a,%00011011     ; 0 1 2 3
    ldh     [rOBP1],a       ; DMG object palette 2
    ld      a,LCDCF_ON|LCDCF_WIN9C00
    ldh     [rLCDC],a       ; enable LCD + window address $9C00 (wtf?)
    xor     a
    ldh     [rIF],a         ; wtf?
    ld      a,IEF_VBLANK|IEF_SERIAL
    ldh     [rIE],a         ; enable VBlank + serial (wtf?) interrupts
    xor     a               ; wtf?
    ldh     [rNR52],a       ; disable sound output
    ldh     [rSC],a         ; disable link port
    ld      a,$66
    ldh     [rSB],a         ; wtf?
    ld      a,%10000000
    ldh     [rSC],a         ; wtf?
    call    Reset00         ; wtf?
    ei
    call    GameInit

.trap       jr    .trap
    ds      $1e0-@,0

section "lonely ret",rom0[$1e0]
LonelyRet:
    ret
    ds      $200-@,0

incbin "bounced.gbc",$200,$32b3-@
CreditsPatch:   db  $a0             ; fixes game freeze on clearing level 31
incbin "bounced.gbc",$32b4,$39d9-@
endc

; ================================================================

if !def(nogame)
section "Trainer + intro code",rom0[$39d9]
else
section "Trainer + intro code",rom0[$150]
endc
ProgramStart::
    cp      $11
    if !def(nogame)
        jr      z,.notdmg
        jp      GameStart
    else
        jr      nz,@
    endc
.notdmg
    di
    push    af
    ld      e,0
    ld      hl,$c000
    ld      bc,$2000
    call    _FillRAM

    ld      bc,$7c80
.loop
    ldh     [c],a
    inc     c
    dec     b
    jr      nz,.loop
    dec     a    ; a = $ff
    ld      [Intro_MenuLast],a

    pop     af
    ld      [Intro_GBCFlag],a
    ld      a,%10000000
    ldh     [TrainerFlags],a
    ld  bc,(_OAMDMA_End-_OAMDMA)<<8|low(OAMDMA)
    ld  hl,_OAMDMA
.copyloop
    ld  a,[hl+]
    ld  [c],a
    inc c
    dec b
    jr  nz,.copyloop

    xor     a
    ldh     [rLCDC],a    ; disable LCD

    call    DoubleSpeed

    ld      e,$ff
    ld      hl,$9800
    ld      bc,$400
    call    _FillRAM

    ld      a,1
    ldh     [rVBK],a
    ld      a,bank(GFX1)
    ld      [rROMB0],a
    ld      hl,Font
    ld      de,$9200
    call    DecodeWLE
    xor     a
    ldh     [rVBK],a
    ld      hl,Font
    ld      de,$8000
    call    DecodeWLE
    
    ld      hl,CapitalLogoTiles
    ld      de,$9000
    call    DecodeWLE
    
    ld      hl,Pal_CapitalLogo
    xor     a
    call    LoadPal
    ld      hl,Pal_Trainer
    ld      a,3
    call    LoadPal
    inc     a
    call    LoadPal
    inc     a
    call    LoadPal
    inc     a
    call    LoadPal
    inc     a
    call    LoadPal
    inc     a
    call    LoadPal

    ld      hl,CapitalLogoMap
    ld      bc,$0414
    ld      de,$9800
    push    bc
    push    de
    call    LoadMap

    ld      a,IEF_VBLANK|IEF_LCDC
    ldh     [rIE],a

    ld      a,8
    ldh     [rLYC],a    ; LY compare = 0
    xor     %01000000
    ldh     [rSTAT],a   ; enable LYC interrupt

    ld      a,7
    ldh     [rWX],a
    ld      a,104
    ldh     [rWY],a

    ld      hl,str_InfiniteLives
    wline   0
    ld      c,3
    call    PrintString
    ld      hl,str_InfiniteTime
    wline   1
    inc     c
    call    PrintString
    ld      hl,str_LevelSkip
    wline   2
    inc     c
    call    PrintString
    ld      hl,str_SuperJump
    wline   3
    inc     c
    call    PrintString
    ld      hl,str_NoStick
    wline   4
    inc     c
    call    PrintString
    
    ld      hl,str_Marquee1+1
    ld      c,3
    line    12
    call    PrintString

    ld      hl,$9C00
    WaitForVRAM
    ld      [hl],">"

    ld      a,bank(MusicData)
    ld      [rROMB0],a
    call    Carillon_Init
    call    Carillon_Load

    ld      a,LCDCF_ON|LCDCF_WIN9C00|LCDCF_BG8800|LCDCF_OBJON|LCDCF_BGON|LCDCF_WINON
    ldh     [rLCDC],a

    ld      a,192
    ld      [MarqueeTimer],a
    xor     a
    ld      [MarqueePos],a
    inc     a
    ld      [MarqueeMessage],a
    ld      a,8
    ld      [ScrollerOffset],a

    xor     a
    ld      [Intro_RedBuffer+94],a
    ld      a,15
    ld      [Intro_GreenBuffer+94],a
    ld      a,31
    ld      [Intro_BlueBuffer+94],a
    ei

Intro_MainLoop::

    call    CheckInput
    ld      a,[sys_btnPress]
    bit     btnStart,a
    jp      nz,ExitIntro

    bit     btnUp,a
    jr      nz,.cursorup
    bit     btnDown,a
    jr      nz,.cursordown
    bit     btnA,a
    jr      z,.done
.togglecheat
    ld  a,[Intro_MenuItem]
    ld  hl,Intro_Cheatmask
    add l
    ld  l,a
    ld  a,[hl]
    ld  b,a
    ld  a,[TrainerFlags]
    xor b
    ld  [TrainerFlags],a
    jr      .done
.cursorup
    ld      a,[Intro_MenuItem]
    ld      b,a
    dec     a
    cp      -1
    jr      nz,.setcursor
    ld      a,Intro_MenuMax-1
    jr      .setcursor
.cursordown
    ld      a,[Intro_MenuItem]
    ld      b,a
    inc     a
    cp      Intro_MenuMax
    jr      c,.setcursor
    xor     a
    ; fall through
.setcursor
    ld      [Intro_MenuItem],a
    call    Intro_GetCursorPos
    WaitForVRAM
    ld      [hl],">"
    ld      a,b
    ld      [Intro_MenuLast],a
    call    Intro_GetCursorPos
    WaitForVRAM
    ld      [hl]," "
.done
 
Menu_DrawYN::
    ; draw Y/N
    ld      a,[TrainerFlags]
    ld      hl,$9C12
    ld      de,$0020
    ld      b,5
.loop
    rra
    ld      c,a
    jr      nc,.no
    WaitForVRAM
    ld      [hl],"Y"
    jr      .next
.no
    WaitForVRAM
    ld      [hl],"N"
.next
    add     hl,de
    ld      a,c
    dec     b
    jr      nz,.loop

    ld      a,bank(MusicData)
    ld      [rROMB0],a
    call    Carillon_Play

    ; run marquee
    ld      a,[MarqueeTimer]
    cp      $ff
    jr      z,.skip
    dec     a
    ld      [MarqueeTimer],a
    jr      c,.waitvbl
.skip
    ld      a,[MarqueePos]
    add     2
    bit     7,a
    jr      z,.noreset
    xor     a
    ld      [MarqueePos],a
    ld      [MarqueeScroll],a
    ld      a,192
    ld      [MarqueeTimer],a
    ld      a,[MarqueeMessage]
    inc     a
    and     7
    ld      [MarqueeMessage],a
    jr      .waitvbl
.noreset
    ld      [MarqueePos],a
    ld      e,a
    ld      a,bank(MarqueeScrollTable)
    ld      [rROMB0],a
    ld      h,high(MarqueeScrollTable)
    ld      l,e
    ld      a,[hl]
    ld      [MarqueeScroll],a
    ; update marquee string
    rra     ; /2
    rra     ; /4
    rra     ; /8
    and     $1f
    ld      c,a
    line    12
    add     e
    dec     a
    ld      e,a
    ld      hl,MarqueeMessageTable
    ld      a,[MarqueeMessage]
    add     a
    add     l
    ld      l,a
    ld      a,[hl+]
    ld      h,[hl]
    add     c
    jr      nc,.nocarry
    inc     h
.nocarry
    ld      l,a
    WaitForVRAM
    ld      a,[hl]
    ld      [de],a


.waitvbl
    halt
    ldh     a,[rLY]
    cp      144
    jr      nz,.waitvbl

    call    DoScroller

    ld      a,bank(ColorBarTable)
    ld      [rROMB0],a
    ld      de,Intro_RedBuffer
    ld      a,[sys_CurrentFrame]
    and     63
    ld      h,high(ColorBarTable)
    ld      l,a
    ld      b,93
    call    .colorloop
    ld      de,Intro_GreenBuffer
    ld      a,[sys_CurrentFrame]
    rra
    and     63
    ld      l,a
    ld      b,93
    call    .colorloop
    ld      de,Intro_BlueBuffer
    ld      a,[sys_CurrentFrame]
    cpl
    and     63
    ld      l,a
    ld      b,93
    call    .colorloop

    call    OAMDMA

    jp      Intro_MainLoop
.colorloop
    ld      a,[hl+]
    ld      [de],a
    inc     e
    ld      a,l
    and     63
    ld      l,a
    dec     b
    jr      nz,.colorloop
    ret

Intro_GetCursorPos:
    ld      l,a
    ld      h,0
    add     hl,hl    ; x2
    add     hl,hl    ; x4
    add     hl,hl    ; x8
    add     hl,hl    ; x16
    add     hl,hl    ; x32
    ld      de,$9C00
    add     hl,de
    ret

ExitIntro::
    ld  a,IEF_VBLANK
    ldh [rIE],a
    halt
    xor     a
    ldh     [rLCDC],a

    ld      a,bank(MusicData)
    ld      [rROMB0],a
    call    Carillon_Stop
    call    NormalSpeed

    ; init routine doesn't clear VRAM so do that here
    ld      a,1
    ldh     [rVBK],a
    ld      e,0
    ld      hl,$8000
    ld      bc,$2000
    call    _FillRAM
    xor     a
    ldh     [rVBK],a
    ld      e,0
    ld      hl,$8000
    ld      bc,$2000
    call    _FillRAM

    ld      a,bank(GFX1)
    ld      [rROMB0],a
    ld      hl,Pal_Blank
    xor     a
    call    LoadPal ; only first line is needed

    ld      hl,TrainerFlags
    res     7,[hl]
    ; simulate initial boot rom exit register state
    ; not sure exactly how much of this is actually required for
    ; a clean boot, but better safe than sorry
    ld      bc,$1180
    push    bc
    pop     af              ; evil hack to write to write to f
    ld      bc,$0000        ; note: inaccurate on GBA
    ld      de,$ff56
    ld      hl,$000d
    ld      sp,$fffe
    if !def(nogame)
        jp      GameStart
    else
        jp      ProgramStart
    endc

; ================================================================

; INPUT: hl = pointer
;        de = destination
PrintString:
    xor     a
    ldh     [rVBK],a
    WaitForVRAM
    ld      a,[hl+]
    and     a
    ret     z
    ld      [de],a
    ld  a,1
    ldh [rVBK],a
    WaitForVRAM
    ld  a,c
    or  %00001000
    ld  [de],a
    inc     de
    jr      PrintString

; ================================================================

; =================
; Scroller routines
; =================
    
DoScroller:
    ld      a,bank(ScrollText)
    ld      [rROMB0],a
    ld      hl,ScrollerPos
    push    hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,h
    cp      high(ScrollTextSize)
    jr      nz,.skip3
    ld      a,l
    cp      low(ScrollTextSize)
    jr      nz,.skip3
    xor     a
    ld      [ScrollerPos],a
    ld      [ScrollerPos+1],a
    ; fall through
.skip3
    ld      a,[ScrollerOffset]
    dec     a
    jr      nz,.skip2
    pop     hl
    ld      a,[hl+]
    ld      b,[hl]
    ld      c,a
    inc     bc
    ld      a,b
    ld      h,b
    ld      [ScrollerPos+1],a
    ld      a,c
    ld      l,c
    ld      [ScrollerPos],a
    ld      a,8
    ld      [ScrollerOffset],a
    jr      .skip
.skip2
    ld      [ScrollerOffset],a
    pop     hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
.skip
    ld      bc,ScrollText
    add     hl,bc
    ld      de,SpriteBuffer
    ld      b,21
.loop
    ; sprite Y pos
    push    hl
    push    bc
    ld      a,b
    dec     a
    add     a
    add     a
    add     a
    ld      b,a
    ld      a,[ScrollerOffset]
    ld      c,a
    ld      a,[sys_CurrentFrame]
    sub     c
    add     b
    pop     bc
    ld      h,high(ScrollerSineTable)
    ld      l,a
    ld      a,[hl]
    add     16
    ld      [de],a
    inc     e
    ; sprite x pos
    ld      a,21
    sub     b
    add     a   ; x2
    add     a   ; x4
    add     a   ; x8
    ld      l,a
    ld      a,[ScrollerOffset]
    add     l
    dec     a
    ld      [de],a
    inc     e
    ; tile number
    pop     hl
    ld      a,[hl+]
    sub     32
    ld      [de],a
    inc     e
    ; attributes
    xor     a
    ld      [de],a
    inc     e
    dec     b
    jr      nz,.loop
    ret

; ================================================================

DoVBlank::
    push    af
    if !def(nogame)
        ldh     a,[TrainerFlags]
        bit     IntroRunning,a
        jr      nz,.intro
        call    DoTrainer
        pop     af
        push    hl
        ld      hl,$c0a6
        jp      DoInterrupt
    endc
.intro
    push    hl
    ld      hl,sys_CurrentFrame
    inc     [hl]
    ; do marquee
    ld      a,[MarqueeScroll]
    ldh     [rSCX],a
    ld      a,96
    ldh     [rSCY],a
    ld      a,bank(Pal_Blank)
    ld      [rROMB0],a
    xor     a
    LRGB    0, 7,15
    call    SetColor
    ld      a,1
    ld      [sys_VBlankFlag],a
    ld      a,6
    ldh     [rLYC],a
    pop     hl
    pop     af
    reti

DoScanline::
    push    af
    if !def(nogame)
        ldh     a,[TrainerFlags]
        bit     IntroRunning,a
        jr      nz,.intro
        pop     af
        push    hl
        ld      hl,$c0b6
        jp      DoInterrupt
    endc
.intro
    push    bc
    push    de
    push    hl

    ldh     a,[rLY]
    cp      7
    jr      c,.exit
    cp      144-40
    jr      nc,.exit
.top
    sub     8
    ld      l,a
    ld      h,high(Intro_BlueBuffer)
    ld      c,[hl]
    ld      h,high(Intro_GreenBuffer)
    ld      b,[hl]
    ld      h,high(Intro_RedBuffer)
    ld      a,[hl]
    call    CombineColors
    xor     a
    call    SetColor
    ld      hl,rLYC
    inc     [hl]
    xor     a
    ldh     [rSCX],a
    ld      a,bank(LogoBounce)
    ld      [rROMB0],a
    ld      h,high(LogoBounce)
    ld      a,[sys_CurrentFrame]
    and     $7f
    ld      l,a
    ld      a,[hl]
    ldh     [rSCY],a
    ; fall through
.exit
    pop     hl
    pop     de
    pop     bc
    pop     af
    reti

; ================================================================

CheckInput:
    push    bc
    ld      a,P1F_5
    ld      [rP1],a
    ld      a,[rP1]
    ld      a,[rP1]
    cpl
    and     a,$f
    swap    a
    ld      b,a
    
    ld      a,P1F_4
    ld      [rP1],a
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    cpl
    and     a,$f
    or      a,b
    ld      b,a
    
    ld      a,[sys_btnHold]
    xor     a,b
    and     a,b
    ld      [sys_btnPress],a
    ld      a,b
    ld      [sys_btnHold],a
    ld      a,P1F_5|P1F_4
    ld      [rP1],a
    pop     bc
    ret

; ================================================================

LoadMap:
    ld      a,c
    ld      [Intro_MapTemp],a
    xor     a
    ld      [Intro_MapTemp2],a
    ld      de,$9800
.loop
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     c
    jr      nz,.loop
    dec     b
    ret     z
    ld      de,$9800
    push    hl
    ld      h,0
    ld      a,[Intro_MapTemp2]
    inc     a
    ld      [Intro_MapTemp2],a
    ld      l,a
    add     hl,hl   ; x2
    add     hl,hl   ; x4
    add     hl,hl   ; x8
    add     hl,hl   ; x16
    add     hl,hl   ; x32
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    ld      a,[Intro_MapTemp]
    ld      c,a
    jr      .loop

_FillRAM::
    ld  a,e
    ld  [hl+],a
    dec bc
    ld  a,b
    or  c
    jr  nz,_FillRAM
    ret

; needed by WLE decoder
_CopyRAM::
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,_CopyRAM
    ret

; needed by WLE decoder
_CopyRAMSmall::
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,_CopyRAMSmall
    ret

include     "WLE_Decode.asm"
include     "GBCPal.asm"

; ================================================================

if !def(nogame)
DoTrainer::
    push    hl
    ldh     a,[TrainerFlags]
    rra
    call    c,.infinitelives
    rra
    call    c,.infinitetime
    rra
    call    c,.levelskip
    rra
    call    c,.superjump
    rra
    call    c,.nostick
    pop     hl
    ret

.infinitelives
    ld      hl,Lives
    ld      [hl],3
    ret
.infinitetime
    ld      hl,Time
    ld      [hl],99
    ret
.levelskip
    push    af
    call    Joypad
    bit     btnSelect+4,a
    jr      z,.nolevelskip
    ld      hl,LevelClearFlag
    ld      [hl],1
.nolevelskip
    pop     af
    ret
.superjump
    push    af
    call    Joypad
    bit     btnB+4,a
    jr      z,.nosuperjump
    ld      hl,MaxJump
    ld      [hl],$7f
.nosuperjump
    pop     af
    ret
.nostick
    ld      hl,StickTimer
    ld      [hl],$1f
    ret
endc

; ================================================================

DoubleSpeed:
    ldh     a,[rKEY1]
    bit     7,a         ; already in double speed?
    ret     nz          ; if yes, return
    jr      DoSpeedSwitch

NormalSpeed:
    ldh     a,[rKEY1]
    bit     7,a         ; already normal speed
    ret     z           ; if yes, return
    ; fall through

DoSpeedSwitch:
    ld      a,%00110000
    ldh     [rP1],a
    xor     %00110001   ; a = %00000000
    ldh     [rKEY1],a   ; prepare speed switch
    stop
    ret

; ================================================================

_OAMDMA:
    di
    ld      a,$c0
    ldh     [rDMA],a
    ld      a,$28
.loop
    dec     a
    jr      nz,.loop
    reti
_OAMDMA_End:

; ================================================================

section "Cheatmask",rom0[$3ffb]
Intro_Cheatmask:    db  %00000001,%00000010,%00000100,%00001000,%00010000

; ===============
; Rest of the ROM
; ===============

if !def(nogame)
    include "Banks.inc"
endc

; ============
; Trainer data 
; ============

section "Intro GFX",romx
GFX1:

Font:               incbin "GFX/Font.chr.wle"
CapitalLogoTiles:   incbin "GFX/CapitalLogo.chr.wle"

CapitalLogoMap:     incbin "GFX/CapitalLogo.map"
CapitalLogoMap_end:
;CapitalLogoAttr:   incbin "GFX/CapitalLogo.atr"
;CapitalLogoAttr_end:

Pal_Blank:
rept    32
    RGB     31,31,31
endr

Pal_CapitalLogo:
    incbin  "GFX/CapitalLogo.pal"
Pal_Trainer:
    RGB      0,11,23
    RGB      0, 0, 0
    RGB     18,25,27
    RGB     31,31,31

    RGB      0,12,25
    RGB      0, 0, 0
    RGB     18,25,27
    RGB     31,31,31

    RGB      0,13,27
    RGB      0, 0, 0
    RGB     18,25,27
    RGB     31,31,31

    RGB      0,14,29
    RGB      0, 0, 0
    RGB     18,25,27
    RGB     31,31,31

    RGB      0,15,31
    RGB      0, 0, 0
    RGB     18,25,27
    RGB     31,31,31

    RGB     31, 0,31
    RGB      0, 0, 0
    RGB     31,31,31
    RGB     31,31,31

;                        ####################
str_InfiniteLives:  str " INFINITE LIVES     "
str_InfiniteTime:   str " INFINITE TIME      "
str_LevelSkip:      str " LEVEL SKIP (SEL)   "
str_SuperJump:      str " SUPER JUMP (B)     "
str_NoStick:        str " NO STICK           "
;                        ####################

MarqueeMessageTable:
    dw      str_Marquee1
    dw      str_Marquee2
    dw      str_Marquee3
    dw      str_Marquee4
    dw      str_Marquee5
    dw      str_Marquee6
    dw      str_Marquee7
    dw      str_Marquee8

section "Marquee text",romx,align[8]
;                        ####################------------
str_Marquee1:       str "   CAPITAL PRESENTS              "
str_Marquee2:       str "   IN THE YEAR 2020              "
str_Marquee3:       str "   =BOUNCED GBC +5=              "
str_Marquee4:       str "   TRAINED BY DEVED              "
str_Marquee5:       str " CODE:          DEVED            "
str_Marquee6:       str " MUSIC:     TWOFLOWER            "
str_Marquee7:       str " GFX:       TWOFLOWER            "
str_Marquee8:       str " PRESS START  TO PLAY            "
;                        ####################------------

ScrollText::
    db      "                    "
    incbin  "scrolltext.txt"
ScrollText_End:
    db      "                    "
ScrollTextSize  equ (ScrollText_End-ScrollText)

section "Logo bounce table",romx,align[8]
LogoBounce:
angle=mul(0,256.0)
    rept    128
    db  (mul(59.5,sin(angle)+1.0)>>16)-$81
angle=angle+256.0
    endr

;Pal_TrainerShine:
;   RGB 15,24,31
;   RGB 16,24,31
;   RGB 17,25,31
;   RGB 18,25,31
;   RGB 19,26,31
;   RGB 20,26,31
;   RGB 21,27,31
;   RGB 22,27,31
;   RGB 23,28,31
;   RGB 24,28,31
;   RGB 25,29,31
;   RGB 26,29,31
;   RGB 27,30,31
;   RGB 28,30,31
;   RGB 29,31,31
;   RGB 30,31,31
;   RGB 31,31,31
;   RGB 30,31,31
;   RGB 29,31,31
;   RGB 28,30,31
;   RGB 27,30,31
;   RGB 26,29,31
;   RGB 25,29,31
;   RGB 24,28,31
;   RGB 23,28,31
;   RGB 22,27,31
;   RGB 21,27,31
;   RGB 20,26,31
;   RGB 19,26,31
;   RGB 18,25,31
;   RGB 17,25,31
;   RGB 16,24,31

section "Color bar table",romx,align[8]
ColorBarTable::
    db   0, 0, 1, 2, 2, 3, 4, 4, 5, 6, 6, 7, 8, 8, 9,10
    db  10,11,12,12,13,14,14,15,16,16,17,18,18,19,20,20
    db  21,20,20,19,18,18,17,16,16,15,14,14,13,12,12,11
    db  10,10, 9, 8, 8, 7, 6, 6, 5, 4, 4, 3, 2, 2, 1, 0

section "Marquee scroll table",romx,align[8]
MarqueeScrollTable::
    db      $00,$00,$00,$00,$00,$00,$01,$01,$02,$03,$03,$04,$05,$06,$07,$08
    db      $09,$0A,$0C,$0D,$0F,$10,$12,$13,$15,$17,$19,$1B,$1D,$1F,$21,$23
    db      $25,$27,$2A,$2C,$2E,$31,$33,$36,$38,$3B,$3E,$40,$43,$46,$49,$4C
    db      $4F,$51,$54,$57,$5A,$5D,$60,$63,$67,$6A,$6D,$70,$73,$76,$79,$7C
    db      $80,$83,$86,$89,$8C,$8F,$92,$95,$98,$9C,$9F,$A2,$A5,$A8,$AB,$AE
    db      $B0,$B3,$B6,$B9,$BC,$BF,$C1,$C4,$C7,$C9,$CC,$CE,$D1,$D3,$D5,$D8
    db      $DA,$DC,$DE,$E0,$E2,$E4,$E6,$E8,$EA,$EC,$ED,$EF,$F0,$F2,$F3,$F5
    db      $F6,$F7,$F8,$F9,$FA,$FB,$FC,$FC,$FD,$FE,$FE,$FF,$FF,$FF,$FF,$FF

section "Scroller sine table",romx,align[8]
ScrollerSineTable:: ; used for scrolltext
angle=0
    rept    256
    db  10+mul(43,sin(angle)+1.0)
angle=angle+256.0
    endr

; ================================================================

section "Music data",romx
MusicData: incbin "musicdata.bin"

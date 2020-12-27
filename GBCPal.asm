section "Color RAM",wram0,align[8]
sys_BGPalBuffer::       ds  4*8
sys_ObjPalBuffer::      ds  4*8
sys_FadeState::         db  ; 0 = not fading, 1 = fade in from white, 2 = fade out to white
sys_FadeBGPals::        db  ; which BG palettes are fading (bitmask)
sys_FadeOBJPals::       db  ; which OBJ palettes are fading (bitmask)
sys_FadeSpeed::         db  ; fade speed in ticks
sys_FadeTimer::         db  ; used in conjunction with above
sys_FadeLevel::         db  ; current intensity level

section "Color routines",rom0

; INPUT:     a = color index to modify
;           hl = color
; DESTROYS:  a, b, hl
SetColor::
    push    de
    bit     6,a
    jr      nz,.obj
    add     a   ; x2
    ld      b,a
    ld      de,sys_BGPalBuffer
    add     e
    ld      e,a
    WaitForVRAM
    ld      a,b
    set     7,a ; auto-increment
    ldh     [rBCPS],a
    WaitForVRAM
    ld      a,l
    ldh     [rBCPD],a
    ld      [de],a
    inc     e
    WaitForVRAM
    ld      a,h
    ldh     [rBCPD],a
    ld      [de],a
    pop     de
    ret
.obj
    add     a   ; x2
    add     a   ; x4
    add     a   ; x8
    ld      b,a
    ld      de,sys_ObjPalBuffer
    add     e
    ld      e,a
    WaitForVRAM
    ld      a,b
    set     7,a ; auto-increment
    ldh     [rOCPS],a
    WaitForVRAM
    ld      a,[hl+]
    ldh     [rOCPD],a
    ld      [de],a
    inc     e
    WaitForVRAM
    ld      a,[hl]
    ldh     [rOCPD],a
    ld      [de],a
    pop     de
    ret
; INPUT:     a = palette number to load into (bit 7 for object palette)
;           hl = palette pointer
; DESTROYS:  b, de, hl
LoadPal:
    push    af
    and     15
    bit     3,a
    jr      nz,.obj
    add     a   ; x2
    add     a   ; x4
    add     a   ; x8
    ld      b,a
    ld      de,sys_BGPalBuffer
    add     e
    ld      e,a
    ld      a,b
    set     7,a ; auto-increment
    ldh     [rBCPS],a
    rept    8
        ld      a,[hl+]
        ldh     [rBCPD],a
        ld      [de],a
        inc     e
    endr
    pop     af
    ret
.obj
    add     a   ; x2
    add     a   ; x4
    add     a   ; x8
    ld      b,a
    ld      de,sys_ObjPalBuffer
    add     e
    ld      e,a
    ld      a,b
    set     7,a ; auto-increment
    ldh [rOCPS],a
    rept    8
        ld      a,[hl+]
        ldh     [rOCPD],a
        ld      [de],a
        inc     e
    endr
    pop     af
    ret
    
; Takes a palette color and splits it into its RGB components.
; INPUT:    hl = color
; OUTPUT:    a = red
;            b = green
;            c = blue
;SplitColors:
;   push    de
;   ld      a,l         ; GGGRRRRR
;   and     %00011111   ; xxxRRRRR
;   ld      e,a
;   ld      a,l
;   and     %11100000   ; GGGxxxxx
;   swap    a           ; xxxxGGGx
;   rra                 ; xxxxxGGG
;   ld      b,a
;   ld      a,h         ; xBBBBBGG
;   and     %00000011   ; xxxxxxGG
;   swap    a           ; xxGGxxxx
;   rra                 ; xxxGGxxx
;   or      b           ; xxxGGGGG
;   ld      b,a
;   ld      a,h         ; xBBBBBGG
;   and     %01111100   ; xBBBBBxx
;   rra                 ; xxBBBBBx
;   rra                 ; xxxBBBBB
;   ld      c,a
;   ld      a,e
;   pop     de
;   ret

; Takes a set of RGB components and converts it to a palette color.
; INPUT:     a = red
;            b = green
;            c = blue
; OUTPUT:   hl = color
; DESTROYS:  a
CombineColors:
    ld      h,0         ; hl = xxxxxxxx ????????
    ld      l,a         ; hl = xxxxxxxx xxxRRRRR
    ld      a,b         ;  a = xxxGGGGG
    and     %00000111   ;  a = xxxxxGGG
    swap    a           ;  a = xGGGxxxx
    rla                 ;  a = GGGxxxxx
    or      l           ;  a = GGGRRRRR
    ld      l,a         ; hl = xxxxxxxx GGGRRRRR
    ld      a,b         ;  a = xxxGGGGG
    and     %00011000   ;  a = xxxGGxxx
    rla                 ;  a = xxGGxxxx
    swap    a           ;  a = xxxxxxGG
    ld      h,a         ; hl = xxxxxxGG GGGRRRRR
    ld      a,c         ;  a = xxxBBBBB
    rla                 ;  a = xxBBBBBx
    rla                 ;  a = xBBBBBxx
    or      h           ;  a = xBBBBBGG
    ld      h,a         ; hl = xBBBBBGG GGGRRRRR
    ret

    PROCESSOR 6502
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    INCLUDE "vcs.h"
    INCLUDE "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    SEG.U Variables
    org $80

JetXPos         byte            ; Player0 X position
JetYPos         byte            ; Player0 Y position
BomberXPos      byte            ; Player1 X position
BomberYPos      byte            ; Player1 X position

JetSpritePtr    word            ; Pointer to player0 sprite in lookup table 
JetColorPtr     word            ; Pointer to player0 color in lookup table 
BomberSpritePtr word            ; Pointer to player1 sprite in lookup table 
BomberColorPtr  word            ; Pointer to player1 color in lookup table 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start ROM code at $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START                 ; Macro for reset memory and registers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start ROM code at $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #10
    STA JetYPos
    LDA #60
    STA JetXPos
    
    LDA #83
    STA BomberYPos
    LDA #54
    STA BomberXPos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize pointers to the correct adresses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #<JetSprite
    STA JetSpritePtr            ; Lo-byte pointer for jet sprite lookup table
    LDA #>JetSprite
    STA JetSpritePtr + 1        ; Hi-byte pointer for jet sprite lookup table

    LDA #<JetColor
    STA JetColorPtr            
    LDA #>JetColor
    STA JetColorPtr + 1      

    LDA #<BomberSprite
    STA BomberSpritePtr
    LDA #>BomberSprite
    STA BomberSpritePtr + 1   

    LDA #<BomberColor
    STA BomberColorPtr
    LDA #>BomberColor
    STA BomberColorPtr + 1        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JET_HEIGHT = 9                  ; Player0 sprite hight (num. of rows in lookup table)
BOMBER_HEIGHT = 9               ; Player1 sprite hight 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start the main display loop and frame rendering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VSYNC and VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #2
    STA VBLANK
    STA VSYNC

    ; VSYNC
    REPEAT 3
        STA WSYNC               ; Display 3 recommended lines of VSYNC
    REPEND
    LDA #0
    STA VSYNC                   ; Turn off vsync

    ; VBLANK
    REPEAT 37
        STA WSYNC
    REPEND
    STA VBLANK                  ; Zero already in A register becouse of VSYNC code block

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 96 visible scanlines (because 2-line kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameVisibleLine:
    LDA #$84                    
    STA COLUBK                  ; Set background to blue color

    LDA #$C2                    
    STA COLUPF                  ; Set playerfield/grass color to green

    ; Setting playfield pattern
    LDA #$F0
    STA PF0

    LDA #$FC
    STA PF1

    LDA #0
    STA PF2

    LDA #%00000001
    STA CTRLPF                  ; Set playfield to reflecting mode

    LDX #96                     ; Number of displaying lines
.GameLineLoop:
.AreWeInsideJetSprite:
    TXA                         ; Transfer X to A
    SEC
    SBC JetYPos                 
    CMP JET_HEIGHT              ; Are we inside the sprite Y bounds
    BCC .DrawSpriteP0           ; If result < SpriteHeight call draw routine
    LDA #0                      ; else set lookup index to #0

.DrawSpriteP0
    TAY                         ; Y is only register that work with pointers
    LDA (JetSpritePtr),Y        ; Load P0 bitmap data from lookup table
    STA WSYNC
    STA GRP0
    LDA (JetColorPtr),Y         ; Load player color from lookup table
    STA COLUP0

.AreWeInsideBomberSprite:
    TXA                         ; Transfer X to A
    SEC
    SBC BomberYPos                 
    CMP BOMBER_HEIGHT           ; Are we inside the sprite Y bounds
    BCC .DrawSpriteP1           ; If result < SpriteHeight call draw routine
    LDA #0                      ; else set lookup index to #0

.DrawSpriteP1
    TAY                         ; Y is only register that work with pointers
    LDA (BomberSpritePtr),Y     ; Load P1 bitmap data from lookup table
    STA WSYNC
    STA GRP1
    LDA (BomberColorPtr),Y      ; Load color from lookup table
    STA COLUP1

    DEX
    BNE .GameLineLoop           ; Loop all lines
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Overscan
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #2
    STA VBLANK                  ; Turn VBLANK on again
    REPEAT 30
        STA WSYNC
    REPEND
    LDA #0
    STA VBLANK
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop back
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame              ; Jump to start of rendering frame: rendering next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JetSprite:
    .byte #%00000000            ;
    .byte #%00010100            ;   # #
    .byte #%01111111            ; #######
    .byte #%00111110            ;  #####
    .byte #%00011100            ;   ###
    .byte #%00011100            ;   ###
    .byte #%00001000            ;    #
    .byte #%00001000            ;    #
    .byte #%00001000            ;    #

JetSpriteTurn:
    .byte #%00000000            ;
    .byte #%00001000            ;    #
    .byte #%00111110            ;  #####
    .byte #%00011100            ;   ###
    .byte #%00011100            ;   ###
    .byte #%00011100            ;   ###
    .byte #%00001000            ;    #
    .byte #%00001000            ;    #
    .byte #%00001000            ;    #

BomberSprite:
    .byte #%00000000            ;
    .byte #%00001000            ;    #
    .byte #%00001000            ;    #
    .byte #%00101010            ;  # # #
    .byte #%00111110            ;  #####
    .byte #%01111111            ; #######
    .byte #%00101010            ;  # # #
    .byte #%00001000            ;    #
    .byte #%00011100            ;   ###

JetColor:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$BA
    .byte #$0E
    .byte #$08

JetColorTurn:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$0E
    .byte #$0E
    .byte #$08

BomberColor:
    .byte #$00
    .byte #$32
    .byte #$32
    .byte #$0E
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size with 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC                   ; Move to $FFFC
    word Reset                  ; write 2 bytes with Reset address
    word Reset                  ; write 2 bytes with Reset address
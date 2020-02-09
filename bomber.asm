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
Score           byte            ; 2-digit score
Timer           byte            ; 2-digit timer 
Temp            byte            ; Temp variable
Random          byte            ; Random number generated to set enemy position
OneDigitOffset  word
TensDigitOffset word

JetSpritePtr    word            ; Pointer to player0 sprite in lookup table 
JetColorPtr     word            ; Pointer to player0 color in lookup table 
BomberSpritePtr word            ; Pointer to player1 sprite in lookup table 
BomberColorPtr  word            ; Pointer to player1 color in lookup table 
JetAnimOffset   byte            ; Player0 sprite frame offset for animation
ScoreSprite     byte         ; store the sprite bit pattern for the score
TimerSprite     byte         ; store the sprite bit pattern for the timer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JET_HEIGHT = 9                  ; Player0 sprite hight (num. of rows in lookup table)
BOMBER_HEIGHT = 9               ; Player1 sprite hight 
DIGITS_HEIGHT = 5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start ROM code at $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START                 ; Macro for reset memory and registers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize RAM variables and TIA registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #10
    STA JetYPos
    LDA #50
    STA JetXPos
    
    LDA #83
    STA BomberYPos
    LDA #54
    STA BomberXPos

    LDA #%11010100
    STA Random                  ; Set seed for random

    LDA #0
    STA Score
    STA Timer                   ; Timer = Score = 0

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
;; Start the main display loop and frame rendering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations and tasks performed in the pre VBlank
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA JetXPos
    LDY #0                      ; Y register using as argument for subroutine
    JSR SetObjectXPos           ; Set P0 horizontal position

    LDA BomberXPos
    LDY #1
    JSR SetObjectXPos

    JSR CalculateDigitOffset    ; Calculate the scoreboard digit lookup table offset

    STA WSYNC
    STA HMOVE                   ; Apply the horizontal offsets previously set
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
;; Display scoreboard
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #0                      ; Clear TIA registers before each new frame
    STA PF0
    STA PF1
    STA PF2
    STA GRP0
    STA GRP1
    STA COLUPF
    LDA #$1C                    ; Set scoreboard color to white
    STA COLUPF
    LDA #%00000000              ; Disable playfield reflection
    STA CTRLPF

    LDX #DIGITS_HEIGHT          ; Start X Counter with 5

.ScoreDigitLoop:
    LDY TensDigitOffset         
    LDA Digits,Y
    AND #$F0                    ; Mask graphics for the ones digits
    STA ScoreSprite
    LDY OneDigitOffset
    LDA Digits,Y
    AND #$0F                    ; Mask graphics for the tens digits
    ORA ScoreSprite             ; Merge ones with tens
    STA ScoreSprite             ; Save it
    STA WSYNC             

    STA PF1

    LDY TensDigitOffset+1       
    LDA Digits,Y
    AND #$F0                    ; Get only tens
    STA TimerSprite
    LDY OneDigitOffset+1
    LDA Digits,Y
    AND #$0F
    ORA TimerSprite
    STA TimerSprite

    JSR Sleep12Cycles          

    STA PF1
    LDY ScoreSprite
    STA WSYNC

    STY PF1
    INC TensDigitOffset
    INC TensDigitOffset+1
    INC OneDigitOffset
    INC OneDigitOffset+1

    STA WSYNC

    DEX
    BNE .ScoreDigitLoop

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

    LDX #84                     ; Number of displaying lines
.GameLineLoop:
.AreWeInsideJetSprite:
    TXA                         ; Transfer X to A
    SEC
    SBC JetYPos                 
    CMP JET_HEIGHT              ; Are we inside the sprite Y bounds
    BCC .DrawSpriteP0           ; If result < SpriteHeight call draw routine
    LDA #0                      ; else set lookup index to #0

.DrawSpriteP0
    CLC                         ; Clear carry flag before addition
    ADC JetAnimOffset           ; Jump to the correct sprite frame address in memory
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
    LDA #%00000101
    STA NUSIZ1                  ; Stretch P1 sprite
    LDA (BomberSpritePtr),Y     ; Load P1 bitmap data from lookup table
    STA WSYNC
    STA GRP1
    LDA (BomberColorPtr),Y      ; Load color from lookup table
    STA COLUP1

    DEX
    BNE .GameLineLoop           ; Loop all lines

    LDA #0
    STA JetAnimOffset           ; Reset jet animation to 0 frame

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
;; Process input for P0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckP0Up:
    LDA #%00010000              ; Player0 joystick up
    BIT SWCHA               
    BNE CheckP0Down             ; If bit pattern doesnt match, bypass Up block
    INC JetYPos
    LDA #0              
    STA JetAnimOffset           ; Set animation offeset to the first frame

CheckP0Down:
    LDA #%00100000
    BIT SWCHA
    BNE CheckP0Left
    DEC JetYPos
    LDA #0              
    STA JetAnimOffset           ; Set animation offeset to the first frame

CheckP0Left:
    LDA #%01000000
    BIT SWCHA
    BNE CheckP0Right
    DEC JetXPos
    LDA JET_HEIGHT              
    STA JetAnimOffset           ; Set animation offeset to the second frame

CheckP0Right:           
    LDA #%10000000
    BIT SWCHA
    BNE EndInputCheck
    INC JetXPos
    LDA JET_HEIGHT              
    STA JetAnimOffset           ; Set animation offeset to the second frame

EndInputCheck:                  ; Do nothing 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Game logic update
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UpdateBomberPosition:
    LDA BomberYPos
    CLC
    CMP #0
    BMI .ResetBomberPosition
    DEC BomberYPos
    JMP EndPositionUpdate
.ResetBomberPosition
    JSR SetRandomBomberPos      ; Call for next random X position
    INC Score
    INC Timer                   ; Incremet score and time after new enemy spawn

EndPositionUpdate:              ; Do nothing

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Check for object collision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckCollisionP0AndP0:
    LDA #%10000000              ; CXPPMM register bit 7 detect P0 and P1 collision
    BIT CXPPMM
    BNE .CollisionP0P1          ; Collision happened 
    JMP CheckCollisionP0PF
.CollisionP0P1:
    JSR GameOver                ; Call GameOver subroutine

CheckCollisionP0PF:
    LDA #%10000000              ; CXP0FB register bit 7 detect P0 and Player Field collision
    BIT CXP0FB                  
    BNE .CollisionP0PF          ; Collision happened  
    JMP EndCollisionCheck
.CollisionP0PF:
    JSR GameOver                ; Call GameOver subroutine


EndCollisionCheck:              
    STA CXCLR                   ; Clear all collision flags before next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop back
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame              ; Jump to start of rendering frame: rendering next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Horizontal position subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A is the target X coordinate position in pixels
;; Y is the object type
;;      0 : player0
;;      1 : player1
;;      2 : missle0
;;      3 : missle1
;;      4 : ball
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetObjectXPos       SUBROUTINE
    STA WSYNC                   ; Start a new scanline
    SEC                         
.Div15Loop
    SBC #15
    BCS .Div15Loop              ; Loop until reac 15 px accuracy
    EOR #7                      ; Handle offset range from -8 to 7
    ASL
    ASL
    ASL
    ASL                         ; For left shifts to get only top 4 bits
    STA HMP0,Y                  ; Set fine offset
    STA RESP0,Y                 ; Set position with 15 accuracy
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GameOver subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameOver            SUBROUTINE
    LDA #$30
    STA COLUBK

    LDA #0
    STA Score
    STA Timer                   ; Reset score and time on Game Over
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate a Linear-Feedback Shift Register random number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate LFSR random namber (0 - FF)
;; Divide the rendom value by 4 to limit size of result to match river
;; Add 30 to compensate offset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetRandomBomberPos  SUBROUTINE
    LDA Random
    ASL
    EOR Random
    ASL
    EOR Random
    ASL
    ASL
    EOR Random
    ASL
    ROL Random

    lsr
    lsr                         ; divide the value by 4 by performing 2 right shifts

    STA BomberXPos
    LDA #30
    ADC BomberXPos              ; Adds 30 + BomberXPos
    STA BomberXPos              

    LDA #96
    STA BomberYPos              ; Set Bomber at the top of the screen
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to handle scoreboard digits to be displayed on the screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CalculateDigitOffset    SUBROUTINE
    LDX #1                      ; X register is the loop counter
.PrepareScoreLoop

    LDA Score,X                 ; Load A with Timer(X) or Score (X=0)
    AND #$0F                    ; Set %00001111 mask on A register so it will remove 10th digits
    STA Temp            
    ASL 
    ASL
    ADC Temp        
    STA OneDigitOffset,X

    LDA Score,X           
    AND #$F0
    LSR
    LSR    
    STA Temp
    LSR
    LSR     
    ADC Temp
    STA TensDigitOffset,X

    DEX
    BPL .PrepareScoreLoop

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Wastes 12 cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; JSR: 6 cycles
;; RTS: 6 cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Sleep12Cycles           SUBROUTINE
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Digits:
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00110011          ;  ##  ##
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %00100010          ;  #   #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01100110          ; ##  ##
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01100110          ; ##  ##
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01100110          ; ##  ##

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01100110          ; ##  ##
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #

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
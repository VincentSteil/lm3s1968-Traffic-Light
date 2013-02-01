;Vincent Steil & Taariq Chasmawala

; PointerTrafficLight.s
; Runs on LM3S1968
; Use a pointer implementation of a Moore finite state machine to operate
; a traffic light.
; Daniel Valvano
; May 21, 2012

;  This example accompanies the book
;  "Embedded Systems: Introduction to the Arm Cortex M3",
;  ISBN: 978-1469998749, Jonathan Valvano, copyright (c) 2012
;  Example 6.4, Program 6.8
;
;Copyright 2012 by Jonathan W. Valvano, valvano@mail.utexas.edu
;   You may use, edit, run or distribute this file
;   as long as the above copyright notice remains
;THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
;OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
;MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
;VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
;OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
;For more information about my classes, my research, and my books, see
;http://users.ece.utexas.edu/~valvano/

; north facing car detector connected to PE1 (1=car present)
; east facing car detector connected to PE0 (1=car present)
; pedestrian sensor connected to PE2 (1=pressed)
; Don't walk LED connected to PG2
; east facing red light connected to PF5
; east facing yellow light connected to PF4
; east facing green light connected to PF3
; north facing red light connected to PF2
; north facing yellow light connected to PF1
; north facing green light connected to PF02

        IMPORT   PLL_Init
        IMPORT   SysTick_Init
        IMPORT   SysTick_Wait10ms

SENSOR             EQU 0x4002401C   ; port E bits 2-0
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
LIGHT              EQU 0x400250FC   ; port F bits 5-0
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_DEN_R   EQU 0x4002551C
SYSCTL_RCGC2_R     EQU 0x400FE108
SYSCTL_RCGC2_GPIOF EQU 0x00000020   ; port F Clock Gating Control
SYSCTL_RCGC2_GPIOE EQU 0x00000010   ; port E Clock Gating Control

GPIO_PORTG2        EQU 0x40026010	;PG2 is the Walk LED
GPIO_PORTG_DIR_R   EQU 0x40026400
GPIO_PORTG_AFSEL_R EQU 0x40026420
GPIO_PORTG_DEN_R   EQU 0x4002651C
SYSCTL_RCGC2_GPIOG EQU 0x00000040   ; port G Clock Gating Control


        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Start
;Linked data structure
;Put in ROM
OUT   EQU 0    ;offset for output 
WAIT  EQU 4    ;offset for time 
NEXT  EQU 8   ;offset for next

GoN   			DCD 0x61 ;North green, East red 1100001
				DCD 100 ;1 sec
				DCD GoN,GoN,EYellowN,EYellowN,PCheckGoN,PCheckYellowN,PCheckYellowN,PCheckYellowN
EYellowN	 	DCD 0x62 ;1100010
				DCD 100
				DCD GoE,GoE,GoE,GoE,PCheckGoE,PCheckGoE,PCheckGoE,PCheckGoE
PCheckGoN	 	DCD 0x61 ;1100001 
				DCD 100
				DCD GoN,GoN,EYellowN,EYellowN,PYellowN,PYellowN,PYellowN,PYellowN
PCheckYellowN 	DCD 0x62 ;1100010
				DCD 100
				DCD GoE,GoE,GoE,GoE,EWalk,EWalk,EWalk,EWalk
PCheckGoE		DCD 0x4C ;1001100
				DCD 100
				DCD GoE,NYellowE,GoE,NYellowE,PYellowE,PYellowE,PYellowE,PYellowE
PYellowN		DCD 0x62 ;1100010
				DCD 100
				DCD EWalk,EWalk,EWalk,EWalk,EWalk,EWalk,EWalk,EWalk
GoE				DCD 0x4C ;1001100
				DCD 100
				DCD GoE,NYellowE,GoE,NYellowE,PCheckGoE,PCheckYellowE,PCheckGoE,PCheckYellowE
PYellowE		DCD 0x54 ;1010100
				DCD 100
				DCD NWalk,NWalk,NWalk,NWalk,NWalk,NWalk,NWalk,NWalk
EWalk			DCD 0x36 ;0110110
				DCD 100
				DCD EWalkFlashOn,EWalkFlashOn,EWalkFlashOn,EWalkFlashOn,EWalkFlashOn,EWalkFlashOn,EWalkFlashOn,EWalkFlashOn
PCheckYellowE	DCD 0x54 ;1010100
				DCD 100
				DCD GoN,GoN,GoN,GoN,NWalk,NWalk,NWalk,NWalk
EWalkFlashOn	DCD 0x64 ;1100100
				DCD 50
				DCD EWalkFlashOff,EWalkFlashOff,EWalkFlashOff,EWalkFlashOff,EWalkFlashOff,EWalkFlashOff,EWalkFlashOff,EWalkFlashOff
EWalkFlashOff	DCD 0x24 ;0100100
				DCD 50
				DCD GoE,GoE,GoE,GoE,GoE,GoE,GoE,GoE
NWalkFlashOn	DCD 0x64 ;1100100
				DCD 50
				DCD NWalkFlashOff,NWalkFlashOff,NWalkFlashOff,NWalkFlashOff,NWalkFlashOff,NWalkFlashOff,NWalkFlashOff,NWalkFlashOff
NWalkFlashOff	DCD 0x24 ;0100100
				DCD 50
				DCD GoN,GoN,GoN,GoN,GoN,GoN,GoN,GoN
NYellowE		DCD 0x54
				DCD 100
				DCD GoN,GoN,GoN,GoN,PCheckGoN,PCheckGoN,PCheckGoN,PCheckGoN
NWalk			DCD 0x36 ;0110110
				DCD 100
				DCD NWalkFlashOn,NWalkFlashOn,NWalkFlashOn,NWalkFlashOn,NWalkFlashOn,NWalkFlashOn,NWalkFlashOn,NWalkFlashOn

				
				
				
Start
    LDR R1, =SYSCTL_RCGC2_R     
    LDR R0, [R1]
    ORR R0, R0, #(SYSCTL_RCGC2_GPIOE|SYSCTL_RCGC2_GPIOF) ; activate port E and port F 
    STR R0, [R1]                 
    NOP
    NOP                ; allow time to finish activating
    LDR R1, =GPIO_PORTE_DIR_R       
    LDR R0, [R1]     
    BIC R0, R0, #0x07  ; PE2-0 input
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTE_AFSEL_R    
    LDR R0, [R1]                    
    BIC R0, R0, #0x07  ; no alt funct                              
    STR R0, [R1]     
    LDR R1, =GPIO_PORTE_DEN_R       
    LDR R0, [R1]           
    ORR R0, R0, #0x07  ; enable PE2-0
    STR R0, [R1] 
    LDR R1, =GPIO_PORTF_DIR_R       
    LDR R0, [R1]     
    ORR R0, R0, #0x3F  ; PF5-0 output
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_AFSEL_R    
    LDR R0, [R1]                    
    BIC R0, R0, #0x3F  ; no alt funct                              
    STR R0, [R1]     
    LDR R1, =GPIO_PORTF_DEN_R       
    LDR R0, [R1]           
    ORR R0, R0, #0x3F  ; enable PF5-0
    STR R0, [R1]
	
	; activate clock for Port G
    LDR R1, =SYSCTL_RCGC2_R         ; R1 = &SYSCTL_RCGC2_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #SYSCTL_RCGC2_GPIOG ; R0 = R0|SYSCTL_RCGC2_GPIOG
    STR R0, [R1]                    ; [R1] = R0
    NOP
    NOP                             ; allow time to finish activating
    ; set direction register
    LDR R1, =GPIO_PORTG_DIR_R       ; R1 = &GPIO_PORTG_DIR_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x04               ; R0 = R0|0x04 (make PG2 output)
    STR R0, [R1]                    ; [R1] = R0
    ; regular port function
    LDR R1, =GPIO_PORTG_AFSEL_R     ; R1 = &GPIO_PORTG_AFSEL_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #0x04               ; R0 = R0&~0x04 (disable alt funct on PG2) (default setting)
    STR R0, [R1]                    ; [R1] = R0
    ; enable digital port
    LDR R1, =GPIO_PORTG_DEN_R       ; R1 = &GPIO_PORTG_DEN_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x04               ; R0 = R0|0x04 (enable digital I/O on PG2) (default setting on LM3S811, not default on other microcontrollers)
    STR R0, [R1]                    ; [R1] = R0
    LDR R6, =GPIO_PORTG2            ; R6 = &GPIO_PORTG2
    LDR R7, [R6]                    ; R7 = [R7]
	
    BL  PLL_Init       ; 50 MHz clock
    BL  SysTick_Init   ; enable SysTick
    LDR R4, =GoN       ; state pointer
    LDR R5, =SENSOR    ; 0x4002400C
    LDR R6, =LIGHT     ; 0x400250FC
	LDR R7, =GPIO_PORTG2 ; don't walk light output
	
	
FSM LDR R0, [R4, #OUT] ; output value
	LSR R1, R0, #4	   ;shift bit 6 to bit 2
	STR R1, [R7]	   ; set don't walk light
	AND R0, R0, #0x3F  ; get only the traffic light output
    STR R0, [R6]       ; set traffic lights
    LDR R0, [R4, #WAIT]; time delay 
    BL  SysTick_Wait10ms
    LDR R0, [R5]       ; read input
    LSL R0, R0, #2     ; 4 bytes/address
    ADD R0, R0, #NEXT  ; 8,12,16,20
    LDR R4, [R4, R0]   ; go to next state 
    B   FSM

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file

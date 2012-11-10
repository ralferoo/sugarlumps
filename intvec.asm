init_screen_state:
	di

	ld bc,#bc02
	out (c),c
	ld bc,#bd33		; centre
	out (c),c

	ld bc,#bc03
	out (c),c
	ld bc,#bd8d		; h width needs to be reduced for crtc 2
	out (c),c
	
	ld bc,#bc04
	out (c),c
	ld bc,#bd00+104-1	; lines total = 104
	out (c),c
	
	ld bc,#bc09
	out (c),c
	ld bc,#bd02		; 3 pixel high
;	ld c,#00		; 1 pixel high		<<< easy trigger for fail
	out (c),c
	
	ld a,#c3
	ld hl,intvec_start
	ld (#38),a
	ld (#39),hl

;	ld bc,#7f00
;	out (c),c
;	ld de,#1054
;	out (c),e
;	out (c),d
;	out (c),e

;	ld bc,#7f10
;	out (c),c
	ei
;	halt
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This is the vsync intterupt
;
; Always called every 6th interrupt after intvec_start has found a vsync,
; i.e. when we are off the top of the screen

intvec_vsync:			; band that extends off the top of the screen
	push bc
	
;	ld bc,DEBUG_PURPLE	; purple
;	out (c),c

; set mode 0 for the top half and pens 1-3
;	call top_half_mode	; set mode and colours for top half
;top_half_mode:	
	ld bc,#7f8c		; mode 0
	out (c),c
	; restore the colours for the top half
	push de
top_half_pen_1 equ $+1
	ld de,#014a
	out (c),d
	out (c),e
top_half_pen_2 equ $+1
	ld de,#0253
	out (c),d
	out (c),e
top_half_pen_3 equ $+1
	ld de,#034c
	out (c),d
	out (c),e
	pop de
;	ret

	ld bc,#bc01
	out (c),c
	ld bc,CRTC_R1_VALUE	; set the CRTC width appropriately
	out (c),c
		
	ld bc,#bc06
	out (c),c
	ld bc,#bd00+104		; visible lines = 103
	out (c),c

	ld bc,#bc0c
	out (c),c		; screen high byte
screen_1_hi equ $+1
	ld bc,#bd2c ;23
	out (c),c
	
	ld bc,#bc0d
	out (c),c		; screen low byte
screen_1_lo equ $+1
	ld bc,#bd00 ;f8
	out (c),c

	ld bc,#bc03
	out (c),c		; fine scroll
	ld bc,#bdf6
	out (c),c

	ld bc,#7f10
	out (c),c

vsync_count equ $+1
        ld bc,0
        inc bc
        ld (vsync_count),bc    

	; make border same colour as background and change pen 15 instead
;	ld bc,#7f44
;	out (c),c
;	ld bc,#7f0f
;	out (c),c
        	
	ld bc,intvec_2
	ld (#39),bc

	pop bc
	ei
	ret     

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This is the 2nd intterupt
;
; Called just before the top of screen 1 and delegates to the time aligned task

intvec_2:			; 2nd band, screen starts in this one
	push bc			

;	ld bc,DEBUG_WHITE	; white
;	out (c),c
	
	ld bc,#bc07
	out (c),c
	ld bc,#bdff		; no sync
	out (c),c
	
;	ld bc,DEBUG_GREEN	; green
;	out (c),c
	
	push de
	push hl
	push af
	
	ld bc,intvec_3
	ld (#39),bc
	ei

	ld bc,#bc01				; this code copied to start of
	out (c),c  				; render task
	ld bc,CRTC_R1_VALUE			; select reg 1, default value

task_jp_vector equ $+1
	jp dummy_task     

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; this is a dummy task that takes approximately the same time as the screen display

dummy_task:
;	ld bc,DEBUG_PURPLE2	; purple
;	out (c),c

	halt			; wait to cyan
	halt			; wait to red
	halt			; wait to yellow

	ld bc,#8003
dummy_task_final:
	djnz dummy_task_final
	dec c
	jr nz, dummy_task_final   	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This is jumped to by the time aligned task to return back to the background
; task

task_complete:
;	ld bc,DEBUG_ORANGE		; orange
;	out (c),c

	call do_scroll      

	; not enough time later on to do this in intvec_6 before the end of the
	; line, but must be done
	ld bc,#bc01
	out (c),c
	ld bc,SCROLL_WIDTH
	out (c),c

	ld bc,#bc03
	out (c),c		; fine scroll
screen_3_fine equ $+1
	ld bc,#bdf5
	out (c),c

; set mode 1 for the bottom half (scroller) and pens 1-3
;	call bottom_half_mode	; set mode and colours for bottom half
;bottom_half_mode:	
	ld bc,#7f8d		; mode 1
	out (c),c

;	push de
bottom_half_pen_1 equ $+1
	ld de,#014b
	out (c),d
	out (c),e
bottom_half_pen_2 equ $+1
	ld de,#0240 ;5f ;57
	out (c),d
	out (c),e
bottom_half_pen_3 equ $+1
	ld de,#0357 ;50
	out (c),d
	out (c),e
	ld c,#10
	out (c),c
;	pop de
;	ret			      



	pop af
	pop hl
	pop de
	pop bc
	ret			; this is the exit point after the task finishes

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This is the 3rd intterupt
;
; Called midway through screen 1

intvec_3:
;	ld bc,DEBUG_CYAN		; cyan
;	out (c),c
	
	ld bc,#bc0c
	out (c),c		; screen high byte
screen_2_hi equ $+1
	ld bc,#bd00+screen_2_crtc_h
	out (c),c
	
	ld bc,#bc0d
	out (c),c		; screen low byte
screen_2_lo equ $+1
	ld bc,#bd00+screen_2_crtc_l
	out (c),c

	ld bc,intvec_4
	ld (#39),bc

	; leave the CRTC and BC in the state we found them	
	ld bc,#bc01
	out (c),c
	ld bc,CRTC_R1_VALUE	; set the CRTC width appropriately

	ei
	ret     

;intvec_3_cycles equ 3+3+(3+4)*5+3+6+3+4+3+1+3
intvec_3_cycles equ 3+3+(3+4)*4+3+6+3+4+3+1+3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This is the 4th intterupt
;
; Called just before the top of screen 2

intvec_4:
;	ld bc,DEBUG_RED		; red
;	out (c),c

	ld bc,#bc07
	out (c),c
	ld bc,#bdff		; no sync
	out (c),c
	
	ld bc,intvec_5
	ld (#39),bc

	; leave the CRTC and BC in the state we found them	
	ld bc,#bc01
	out (c),c
	ld bc,CRTC_R1_VALUE	; set the CRTC width appropriately

	ei
	ret     

;intvec_4_cycles equ 3+3+(3+4)*3+3+6+3+4+3+1+3
intvec_4_cycles equ 3+3+(3+4)*2+3+6+3+4+3+1+3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This is the 5th intterupt
;
; Called midway through screen 2

intvec_5:
;	ld bc,DEBUG_YELLOW		; yellow
;	out (c),c
	
	ld bc,#bc06
	out (c),c
	ld bc,#bd00+88+1	; visible lines = 88
	out (c),c		; plus 1 for blank line at top
	
	ld bc,#bc0c
	out (c),c		; screen high byte
screen_3_hi equ $+1
	ld bc,#bd1a	;3c
	out (c),c
	
	ld bc,#bc0d
	out (c),c		; screen low byte
screen_3_lo equ $+1
	ld bc,#bd20	;00
	out (c),c

	ld bc,intvec_6
	ld (#39),bc

	; leave the CRTC and BC in the state we found them	
	ld bc,#bc01
	out (c),c
	ld bc,CRTC_R1_VALUE	; set the CRTC width appropriately

	; test of wrong width left in register
;	ld bc,#bdff	;28	; 32 chars wide, 8 to the start
;	out (c),c

	ei
	ret     

;intvec_5_cycles equ 3+3+(3+4)*7+3+6+3+4+3+1+3
intvec_5_cycles equ 3+3+(3+4)*6+3+6+3+4+3+1+3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This is the 6th intterupt
;
; Called just before the top of screen 3 (ie the scroller)

intvec_6:
	push bc
	 
;	ld bc,DEBUG_PINK		; pink
;	out (c),c

	ld bc,#bc07
	out (c),c
	ld bc,#bd00+49		; sync at line 64
	out (c),c
	
	ld bc,#bc06
	out (c),c
	ld bc,#bd10		; 16 visible lines
	out (c),c

	ld bc,intvec_vsync
	ld (#39),bc
 
        call do_music_corrupt_only_bc

	pop bc
	ei
	ret     

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This is the initial intterupt used for vsync detection
;
; Does nothing until a vsync is detected, then it chains to the 2nd interrupt

intvec_start:
	push bc
	push af

blank_frames equ $+1
	ld a,20
	dec a
	ld (blank_frames),a
	jr nz, not_found_vsync
	
done_blank_frames:
	ld bc,intvec_start2
	jr store_bc_ei_ret

intvec_start2:
	push bc
	push af

stall_out equ $+1
	ld a,12
	dec a
	ld (stall_out),a
	jr nz,no_stall_out

	ld bc,#bc02
	out (c),c
	ld bc,#bd32		; centre can't be 33 on old crtc type
	out (c),c

;	ld a,#c9
;	ld (do_scroll),a
	
no_stall_out:	
	ld b,#f5		; check for vsync, if we get it, we're on
        in b,(c)		; line 2
        rr b
        jr nc,not_found_vsync

	ld bc,intvec_start_3
	jr store_bc_ei_ret

intvec_start_3:			; line 54
	push bc
	push af
	ld bc,#bc09
	out (c),c
	ld bc,#bd00		; 1 pixel high
	out (c),c
	
	ld bc,intvec_2
store_bc_ei_ret:
	ld (#39),bc

not_found_vsync:
        pop af
	pop bc
	ei
	ret     



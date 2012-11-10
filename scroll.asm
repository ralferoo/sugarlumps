;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; update the scroll position

do_scroll:
;	ret
	  
scroll_ptr equ $+1
	ld hl,#4000		; #c000 -> 30, #4000 -> 10
	inc hl
	res 3,h
	ld (scroll_ptr),hl	; update scroll screen address
	
	ld a,h			; 40..47
	sub #20			; 20..27, carry=0
	rra			; 10..13, carry=bit0

	ld (screen_3_hi),a
	ld a,l
	rra

	ld (screen_3_lo),a
	
	; want F5 when odd, F6 when even
	; ccf : sbc a,a : neg : add a,#f5

	sbc a,a
	add a,#f6
	
	ccf
	sbc a,a
	neg
	add a,#f5
	ld (screen_3_fine),a
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ld bc,SCROLL_BYTES-3
        add hl,bc
        res 3,h                    ; hl = destination buffer
        
scroll_source equ $+1
        ld de,font_buffer+#400

scroll_pixel equ $+1
        ld a,1
        dec a
        jr nz,store_scroll_pixel

        push bc
skip_bad_char:
next_scroll_char equ $+1
        ld bc,initial_scroll_message
restart_msg:
        ld a,(bc)
        inc bc
        add a,a
        jr nz,no_restart_msg

scroll_message_reset equ $+1
        ld bc,initial_scroll_message
        jr restart_msg

no_restart_msg:        
        ld (next_scroll_char),bc

        ld b,font_buffer/256
        ld c,a
        ld a,(bc)
        inc c
        ld e,a
        ld a,(bc)
        inc c
        ld d,a
        or e
        jr z,skip_bad_char

; now de = pixel data for the next character, first fetch and store the width

        ld a,(de)
        or a
        jr z,skip_bad_char
        add a,3
        sra a
        sra a
        inc de
        pop bc        

store_scroll_pixel:
        ld (scroll_pixel),a                                                                                                       	
        ld bc,SCROLL_BYTES
	
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h

	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h

	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	ld a,(de)
	inc de
	ld (hl),a
	add hl,bc
	res 3,h
	
        ld (scroll_source),de

	ret	      	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;

initial_scroll_message: DEFB " ",0

scroll_message:

        DEFB "IN 2011, A NEW DAY DAWNED ON THE 8-BIT SCENE. "
        DEFB "THE BATMAN FOREVER DEMO KICKED THE AMSTRAD CPC INTO THE SCENE!"
        DEFB "            "
        
        DEFB "I DUSTED OFF MY CPC 464, JOINED THE CRTC DEMO "
        DEFB "GROUP AND STARTED WORKING ON A CHUNKY PIXEL TRIANGLE RENDERER "
        DEFB "WHICH SOMEHOW MORPHED INTO A SMALL INTRO..."
        
        DEFB "                              "

	DEFB "   CREDITS   "
	DEFB "   ...   "
	DEFB "CODE / GFX: DOZ"
	DEFB "   ...   "
	DEFB "MUSIC: MR_LOU"
	DEFB "   ...   "
	DEFB "FONT: 04.JP.ORG"
	DEFB "   ...   "

        DEFB "GREETZ: PUPPEH, MEGMEG, TUNK, DELTAFIRE, RC55, JOEY, REENIGNE, "
        DEFB "JIMJAM, "
        DEFB "M0D, SIL, H0FFMAN, REED, GASMAN, FRANKY, DOTWAFFLE, DANBEE, DFOX, TOPY44, "
        DEFB "KRUSTY, ELIOT, VOXFREAX FROM BENEDICTION, "
        DEFB "BRYCE, ARNOLDEMU, GRYZOR, DEVILMARKUS AND EVERYONE AT CPCWIKI.EU, "
        DEFB "AND FINALLY BATMAN GROUP FOR INSPIRING ME TO START CPC CODING AGAIN "
        DEFB "AFTER 23 YEARS!"     
        DEFB "                              "

     
        DEFB "   AND NOW, THE REAL-TIME TWISTER.        "
        DEFB "NORMALLY, A TWISTER IS FAIRLY SIMPLE - EACH POSSIBLE LINE IS "
        DEFB "PRE-CALCULATED AND SO IT'S NOT POSSIBLE TO DO MUCH EXCEPT "
        DEFB "VARY THE SPEED.     HOWEVER, IF YOU CALCULATE THE TWISTER "
        DEFB "IN REALTIME, YOU CAN HAVE A LOT MORE FUN... :)       "

        DEFB "                              "
        
        defb "PRESENTED AT SUNDOWN 2012. "
        DEFB "THANKS TO RC55 AND THE REST OF THE TEAM FOR THIS FANTASTIC EVENT!" 

        defb "     SEE YOU NEXT YEAR!"

        DEFB "                              "

	defb 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; put known pattern on screen
	  	    
clear_screen:
	ld hl,#4000
	call clear_area
	ld hl,#c000
	call clear_area
	ld hl,#8000
clear_area:
	push hl
	pop de
	inc de
	ld (hl),0
	ld bc,#7ff
	ldir
	ret   
	  	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; set colour palette

set_palette:
        ld bc,#7f10
        out (c),c
        ld c,(hl)
        inc hl  
        out (c),c   ; border colour
        xor a
        out (c),a
        out (c),c   ; background
        
        ld a,(hl)
        ld (top_half_pen_1),a   ; pen 1
        inc hl
        
        ld a,(hl)
        ld (top_half_pen_2),a   ; pen 2        
        inc hl
        
        ld a,(hl)
        ld (top_half_pen_3),a   ; pen 3
        
        ld a,4
        out (c),a
palette_loop:
        inc hl
        ld c,(hl)
        out (c),c               ; pens 4-15
        inc a
        out (c),a
        cp 16
        jr nz,palette_loop
        ret
                             
	  	    


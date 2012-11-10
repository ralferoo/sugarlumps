;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; sets the current draw colour to a

set_colour:
	ld (draw_line_colour),a		   
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; draws a polygon sepcified in hl
;
; hl = poly list (x1, y1, ... xn, yn, 0)

draw_poly:
        ld a,(hl)
        or a
        ret z
        
        inc hl
        ld d,(hl)
        ld e,a
        inc hl                            ; get x0, y0
        push de
        jr poly_continue
        
poly_loop:
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl                            ; next point
poly_continue:
        ld a,(hl)
        or a
        jr z, poly_end
        push hl
        inc hl
        ld h,(hl)
        ld l,a
        call draw_line
        pop hl
        jr poly_loop

poly_end:
        pop hl                            ; first point again
        jp draw_line                       

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; add line to line stack, note this line must be completely on the playfield
;
; draws line segment (l,h) -> (e,d), i.e. low byte is x-coord, high byte is y

draw_line:
        ld a,d
        sub h                             ; deltay
        ret z                             ; nothing to do for a horizontal line  
        jr nc, positive_deltay
        ex hl,de       
        neg
positive_deltay:
        ld d,a                            ; save deltay in d
        ld yl,d                           ; save loop counter    

        sra a
        ld c,a				  ; c=deltay/2 = initial error

        ld a,e
        sub l                             ; deltax
        jr nc, positive_deltax

negative_deltax:                
        neg
        ld b,a                            ; save deltax

        ld b,1                            ; compensate for extra iteration
calc_neg_step:
        dec b
        sub d                             ; deltax -= deltay
        jr nc, calc_neg_step              ; repeat
        add a,d                           ; make sure deltax is +ve
        ld e,a                            ; save mod(deltax) in e
                                          ; b=int(deltax/deltay)  
        ld xh,-4                          ; xh=xinc

        ld a,h
        sub PLAYFIELD_Y_OFFSET
        jr nc, starts_below_top
starts_off_top:                           ; off top of screen
        ld h,a                            ; keep as a counter                                                                

next_off_top:
        ld a,c
        sub e
        jr nc, poly_find_top
        add a,d
        ld c,a

        ld a,xh
        srl a
        srl a
        add a,l
        add a,b
        ld l,a                            ; x += xinc
        
        dec yl
        ret z
        
        inc h                             ; y += 1
        jr nz, next_off_top

        ld h, render_page                                  
        jr starts_on_screen                                  

poly_find_top:
        ld c,a
        
        ld a,l
        add a,b
        ld l,a

        dec yl
        ret z
        
        inc h
        jr nz, next_off_top

        ld h, render_page                                  
        jr starts_on_screen                                  

positive_deltax:         
        ld b,a                            ; save deltax

        ld b,-1                           ; compensate for extra iteration
calc_pos_step:
        inc b
        sub d                             ; deltax -= deltay
        jr nc, calc_pos_step              ; repeat
        add a,d                           ; make sure deltax is +ve
        ld e,a                            ; save mod(deltax) in e
                                          ; b=int(deltax/deltay)  
        ld xh,4                           ; xh=xinc

        ld a,h
        sub PLAYFIELD_Y_OFFSET
        jr c, starts_off_top              ; off top of screen
starts_below_top:
        add a,render_page
        ret c                             ; off bottom of screen  

        ld h,a                            ; y part of address done

starts_on_screen:
        sla l         
        scf                                  
        rl l                              ; shift in 1, check next bit

        ld (draw_wholly_unclipped_line_sp_save),sp
draw_sp equ $+1
        ld sp,0
        push de                           ; save deltas
        
        ld a,b                            ; int(deltax/deltay)
        add a,a
        add a,a                           ; 4*int(deltax/deltay)
        ld e,a                            ; xl = xstep
        add xh
        ld d,a                            ; xh = xstep+xinc
        push de                           ; save x steps
        
        ld b,yl                           ; loop counter is also deltay    
        xor a
        sub h                             ; h=lines left on screen
        cp b
        jr nc,no_truncate_bottom          ; no carry, b < lines left
        ld b,a                            ; truncate

no_truncate_bottom:
	ld a,c	   
;        ld yl,0                           ; iy = af for line, deltax/2, NZ

draw_line_colour equ $+1
	ld c,0

        push hl                           ; save address
        push bc                           ; save loop + colour

	ld c,0
	ld b,a
        push bc                           ; save error and nz flag

        ld (draw_sp),sp
draw_wholly_unclipped_line_sp_save equ $+1
        ld sp,0
        ret         



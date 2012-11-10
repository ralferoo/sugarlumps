;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; not happy with the existing clipping stuff at all - it seems to complicate
; everything and still has loads of stack access so isn't massively quick
;
; also going to try a new poly format for lines:
; point1, point2, ..., pointn, 0
;
; clip_poly - ix = source, iy = dest
clip_poly:
        ld l,(ix+0)
	inc ix
	ld h,(ix+0)
	inc ix					; HL = first point
	
	ld a,l
	or a
	jp z,clip_poly_finished			; no points at all

	push hl					; save first point
		
	sub PLAYFIELD_X_OFFSET
	jr c,clip_poly_starts_off_left
	
	sub PLAYFIELD_WIDTH+1
	jr nc,clip_poly_starts_off_right 	  

clip_poly_onscreen_loop:			; HL = point on screen
	ld (iy+0),l
	inc iy
	ld (iy+0),h				; copy point straight through
	inc iy

	ex hl,de				; DE = last point

        ld l,(ix+0)
	inc ix
	ld h,(ix+0)
	inc ix					; HL = next point					
	
	ld a,l
	or a
	jp z,clip_poly_end_point
	
clip_poly_onscreen_test:
	sub PLAYFIELD_X_OFFSET
	jr c,clip_poly_onscreen_to_left		; just gone off screen

	sub PLAYFIELD_WIDTH+1
	jr c,clip_poly_onscreen_loop

clip_poly_onscreen_to_right:			     	  
	inc a
	ld l,a
	ld a,e
	sub PLAYFIELD_X_OFFSET+PLAYFIELD_WIDTH
	ld e,a
	call find_midpoint_hl_de		; get midpoint y in a
	
	ld (iy+0),PLAYFIELD_X_OFFSET+PLAYFIELD_WIDTH
	inc iy
	ld (iy+0),a
	inc iy					; store point we cross right

clip_poly_off_right_loop:
	ex hl,de				; DE = last off right point (E +ve) 		     	       

        ld l,(ix+0)
	inc ix
	ld h,(ix+0)
	inc ix					; HL = next point					
	
	ld a,l
	or a
	jp z,clip_poly_off_right_end_point
	
	sub PLAYFIELD_X_OFFSET+PLAYFIELD_WIDTH
	ld l,a
        jr z,clip_poly_off_right_loop_end	
	jr nc,clip_poly_off_right_loop		; still off right, loop more

;	inc a
clip_poly_off_right_loop_end:
	call find_midpoint_hl_de		; get midpoint y in a
	
	ld e,PLAYFIELD_X_OFFSET+PLAYFIELD_WIDTH
	ld d,a					; save this new position
	
	ld (iy+0),e
	inc iy
	ld (iy+0),a
	inc iy					; store point we cross back

	ld a,l
	add a,e					; fix HL
	ld l,a
	jr clip_poly_onscreen_test		; check possible RH cross...

clip_poly_starts_off_right:			  			  			  
	inc a
	ld l,a
	jr clip_poly_off_right_loop

clip_poly_starts_off_left:			  			  			  
	ld l,a
	jr clip_poly_off_left_loop

clip_poly_off_left_end_point:
	pop hl					; HL = first point					

	ld a,l
	sub PLAYFIELD_X_OFFSET
	jp c,clip_poly_finished			; still off left, we're done
	
	ld l,a	
	call find_midpoint_hl_de		; get midpoint y in a
	
	ld e,PLAYFIELD_X_OFFSET
	ld d,a					; save this new position
	
	ld (iy+0),e
	inc iy
	ld (iy+0),a
	inc iy					; store point we cross back

	ld a,l
	add a,e					; fix HL
	ld l,a
	jr clip_poly_onscreen_test_last		; check possible RH cross...

clip_poly_onscreen_to_left:
	ld l,a
	ld a,e
	sub PLAYFIELD_X_OFFSET
	ld e,a
	call find_midpoint_hl_de		; get midpoint y in a
	
	ld (iy+0),PLAYFIELD_X_OFFSET
	inc iy
	ld (iy+0),a
	inc iy					; store point we cross left

clip_poly_off_left_loop:
	ex hl,de				; DE = last off left point (E -ve) 		     	       

        ld l,(ix+0)
	inc ix
	ld h,(ix+0)
	inc ix					; HL = next point					
	
	ld a,l
	or a
	jr z,clip_poly_off_left_end_point
	
	sub PLAYFIELD_X_OFFSET
	ld l,a	
	jr c,clip_poly_off_left_loop		; still off left, loop more

	call find_midpoint_hl_de		; get midpoint y in a
	
	ld e,PLAYFIELD_X_OFFSET
	ld d,a					; save this new position
	
	ld (iy+0),e
	inc iy
	ld (iy+0),a
	inc iy					; store point we cross back

	ld a,l
	add a,e					; fix HL
	ld l,a
	jp clip_poly_onscreen_test		; check possible RH cross...

clip_poly_off_right_end_point:
	pop hl					; HL = first point					

	ld a,l
	sub PLAYFIELD_X_OFFSET+PLAYFIELD_WIDTH+1
	jr nc,clip_poly_finished		; still off right, we're done
	
	inc a
	ld l,a	
	call find_midpoint_hl_de		; get midpoint y in a
	
	ld e,PLAYFIELD_X_OFFSET+PLAYFIELD_WIDTH
	ld d,a					; save this new position
	
	ld (iy+0),e
	inc iy
	ld (iy+0),a
	inc iy					; store point we cross back

	ld a,l
	add a,e					; fix HL
	ld l,a
	jr clip_poly_onscreen_test_last		; check possible RH cross...

clip_poly_end_point:
	pop hl					; HL = first point					

clip_poly_onscreen_test_last:
	ld a,l
	sub PLAYFIELD_X_OFFSET
	jr c,clip_poly_finish_on_left		; find boundary on midpoint
	sub PLAYFIELD_WIDTH+1
	jr c,clip_poly_finished			; first point was on, done

clip_poly_finish_on_right:
	inc a
	ld l,a

	ld a,e
	sub PLAYFIELD_X_OFFSET+PLAYFIELD_WIDTH
	ld e,a

	call find_midpoint_hl_de		; get midpoint y in a
			 
	ld (iy+0),PLAYFIELD_X_OFFSET+PLAYFIELD_WIDTH
	inc iy
	ld (iy+0),a
	inc iy					; store point we cross left
	ld (iy+0),0
	ret

clip_poly_finish_on_left:			 
	ld l,a

	ld a,e
	sub PLAYFIELD_X_OFFSET
	ld e,a

	call find_midpoint_hl_de		; get midpoint y in a
			 
	ld (iy+0),PLAYFIELD_X_OFFSET
	inc iy
	ld (iy+0),a
	inc iy					; store point we cross left

clip_poly_finished:
	ld (iy+0),0
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; finds midpoint of h and d in a (all unsigned), using -l and e as the bias ratios
; preserve hl, result in a, corrupt bc and de 
;

fmp_retry:

fmp_de_save equ $+1
        ld de,0
fmp_hl_save equ $+1
        ld hl,0
        jr find_midpoint_hl_de         

find_midpoint_hl_de:
        ld (fmp_de_save),de            
        ld (fmp_hl_save),hl            

	ld a,e
	add a,a
	jr c, de_negative	    
	jr z,midpoint_return_d

        ld a,l
        or a
	jr z,midpoint_return_h
        
	ld b,d
	ld c,e
	ld d,h
	ld e,l
	jr midpoint_left_test_x 

de_negative:
	ld b,h
	ld c,l
	jr midpoint_left_test_x    

; finds midpoint of B and H (unsigned) by using the ratios of C and -L
; result in A 
;
; BC=right point (C +ve), DE=left point (L -ve)

midpoint_move_left:
	sra a			; result was +ve, so still moving left.
	ld c,a			; so the midpoint becomes our new right point
	jr z,midpoint_found

	ld a,b
	add a,d
	rra
	ld b,a			; and average the y coordinate  			
		    
midpoint_left_test_x:			   
	ld a,c
	add a,e
	jr c,midpoint_move_left	; carry means still keep moving left 

midpoint_move_right:
	inc a
	sra a			; result was -ve, so move right
	ld e,a			; so the midpoint becomes our new left point
	jr z,midpoint_found

	ld a,b
	add a,d
	rra
	adc a,0
	ld d,a			; and average the y coordinate  			
		    
	ld a,c
	add a,e
	jr c,midpoint_move_left	; carry means still keep moving left 
	jr midpoint_move_right		; carry means keep moving right

midpoint_found:
	ld a,b
	add a,d
	rra
	ret

midpoint_return_d:
        ld a,d
        ret

midpoint_return_h:
        ld a,h
        ret
                  

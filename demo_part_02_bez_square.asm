demo_02:
        xor a
loop_part_02:
        call draw_part_02
        call swap_buffers
        call get_frame_count
        jr nc, loop_part_02                                        

        jp swap_buffers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_part_02:
        ld c,a
             
p02_rot_angle equ $+1
	add a,0
	ld e,a
	ld (p02_rot_angle),a

        ld b,8
        ld hl,p02_rates
p02_calc_loop:
        push bc

        ex af,af'
        ld b,(hl)
        inc hl
        xor a
p02_calc_loop2:
        add a,c
        djnz p02_calc_loop2
        add a,(hl)
        ld (hl),a
        inc hl                            
	ld e,a

	ld d, base_sin_table/256
        call calc16sincos
	ex af,af'

        call calc_part02_nextpart

        pop bc
        push de                 ; save the coords
        dec b
        jr nz, p02_calc_loop      ; repeat for all	


p02_rot_angle_inner equ $+1
	ld a,0
	sub c
	ld e,a
	ld (p02_rot_angle_inner),a

        ld b,8
;        ld hl,p02_rates
p02_calc_loop_inner:
        push bc

        ex af,af'
        ld b,(hl)
        inc hl
        xor a
p02_calc_loop2_inner:
        add a,c
        djnz p02_calc_loop2_inner
        add a,(hl)
        ld (hl),a
        inc hl                            
	ld e,a

	ld d, base_sin_table/256
        call calc16sincos
	ex af,af'

        call calc_part02_nextpart_inner

        pop bc
        push de                 ; save the coords
        dec b
        jr nz, p02_calc_loop_inner      ; repeat for all	

	ld hl,2*7
	add hl,sp
	
	ld e,(hl)
	inc hl
	ld d,(hl)               ; DE = first point
	
        ld ix,poly_buffer
	ld b,4
p02_draw_loop_inner:
        ld a,b      
        pop bc
        pop hl
        push af
        push hl
        call draw_bezier_segment       
	pop de
	pop bc
	djnz p02_draw_loop_inner
	
        ld (ix+0),0
        ld ix,poly_buffer
        ld iy,poly_buffer2
        call clip_poly

        ld a,PEN_2
	ld (draw_line_colour),a		   
        ld hl,poly_buffer2

        call draw_poly

;;;	
	
	ld hl,2*7
	add hl,sp
	
	ld e,(hl)
	inc hl
	ld d,(hl)               ; DE = first point
	
        ld ix,poly_buffer
	ld b,4
p02_draw_loop:
        ld a,b      
        pop bc
        pop hl
        push af
        push hl
        call draw_bezier_segment       
	pop de
	pop bc
	djnz p02_draw_loop
	
        ld (ix+0),0
        ld ix,poly_buffer
        ld iy,poly_buffer2
        call clip_poly

        ld a,PEN_1
	ld (draw_line_colour),a		   
        ld hl,poly_buffer2

        jp draw_poly

calc16sincos:
	ld a,(de)
	xor #80
	sra a
	sra a
	sra a
	sra a                   ; +- 7
	ld c,a
	ld a,e
	add a,#40

	ld e,a
	ld a,(de)
	xor #80
	sra a
	sra a
	sra a
	sra a                   ; +- 7
	ld b,a                  ; BC=8*sincos(partial angle)
	
        ret
        
calc_part02_nextpart:
	ld e,a        
	ld a,(de)
	xor #80
	sra a
	sra a                   ; +- 16
	add a,c
	add a,PLAYFIELD_X_OFFSET+#20
	ld c,a
        ld a,e
        add a,#40
        
	ld e,a        
	ld a,(de)
	xor #80
	sra a
	sra a                   ; +- 16
	add a,b
	add a,#80 ;PLAYFIELD_Y_OFFSET+(num_rows/2)
	ld d,a

        ld a,e
        add a,#c0+#20

	ld e,c
        ret

calc_part02_nextpart_inner:
	ld e,a        
	ld a,(de)
	xor #80
 	sra a
	sra a
	sra a                   ; +- 16
	add a,c
	add a,PLAYFIELD_X_OFFSET+#20
	ld c,a
        ld a,e
        add a,#40
        
	ld e,a        
	ld a,(de)
	xor #80
	sra a
	sra a
	sra a                   ; +- 16
	add a,b
	add a,#80 ;PLAYFIELD_Y_OFFSET+(num_rows/2)
	ld d,a

        ld a,e
        add a,#c0+#20

	ld e,c
        ret

p02_rates:
        defw #8009
        defw #a008
        defw #c007
        defw #e006

        defw #0003
        defw #2002
        defw #4007
        defw #6005

          
        defw #1001
        defw #2002
        defw #3003
        defw #4005

        defw #5007
        defw #600b
        defw #7703
        defw #8001

          
        defw #c000;3
        defw #8000;5
        defw #4000;7
        defw #aa00;4

        defw #2200;9
        defw #5500;6
        defw #0000;2
        defw #dd00;1
                       


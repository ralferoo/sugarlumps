demo_bezier:

        xor a 
bezierloop:
        call draw_test_bezier
        call swap_buffers
        call get_frame_count
        jr nc, bezierloop 
        ret
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_test_bezier:
        ld b,a
                 
	ld d, base_sin_table/256
bez1_angle equ $+1
	ld a,6
	add a,b
	ld e,a
	ld (bez1_angle),a
	call sincos
	ld (bez_sincos1a),hl
	ld (bez_sincos1b),hl
	
bez2_angle equ $+1
	ld a,99
	add a,b
	add a,b
	add a,b
	add a,b
	add a,b
	ld e,a
	ld (bez2_angle),a
	call sincos
	ld (bez_sincos2a),hl
	ld (bez_sincos2b),hl
	
bez3_angle equ $+1
	ld a,167
	add a,b
	add a,b
	ld e,a
	ld (bez3_angle),a
	call sincos
	ld (bez_sincos3),hl
	
bez4_angle equ $+1
	ld a,200
	add a,b
	add a,b
	add a,b
	ld e,a
	ld (bez4_angle),a
	call sincos
	ld (bez_sincos4),hl

bez5_angle equ $+1
	ld a,240
	add a,b
	add a,b
	add a,b
	add a,b
	add a,b
	ld e,a
	ld (bez5_angle),a
	call sincos
	ld (bez_sincos5a),hl
	ld (bez_sincos5b),hl
	
bez6_angle equ $+1
	ld a,24
	add a,b
	add a,b
	add a,b
	ld e,a
	ld (bez6_angle),a
	call sincos
	ld (bez_sincos6a),hl
	ld (bez_sincos6b),hl
	
bez7_angle equ $+1
	ld a,67
	add a,b
	ld e,a
	ld (bez7_angle),a
	call sincos
	ld (bez_sincos7),hl
	
bez8_angle equ $+1
	ld a,100
	add a,b
	add a,b
	ld e,a
	ld (bez8_angle),a
	call sincos
	ld (bez_sincos8),hl


        ld a,PEN_1
	ld (draw_line_colour),a		   
        
        ld ix,poly_buffer
bez_sincos1a equ $+1
        ld de,#013e
bez_sincos2a equ $+1
        ld hl,#2e01
bez_sincos3 equ $+1
        ld bc,#0000
        call draw_bezier_segment       

bez_sincos2b equ $+1
        ld de,#013e
bez_sincos1b equ $+1
        ld hl,#2e01
bez_sincos4 equ $+1
        ld bc,#3e25
        call draw_bezier_segment       

        ld (ix+0),0
        ld ix,poly_buffer
        ld iy,poly_buffer2
        call clip_poly
        ld hl,poly_buffer2
        call draw_poly

        ld a,PEN_2
	ld (draw_line_colour),a		   

        ld ix,poly_buffer
bez_sincos5a equ $+1
        ld de,#013e
bez_sincos6a equ $+1
        ld hl,#2e01
bez_sincos7 equ $+1
        ld bc,#0000
        call draw_bezier_segment       

bez_sincos6b equ $+1
        ld de,#013e
bez_sincos5b equ $+1
        ld hl,#2e01
bez_sincos8 equ $+1
        ld bc,#3e25
        call draw_bezier_segment       

        ld (ix+0),0
        ld ix,poly_buffer
        ld iy,poly_buffer2
        call clip_poly
        ld hl,poly_buffer2

        jp draw_poly      
	

sincos:
	ld a,(de)
        xor #80
        sra a
        sra a
        ld c,a
        sra a
        sra a
        sra a
        neg
        add a,c
        add a,32+PLAYFIELD_X_OFFSET
        ld l,a
        
        ld a,e
        add a,#40
        ld e,a                                                         

        ld a,(de)        
        xor #80
        sra a              ; +- 64
        sra a              ; +- 32
        sra a              ; +- 16
        ld c,a
        add a,51
        sra a              ; +- 8
;        sra a              ; +- 4
        add a,c            ; +- 24
        add a,PLAYFIELD_Y_OFFSET
        ld h,a
	ret




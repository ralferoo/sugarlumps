;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; basic rotation demo



demo_part_0150_poly:

        call swap_buffers
        call swap_buffers

        ld a,#7e
        ld (demo_part_0150_poly_angle),a

        ld hl,#17f
        ld (poly_info1+7),hl
        dec h
        ld (poly_info2+7),hl
        ld (poly_info3+7),hl

        ld a,PLAYFIELD_X_OFFSET+96
        ld (poly_info1+4),a
        ld (poly_info2+4),a
        ld (poly_info3+4),a

        ld a,PEN_1
        ld (poly_info1+6),a
        ld a,PEN_2
        ld (poly_info2+6),a
        ld a,PEN_4
        ld (poly_info3+6),a

        ld hl,demo_03_trans_palette
        call set_palette
        
        ld a,256-#58
        call set_frame_count
        xor a  

demo_part_0150_poly_loop1:
        call part_0150_rotangle_work                    
        jp nc, demo_part_0150_poly_loop1

        ld hl, poly_info2+8
        ld (hl),1

        push af
        ld a,256-#58
        call set_frame_count
        pop af

demo_part_0150_poly_loop2:
        call part_0150_rotangle_work                    
        jp nc, demo_part_0150_poly_loop2

        ld hl, poly_info3+8
        ld (hl),1

demo_part_0150_poly_loop3:
        call part_0150_rotangle_work                    
        jp nc, demo_part_0150_poly_loop3




        ld c,a
        ld a,PEN_1 and #55
        ld (poly_info1+6),a
        ld a,#c0
        call set_frame_count
        ld a,c

demo_part_0150_poly_fade_1:
        call part_0150_rotangle_work                    
        jp nc, demo_part_0150_poly_fade_1

        ld c,a
        ld a,PEN_4 and #55
        ld (poly_info3+6),a
        xor a
        ld (poly_info1+6),a
        ld a,#c0
        call set_frame_count
        ld a,c

demo_part_0150_poly_fade_2:
        call part_0150_rotangle_work                    
        jp nc, demo_part_0150_poly_fade_2

        ld c,a
        ld a,PEN_2 and #55
        ld (poly_info2+6),a
        xor a
        ld (poly_info3+6),a
        ld a,#c0
        call set_frame_count
        ld a,c

demo_part_0150_poly_fade_3:
        call part_0150_rotangle_work                    
        jp nc, demo_part_0150_poly_fade_3

        ld c,a
        xor a
        ld (poly_info2+6),a
        ld a,#c0
        call set_frame_count
        ld a,c

        call swap_buffers
        call swap_buffers

        ld hl,default_palette        
        call set_palette
        call reset_frame_count  
        ret 



part_0150_rotangle_work:
        call part_0150_rotangle                  

        ld ix, poly_info1
        call sincos_0150
        ld ix, poly_info2
        call sincos_0150
        ld ix, poly_info3
        call sincos_0150


        ld ix, poly_info1
        call draw_0150_poly
        ld ix, poly_info2
        call draw_0150_poly
        ld ix, poly_info3
        call draw_0150_poly
        
        call swap_buffers
        jp get_frame_count




poly_info1:
        defb 3, #40+#55, 3, 0, PLAYFIELD_X_OFFSET+96, #74, PEN_1, 127, 1
poly_info2:
        defb 4, #40+#40, 4, 0, PLAYFIELD_X_OFFSET+96, #70, PEN_2, 127, 0
poly_info3:
        defb 5, #40+#33, 5, 0, PLAYFIELD_X_OFFSET+96, #70, PEN_4, 127, 0

part_0150_rotangle:
        ld (slide_0150_adj),a                  

        add a,a
demo_part_0150_poly_angle equ $+1
	ld de, base_sin_table+#0
        add a,e
        ld (demo_part_0150_poly_angle),a
        ret

sincos_0150:
        ld a,(ix+8)
        or a
        jr z,adjust_0150
            
        ld a,(ix+7)
        or a
        jr z, do_sincos_0150    

slide_0150_adj equ $+1
        sub 0
        jr nc, store_0150
        xor a
store_0150:
        ld (ix+7),a
        
        sra a
        add a,PLAYFIELD_X_OFFSET+32
        ld (ix+4),a
        
        ld a,#70
        ld (ix+5),a

adjust_0150:        
        ld a,e
        add a,#55
        ld e,a
        ret           

do_sincos_0150:
        ld a,(de)
        srl a
        srl a
        srl a
        add a,PLAYFIELD_X_OFFSET+32-16
        ld (ix+4),a

        ld a,e
        add a,#40
        ld e,a
                                
        ld a,(de)
        srl a
        srl a
        srl a
        add a,#70
        ld (ix+5),a

        ld a,e
        add a,#c0+#55
        ld e,a
        ret                        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
draw_0150_poly:
	ld hl, poly_buffer
	ld d, base_sin_table/256

	ld a,(ix+2)
	add (ix+3)
	ld (ix+3),a
	
	ld b,(ix+0)
draw_0150_poly_loop:   
	ld e,a
	ld a,(de)
	xor #80
	sra a
	sra a
	sra a
	add (ix+4)
	ld (hl),a
	inc hl    

	ld a,e
	sub #40
	ld e,a
	ld a,(de)
	xor #80
	sra a
	sra a
	sra a
	add (ix+5)
	ld (hl),a
	inc hl    

	ld a,e
	add (ix+1)
	djnz draw_0150_poly_loop

        xor a
        ld (hl),a

        ld a,(ix+6)
        call set_colour               

        ld ix,poly_buffer
        ld iy,poly_buffer2
        call clip_poly
        ld hl,poly_buffer2
        jp draw_poly

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



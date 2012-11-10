;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CRTC logo with triangle on top

demo_part_0150_crtc:
        call demo_part_0150_draw_c
        call swap_buffers_no_erase
        call demo_part_0150_delay
        
        call demo_part_0150_draw_r
        call swap_buffers_no_erase
        call demo_part_0150_delay
        
        call demo_part_0150_draw_t
        call swap_buffers_no_erase
        call demo_part_0150_delay
        
        call demo_part_0150_draw_c2
        call swap_buffers_no_erase
        call demo_part_0150_delay

        xor a
        ld (draw_test_crtc_offset),a

crtcloop1:
        call draw_test_crtc
        call swap_buffers
        call get_frame_count
        jr nc, crtcloop1 

crtcloop2:
        call draw_test_crtc
        call swap_buffers
        call get_frame_count
        jr nc, crtcloop2 

        xor a
        ld (draw_test_crtc_offset),a

crtcloop3:
        call draw_test_crtc_off
        call swap_buffers
        call get_frame_count
        jr nc, crtcloop3 

        call demo_part_0150_draw_c
        call demo_part_0150_draw_r
        call demo_part_0150_draw_t
        call demo_part_0150_draw_c2
        jp swap_buffers_no_erase

        
        
        
demo_part_0150_delay:        
        ld a,#e0
        call set_frame_count
demo_part_0150_delay_loop:        
        call swap_buffers
        call get_frame_count
        jr nc, demo_part_0150_delay_loop
        ret 
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demo_part_0150_draw_c:
        ld a,PEN_1
        call set_colour               
        ld hl,crtc_poly1
        jp draw_poly

demo_part_0150_draw_r:
        ld a,PEN_2
        call set_colour               
        ld hl,crtc_poly2
        jp draw_poly

demo_part_0150_draw_t:
        ld a,PEN_3
        call set_colour               
        ld hl,crtc_poly3
        jp draw_poly

demo_part_0150_draw_c2:
        ld a,PEN_6
        call set_colour               
        ld hl,crtc_poly4
        jp draw_poly

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_test_crtc_off:
        ld d,32+PLAYFIELD_X_OFFSET+64
        jr draw_test_crtc_cont

draw_test_crtc:
        ld d,32+PLAYFIELD_X_OFFSET

draw_test_crtc_cont:
	ld iy,poly_angles
        ld h,base_sin_table/256  
        
        ld ix,poly_buffer2
        ld b,3

draw_test_crtc_offset equ $+1
        add a,0
        jr c,no_draw_test_crtc_offset              
        ld (draw_test_crtc_offset),a
        
        scf
        rra
        scf
        rra

        add a,d
        ld d,a
        
;        call reset_frame_count
no_draw_test_crtc_offset:

update_loop:
        ld a,(iy+0)
        ld l,a

        ld c,(iy+3)
        add a,c
        ld (iy+0),a
        inc iy
            
        ld a,(hl)
        xor #80
        sra a
        sra a
        ld c,a
        sra a
        sra a
        sra a
        neg
        add a,c
;        sra a
        add a,d
        ld (ix+0),a
        inc ix

        ld a,l
        add a,#40
        ld l,a
                                                         
        ld a,(hl)
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
        ld (ix+0),a
        inc ix

;        ld a,l
;        add a,#c0-#75
;        ld l,a

        djnz update_loop
        ld (ix+0),0
                 
        ld ix,poly_buffer2
        ld iy,poly_buffer
        call clip_poly
                                                                 
        ld a,PEN_8
        call set_colour               

        ld hl,poly_buffer
        call draw_poly
        
        ret
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poly_angles:
        defb 200,30,67
poly_rangle_rates: defb 3,5,-2
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

X_0 equ 9+PLAYFIELD_X_OFFSET
Y_0 equ PLAYFIELD_Y_OFFSET

X_1 equ	27+X_0
Y_1 equ PLAYFIELD_Y_OFFSET

X_2 equ X_0
Y_2 equ 27+PLAYFIELD_Y_OFFSET

X_3 equ	X_1
Y_3 equ 27+PLAYFIELD_Y_OFFSET

P0 equ 0
P1 equ 7
P2 equ 14
P3 equ 21

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crtc_poly1:
        defb P0+X_0,P3+Y_0, P0+X_0,P1+Y_0, P1+X_0,P1+Y_0, P1+X_0,P0+Y_0, P3+X_0,P0+Y_0, P3+X_0,P1+Y_0, P1+X_0,P1+Y_0, P1+X_0,P2+Y_0, P3+X_0,P2+Y_0, P3+X_0,P3+Y_0    
        defb 0        

crtc_poly2:
        defb P0+X_1,P3+Y_1, P0+X_1,P1+Y_1, P1+X_1,P1+Y_1, P1+X_1,P0+Y_1, P3+X_1,P0+Y_1, P3+X_1,P1+Y_1, P1+X_1,P1+Y_1, P1+X_1,P3+Y_1    
        defb 0        

crtc_poly3:
        defb P0+X_2,P0+Y_2, P3+X_2,P0+Y_2, P3+X_2,P1+Y_2, P2+X_2,P1+Y_2, P2+X_2,P3+Y_2, P1+X_2,P3+Y_2, P1+X_2,P1+Y_2, P0+X_2,P1+Y_2    
        defb 0        

crtc_poly4:
        defb P0+X_3,P3+Y_3, P0+X_3,P1+Y_3, P1+X_3,P1+Y_3, P1+X_3,P0+Y_3, P3+X_3,P0+Y_3, P3+X_3,P1+Y_3, P1+X_3,P1+Y_3, P1+X_3,P2+Y_3, P3+X_3,P2+Y_3, P3+X_3,P3+Y_3    
        defb 0        




demo_03:

        call swap_buffers
        call swap_buffers
        call swap_buffers

        ld hl,demo_03_palette        
        call set_palette	


        ld ix,demo_03_sizes
        ld iy,demo_03_pens

        call reset_frame_count  

        ld hl,demo_03_palette        
        call set_palette	
        
        call partial_frame
        ld a,#c0
        ld (part_03_intro_sin_sum),a
        ld (part_03_intro_sin2_sum),a

        ld a,#c9
        ld (part_03_do_transparent),a

        ld a,render_page        
        ld (ix+0),a
        ld (ix+1),a
        ld (ix+2),a
        ld (ix+3),a
        ld (ix+4),a
        ld (ix+5),a
        

        xor a

loop_part_03_intro_blue:
        call part_03_get_sin
        ld (ix+4),b
        push af
        ld a,render_page
        sub b
        add a,render_page
        ld (ix+0),a
        pop af 
        
        call draw_part_03
        call erase_part_03
        call get_frame_count
        jr nc,loop_part_03_intro_blue
        
        call partial_frame

loop_part_03_intro_red:
        call part_03_get_sin
        ld (ix+3),b
        push af
        ld a,render_page
        sub b
        add a,render_page-#10
        ld (ix+0),a
        pop af 
        
        call draw_part_03
        call erase_part_03
        call get_frame_count
        jr nc,loop_part_03_intro_red

        call partial_frame

loop_part_03_intro_green:
        call part_03_get_sin
        ld (ix+2),b
        push af
        ld a,render_page
        sub b
        add a,render_page-#20
        ld (ix+0),a
        pop af 
        
        call draw_part_03
        call erase_part_03
        call get_frame_count
        jr nc,loop_part_03_intro_green

        call partial_frame

loop_part_03_intro_yellow:
        call part_03_get_sin
        ld (ix+1),b
        push af
        ld a,render_page
        sub b
        add a,render_page-#30
        ld (ix+0),a
        pop af 
        
        call draw_part_03
        call erase_part_03
        call get_frame_count
        jr nc,loop_part_03_intro_yellow

loop_part_03_adj_ix0:
        call draw_part_03
        call erase_part_03
        
        ld a,(ix+0)
        cp #d0
        jr z,loop_part_03_adj_ix0_there
        inc (ix+0)
loop_part_03_adj_ix0_there:        
        
        call get_frame_count
        jr nc,loop_part_03_adj_ix0

        call draw_part_03
        call erase_part_03

start_part_03_intro_expand:
        ld a,#80+#2c
        call set_frame_count
        ld a,#c0+#2c
        ld (part_03_intro_sin_sum),a

        call get_frame_count

loop_part_03_intro_expand:
        call part_03_get_sin
        ld (ix+4),b
        ld (ix+3),b
        ld (ix+2),b
        ld (ix+1),b
        
        call draw_part_03
        call erase_part_03
        call get_frame_count
        jr nc,loop_part_03_intro_expand

part_03_remove_yellow_pen:
        push af
               
        ld b,num_rows                      
        ld a,(ix+0)
        ld (ix+0),b
        add a,a
        add (ix+1)
        ld (ix+1),a
                          
        ld iy,demo_03_alt_pens
        
        pop af

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; now change the palette again and move to 3 separate thinner lines
;
        call draw_part_03
        call erase_part_03
        call get_frame_count

        ld ix,demo_03_size_test2
        ld iy,demo_03_narrow_pens

        call partial_frame2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loop_part_03_make_narrow:
        call narrow_part_03_head
        srl a
        call narrow_part_03_tail                 
        call draw_part_03
        call erase_part_03
        call get_frame_count
        jr nc,loop_part_03_make_narrow

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; enable transparency

        push af
        ld hl,demo_03_trans_palette
        call set_palette
        pop af

loop_part_03_make_narrow2:
        call narrow_part_03_head
        srl a
        call narrow_part_03_tail                 
        call draw_part_03
        call erase_part_03
        call get_frame_count
        jr nc,loop_part_03_make_narrow2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        call swap_buffers
        call swap_buffers
        ret


narrow_part_03_head:
        ld c,a

        srl a
part_03_intro_sin2_sum equ $+1
        ld hl,base_sin_table+#c0     ; start at size 0
        add a,l
        ld (part_03_intro_sin2_sum),a
        ld a,(hl)
        ret
        
narrow_part_03_tail:
        
        ld b,a
        neg
        
        add a,#f
        ld (ix+1),a
        ld (ix+3),a
        ld (ix+5),a
        ld a,b
        add a,#f
        ld (ix+0),a

        ld a,b
        add a,#d0
        ld (ix+2),a
        ld (ix+4),a

        ld a,c
        ret                         

partial_frame:
        ld c,a              
        ld a,#28
        call set_frame_count

        ld a,#c0
        ld (part_03_intro_sin_sum),a
        
        ld a,c
        ret

partial_frame2:
        ld c,a              
        ld a,#80 ; 30 ;40
        call set_frame_count
        ld a,c
        ret

part_03_get_sin:
        ld c,a        
part_03_intro_sin_sum equ $+1
        ld hl,base_sin_table+#c0     ; start at size 0
        add a,l
        ld (part_03_intro_sin_sum),a
        ld a,(hl)
        srl a
        srl a
        add a,render_page
        ld b,a
        ld a,c
        ret

part_03_get_sin_offset:
        ld c,a
        ld a,b
        add a,l
        ld l,a               
        ld a,(hl)
        srl a
        srl a
        add a,render_page
        ld b,a
        ld a,c
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PART03_NEXT_0 equ 0
PART03_NEXT_1 equ #10
PART03_NEXT_2 equ #18
PART03_NEXT_3 equ #20
PART03_NEXT_4 equ #30

draw_part_03:
        call draw_part_03_2halt
        halt
        ret     

draw_part_03_2halt:
        call draw_part_03_norender                  
        call do_simple_render
        halt
        halt
        ret


draw_part_03_norender:
        add a,a     
p03_rot_angle equ $+1
	add a,0
	ld (p03_rot_angle),a
	ld h, base_sin_addr_table/256

        add (ix+0) 
	ld l,a
        ld c,(iy+0)
        call part_03_line
        push hl

        ld a,l
        add a,TWISTER_FUDGE_CALC
        add (ix+1) 
        ld l,a
        ld c,(iy+1)
        call part_03_line
        push hl

        ld a,l
        add a,TWISTER_FUDGE_CALC
        add (ix+2) 
        ld l,a
        ld c,(iy+2)
        call part_03_line 
        push hl

        ld a,l
        add a,TWISTER_FUDGE_CALC
        add (ix+3) 
        ld l,a
        ld c,(iy+3)
        call part_03_line 
        push hl

        ld a,l
        add a,TWISTER_FUDGE_CALC
        add (ix+4) 
        ld l,a
        ld c,(iy+4)
        call part_03_line 
        push hl

        ld a,l
        add a,TWISTER_FUDGE_CALC
        add (ix+5) 
        ld l,a
        ld c,(iy+5)
        call part_03_line 
        call part_03_line_bottom 

        pop hl
        ld c,(iy+4)
        call part_03_line_bottom 

        pop hl
        ld c,(iy+3)
        call part_03_line_bottom 

        pop hl
        ld c,(iy+2)
        call part_03_line_bottom 

        pop hl
        ld c,(iy+1)
        call part_03_line_bottom 

        pop hl
        ld c,(iy+0)
        jr part_03_line_bottom 

part_03_do_transparent:
        ret               

        ld de, render_page*256+1
        xor a
part_03_do_transparent_loop:
        ld (de),a
        inc d
        jr nz,part_03_do_transparent_loop                            
        ret               
              

;;;;;;;;;;;;;;;;;;;;;

TWISTER_SPLIT_HEIGHT equ 16
TWISTER_FUDGE_CALC equ num_rows-TWISTER_SPLIT_HEIGHT

part_03_line:
        ld d, render_page

        ld b,TWISTER_SPLIT_HEIGHT
part_03_line_top_loop:                                          
        ld e,(hl)
        inc l

        ld a,(de)
        xor c
        ld (de),a
        
        inc d
        djnz part_03_line_top_loop
        ret



part_03_line_bottom:
        ld d, render_page+TWISTER_SPLIT_HEIGHT

part_03_line_loop:                                          
        ld e,(hl)
        inc l

        ld a,(de)
        xor c
        ld (de),a
        
        inc d
        jr nz,part_03_line_loop
        ret



part_03_split:
        ld de, render_page*256+1
        
part_03_split_loop:
        ld a,l 
        inc l
        
        add a,a
        sbc a,a
        and c
        ld (de),a
        
        inc d
        jr nz,part_03_split_loop
        ret                   
              
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

erase_part_03:
	ld a,(p03_rot_angle)

        add (ix+0) 
	ld l,a
	ld h, base_sin_addr_table/256
        call part_03_erase 

        ld a,l
        add (ix+1) 
        ld l,a
        call part_03_erase 

        ld a,l
        add (ix+2) 
        ld l,a
        call part_03_erase 

        ld a,l
        add (ix+3) 
        ld l,a
        call part_03_erase 

        ld a,l
        add (ix+4) 
        ld l,a
        call part_03_erase 

        ld a,l
        add (ix+5) 
        ld l,a

part_03_erase: 
        ld d, render_page
        xor a

part_03_erase_loop:                                          
        ld e,(hl)
        inc l

        ld (de),a        
        inc d
        jr nz,part_03_erase_loop

        ret
; colours are: 0001, 0011, 0111, 1111 or 1111, 1110, 1100, 1000

DEMO_03_COL0  equ #54             ;  0 black
DEMO_03_COL1  equ #4a             ; 24 yellow
DEMO_03_COL2  equ #52             ; 18 green
DEMO_03_COL3  equ #4c             ;  6 red
DEMO_03_COL4  equ #55             ;  2 blue
DEMO_03_COL_X equ #4b

DEMO_03_COL0_H  equ #41             ;  0 black
DEMO_03_COL2_H  equ #59             ; 18 green
DEMO_03_COL3_H  equ #47             ;  6 red
DEMO_03_COL4_H  equ #57             ;  2 blue

demo_03_sizes:
        defb render_page,render_page,render_page,render_page,render_page,render_page

demo_03_pens:
        defb PEN_1,PEN_1 xor PEN_2,PEN_2 xor PEN_4,PEN_4 xor PEN_8,PEN_8,0

demo_03_alt_pens:
        defb 0,PEN_2,PEN_2 xor PEN_4,PEN_4 xor PEN_8,PEN_8,0

demo_03_narrow_pens:
        defb PEN_2,PEN_2,PEN_4,PEN_4,PEN_8,PEN_8

demo_03_size_test2:
        defb #0f,#0f,#d0,#0f,#d0,#0f

demo_03_palette:
        defb    DEMO_03_COL0
        defb    DEMO_03_COL1
        defb    DEMO_03_COL2
        defb    DEMO_03_COL2
        defb    DEMO_03_COL3
        defb    DEMO_03_COL3
        defb    DEMO_03_COL3
        defb    DEMO_03_COL3
        defb    DEMO_03_COL4
        defb    DEMO_03_COL4
        defb    DEMO_03_COL4
        defb    DEMO_03_COL4
        defb    DEMO_03_COL4
        defb    DEMO_03_COL4
        defb    DEMO_03_COL4
        defb    DEMO_03_COL4

demo_03_trans_palette:
        defb    DEMO_03_COL0
        defb    DEMO_03_COL1
        defb    DEMO_03_COL2        ; green
        defb    DEMO_03_COL2
        defb    DEMO_03_COL3        ; red
        defb    DEMO_03_COL3
        defb    DEMO_03_COL3
        defb    DEMO_03_COL3
        defb    DEMO_03_COL4        ; blue
        defb    DEMO_03_COL4
        defb    #53                ; blue+green=cyan
        defb    DEMO_03_COL4
        defb    #4d                ; red+blue=magenta
        defb    DEMO_03_COL4
        defb    #4b                ; white
        defb    DEMO_03_COL4

demo_03_alt_palette:
        defb    DEMO_03_COL0
        defb    DEMO_03_COL2       ; green
        defb    DEMO_03_COL3       ; red
        defb    DEMO_03_COL3      
        defb    DEMO_03_COL4       ; blue
        defb    DEMO_03_COL4
        defb    DEMO_03_COL4
        defb    DEMO_03_COL4
        
        defb    DEMO_03_COL0
        defb    DEMO_03_COL2
        defb    DEMO_03_COL3
        defb    #4a                ; green+red=yellow
        defb    DEMO_03_COL4
        defb    #53                ; blue+green=cyan
        defb    #4d                ; red+blue=magenta
        defb    #4b                ; white

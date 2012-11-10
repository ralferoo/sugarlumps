demo_01_set_palette:
        call swap_buffers
        call swap_buffers
        call swap_buffers
        
        ld hl,sun_rise_palette
        jp set_palette            

set_default_palette:
        call swap_buffers
        call swap_buffers
        call swap_buffers
        
        ld hl,default_palette
        jp set_palette            



demo_01:
        call demo_01_set_palette
        call reset_frame_count                                                                                  
        call init_part_01
sunriseloop:
        call swap_buffers
        call get_frame_count
        call draw_part_01
        jr nc, sunriseloop 

        call set_default_palette        
        jp reset_frame_count



demo_01_reverse:
        call demo_01_set_palette
        call reset_frame_count                                                                                  
        call init_part_01_reverse
sunriselooprev:
        call swap_buffers
        call get_frame_count
        call draw_part_01_reverse
        jr nc, sunriselooprev 

        call set_default_palette        
        jp reset_frame_count

init_part_01_reverse:
        ret             

draw_part_01_reverse:
        ld b,a
        ld a,(sun_height)
        add a,b             
        ld (sun_height),a

        cp num_rows*4
        jr c,divide_part_01 

        scf
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                  

COL_SUN_TOP equ #4a        
COL_SUN_BOT equ #4e        

COL_SKY_TOP equ #44        
COL_SKY_MID equ #48        
COL_SKY_BOT equ #4c       

sun_rise_palette:
        defb #54,COL_SUN_TOP
        defb COL_SKY_TOP,#51 ; COL_SUN_TOP
        defb COL_SKY_MID,#4d ;COL_SUN_TOP
        defb COL_SKY_BOT,#47 ;COL_SUN_TOP
        defb COL_SUN_BOT,COL_SUN_BOT  
        defb #55,#55 
        defb #4f,#4f 
        defb #5c,#5c 

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                  

SUN_MID         equ #a7 
SUN_SIZE        equ #10

SUN_LEFT        equ SUN_MID-SUN_SIZE
SUN_RIGHT       equ SUN_MID+SUN_SIZE

SUN_PAUSE       equ 50

init_part_01:   
        ld a,20
                
        ld a,num_rows*4+SUN_PAUSE     
        jr cont_part_01
             
draw_part_01:

        neg     
sun_height equ $+1
        add a,0

cont_part_01:
        ld (sun_height),a
        cp #5
        ret c

        sub SUN_PAUSE
        jr nc,divide_part_01

        xor a
divide_part_01:
        
        srl a
        srl a
        ld (part_01_horiz),a         

        add a,PLAYFIELD_Y_OFFSET         
        ld b,a
        add a,SUN_SIZE
        ld c,a
        push bc
        
        ; bezier: de->bc->hl              b=top, c=mid
        
        ld d,c
        ld h,b
        ld e,SUN_LEFT
        ld c,e
        ld l,SUN_MID

        ld ix,poly_buffer+2        
        ld (ix-2),e
        ld (ix-1),d        

        call draw_bezier_segment       

        pop bc
        push bc
        
        ld d,b
        ld e,SUN_MID
        ld h,c
        ld c,SUN_RIGHT
        ld l,c

        call draw_bezier_segment       

        ld (ix+0),0

        ld a,PEN_1
        call set_colour               
        ld hl,poly_buffer
        call draw_poly      

        pop bc
        ld a,b
        add a,SUN_SIZE*2
        ld b,a
        push bc                        ; b=bottom, c=mid
        
        ld h,b
        ld l,SUN_MID
        ld d,c
        ld c,SUN_RIGHT
        ld e,c

        ld ix,poly_buffer+2        
        ld (ix-2),e
        ld (ix-1),d        

        call draw_bezier_segment       

        pop bc
        
        ld h,c
        ld d,b
        ld l,SUN_LEFT
        ld c,l
        ld e,SUN_MID

        call draw_bezier_segment       

        ld (ix+0),0

        ld a,PEN_8
        call set_colour               
        ld hl,poly_buffer
        call draw_poly      

        ld (draw_wholly_unclipped_line_sp_save),sp
        ld sp,(draw_sp)

	ld de,0                                       
        ld b,1                            ; 1 line

part_01_horiz equ $+1
        ld a,0
        add a,render_page+SUN_SIZE
        jr c,sun_blend_done

        ld l,SUN_LEFT*4+1
        ld h,a
        ld c,PEN_9 and #55
        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag

        ld l,SUN_RIGHT*4+1
        ld h,a
        ld c,PEN_9 and #55
        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag
              
        inc h
        jr c,sun_blend_done
                              
        ld c,PEN_9 and #aa
        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag
              
        ld l,SUN_LEFT*4+1
        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag

sun_blend_done:        
        ld a,(part_01_horiz)
        add a,render_page
        jr z,done_horiz

        sra a               ; midpoint between y and bottom of screen
        
        ld h,a
        ld l,1
        ld c,PEN_2 and #aa

        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag

        ld c,PEN_2 and #55
        inc h
        jr z,done_horiz

        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag

        ld b,3                            ; 3 line
        ld c,PEN_2
        inc h
        jr z,done_horiz

        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag

        add a,5
        jr c,done_horiz
        ld h,a
        ld b,1                            ; 1 line
        ld c,#24       ;(PEN_2 and #55) or (PEN_4 and #aa) 

        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag

        ld c,#18       ;(PEN_2 and #aa) or (PEN_4 and #55) 
        inc h
        jr z,done_horiz

        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag

        ld b,6                            ; 3 line
        ld c,PEN_4
        inc h
        jr z,done_horiz

        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag
        
        add a,8
        jr c,done_horiz
        ld h,a
        ld b,1                            ; 1 line
        ld c,#2c       ;(PEN_4 and #55) or (PEN_6 and #aa) 

        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag

        ld c,#1c       ;(PEN_4 and #aa) or (PEN_6 and #55) 
        inc h
        jr z,done_horiz

        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag

        ld b,9                            ; 3 line
        ld c,PEN_6
        inc h
        jr z,done_horiz

        push de                           ; save deltas
        push de                           ; save x steps
        push hl                           ; save address
        push bc                           ; save loop + colour
        push de                           ; save error and nz flag
        
done_horiz:
        ld (draw_sp),sp
        ld sp,(draw_wholly_unclipped_line_sp_save)

        and a
        ret

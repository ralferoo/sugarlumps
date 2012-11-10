; 0000-003f     intvec
; 0040-07ff     free
; 0800-3fff         program
; 4000-47ff     screen for scroller
; 4800-75ff     music (only goes to #4932 currently)
; 7600-7fff     music player
; 8000-87ff     screen part 1
; 8800-9fff     patch code (ends at 9540 currently)
; a000-b8ff     poly stack 1
; a900-b1ff     poly stack 2
; b200-baff     poly stack 3
; bb00-bdff     poly buffer
; be00-beff     sin table
; bf00-bfff     main stack
; c000-c7ff     screen part 2
; c800-c8ff     font buffer
; c900-cfff     free
; d000-ffff     render base

num_columns     equ 64
num_rows        equ 48
screen_bytes    equ 82 ; 88 ; 96 

screen_base     equ #8000
screen_offset	equ 18+screen_bytes

render_page     equ 256-num_rows	;render_base/256	
render_end_page equ 0			;render_page+num_rows	
render_base     equ (render_page*256)   ; #d000

music_data	equ #4800
music_base      equ #7600

poly_buffer     equ #bb00            
poly_buffer_end equ #bc00            
poly_buffer2    equ #bc00            
poly_buffer2end equ #bd00
            
poly_stack1_top equ #bb00
poly_stack2_top equ #b200
poly_stack3_top equ #a900
poly_stack_base equ #a000
main_stack_top  equ #c000

patches_base    equ #8800

base_sin_table  equ #be00
base_sin_addr_table  equ #bd00

life_base       equ #8800
freemem_base    equ #b680		; for trashing on initialisation

font_buffer     equ #c800

SCROLL_BYTES    equ #66            ; should be #7c, but #5c/#5e lets us see the music stats

CRTC_R1_VALUE   equ #bd00+(screen_bytes/2)	;bd28	; 32 chars wide, 8 to the start
SCROLL_WIDTH    equ #bd00+(SCROLL_BYTES/2) ;3e		; 48 chars wide, use 3e, actually visible=2e

NUMBER_LINE_FUNCTIONS equ 16

INITIAL_LINE	equ 1
INITIAL_CYCLES	equ 14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLAYFIELD_X_OFFSET equ #80                                                            
PLAYFIELD_Y_OFFSET equ #80-(num_rows/2)                                                            

PLAYFIELD_WIDTH equ #3f

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEBUG_MUSIC_STARTED equ #7f54 ;40
DEBUG_MUSIC_STOPPED equ #7f54                                                           

;DEBUG_PURPLE	equ #7f4d				
;DEBUG_WHITE 	equ #7f4d				
;DEBUG_GREEN 	equ #7f56				
;DEBUG_PURPLE2	equ #7f58				
;DEBUG_ORANGE	equ #7f4e			
;DEBUG_CYAN	equ #7f53		
;DEBUG_RED	equ #7f4c		
;DEBUG_YELLOW	equ #7f4a		
;DEBUG_PINK	equ #7f47		
;DEBUG_DONE	equ #7f4c		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;COLOUR_BLACK	equ #7f54		
;COLOUR_YELLOW	equ #7f4a		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PEN_0	equ #00
PEN_1	equ #c0
PEN_2	equ #0c
PEN_3	equ #cc
PEN_4	equ #30
PEN_5	equ #f0
PEN_6	equ #3c
PEN_7	equ #fc
PEN_8	equ #03
PEN_9	equ #c3
PEN_10	equ #0f
PEN_11	equ #cf
PEN_12	equ #33
PEN_13	equ #f3
PEN_14	equ #3f
PEN_15	equ #ff2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
screen_2_offset	equ screen_bytes*26
screen_2_crtc_l	equ (screen_2_offset/2) and 255
screen_2_crtc_h	equ ((screen_2_offset and #600)/512) or #30

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org #800

; timings, based on tempo of music:
;
; 6 vsync per note, 64 notes per block, 50 hz, 32 blocks
; = 6 * 64 / 50 * 32 = 245.76 seconds until loop (4 minutes 5 seconds)
;
; currently have 30 seconds (6 * 256/50) of demo


music_init equ music_base+0
music_play_real equ music_base+3
music_stop equ music_base+6

restart:
        di        
	ld sp,main_stack_top

        ld hl,music_player_src+music_player_len-1
        ld de,music_base+music_player_len-1
        ld bc,music_player_len
        lddr

        ld hl,music_src+music_len-1
        ld de,music_data+music_len-1
        ld bc,music_len
        lddr

	ld ix,poly_buffer
	ld hl,#7e94-#28
	ld de,#6aa8-#28
	ld bc,#6a94-#28

	call draw_bezier
	inc ix
	inc ix

	push ix
	
	ld hl,#7ebc-#28
	ld de,#6aa8-#28
	ld bc,#6abc-#28
	call draw_bezier
	inc ix
	inc ix

	pop iy
invloop:
	ld a,(iy+0)
	ld (ix+0),a
	or a
	jr z,donetest
	xor #80
	neg
	xor #80
	ld (ix+0),a
	
	ld a,(iy+1)
	ld (ix+1),a
	inc ix
	inc ix
	inc iy
	inc iy
	jr invloop
donetest:		

	ld a,#c9
	ld (#30),a				; ensure RST vector set up      

        call decompress_font

        ld de,music_data
        call music_init
	call clear_screen
	call init_screen_state
                
        ld hl,default_palette        
        call set_palette	

        call build_sin_table
        call init_buffers
        call create_render

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

render_triangles_task equ $+1
        ld hl,0
	ld (task_jp_vector),hl

        ld hl,scroll_message
        ld (scroll_message_reset),hl
        ld (next_scroll_char),hl
          
        xor a
        ld (music_play),a
          
demostart:

        call demo_01
        call demo_part_0150_crtc
        call demo_part_0150_poly
        call demo_02
        call demo_bezier
        call demo_03

        ld hl,default_palette        
        call set_palette	

        call demo_01_reverse

        ld b,0
restartloop:
        halt
        djnz restartloop
                           
        jr demostart

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; gets frames since last call, also sets CF every 256 frames :)

get_frame_count:
        ld a,(vsync_count)
last_frame equ $+1
	ld b,0
	ld (last_frame),a
        sub b
        ret            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_frame_count:
        xor a
set_frame_count:
        ld (vsync_count),a          
	ld (last_frame),a
        ret            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

do_music_corrupt_only_bc:
        push af
        push de
        push hl
        push ix
        push iy
        ex af,af'
        exx
        push af
        push bc
        push de
        push hl


	ld bc,#7f10
	out (c),c
	ld c,DEBUG_MUSIC_STARTED and 255 ;#43 ;DEBUG_GREEN and 255
	out (c),c		; green again

music_play equ $+1
        jr skip_music_play   

        call music_play_real
skip_music_play:
	ld bc,DEBUG_MUSIC_STOPPED ;#7f54 ;DEBUG_GREEN
	out (c),c		; green again
        
        pop hl
        pop de
        pop bc
        pop af
        exx
        ex af,af'
        pop iy
        pop ix
        pop hl
        pop de
        pop af
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_palette:
        defb #54,#4a,#53,#4c, #45,#4b,#55,#4d
        defb #41,#43,#5b,#47, #4f,#59,#57,#42

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        read "bezier.asm"
        read "draw_poly.asm"
        read "clip_poly.asm"

        read "scroll.asm" 
        read "intvec.asm"
        read "buffers.asm"

        read "test_poly_bezier.asm" 
        
        read "demo_part_01_sunrise.asm"
        read "demo_part_01_10_crtc.asm"
        read "demo_part_01_50_poly_rot.asm"
        read "demo_part_02_bez_square.asm"
        read "demo_part_03_twister.asm"
        
        read "rawfont.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; everything after this is available to be overwritten once the codegen has run


heap_start:
        read "create_render.asm"
	read "create_render_triangles.asm"
        read "line_segments.asm"
        read "clear_screen.asm"
        read "build_sin_table.asm"

music_src:
        readbin "music/80-4800.raw"
music_len equ $-music_src

music_player_src:
        readbin "music/stk7600.raw"
music_player_len equ $-music_player_src

heap_end:

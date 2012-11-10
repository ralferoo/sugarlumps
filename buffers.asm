; double buffering strategy
;
; rendering:
;                       v render_sp                v render_top
; +---------------------+--------------------------+-----+
; |     free            |      render data         | #FF |
; +---------------------+--------------------------+-----+
;
; drawing:
;                v draw_sp          v erase_sp	   v draw_top
; +--------------+------------------+--------------+-----+
; |   free       |    new render    |    old erase | #FF |
; +--------------+------------------+--------------+-----+
;
; next:
;                                          next_sp v next_top
; +------------------------------------------------+-----+
; |     free                                       | #xx |
; +------------------------------------------------+-----+
;
;
; so, if rendering complete, then render_sp == render_top and #FF changed
; to something else (usually #44).
;
; when rendering complete, we want to take the latest draw_sp and copy it to
; render_sp and the rendering will start up next frame.
;
; we could just use the current render_sp as the next draw_sp, but instead we're
; going to triple buffer these render stacks to make erasing easier.
;
; so: render_sp' = draw_sp
;     draw_sp' = next_sp
;     next_sp' = render_sp
;
; we then have the added complication of precopying the erase data... so, before
; the flip we need:
;
; length = erase_sp - draw_sp
; *next_sp = #FF
; copy length bytes from draw_sp to next_sp' - length
; erase_sp' = draw_sp' = next_sp - length
; render_sp' = draw_sp
; next_sp' = render_sp
;
; the byte marked as #FF is actually the flags register, ZF=no more processing
; CF=render frame. ZF=#40, CF=#01.

init_buffers:
	ld de,poly_stack_base
	push de
	ld bc,stack_msg_len
	ld hl,stack_msg
	ldir
	pop hl
	ld bc,poly_stack1_top-(poly_stack_base+stack_msg_len)
	ldir

	ld a,#fe		; ZF set, CF clear = no processing, no render     

	ld hl,poly_stack1_top-2
	ld (hl),a
	ld (render_sp),hl     

	ld hl,poly_stack2_top-2
	ld (hl),a
	ld (next_sp),hl     

	ld hl,poly_stack3_top-2
	ld (hl),a
	ld (draw_sp),hl   
	ld (erase_sp),hl     

        ret

stack_msg: defb "- poly stacks -",0
stack_msg_len equ $-stack_msg

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; swaps the buffers. the current draw buffer will be queued for draw, but it
; will not be automatically erased.

swap_buffers_no_erase:
        ld hl,(next_sp)  	; HL = next_sp
	ld de,(draw_sp)		; DE = draw_sp
	jr no_copy		; skip copy altogether
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; swaps the buffers. the current draw buffer will be queued for draw and
; will additionally be copied into the start of the next draw buffer so it
; will be automatically erased after 1 frame.

swap_buffers:
erase_sp equ $+1
	ld hl,0			; HL = erase_sp
	ld de,(draw_sp)		; DE = draw_sp
	and a     
	sbc hl,de		; HL = length
	ld b,h
	ld c,l			; BC = length, ZF if BC=0
	
next_sp equ $+1
	ld hl,0  		; HL = next_sp
	ld (hl),#ff		; set up terminal byte

	jr z,no_copy		; skip copy if BC = 0

	push de			; save draw_sp
 	sbc hl,bc		; HL = next_sp-length
 	push hl			; save next_sp-length
 	
	ex hl,de		; HL = draw_sp, DE = next_sp-length
	ldir

	pop hl			; HL = next_sp-length
	pop de			; DE = draw_sp
no_copy:	
	ld (erase_sp),hl
	ld (draw_sp),hl
	
wait_for_current_render:
render_sp equ $+1
	ld hl,0
	ld a,(hl)		; check current render stack
	and #41			; mask off just ZF(#40) and CF(#01)
	cp #40			; ZF = end of list, CF = not yet rendered
	jr z,current_render_done
	
;	ld bc,#7f10
;	out (c),c
;	ld c,#48
;	out (c),c
	
	halt		

;	ld c,#53
;	out (c),c
	
	jr wait_for_current_render		
current_render_done:
	
	ld (render_sp),de	; now render has finished, replace with draw
	ld (next_sp),hl		; and the old rendered becomes the next one
	
        ret


do_simple_render_halt:
        halt              
do_simple_render:
;draw_top equ $+1
        ld hl,(render_sp)
        ld a,(hl)
        rra
        jr c,do_simple_render_halt
        ccf
        rla
        ld (hl),a
        ret                


wait_render_done:
        ld a,(render_mark)
wait_render_loop:
        halt
render_mark equ $+1
        cp 0
        jr nz,wait_render_loop
        ret                     

;        ld a,(render_mark)
;        ld c,a
;wait_render_loop:
	halt
;        ld a,(render_mark)
;        sub c
;        jr z,wait_render_loop
;        ret
        		
	ld hl,(render_sp)
	ld a,(hl)		; check current render stack
	and #41			; mask off just ZF(#40) and CF(#01)
	cp #40			; ZF = end of list, CF = not yet rendered
	jr nz,wait_render_done
	ret
	

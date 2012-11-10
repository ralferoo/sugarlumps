create_render:
	ld hl,patches_base			; create the prologue
        call create_line_functions

        ld ix,INITIAL_CYCLES          		; initial cycle count
	ld a,INITIAL_LINE

        ld (primary_task),hl

        ld (render_triangles_task),hl
        call create_render_triangles

	exx
        ld de,screen_base+screen_offset
        ld (patches_start_de_save),de
	exx          
 
        ex hl,de
	ld hl,patches_start
	ld bc,patches_start_len
	ldir
	ex hl,de
	exx      				; hl' holds target patch code

        ld bc,-(3)          		; initial cycle count
	add ix,bc                                                

	ld (next_event_a),a
	ld iy,next_event_table_initial

        ld hl,start_next_page
        ld (next_event_page_end_func),hl                                                                

        ld hl,render_base
	jr in_patch_code 

; main render loop, called for each pixel/byte
render_loop:
	ld a,l
	add a,#ff
	sbc a,a			; A=00 if first byte, FF if other
	and #ee-#3e
	add a,#3e

        ld (hl),a               ; LD/XOR	2us
        inc l
        ld (hl),0               ; gfx data
        inc l
        ld (hl),#12             ; LD (DE),A	2us
        inc l

	ld bc,-(2+2+1)            ; LD/XOR, STORE, JP/INC E

        ld a,l
        inc a
        jr z,last_column

        ld a,#1c                ; INC E		1us
        inc e
        jr nz,screen_page_ok	; no page carry
        inc d
        dec bc
        ld a,#13                ; INC DE	2us
	bit 3,d			; check for 2k overflow
        jr nz,screen_page_overflow

; normal pixel - not end of line, no clock overflow
screen_page_ok:        
	add ix,bc		; update clocks count
	jr nc,clock_overflow

        ld (hl),a
        inc l
        jr render_loop

; clock overflow case - store JP (HL), process event, patch up
clock_overflow:			; clock done inc instruction after JP	
	ld (hl),#e9		; JP (HL)	1us
	inc l
	dec ix			; compensate clock for JP

	exx
	ld (hl),a
	inc hl
	exx			; store deferred instruction		

; handles returning from the patch code back into the render code
in_patch_code:			; assumes IX already updated correctly
	ld a,xh
	rla      
	call c,next_event	; process event if outstanding clock overflow
	
	ld a,render_end_page
	cp h
	jr z,finished_render_codegen

	ld bc,-(3+3)
	add ix,bc		; update cycle count
	call nc,next_event	; process event if about to overflow

	push hl
	exx
	ld de,6
	ex de,hl
	add hl,de		; HL = next_patch, DE = current ptr
	ex de,hl		; DE = next_patch, HL = current ptr
	
	ld (hl),#21		; LD HL,next_patch
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
;	exx

;	exx
	pop de			; DE = next_code
	ld (hl),#c3		; JP next_code
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	exx
	
	jr render_loop

; reached the last column of a line
last_column:			; BC=-5, but not yet added to ix
	ld a,screen_bytes+1-64
	add a,e
	ld e,a
	push af

	exx	
        ld (hl),#1e		; LD E,#39	2us
	inc hl
        ld (hl),a       
	inc hl
	exx	
        dec bc
        dec bc                      

        pop af
        jr nc, add_ix_bc_write_jp_hl        ; screen address now correct
	
	ld a,#14		; INC D		1us
	inc d

screen_page_overflow:		; if got here from add, bc=-6
	dec bc				

	exx
	ld (hl),a
	inc hl
	exx	

	bit 3,d			; check for 2k overflow
	jr z, add_ix_bc_write_jp_hl

        res 3,d
        set 6,d	
	
	exx
        ld (hl),#cb		; RES 3,D	2us
	inc hl
        ld (hl),#9a       
	inc hl
        ld (hl),#cb		; SET 6,D	2us
	inc hl
        ld (hl),#f2       
	inc hl
	exx	

        dec bc
        dec bc
        dec bc
        dec bc

add_ix_bc_write_jp_hl:	
	ld (hl),#e9		; JP (HL)
	inc hl			; may be last, so inc h too
        add ix,bc

	jr in_patch_code 

; finished the render code, for now patch up with nops until the end of the
; next page...	
finished_render_codegen:

        exx
        ex hl,de
        ld hl,update_render_mark_code
        ld bc,update_render_mark_code_size
        ldir
        ex hl,de
        exx
        ld bc,-update_render_mark_code_cycles
        add ix,bc
	call nc,next_event	; process event if about to overflow
                        
        ld hl,add_jump_to_1st_page
finished_codegen_pad_hl_add_jump_to_1st_page_fn:
        ld (next_event_page_end_func),hl                                                                

pad_with_nulls:
	call delay_by_one_event       
        jr pad_with_nulls          ; repeat for remaining lines           

delay_by_one_event:
        xor a       
        ld bc,-5                   ; count through first loop
        
pad_with_nulls_loop:
        inc a
        add ix,bc
        ld c,-4              
        jr c,pad_with_nulls_loop ; loop until cycle count overflowed
        
        exx
        ld (hl),#3e                ; ld a,#xx             2us
        inc hl
        ld (hl),a
        inc hl
        ld (hl),#3d                ; x: dec a             1us    
        inc hl                       
        ld (hl),#20
        inc hl
        ld (hl),#fd                ; jr nz,x ($-3)        3us taken, 2us not
        inc hl
        exx

        jr next_event            ; handle this line and

; special end function, jumped to by next_event
add_jump_to_1st_page:
        pop hl                  ; pop the return value from the call to next_event
        
primary_task equ $+1
        ld hl,0

; reached end of page, add a jump to the address passed in hl
end_page_jump:                        
        ld (end_page_jump_code+1),hl
        exx
        ex hl,de
        ld hl,end_page_jump_code
        ld bc,end_page_jump_code_size
        ldir
        ex hl,de
        exx
        ret                                 

end_page_jump_code:
        ld hl,0
        ld (task_jp_vector),hl
        jp task_complete
end_page_jump_code_size equ $-end_page_jump_code
               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
               
update_render_mark_code:
        ld hl,render_mark
        inc (hl)
update_render_mark_code_size equ $-update_render_mark_code
update_render_mark_code_cycles equ 3+3
                                            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; this adds the code for the "next" event to the instruction stream in hl'

next_event:

next_event_a equ $+1
	ld a,0
	inc a
	ld (next_event_a),a

	cp (iy+0)
	jr z, do_next_event_table 

	ld bc,-4	;-(4+7)
	add ix,bc
	
	ld bc,#41c0		; out (c),b : 192
	rra
	jr c,got_even_to_odd

next_event_patch	
	ld bc,#4940		; out (c),c : 64  
got_even_to_odd:
	ld a,b
	exx	

	ld (hl),#ed
	inc hl
	ld (hl),a
	inc hl
	exx	
	ld b,0	   	   

add_ix_bc_munge_time:
	add ix,bc   

	ld a,xh
	rla      
	jr c,next_event		; repeat if still in overflow

	ret                                                                                   

do_next_event_table:
	ld c,(iy+1)
	ld b,(iy+2)
        push bc
        ld bc,5
        add iy,bc
	ld c,(iy-2)
	ld b,(iy-1)
	add ix,bc   
        ret

short_line_and_di:
	exx
	ld (hl),#ed
	inc hl
	ld (hl),#49		; short line
	inc hl
;	ld (hl),#f7		; RST #30
;	inc hl
	ld (hl),#f3		; DI
	inc hl
	exx
	
	ld bc,64-12
	add ix,bc
	ret

long_line_and_ei:
	exx
	ld (hl),#ed
	inc hl
	ld (hl),#41		; long line
	inc hl
;	ld (hl),#f7		; RST #30
;	inc hl
	ld (hl),#fb		; EI
	inc hl
	exx

	ld bc,192-5
	add ix,bc
	ret

; create a virtual jump to the next page
              
start_next_page:
	; debugging RST #30	
	exx
	ld (hl),#f7		; RST #30
	inc hl
	exx

	; save this for the LDIR later
	ld (patches_start_de_save),de	; save start data
	
	push hl

	exx

        ; firstly, we need to save a. we'll patch this up later	
	ld (hl),#32                   ; LD (#xxxx),a
	inc hl
	push hl                       ; save address of xxxx
	inc hl
	inc hl
	
	push hl
	ld de,end_page_jump_code_size
	add hl,de
	ex hl,de                      ; DE = target jump address
	pop hl                        ; restore HL, current address  
	push de
	exx
	pop hl                        ; HL = target jump address
	
        call end_page_jump

        exx         
  	ex hl,de                      ; copy code for start of next page	 
	ld hl,patches_start
	ld bc,patches_start_len
	ldir
	ex hl,de  				; hl' holds target patch code
	exx

;        ld ix,-(3+2)          		; initial cycle count
        ld ix,INITIAL_CYCLES          		; initial cycle count

	ld a,INITIAL_LINE
	ld (next_event_a),a
	ld iy,next_event_table

	call next_event

        ; now we need to restore A, patch up save address from earlier
	exx
        ld (hl),#3e                   ; LD A,#xx
        inc hl
        push hl
        inc hl
        exx

        pop bc                        ; BC = address of xx in LD A,#xx
        pop hl                        ; HL = address of xxxx in LD (#xxxx),A
        ld (hl),c
        inc hl
        ld (hl),b                     ; patch in address
        
        pop hl                        ; preserve hl, this is pixel code addr
                                      ; note, we never corrupted de in this code         	

	ret


next_event_table:
	defb 24
	defw short_line_and_di,0
	defb 29
	defw long_line_and_ei,0-intvec_3_cycles

	defb 26+24
	defw short_line_and_di,0
next_event_table_initial:
	defb 26+29
	defw long_line_and_ei,0-intvec_4_cycles

	defb 52+24
	defw short_line_and_di,0
	defb 52+29
	defw long_line_and_ei,0-intvec_5_cycles

	defb 98
next_event_page_end_func:
	defw start_next_page,0
	
	defb -1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

patches_start:
patches_start_de_save equ $+1
	ld de,screen_base+screen_offset
patches_start_len equ ($-patches_start)	    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


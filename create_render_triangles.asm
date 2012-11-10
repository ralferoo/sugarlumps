;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; create the render task


create_render_triangles:
	ld (next_event_a),a
	ld iy,render_tris_next_event_table
	exx
	call next_event                           ; do initial output                              
        exx

        ex hl,de
	ld hl,render_tris_start
	ld bc,render_tris_start_len
	ldir                                      ; create the pushes
	ex hl,de
	ld bc,-(render_tris_start_cycles+10)      ; entry point around 10
	add ix,bc                                 ; account for the cycles

        xor a
        ld (render_triangles_cp_h),a

;        jr create_render_triangles_long_jump

create_render_triangles_loop:
        ld a,xh
        rla  

        exx
	call c,next_event	                   ; process event if outstanding clock overflow
	exx

        ld a,h
render_triangles_cp_h equ $+1
        cp #0
        jr nz,create_render_triangles_long_jump                      
        
        ld a,l
        add a,5                                   ; space for LD L,xx : JP xxxx
        jr c,create_render_triangles_long_jump
        
        ld (hl),#2e                               ; LD L,#xx
        inc hl
        ld (hl),a
        ld bc,-(5+tris_cycle_counts_initial)
        jr create_render_triangles_do_jump

diff_h: ex af,af'
create_render_triangles_long_jump:
        ld b,h                          
        ld a,l
        add a,6
                                  
        ld (hl),#21                               ; LD HL,#xx
        inc hl
        ld (hl),a
        inc hl
        ld a,b
        adc a,0
        ld (hl),a
        ld (render_triangles_cp_h),a
        ld bc,-(6+tris_cycle_counts_initial)

create_render_triangles_do_jump:
        inc hl
        ld (hl),#c3                              ; JP xxxx
        inc hl

create_line_function_table equ $+1
        ld de,0                                  ; DE = functions table
        ld a,NUMBER_LINE_FUNCTIONS               ; A = functions count

create_render_triangles_search:        
        add ix,bc                                ; adjust cycle count
        jr nc,create_render_triangles_use_this_one ; expect carry as -ve
        
        inc de
        inc de
        ld bc,-tris_cycle_counts_extra
        dec a
        jr nz,create_render_triangles_search

create_render_triangles_use_this_one:
        ex hl,de
        ldi
        ldi
        ex hl,de                                 ; copy address
        jr create_render_triangles_loop                             


long_line_and_switch_task:
	exx
	ex hl,de
	ld hl,render_tris_switch_task
	ld bc,render_tris_switch_task_len
	ldir                                     ; copy switch function                   
	ex hl,de
	
	ld (render_tris_switch_continuation_addr),hl
	ld (render_tris_switch_continuation_ix),ix
	ld (render_tris_switch_continuation_next_ev_a),a
	exx

	ld bc,192-render_tris_no_switch_cyles
	add ix,bc
	ret
                                       
render_triangles_end_page:
        exx                  
        pop bc                  

        ex hl,de
	ld hl,render_tris_end
	ld bc,render_tris_end_len
	ldir
;	ld bc,-render_tris_end_cycles
;	add ix,bc                                 ; account for the cycles
        
render_tris_switch_continuation_addr equ $+1
	ld hl,0
	dec hl
	ld (hl),d
	dec hl
	ld (hl),e                                 ; update jump pointer
	ex hl,de                                  ; HL = buffer on exit

render_tris_switch_continuation_ix equ $+2
	ld ix,0
	ld bc,192-render_tris_switch_cyles
	add ix,bc                                 ; IX = current clock
	
render_tris_switch_continuation_next_ev_a equ $+1	
	ld a,0                                    ; A = current line

        ret

tris_cycle_counts_initial equ 26
tris_cycle_counts_extra equ 20

; a = error, af' trashed
; b = loops
; c = colour
; d = deltay
; e = deltax
; hl = address
; ixl = xstep
; ixh = xstep + xinc

;next_render_switch_jr_byte: defb #20

render_tris_start:
        exx
        ex af,af'
;2
        push af
        push bc
        push de
        push hl
        push ix
;21
        xor a
        
        ld (render_tris_sp_save),sp
        ld sp,(render_sp)
        exx
;14
render_tris_start_len equ $-render_tris_start
render_tris_start_cycles equ 2+21+14

render_tris_end:
        exx

        jr z, render_tris_end_dont_save
        push de
        push ix                              ; save current render task if
        push hl                              ; not finished  
        push bc
        push af        
render_tris_end_dont_save:
;                
        ld (render_sp),sp
        ld sp,(render_tris_sp_save)
;12        
        pop ix
        pop hl
        pop de
        pop bc
        pop af
;16
        ex af,af'
        exx
;2        
        jp task_complete
render_tris_end_len equ $-render_tris_end

render_tris_sp_save: defs 2



render_tris_switch_task:                    
        jr nz,render_tris_no_switch_1
;2/3        
        out (c),b
;4                
        pop af
;7
        jr nz, render_tris_no_switch_2
;2/3         
        jr nc, render_tris_no_switch_3      ; byte=FF sets ZF and CF
;2/3         
        jr render_tris_do_switch
;3

render_tris_no_switch_1:              ; 7 cycles to here
        out (c),b
;4                
        defs 12                              
        jr render_tris_no_switch_end

;14+3                                       
render_tris_no_switch_2:              ; 16 cycles to here
        defs 2
render_tris_no_switch_3:              ; 18 cycles to here
        push af 
        xor a                              
        jr render_tris_no_switch_end
;4
render_tris_do_switch:                ; 20 cycles to here
        xor a                              
        push af 
        ld (render_sp),sp
        ld sp,(render_tris_sp_save)
        exx   
;14        
        pop ix
        pop hl
        pop de
        pop bc
        pop af
;16
        ex af,af'
        exx
;2        
        jp 0
;3

render_tris_no_switch_end:              ; 22 cycles to here

render_tris_switch_task_len equ $-render_tris_switch_task

render_tris_switch_cyles equ (20+14+16+2+3)
render_tris_no_switch_cyles equ 22


                          

render_tris_next_event_table:
	defb 24
	defw short_line_and_di,0
	defb 29
	defw long_line_and_ei,0-intvec_3_cycles

	defb 26+24
	defw short_line_and_di,0

	defb 26+27
	defw long_line_and_switch_task,0
	
	defb 26+29
	defw long_line_and_ei,0-intvec_4_cycles

	defb 52+24
	defw short_line_and_di,0
	defb 52+29
	defw long_line_and_ei,0-intvec_5_cycles

	defb 98
	defw render_triangles_end_page,0
	
	defb -1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


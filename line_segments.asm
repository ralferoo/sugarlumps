; base of code is this function:
;
; a = error, af' trashed
; b = loops
; c = colour
; d = deltay
; e = deltax
; hl = address
; ixl = xstep
; ixh = xstep + xinc
        
;draw_line_segments:
;        exx
;        jp nz, iteration_1
;        jp  load_segment_1
;
;iteration_1:
;        sub e                             ; error -= deltax
;        jr nc, no_overflow_1              ; no step
;        add a,d                           ; error += deltay
;;4
;        ex af,af'                         ; save error  
;        ld a,(hl)
;        xor c
;        ld (hl),a                         ; set colour
;;6
;        ld a,xh
;        add a,l
;        ld l,a                            ; x += xinc+xstep
;        inc h                             ; y += 1
;        ex af,af'                         ; restore error  
;;6
;        dec b
;        jp nz,iteration_2                  ; loop
;;5
;        jp load_segment_2
;;3
;         
;no_overflow_1:
;        ex af,af'                         ; save error  
;        ld a,(hl)
;        xor c
;        ld (hl),a                         ; set colour
;
;        ld a,xl
;        add a,l
;        ld l,a                            ; x += xstep
;        inc h                             ; y += 1
;        ex af,af'                         ; restore error  
;        dec b
;        jp nz,iteration_2                  ; loop
;        jp load_segment_2
;
;;empty_segment_skip_1:
;;        push bc                      
;
;load_segment_1:
;        pop af                            ; 3 a=error, f=continue
;        jr z, empty_segment_skip_2        ; 2 (3)
;;5/6
;        pop bc                            ; 3 b=loops, c=colour
;        pop de                            ; 3 d=deltax, e=deltay
;        pop hl                            ; 3 hl=addr
;        pop ix                            ; 4 ixh=xstep+xinc, ixl=xstep
;;13
;iteration_2:                               
                                                              
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; start->it'     4
;   it'->exit    22 = 26 for single iteration

; start->load'   6
; load'->exit    20 = 26                                                                   

; start->it      4
;    it->it     20
;    it->exit   22 = 46

; start->it      4
;    it->load   22
;  load->exit   20 = 46

; start->load    6
;  load->it     18
;    it->exit   22 = 46

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  load->skip    6
;  skip->load   14
;    it->load   22
;  load->it     18
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


create_line_functions:
        ld (create_line_fn_sp_save),sp

        ld ix,freemem_base                   ; some random bit of memory to trash                                    
        ld iy,freemem_base-load_segment_empty_patch_add


        exx
        ld b,NUMBER_LINE_FUNCTIONS
        exx
        ex hl,de                            ; DE = dest code
create_line_loop:

        push de                             ; save, ready for pop hl below  

        call update_ix_iteration
        
        ld hl,iteration_code
        ld bc,iteration_code_length
        ldir                                ; copy iteration code                                                                      

        pop hl                              ; HL=iteration code addr
        push hl                             ; save, ready for pop ix  
        ld bc,-2
        add hl,bc
        sbc hl,de                           ; HL=distance to iteration from here+3

        push de                             ; save jumpblock pointer
        ex hl,de
        ld (hl),#d9                         ; EXX
        inc hl
        ld (hl),#20                         ; JR NZ,iteration code
        inc hl
        ld (hl),e
        inc hl
        ld (hl),#18                         ; JR load code
        inc hl
        ld (hl),empty_segment_skip_code_length   ; skip skipping code
        inc hl
        ex hl,de                            ; DE=code pointer again, HL=after jumpblock

        call update_iy_patch_next_jump      ; patches last iy to this de
        
        ld hl,empty_segment_skip_code
        ld bc,empty_segment_skip_code_length
        ldir                                ; copy empty_segment_skip code                                                                      

        call update_ix_load_segment

        pop hl                              ; jumpblock address
        pop ix                              ; next address to overwrite

        push hl                             ; push load function
        ld hl,load_segment_code
        ld bc,load_segment_code_length
        ldir                                ; copy load_segment code                                                                      
                                                      
        push de
        pop iy                              ; update iy with next     

        exx
        dec b
        exx
        jr nz, create_line_loop

finished_line_loop:
        push de                             ; save, ready for pop hl below  

        call update_ix_iteration
        
        ld hl,iteration_last
        ld bc,iteration_last_length
        ldir                                ; copy iteration code                                                                      

        pop hl                              ; HL=iteration code addr
        push hl                             ; save, ready for pop ix  
        ld bc,-2
        add hl,bc
        sbc hl,de                           ; HL=distance to iteration from here+3

        push de                             ; save jumpblock pointer
        ex hl,de
        ld (hl),#d9                         ; EXX
        inc hl
        ld (hl),#20                         ; JR NZ,iteration code
        inc hl
        ld (hl),e
        inc hl
        ld (hl),#18                         ; JR load code
        inc hl
        ld (hl),empty_segment_skip_code_length   ; skip skipping code
        inc hl
        ex hl,de                            ; DE=code pointer again, HL=after jumpblock

        call update_iy_patch_next_jump      ; patches last iy to this de
        
        ld hl,empty_segment_skip_code
        ld bc,empty_segment_skip_code_length
        ldir                                ; copy empty_segment_skip code                                                                      

        call update_ix_load_segment

        pop hl                              ; jumpblock address
        pop ix                              ; next address to overwrite

        push hl                             ; push load function
        ld hl,load_segment_last
        ld bc,load_segment_last_length
        ldir                                ; copy load_segment code                                                                      

        ex hl,de

;;;;;;;;;;;;;;; now make the entry functions

        ld (create_line_function_table),hl        

        ld a,1+NUMBER_LINE_FUNCTIONS
create_entries:
        pop de                              ; DE = jumpblock
        
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        
        dec a
        jr nz,create_entries  
        
create_line_fn_sp_save equ $+1
        ld sp,0               
        ret

                                          
update_ix_iteration:
        push de
        pop hl
        ld bc,0-iteration_ofs_1
        add hl,bc                           ; note, will set carry
        push ix
        pop bc
        sbc hl,bc                           ; subtract the extra 1  
        ld (ix+iteration_ofs_1),l

        ld bc,iteration_ofs_1-iteration_ofs_2
        add hl,bc                             
        ld (ix+iteration_ofs_2),l
        ret

update_iy_patch_next_jump:
        push de
        pop hl
        ld bc,load_segment_empty_patch_add-1
        add hl,bc
        push iy
        pop bc
        sbc hl,bc                           ; HL = distance from last to this one
        ld (iy-load_segment_empty_patch_add),l ; patch previous JR
        ret                  

update_ix_load_segment:        
        push de
        pop hl
        ld bc,0-load_segment_ofs_1
        add hl,bc                           ; note, will set carry
        push ix
        pop bc
        sbc hl,bc                           ; subtract the extra 1  
        ld (ix+load_segment_ofs_1),l

        ld bc,load_segment_ofs_1-load_segment_ofs_2
        add hl,bc                             
        ld (ix+load_segment_ofs_2),l
        ret

; iteration to iteration = 20, to load = 22

iteration_code:
        sub e                             ; error -= deltax
        jr nc, no_overflow                ; no step
        add a,d                           ; error += deltay
;4
        ex af,af'                         ; save error  
        ld a,(hl)
        xor c
        ld (hl),a                         ; set colour
;6
        ld a,xh
        add a,l
        ld l,a                            ; x += xinc+xstep
        inc h                             ; y += 1
        ex af,af'                         ; restore error  
;6
        dec b
iteration_ofs_1 equ $+1-iteration_code
        jr nz,$+1 ;iteration_2                  ; loop
;4
load_segment_ofs_1 equ $+1-iteration_code
        jr $+1 ;load_segment_2
;3
         
no_overflow:
        ex af,af'                         ; save error  
        ld a,(hl)
        xor c
        ld (hl),a                         ; set colour

        ld a,xl
        add a,l
        ld l,a                            ; x += xstep
        inc h                             ; y += 1
        ex af,af'                         ; restore error  
        dec b
iteration_ofs_2 equ $+1-iteration_code
        jr nz,$+1 ;iteration_2                  ; loop
;5
load_segment_ofs_2 equ $+1-iteration_code
        jr $+1 ;load_segment_2

iteration_code_length equ $-iteration_code


;; iteration_last to hl' = 22
         
iteration_last:                              
        sub e                             ; error -= deltax
        jr nc, no_overflow_last           ; no step
        add a,d                           ; error += deltay
;4
        ex af,af'                         ; save error  
        ld a,(hl)
        xor c
        ld (hl),a                         ; set colour
;6
        ld a,xh
        jr continue_last
;5        

no_overflow_last:
;4
        ex af,af'                         ; save error  
        ld a,(hl)
        xor c
        ld (hl),a                         ; set colour
;6
        ld a,xl
        jr continue_last
;5        
continue_last:
        add a,l
        ld l,a                            ; x += xstep
        inc h                             ; y += 1
        ex af,af'                         ; restore error  
        dec b
;5        
        exx
        jp (hl)                           ; return    
;2
iteration_last_length equ $-iteration_last                              



empty_segment_skip_code:
;6
        push af                      
;4
;        ld bc,DEBUG_NOTHING_TO_DO
;        out (c),c
        jr essc_a
essc_a:
        jr essc_b
essc_b: jr essc_c
essc_c: nop
;10
empty_segment_skip_code_length equ $-empty_segment_skip_code

;load_segment_code takes 18 to next iteration  
load_segment_code:
        pop af                            ; 3 a=error, f=continue
load_segment_empty_skip_ofs equ $+1
        jr z, empty_segment_skip_code     ; 2 (3)
;5/6
        pop bc                            ; 3 b=loops, c=colour
        pop hl                            ; 3 hl=addr
        pop ix                            ; 4 ixh=xstep+xinc, ixl=xstep
        pop de                            ; 3 d=deltax, e=deltay
;13
load_segment_code_length equ $-load_segment_code
load_segment_empty_patch_add equ $-load_segment_empty_skip_ofs




; load_segment_last always takes 20 cycles to (hl)

load_segment_last:
        pop af                            ; 3 a=error, f=continue
        jr z, empty_segment_last_code     ; 2 (3)
;5/6
        pop bc                            ; 3 b=loops, c=colour
        pop hl                            ; 3 hl=addr
        pop ix                            ; 4 ixh=xstep+xinc, ixl=xstep
        pop de                            ; 3 d=deltax, e=deltay
;13
        exx
        jp (hl)                           ; return    
;2

empty_segment_last_code:
;6
        push af                      
;4
        pop af
        push af
        nop
;8        
        exx
        jp (hl)                           ; return    
;2
load_segment_last_length equ $-load_segment_last


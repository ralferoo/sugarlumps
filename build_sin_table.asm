build_sin_table:
        ld hl, quadrant_of_sin_table
        ld ix, base_sin_table+128       ; works up      
        ld iy, base_sin_table+256       ; works down                
        ld b,65
build_sin_table_loop:
        ld a,(hl)
        inc hl
        ld (ix-128),a                   ; 00  -> 40                                                 
        ld (iy-128),a                   ; 80  -> 40
        cpl                             ; could use neg, not sure there's an advantage
        inc a
        ld (ix+0),a                     ; 80  -> C0
        ld (iy+0),a                     ; 100 -> C0   
        inc ix
        dec iy
        djnz build_sin_table_loop

	ld de, base_sin_table
        ld hl, base_sin_addr_table
new_sin:
        ld a,(de)
        inc e
        and #fc
        inc a
        ld (hl),a
        inc l
        jr nz,new_sin
        
        ret                         

        read "sin.asm"


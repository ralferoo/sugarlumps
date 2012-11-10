decompress_font:
        ld de,font_buffer
        
        xor a                                         ; clear the font table buffer
clear_font_buffer:
        ld (de),a
        inc e
        jr nz, clear_font_buffer

        ld hl,raw_font_data
render_font:
        ld a,(hl)
        inc hl
        add a,a
        ret z
        
        ex hl,de
        ld l,a 
        ld (hl),e
        inc hl
        ld (hl),d
        ex hl,de
        
        ld a,(hl)                                    ; width of fonts
        inc hl
        
        add a,3                                      ; move to next multiple
        and #fc                                      ; /4 * 4
        add a,a
        add a,a                                      ; * 4 

        ld b,0 
        ld c,a
        add hl,bc
        
        jr render_font
                
raw_font_data:
        readbin "font/dnd_font.raw"
raw_font_data_length equ $-raw_font_data
                   

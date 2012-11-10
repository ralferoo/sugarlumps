
; draws bezier (e,d) -> (l,h) with control point at (c,b)
; to poly buffer at ix. unlike the segment code below, this also adds the
; start point and the terminator, although this might well not be needed...

draw_bezier:
        ld (ix+0),e
        ld (ix+1),d
        inc ix
        inc ix

        call draw_bezier_segment
        
        ld (ix+0),0
        ret
        
; draws bezier segment (e,d) -> (l,h) with control point at (c,b)
; to poly buffer at ix

draw_bezier_segment:            
        push hl               ; save right hand coords for later
        
        ld a,e
        add a,l
        rra
        ld l,a                ; l = x midpoint between left and right

        adc a,c
        rra
        cp l
        ld l,a                ; l = x midpoint on curve
;        jr z, possibly_line_x
;        cp e
        jr nz, no_bezier_line_x ; need to subdivide
possibly_line_x:        

        ld a,d
        add a,h
        rra
        ld h,a                ; h = y midpoint between left and right
        
        adc a,b
        rra
        cp h
        ld h,a                ; h = y midpoint on curve
;        jr z, possibly_line_y
;        cp d
        jr nz, no_bezier_line_y ; need to subdivide
possibly_line_y:
        
        pop hl
        
;        ld (ix+0),c
;        ld (ix+1),b
;        inc ix
;        inc ix
        
        ld (ix+0),l
        ld (ix+1),h
        inc ix
        inc ix
        ret

no_bezier_line_x:
        ld a,d
        add a,h
        rra                 ; a = y midpoint between left and right
        
        adc a,b
        rra 
        ld h,a                ; h = y midpoint on curve

no_bezier_line_y:
        push hl               ; save midpoint on curve  
        push bc               ; save original control point
        
        ld a,e
        add a,c
        rra
        ld c,a                ; new control point = midpoint of left and control                                              
                
        ld a,d
        add a,b
        rra
        ld b,a                ; new control point = midpoint of left and control

        call draw_bezier_segment ; subdivide left
                
        pop bc                ; restore original control point
        pop de                ; restore new mid "on curve" point
        pop hl                ; restore right point
        
        ld a,l
        add a,c
        rra
        ld c,a                ; new control point = midpoint of right and control                                              
                
        ld a,h
        add a,b
        rra
        ld b,a                ; new control point = midpoint of right and control

        jr draw_bezier_segment ; subdivide left
                

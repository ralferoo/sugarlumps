#!/usr/bin/python

# line (l,h)->(e,d) and c is colour

def line(xl,yl, xr,yr):
    print "(%d,%d)-(%d,%d)"%(xl,yl, xr,yr)

def add_sra(a,b):
    return int((a+b)/2)

# ld a,l
# add a,e
# sra a         ; a=(l+e)/2
# add a,c
# sra a         ; a=(c+(l+e)/2)/2

def bezier_z80(reg_l,reg_h, reg_c,reg_b, reg_e,reg_d):
    # save these
    saved = (reg_e,reg_d)

    # find x midpoints
    reg_e = add_sra(reg_l,reg_e)          # midpoint between left and right
    a = add_sra(reg_e,reg_c)             # midpoint between that and control

    if reg_e==a: # or reg_c==xm:
        reg_e = a
        # find y midpoints
        reg_d = add_sra(reg_h,reg_d)         # midpoint between left and right
        a = add_sra(reg_d,reg_b)         # midpoint between that and control

        if reg_d==a: # or reg_c==xm:        # midpoint too close, draw lines
            (reg_e,reg_d) = saved
            #print "(%d,%d)-(%d,%d)-(%d,%d)"%(reg_l,reg_h, xm,ym, reg_e,reg_d)
            #line(reg_l,reg_h, reg_c,reg_b)
            #line(reg_c,reg_b, reg_e,reg_d)
            #print
            line(reg_l,reg_h, reg_e,reg_d)
            return
        reg_d = a
    else:
        reg_e = a
        # find y midpoints
        a = add_sra(reg_h,reg_d)        # midpoint between left and right
        reg_d = add_sra(a,reg_b)           # midpoint between that and control

    # here, reg_e and reg_d contain the point on the curve midway

    # calculate the midpoint of left and control, this becomes the control
    # point between left and the curve point found above
    xs = add_sra(reg_l,reg_c)
    ys = add_sra(reg_h,reg_b)
    bezier_z80( reg_l,reg_h, xs,ys, reg_e,reg_d)
    # needs to save reg_de and reg_bc during this call

    # calculate the midpoint of right and control, this becomes the control
    # point between right and the curve point found above
    (reg_l,reg_h) = saved
    xs = add_sra(reg_l,reg_c)
    ys = add_sra(reg_h,reg_b)
    bezier_z80( reg_e,reg_d, xs,ys, reg_l,reg_h)


def bezier(xl,yl, xc,yc, xr,yr):
    (xm2,ym2) = (xl+xr, yl+yr)          # midpoint of line between left & right
    (xm,ym) =( int(xm2/2), int(ym2/2) )
    
    (xn,yn) = ( int((xm+xc)/2), int((ym+yc)/2) )    # between midpoint & control

    if xm<>xn and ym<>yn:
        (xlc,ylc) = ( int((xl+xc)/2), int((yl+yc)/2) )    # between left & ctl
        (xrc,yrc) = ( int((xr+xc)/2), int((yr+yc)/2) )    # between left & ctl
        bezier( xl,yl, xlc,ylc, xn,yn)
        bezier( xn,yn, xrc,yrc, xr,yr)

    else:
        line(xl,yl, xc,yc)
        line(xc,yc, xr,yr)

#bezier_z80(0,64, 0,0, 64,0)
#bezier_z80(0,64, 63,63, 64,0)


bezier_z80(0,16, 0,0, 16,0)
print "---"
bezier_z80(0,16, 0,32, 16,32)
print "---"
bezier_z80(32,16, 32,0, 16,0)
print "---"
bezier_z80(32,16, 32,32, 16,32)

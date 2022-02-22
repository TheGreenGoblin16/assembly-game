IDEAL
MODEL small
STACK 256

DATASEG
WHITE dw 0Fh
BLACK dw 00h
GREEN dw 48h
PINK dw 0Dh

NOTE_F3 dw 6833
NOTE_G3 dw 6087
NOTE_C4 dw 4560
NOTE_A4 dw 2416

BRICK_WIDTH dw 45
BRICK_HEIGHT dw 20
BRICK_WIDTH_PLUS dw 49
BRICK_HEIGHT_PLUS dw 24

prev_time db 0
racketx dw 40
rackety dw 191
racketspeed dw 4
ballx dw 61
bally dw 141
ballspeedx dw 2
ballspeedy dw 2
pillx dw 0
pilly dw 0

pill_flag db 0
pill_velocity db 3 ; higher is slower actually
pill_counter db 0

; 28h = red. 2Ah = orange. 2Ch = yellow. 2Fh = lime. 34h = cyan.
bricks_array dw 11,6,28h,1, 61,6,28h,1, 111,6,28h,1, 161,6,28h,1, 211,6,28h,1, 261,6,28h,1, 11,32,2Ah,1, 61,32,2Ah,1, 111,32,2Ah,1, 161,32,2Ah,1, 211,32,2Ah,1, 261,32,2Ah,1, 11,58,2Ch,1, 61,58,2Ch,1, 111,58,2Ch,1, 161,58,2Ch,1, 211,58,2Ch,1, 261,58,2Ch,1, 11,84,2Fh,1, 61,84,2Fh,1, 111,84,2Fh,1, 161,84,2Fh,1, 211,84,2Fh,1, 261,84,2Fh,1, 11,110,34h,1, 61,110,34h,1, 111,110,34h,1, 161,110,34h,1, 211,110,34h,1, 261,110,34h,1, 0

starting_screen_text db "[ Welcome to Breakout 1999! ]", 10,10, "Your goal is to move the racket (white  rectangle), hit the ball with it, and   destroy the bricks. If you let the ball touch the bottom, you'll lose the game!", 10, "There are also sometimes pink pills     falling from bricks, I will let you     discover what they do (;", 10,10, "Controls:", 10, "a,d - move the racket", 10, "shift+Q - force quit", 10,10, "- Press a key to start the game -$"
win_screen_text db "[ You won! ]", 10,10, "You managed to destroy all the bricks!  Good job! Now get some life and play   outside...", 10,10, "- Press a key to exit -$"
lose_screen_text db "[ You lost! ]", 10,10, "You didn't hit the ball in time... Oh   no... Now you'll have to do it all over again!", 10,10, "- Press a key to exit -$"

CODESEG

proc starting_screen

    mov ah, 09h
    mov dx, offset starting_screen_text
    int 21h

    mov ah, 00h
    int 16h

    ret
endp

proc win_screen

    mov ah, 09h
    mov dx, offset win_screen_text
    int 21h

    mov ah, 00h
    int 16h

    ret
endp

proc lose_screen
    
    mov ah, 09h
    mov dx, offset lose_screen_text
    int 21h

    mov ah, 00h
    int 16h

    ret
endp

proc mov_signed ; variable, number
    push bp
    mov bp, sp
    push ax
    push dx
    push si
    
    mov dx, 0
    mov si, [bp+4]
    mov ax, [bp+6]

    cmp [si], dx
    jl mov_signed_minus
    jmp mov_signed_exit
    mov_signed_minus:
        neg ax

    mov_signed_exit:
    mov [si], ax
    pop si
    pop dx
    pop ax
    pop bp
    ret 4
endp

proc fix_parity ; variable
    push bp
    mov bp, sp
    push ax
    push dx
    push si

    mov dx, 1
    mov si, [bp+4]

    mov ax, [si]   
    and ax, dx
    cmp ax, 0
    je fix_parity_fix
    jmp fix_parity_end

    fix_parity_fix:
        mov ax, [si]
        dec ax
        mov [si], ax
    
    fix_parity_end:
    pop si
    pop dx
    pop ax
    pop bp
    ret 2
endp

proc revert_ballspeedx 
    push 2
    push offset ballspeedx
    call mov_signed
    push offset ballx
    call fix_parity
    ret
endp

proc graphic_mode
    push ax

    mov ah, 00h
    mov al, 13h
    int 10h
    
    pop ax
    ret
endp

proc set_background
    push ax
    push bx

    mov ah, 0Bh
    mov bh, 00h
    mov bl, 0Fh
    int 10h

    pop bx
    pop ax
    ret
endp

proc paint_pixel ; x, y, color
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov ah, 0Ch
    mov bh, 0
    mov cx, [bp+4]
    mov dx, [bp+6]
    mov al, [bp+8]
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6
endp



proc draw_rect ; x, y, width, height, color
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov ax, [bp+4] ;x
    mov bx, [bp+6] ;y
    mov dl, [bp+8] ;width
    mov dh, [bp+10] ;height
    
    xor cx, cx
    rect_row:
        mov ax, [bp+4]
        mov cl, 0
        rect_pixel:
            push [bp+12]
            push bx
            push ax
            call paint_pixel
            inc ax
            inc cl
            cmp cl, dl
            jle rect_pixel
        inc bx
        inc ch
        cmp ch, dh
        jle rect_row

    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10
endp

proc wait_tenth
    push ax
    push cx
    push dx
    
    mov ah, 86h
    mov cx, 0001h
    mov dx, 86A0h
    int 15h

    pop dx
    pop cx
    pop ax
    ret
endp

proc play_bit
    push bp
    mov bp, sp
    push ax

    in al, 61h ; Open speaker
    or al, 00000011b
    out 61h, al
    
    mov al, 0B6h ; Send control word to change frequency
    out 43h, al

    mov ax, [bp+4] ; Play frequency 131Hz
    out 42h, al ; Sending lower byte
    mov al, ah
    out 42h, al ; Sending upper byte

    pop bp
    pop ax
    ret 2
endp

proc stop_bit
    push ax

    in al, 61h
    and al, 11111100b
    out 61h, al

    pop ax
    endp
endp

proc key_pressed ; returns zf=0 if key pressed
    mov ah, 01h
    int 16h
    ret
endp

proc get_key ; returns ah=scancode al=ascii
    mov ah, 00h
    int 16h
    ret
endp

proc debug_char
    push ax
    push dx

    mov ah, 02h
    mov dl, "a"
    int 21h

    pop dx
    pop ax
    ret
endp

proc draw_bricks ; ax = bricks array offset, brick[8]=x[2]y[2]color[2]present[2]
    push ax
    push si

    mov si, ax
    draw_bricks_loop:
        mov ax, [si]
        cmp ax, 00h
        je draw_bricks_end

        mov ax, [si+6]
        cmp ax, 0
        je draw_bricks_nonpresent
        push [si+4]
        jmp draw_bricks_continue

        draw_bricks_nonpresent:
        push [BLACK]
        
        draw_bricks_continue:
        push [BRICK_HEIGHT]
        push [BRICK_WIDTH]
        push [si+2]
        push [si+0]
        call draw_rect
        
        add si, 8
        jmp draw_bricks_loop

    draw_bricks_end:
    pop si
    pop ax
    ret
endp

;; check if ball is in collision with a brick given as params
proc collision_field ; x, y   ; ax... 0=none, 1=top/buttom, 2=left/right, 3=corners
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    
    mov al, 0
    top_collision:
        mov cx, [bp+4] ;x
        mov dx, [bp+6] ;y
        sub dx, 1
        cmp dx, [bally]
        jne buttom_collision
        sub cx, 2
        mov dx, [ballx]
        sub dx, cx
        cmp dx, [BRICK_WIDTH_PLUS]
        ja buttom_collision
        add al, 1
    buttom_collision:
        mov cx, [bp+4]
        mov dx, [bp+6]
        add dx, [BRICK_HEIGHT]
        inc dx
        cmp dx, [bally]
        jne left_collision
        sub cx, 2
        mov dx, [ballx]
        sub dx, cx
        cmp dx, [BRICK_WIDTH_PLUS]
        ja left_collision
        add al, 1
    left_collision:
        mov cx, [bp+4]
        mov dx, [bp+6]
        sub cx, 2
        cmp cx, [ballx]
        jne right_collision
        sub dx, 2
        mov cx, [bally]
        sub cx, dx
        cmp cx, [BRICK_HEIGHT_PLUS]
        ja right_collision
        add al, 2
    right_collision:
        mov cx, [bp+4]
        mov dx, [bp+6]
        add cx, [BRICK_WIDTH]
        inc cx
        cmp cx, [ballx]
        jne collision_field_end
        sub dx, 2
        mov cx, [bally]
        sub cx, dx
        cmp cx, [BRICK_HEIGHT_PLUS]
        ja collision_field_end
        add al, 2

    collision_field_end:
    pop dx
    pop cx
    pop bx
    pop bp
    ret 4
endp

;; check if ball is in collision with any brick
proc collide_bricks ; ax = bricks array offset
    push ax
    push si
    
    mov si, ax
    collide_bricks_loop:
        mov ax, [si]
        cmp ax, 0
        je collide_bricks_end

        mov ax, [si+6]
        cmp ax, 0
        je collide_bricks_continue

        push [si+2]
        push [si+0]
        call collision_field
        cmp al, 1
        je collide_bricks_top_buttom
        cmp al, 2
        je collide_bricks_left_right
        cmp al, 3
        je collide_bricks_corner
        cmp al, 0
        je collide_bricks_continue
        
        collide_bricks_top_buttom:
            neg [ballspeedy]
            jmp collide_bricks_destroy
        collide_bricks_left_right:
            neg [ballspeedx]
            jmp collide_bricks_destroy
        collide_bricks_corner:
            neg [ballspeedx]
            neg [ballspeedy]
            jmp collide_bricks_destroy

        collide_bricks_destroy:
            mov ax, 0
            mov [si+6], ax
            call revert_ballspeedx
            push [NOTE_C4]
            call play_bit
            call spawn_pill
            jmp collide_bricks_continue

        collide_bricks_continue:
        add si, 8
        jmp collide_bricks_loop

    collide_bricks_end:
    pop si
    pop ax
    ret
endp

proc check_bricks
    push bx
    push si

    mov bx, 0
    mov si, ax
    check_bricks_loop:
        mov ax, [si]
        cmp ax, 00h
        je check_bricks_end

        mov ax, [si+6]
        cmp ax, 0
        je check_bricks_continue
        inc bx
        jmp check_bricks_continue
        
        check_bricks_continue:
        add si, 8
        jmp check_bricks_loop

    check_bricks_end:
    mov ax, bx

    pop si
    pop bx
    ret
endp

proc clear_ball
    push ax

    push [BLACK] ;; Clear the old ball
    push 3
    push 3
    mov ax, [bally]
    dec ax
    push ax ;y
    mov ax, [ballx]
    dec ax
    push ax ;x
    call draw_rect
    
    pop ax
    ret
endp

proc draw_pill
    push ax
    
    mov ax, 0
    add ax, [pillx]
    add ax, [pilly]
    cmp ax, 0
    je draw_pill_black
    push [PINK]
    jmp draw_pill_continue

    draw_pill_black:
    push [BLACK]

    draw_pill_continue:
    push 3
    push 3
    mov ax, [pilly]
    dec ax
    push ax
    mov ax, [pillx]
    dec ax
    push ax
    call draw_rect

    pop ax
    ret
endp

proc clear_pill
    push ax

    push [BLACK]
    push 3
    push 3
    mov ax, [pilly]
    dec ax
    push ax
    mov ax, [pillx]
    dec ax
    push ax
    call draw_rect

    pop ax
    ret
endp

proc spawn_pill ; works exclusively in collide_bricks
    push ax
    
    mov ax, 0
    add ax, [pillx]
    add ax, [pilly]
    cmp ax, 0
    jne spawn_pill_exit
    mov al, [prev_time]
    and al, 00001111b
    cmp al, 2
    jg spawn_pill_exit
    mov ax, [si+0]
    add ax, 22
    mov [pillx], ax
    mov ax, [si+2]
    mov [pilly], ax

    spawn_pill_exit:
    pop ax
    ret
endp

proc accelerate_pill
    push ax

    mov al, 3

    cmp [pill_counter], 5
    jbe accelerate_pill_exit
    dec ax
    cmp [pill_counter], 18
    jbe accelerate_pill_exit
    dec ax
    cmp [pill_counter], 40
    jbe accelerate_pill_exit
    dec ax

    accelerate_pill_exit:
    mov [pill_velocity], al
    pop ax
    ret
endp

proc move_pill
    push ax

    mov ax, 0
    add ax, [pillx]
    add ax, [pilly]
    cmp ax, 0
    je move_pill_exit

    call accelerate_pill
    mov al, [pill_velocity]
    cmp [pill_flag], al
    je move_pill_full
    jmp move_pill_less
    
    move_pill_less:
        inc [pill_flag]
        jmp move_pill_exit
    move_pill_full:
        mov [pill_flag], 0
        inc [pilly]
        inc [pill_counter]

    cmp [pilly], 189
    jl move_pill_exit
    mov ax, [pillx]
    sub ax, [racketx]
    cmp ax, 50
    jbe move_pill_on
    jmp move_pill_through

    move_pill_on:
        mov [pillx], 0
        mov [pilly], 0
        mov [pill_counter], 0
        push [NOTE_A4]
        call play_bit
        jmp move_pill_exit
    move_pill_through:
        cmp [pilly], 197
        jl move_pill_exit
        mov [pillx], 0
        mov [pilly], 0
        mov [pill_counter], 0
        mov [racketspeed], 2
        jmp move_pill_exit

    move_pill_exit:
    pop ax
    ret
endp

start:
    mov ax, @data
    mov ds, ax

    call graphic_mode
    call starting_screen
    call graphic_mode
    call set_background
    
    gameloop:
        mov ah, 2Ch ;; Loop system: checks every iteration if time has passed
        int 21h ; ch=hour cl=minute dh=second dl=1/100 second
        cmp dl, [prev_time]
        je gameloop
        mov [prev_time], dl
        call stop_bit
        
        call clear_ball

        call clear_pill

        call key_pressed ;; If no key was pressed, skip input stage
        jz gameloop_calc

        push [BLACK] ;; Clear the old racket
        push 10
        push 52
        push [rackety]
        push [racketx]
        call draw_rect

        call get_key ;; Input: jump to the label of the key pressed
        cmp al, "d"
        je key_d
        cmp al, "a"
        je key_a
        cmp al, "Q"
        je key_q
        jmp gameloop_calc

        key_d:
            cmp [racketx], 264
            jg gameloop_calc
            mov ax, [racketspeed]
            add [racketx], ax
            jmp gameloop_calc
        key_a:
            cmp [racketx], 4
            jl gameloop_calc
            mov ax, [racketspeed]
            sub [racketx], ax
            jmp gameloop_calc
        key_q:
            jmp exit
        
    gameloop_calc:
        mov ax, [ballspeedx]
        add [ballx], ax
        mov ax, [ballspeedy]
        add [bally], ax

        cmp [ballx], 317
        jge sides_boundry
        cmp [ballx], 1
        jle sides_boundry
        y_boundries:
        cmp [bally], 189
        jge racket_boundry
        cmp [bally], 1
        jle top_boundry
        jmp gameloop_draw

        sides_boundry:
            neg [ballspeedx]
            jmp y_boundries
        top_boundry:
            neg [ballspeedy]
            jmp gameloop_draw
        racket_boundry:
            mov ax, [ballx]
            sub ax, [racketx]
            cmp [bally], 191
            jge racket_boundry_through
            mov [racketspeed], 4
            cmp ax, 15
            jbe racket_boundry_edges
            cmp ax, 35
            jbe racket_boundry_center
            cmp ax, 50
            jbe racket_boundry_edges
            jmp gameloop_draw
        racket_boundry_edges:
            neg [ballspeedy]
            push 1
            push offset ballspeedx
            call mov_signed
            push [NOTE_G3]
            call play_bit
            jmp gameloop_draw
        racket_boundry_center:
            neg [ballspeedy]
            call revert_ballspeedx
            push [NOTE_F3]
            call play_bit
            jmp gameloop_draw
        racket_boundry_through:
            cmp [bally], 197
            jge lose_exit
            jmp gameloop_draw


    gameloop_draw:
        mov ax, offset bricks_array
        call collide_bricks
        call draw_bricks
        call check_bricks
        
        cmp ax, 0
        je win_exit

        call move_pill

        push [GREEN] ;; Draw a new ball
        push 3
        push 3
        mov ax, [bally]
        dec ax
        push ax ;y
        mov ax, [ballx]
        dec ax
        push ax ;x
        call draw_rect

        push [WHITE] ;; Draw a new racket
        push 4
        push 50
        push [rackety]
        push [racketx]
        call draw_rect

        call draw_pill
        
        jmp gameloop

win_exit:
    call graphic_mode
    call win_screen
    jmp exit

lose_exit:
    call graphic_mode
    call lose_screen

exit:
    call stop_bit
    mov ah, 4Ch
    int 21h
END start
IDEAL
MODEL small
STACK 256

DATASEG
WHITE dw 0Fh
BLACK dw 00h
GREEN dw 48h
BRIGHT_GREEN dw 5Fh

; divisor = 1193180 / frequency
NOTE_C2 dw 18242
NOTE_A2 dw 10847
NOTE_F3 dw 6833
NOTE_G3 dw 6087
NOTE_C4 dw 4560
NOTE_A4 dw 2416

BRICK_WIDTH dw 45
BRICK_HEIGHT dw 20
BRICK_WIDTH_PLUS dw 49
BRICK_HEIGHT_PLUS dw 24

prev_time db 0
random_num db 1
random_boolean db 0
total_bricks db 0

racketx dw 40
rackety dw 191
racketspeed dw 4
rackethit dw 0

ballx dw 55
bally dw 141
ballspeedx dw 2
ballspeedy dw 2

pill1_x dw 0 ; decreasing racketspeed
pill1_y dw 0
pill1_color dw 65h ; blue
pill1_chance db 1 ; 0-3
pill1_flag db 0
pill1_velocity db 3 ; higher is slower actually
pill1_counter db 0

pill2_x dw 0 ; increasing racketspeed
pill2_y dw 0
pill2_color dw 43h ; orange
pill2_chance db 6 ; 4-7
pill2_flag db 0
pill2_velocity db 3
pill2_counter db 0

pill3_x dw 0 ; teleporting racket
pill3_y dw 0
pill3_color dw 54h ; pink 
pill3_chance db 9 ; 8-11
pill3_flag db 0
pill3_velocity db 3
pill3_counter db 0

; 28h = red. 2Ah = orange. 2Ch = yellow. 2Fh = lime. 34h = cyan.
bricks_array dw 11,6,28h,4, 61,6,28h,4, 111,6,28h,4, 161,6,28h,4, 211,6,28h,4, 261,6,28h,4, 11,32,2Ah,4, 61,32,2Ah,4, 111,32,2Ah,4, 161,32,2Ah,4, 211,32,2Ah,4, 261,32,2Ah,4, 11,58,2Ch,4, 61,58,2Ch,4, 111,58,2Ch,4, 161,58,2Ch,4, 211,58,2Ch,4, 261,58,2Ch,4, 11,84,2Fh,4, 61,84,2Fh,4, 111,84,2Fh,4, 161,84,2Fh,4, 211,84,2Fh,4, 261,84,2Fh,4, 11,110,34h,4, 61,110,34h,4, 111,110,34h,4, 161,110,34h,4, 211,110,34h,4, 261,110,34h,4, 0

starting_screen_text db "[ Welcome to Breakout 1999! ]", 10,10, "Your goal is to move the racket (white  rectangle), hit the ball with it, and   destroy the bricks. If you let the ball touch the bottom, you'll lose the game!", 10, "There are also sometimes colorful pills falling from bricks, I will let you     discover what they do (;", 10,10, "Controls:", 10, "a,d - move the racket", 10, "shift+Q - force quit", 10,10, "Made by Ohad K", 10,10,10, "- Press a key to start the game -$"
win_screen_text db "[ You won! ]", 10,10, "You managed to destroy all the bricks!  Good job! Now get some life and play    outside...", 10,10,10, "- Press a key to exit -$"
lose_screen_text db "[ You lost! ]", 10,10, "You didn't hit the ball in time... Oh   no... Now you'll have to do it all over again!", 10,10,10, "- Press a key to exit -$"

win_melody dw 2711, 2415, 2031, 2711, 1612, 1,1, 1612, 1,1, 1809, 1,1,1,1, 2711, 2415, 2031, 2711, 1809, 1,1, 1809, 1,1, 2031, 1, 2152, 2415, 1,1, 2711, 2415, 2031, 2711, 2031, 1,1,1, 1809, 1, 2152, 1,1,1, 2711, 1,1, 2711, 1,1, 1809, 1,1, 2031, 0
lose_melody dw 9663, 9121, 8126, 1, 12175, 1, 10847, 1, 13666, 1, 14478, 0

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

    mov ax, offset win_melody
    call play_melody

    mov ah, 00h
    int 16h

    call wait_tenth

    ret
endp

proc lose_screen
    
    mov ah, 09h
    mov dx, offset lose_screen_text
    int 21h

    mov ax, offset lose_melody
    call play_melody

    mov ah, 00h
    int 16h

    call wait_tenth

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

proc dec_to_zero ; variable
    push bp
    mov bp, sp
    push si
    push dx

    mov si, [bp+4]
    mov dx, 0
    cmp [si], dx
    jle dec_to_zero_end
    mov dx, 4
    cmp [si], dx
    jge dec_to_zero_end
    mov dx, 1
    sub [si], dx

    dec_to_zero_end:
    pop dx
    pop si
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

proc draw_char ; column, row, char
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov ah, 02h
    mov bh, 0
    mov dh, [bp+4]
    mov dl, [bp+6]
    int 10h

    mov ah, 0Eh
    mov bh, 0
    mov al, [bp+8]
    mov bl, 0Fh
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6
endp

proc init_prg
    push ax

    mov al, [prev_time]
    mov [random_num], al

    pop ax
    ret
endp

proc generate_prg
    push ax
    push dx

    mov al, [random_num] ; (a*x + d) mod m
    mov dl, 3
    mul dl
    add al, 9
    mov ah, 0
    mov dl, 17
    div dl
    mov [random_num], ah

    pop dx
    pop ax
    ret
endp

proc boolean_prg ; returns al=0 or 1
    push ax

    call generate_prg
    mov al, [random_num]
    and al, 00000001b
    mov [random_boolean], al

    pop ax
    ret
endp

proc draw_random_rect ; x, y, width, height, color
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
    
    call init_prg
    xor cx, cx
    random_rect_row:
        mov ax, [bp+4]
        mov cl, 0
        random_rect_pixel:
            call boolean_prg
            cmp [random_boolean], 1
            jne random_rect_pixel_continue
            push [bp+12]
            push bx
            push ax
            call paint_pixel
            random_rect_pixel_continue:
            inc ax
            inc cl
            cmp cl, dl
            jle random_rect_pixel
        inc bx
        inc ch
        cmp ch, dh
        jle random_rect_row

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

proc play_beep ; divisor
    push bp
    mov bp, sp
    push ax

    in al, 61h ; Open speaker
    or al, 00000011b
    out 61h, al
    
    mov al, 0B6h ; Send control word to change frequency
    out 43h, al

    mov ax, [bp+4] ; Play divisor
    out 42h, al ; Sending lower byte
    mov al, ah
    out 42h, al ; Sending upper byte

    pop bp
    pop ax
    ret 2
endp

proc stop_beep
    push ax

    in al, 61h
    and al, 11111100b
    out 61h, al

    pop ax
    ret
endp

proc play_melody ; ax = notes array offset, divisor[2]
    push ax
    push si

    mov si, ax
    play_melody_loop:
        mov ax, [si]
        cmp ax, 0
        je play_melody_end

        cmp ax, 1
        je play_melody_continue

        push ax
        call play_beep

        play_melody_continue:
        call wait_tenth
        call stop_beep
        add si, 2
        jmp play_melody_loop
    
    play_melody_end:
    call stop_beep
    pop si
    pop ax
    ret
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
        cmp ax, 4
        jl draw_bricks_broken
        push [si+4]
        jmp draw_bricks_present

        draw_bricks_broken:
        push [BLACK]
        push [BRICK_HEIGHT]
        push [BRICK_WIDTH]
        push [si+2]
        push [si+0]
        call draw_random_rect
        jmp draw_bricks_continue

        draw_bricks_nonpresent:
        push [BLACK]
        
        draw_bricks_present:
        push [BRICK_HEIGHT]
        push [BRICK_WIDTH]
        push [si+2]
        push [si+0]
        call draw_rect
        
        draw_bricks_continue:
        add si, 8
        jmp draw_bricks_loop

    draw_bricks_end:
    pop si
    pop ax
    ret
endp

proc collision_field ; x, y
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
        jne bottom_collision
        sub cx, 2
        mov dx, [ballx]
        sub dx, cx
        cmp dx, [BRICK_WIDTH_PLUS]
        ja bottom_collision
        add al, 7
    bottom_collision:
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
        add al, 4
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
        add al, 5
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
        add al, 6

    collision_field_end:
    pop dx
    pop cx
    pop bx
    pop bp
    ret 4
endp

; order is fucked up because assembly is annoying with jumps
proc collide_bricks ; ax = bricks array offset
    push ax
    push si
    
    mov si, ax
    collide_bricks_loop:
        mov ax, [si]
        cmp ax, 0
        je collide_bricks_end

        mov ax, [si+6]
        cmp ax, 4
        jl collide_bricks_continue
        jmp collide_bricks_present

        collide_bricks_continue:
            mov ax, si
            add ax, 6
            push ax
            call dec_to_zero
            add si, 8
            jmp collide_bricks_loop

        collide_bricks_end:
            pop si
            pop ax
            ret

        collide_bricks_present:
        push [si+2]
        push [si+0]
        call collision_field
        cmp al, 4
        je collide_bricks_top_bottom
        cmp al, 7
        je collide_bricks_top_bottom
        cmp al, 5
        je collide_bricks_left_right
        cmp al, 6
        je collide_bricks_left_right
        cmp al, 9
        je collide_bricks_bottom_left
        cmp al, 10
        je collide_bricks_bottom_right
        cmp al, 12
        je collide_bricks_top_left
        cmp al, 13
        je collide_bricks_top_right
        cmp al, 0
        je collide_bricks_continue
        
        collide_bricks_top_bottom:
            neg [ballspeedy]
            jmp collide_bricks_destroy
        collide_bricks_left_right:
            neg [ballspeedx]
            jmp collide_bricks_destroy
        collide_bricks_bottom_left:
            mov [ballspeedx], -2
            mov [ballspeedy], 2
            jmp collide_bricks_destroy
        collide_bricks_bottom_right:
            mov [ballspeedx], 2
            mov [ballspeedy], 2
            jmp collide_bricks_destroy
        collide_bricks_top_left:
            mov [ballspeedx], -2
            mov [ballspeedy], -2
            jmp collide_bricks_destroy
        collide_bricks_top_right:
            mov [ballspeedx], 2
            mov [ballspeedy], -2
            jmp collide_bricks_destroy

        collide_bricks_destroy:
            mov ax, 3
            mov [si+6], ax
            call revert_ballspeedx
            push [NOTE_C4]
            call play_beep
            call spawn_pill1
            call spawn_pill2
            call spawn_pill3
            inc [total_bricks]
            jmp collide_bricks_continue
endp

; PILLS PROCEDURES START HERE

proc draw_pill1
    push ax
    
    mov ax, 0
    add ax, [pill1_x]
    add ax, [pill1_y]
    cmp ax, 0
    je draw_pill1_exit

    push [pill1_color]
    push 3
    push 3
    mov ax, [pill1_y]
    dec ax
    push ax
    mov ax, [pill1_x]
    dec ax
    push ax
    call draw_rect

    draw_pill1_exit:
    pop ax
    ret
endp

proc clear_pill1
    push ax

    push [BLACK]
    push 3
    push 3
    mov ax, [pill1_y]
    dec ax
    push ax
    mov ax, [pill1_x]
    dec ax
    push ax
    call draw_rect

    pop ax
    ret
endp

proc spawn_pill1 ; works exclusively in collide_bricks
    push ax
    
    mov ax, 0
    add ax, [pill1_x]
    add ax, [pill1_y]
    cmp ax, 0
    jne spawn_pill1_exit
    mov al, [prev_time]
    and al, 00001111b
    cmp al, [pill1_chance]
    jg spawn_pill1_exit
    mov ax, [si+0]
    add ax, 22
    mov [pill1_x], ax
    mov ax, [si+2]
    mov [pill1_y], ax

    spawn_pill1_exit:
    pop ax
    ret
endp

proc accelerate_pill1
    push ax

    mov al, 3

    cmp [pill1_counter], 5
    jbe accelerate_pill1_exit
    dec ax
    cmp [pill1_counter], 18
    jbe accelerate_pill1_exit
    dec ax
    cmp [pill1_counter], 40
    jbe accelerate_pill1_exit
    dec ax

    accelerate_pill1_exit:
    mov [pill1_velocity], al
    pop ax
    ret
endp

proc move_pill1
    push ax

    mov ax, 0
    add ax, [pill1_x]
    add ax, [pill1_y]
    cmp ax, 0
    je move_pill1_exit

    call accelerate_pill1
    mov al, [pill1_velocity]
    cmp [pill1_flag], al
    je move_pill1_full
    jmp move_pill1_less
    
    move_pill1_less:
        inc [pill1_flag]
        jmp move_pill1_exit
    move_pill1_full:
        mov [pill1_flag], 0
        inc [pill1_y]
        inc [pill1_counter]

    cmp [pill1_y], 189
    jl move_pill1_exit
    mov ax, [pill1_x]
    sub ax, [racketx]
    cmp ax, 50
    jbe move_pill1_within
    jmp move_pill1_through

    move_pill1_within:
        mov [pill1_x], 0
        mov [pill1_y], 0
        mov [pill1_counter], 0
        push [NOTE_A4]
        call play_beep
        jmp move_pill1_exit
    move_pill1_through:
        cmp [pill1_y], 197
        jl move_pill1_exit
        dec [racketspeed]
        mov [pill1_x], 0
        mov [pill1_y], 0
        mov [pill1_counter], 0
        push [NOTE_A2]
        call play_beep
        jmp move_pill1_exit

    move_pill1_exit:
    pop ax
    ret
endp



proc draw_pill2
    push ax
    
    mov ax, 0
    add ax, [pill2_x]
    add ax, [pill2_y]
    cmp ax, 0
    je draw_pill2_exit

    push [pill2_color]
    push 3
    push 3
    mov ax, [pill2_y]
    dec ax
    push ax
    mov ax, [pill2_x]
    dec ax
    push ax
    call draw_rect

    draw_pill2_exit:
    pop ax
    ret
endp

proc clear_pill2
    push ax

    push [BLACK]
    push 3
    push 3
    mov ax, [pill2_y]
    dec ax
    push ax
    mov ax, [pill2_x]
    dec ax
    push ax
    call draw_rect

    pop ax
    ret
endp

proc spawn_pill2 ; works exclusively in collide_bricks
    push ax
    
    mov ax, 0
    add ax, [pill2_x]
    add ax, [pill2_y]
    cmp ax, 0
    jne spawn_pill2_exit
    mov al, [prev_time]
    and al, 00001111b
    cmp al, 4
    jl spawn_pill2_exit
    cmp al, [pill2_chance]
    jg spawn_pill2_exit
    mov ax, [si+0]
    add ax, 22
    mov [pill2_x], ax
    mov ax, [si+2]
    mov [pill2_y], ax

    spawn_pill2_exit:
    pop ax
    ret
endp

proc accelerate_pill2
    push ax

    mov al, 3

    cmp [pill2_counter], 5
    jbe accelerate_pill2_exit
    dec ax
    cmp [pill2_counter], 18
    jbe accelerate_pill2_exit
    dec ax
    cmp [pill2_counter], 40
    jbe accelerate_pill2_exit
    dec ax

    accelerate_pill2_exit:
    mov [pill2_velocity], al
    pop ax
    ret
endp

proc move_pill2
    push ax

    mov ax, 0
    add ax, [pill2_x]
    add ax, [pill2_y]
    cmp ax, 0
    je move_pill2_exit

    call accelerate_pill2
    mov al, [pill2_velocity]
    cmp [pill2_flag], al
    je move_pill2_full
    jmp move_pill2_less
    
    move_pill2_less:
        inc [pill2_flag]
        jmp move_pill2_exit
    move_pill2_full:
        mov [pill2_flag], 0
        inc [pill2_y]
        inc [pill2_counter]

    cmp [pill2_y], 189
    jl move_pill2_exit
    mov ax, [pill2_x]
    sub ax, [racketx]
    cmp ax, 50
    jbe move_pill2_within
    jmp move_pill2_through

    move_pill2_within:
        inc [racketspeed]
        mov [pill2_x], 0
        mov [pill2_y], 0
        mov [pill2_counter], 0
        push [NOTE_A4]
        call play_beep
        jmp move_pill2_exit
    move_pill2_through:
        cmp [pill2_y], 197
        jl move_pill2_exit
        mov [pill2_x], 0
        mov [pill2_y], 0
        mov [pill2_counter], 0
        push [NOTE_A2]
        call play_beep
        jmp move_pill2_exit

    move_pill2_exit:
    pop ax
    ret
endp



proc draw_pill3
    push ax
    
    mov ax, 0
    add ax, [pill3_x]
    add ax, [pill3_y]
    cmp ax, 0
    je draw_pill3_exit

    push [pill3_color]
    push 3
    push 3
    mov ax, [pill3_y]
    dec ax
    push ax
    mov ax, [pill3_x]
    dec ax
    push ax
    call draw_rect

    draw_pill3_exit:
    pop ax
    ret
endp

proc clear_pill3
    push ax

    push [BLACK]
    push 3
    push 3
    mov ax, [pill3_y]
    dec ax
    push ax
    mov ax, [pill3_x]
    dec ax
    push ax
    call draw_rect

    pop ax
    ret
endp

proc spawn_pill3 ; works exclusively in collide_bricks
    push ax
    
    mov ax, 0
    add ax, [pill3_x]
    add ax, [pill3_y]
    cmp ax, 0
    jne spawn_pill3_exit
    mov al, [prev_time]
    and al, 00001111b
    cmp al, 8
    jl spawn_pill3_exit
    cmp al, [pill3_chance]
    jg spawn_pill3_exit
    mov ax, [si+0]
    add ax, 22
    mov [pill3_x], ax
    mov ax, [si+2]
    mov [pill3_y], ax

    spawn_pill3_exit:
    pop ax
    ret
endp

proc accelerate_pill3
    push ax

    mov al, 3

    cmp [pill3_counter], 5
    jbe accelerate_pill3_exit
    dec ax
    cmp [pill3_counter], 18
    jbe accelerate_pill3_exit
    dec ax
    cmp [pill3_counter], 40
    jbe accelerate_pill3_exit
    dec ax

    accelerate_pill3_exit:
    mov [pill3_velocity], al
    pop ax
    ret
endp

proc pill3_effect
    push ax
    push bx

    call clear_racket
    mov ax, [pill3_x]
    sub ax, 25
    mov [racketx], ax

    pop bx
    pop ax
    ret
endp

proc move_pill3
    push ax

    mov ax, 0
    add ax, [pill3_x]
    add ax, [pill3_y]
    cmp ax, 0
    je move_pill3_exit

    call accelerate_pill3
    mov al, [pill3_velocity]
    cmp [pill3_flag], al
    je move_pill3_full
    jmp move_pill3_less
    
    move_pill3_less:
        inc [pill3_flag]
        jmp move_pill3_exit
    move_pill3_full:
        mov [pill3_flag], 0
        inc [pill3_y]
        inc [pill3_counter]

    cmp [pill3_y], 189
    jl move_pill3_exit
    mov ax, [pill3_x]
    sub ax, [racketx]
    cmp ax, 50
    jbe move_pill3_within
    jmp move_pill3_through

    move_pill3_within:
        mov [pill3_x], 0
        mov [pill3_y], 0
        mov [pill3_counter], 0
        push [NOTE_A4]
        call play_beep
        jmp move_pill3_exit
    move_pill3_through:
        cmp [pill3_y], 197
        jl move_pill3_exit
        call pill3_effect
        mov [pill3_x], 0
        mov [pill3_y], 0
        mov [pill3_counter], 0
        push [NOTE_A2]
        call play_beep
        jmp move_pill3_exit

    move_pill3_exit:
    pop ax
    ret
endp


proc clear_ball
    push ax

    push [BLACK]
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

proc draw_ball
    push ax

    push [GREEN] ; Draw a new ball
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

proc clear_racket
    push [BLACK]
    push 10
    push 52
    push [rackety]
    push [racketx]
    call draw_rect

    ret
endp

proc draw_racket

    cmp [rackethit], 1
    jge draw_racket_hit
    push [WHITE]
    jmp draw_racket_continue

    draw_racket_hit:
    push [BRIGHT_GREEN]

    draw_racket_continue:
    push 4
    push 50
    push [rackety]
    push [racketx]
    call draw_rect

    ret
endp

proc update_chances
    cmp [total_bricks], 6
    jl update_chances_exit
    mov [pill1_chance], 2
    mov [pill2_chance], 5
    mov [pill3_chance], 10
    cmp [total_bricks], 18
    jl update_chances_exit
    mov [pill1_chance], 3
    mov [pill2_chance], 4
    mov [pill3_chance], 11
    cmp [total_bricks], 24
    jl update_chances_exit
    mov [pill2_chance], 3

    update_chances_exit:
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
        mov ah, 2Ch ; Loop system: checks every iteration if time has passed
        int 21h ; ch=hour cl=minute dh=second dl=1/100 second
        cmp dl, [prev_time]
        je gameloop
        mov [prev_time], dl
        call stop_beep
        
        call clear_ball

        call clear_pill1
        call clear_pill2
        call clear_pill3

        call key_pressed ; If no key was pressed, skip input stage
        jz gameloop_calc

        call clear_racket

        call get_key ; Input: jump to the label of the key pressed
        cmp al, "d"
        je key_d
        cmp al, "a"
        je key_a
        cmp al, "Q"
        je key_Q
        cmp al, "P"
        je key_P
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
        key_Q:
            jmp exit
        key_P:
            mov [total_bricks], 29
        
    gameloop_calc:
        mov ax, [ballspeedx]
        add [ballx], ax
        mov ax, [ballspeedy]
        add [bally], ax
        
        push offset rackethit
        call dec_to_zero

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
            call play_beep
            mov [rackethit], 3
            jmp gameloop_draw
        racket_boundry_center:
            neg [ballspeedy]
            call revert_ballspeedx
            push [NOTE_F3]
            call play_beep
            mov [rackethit], 3
            jmp gameloop_draw
        racket_boundry_through:
            cmp [bally], 197
            jge lose_exit
            jmp gameloop_draw

    gameloop_draw:
        call update_chances
        mov ax, offset bricks_array
        call collide_bricks
        call draw_bricks
        
        cmp [total_bricks], 30
        jge win_exit

        call move_pill1
        call move_pill2
        call move_pill3

        call draw_ball
        call draw_racket

        call draw_pill1
        call draw_pill2
        call draw_pill3

        mov ax, [racketspeed]
        add ax, 48
        push ax
        push 39
        push 0
        call draw_char
        
        jmp gameloop

win_exit:
    call stop_beep
    call graphic_mode
    call win_screen
    jmp exit

lose_exit:
    call stop_beep
    call graphic_mode
    call lose_screen
    jmp exit

exit:
    call stop_beep
    mov ah, 4Ch
    int 21h
END start
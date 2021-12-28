IDEAL
MODEL small
STACK 256

DATASEG
WHITE dw 0Fh
BLACK dw 00h
GREEN dw 30h
BRICK_WIDTH dw 30
BRICK_HEIGHT dw 20

prev_time db 0
racketx dw 40
rackety dw 191
ballx dw 101
bally dw 101
ballspeedx dw 2
ballspeedy dw 2

bricks_array dw 10,10,0Eh,1, 80,50,22h,1, 100,100,0Fh,0, 0

CODESEG

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
    row:
        mov ax, [bp+4]
        mov cl, 0
        pixel:
            push [bp+12]
            push bx
            push ax
            call paint_pixel
            inc ax
            inc cl
            cmp cl, dl
            jle pixel
        inc bx
        inc ch
        cmp ch, dh
        jle row

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
    mov dl, 101
    int 21h

    pop dx
    pop ax
    ret
endp

proc draw_bricks ; ax = bricks array offset, brick[8]=x[2]y[2]color[2]present[2]
    push ax
    push di

    mov di, ax
    draw_bricks_loop:
        mov ax, [di]
        cmp ax, 00h
        je draw_bricks_end

        mov ax, [di+6]
        cmp ax, 0
        je draw_bricks_continue

        push [di+4]
        push [BRICK_HEIGHT]
        push [BRICK_WIDTH]
        push [di+2]
        push [di+0]
        call draw_rect
        
        draw_bricks_continue:
        add di, 8
        jmp draw_bricks_loop

    draw_bricks_end:
    pop di
    pop ax
    ret
endp

start:
    mov ax, @data
    mov ds, ax

    call graphic_mode
    call set_background
    
    gameloop:
        mov ah, 2Ch ;; Loop system: checks every iteration if time has passed
        int 21h ; ch=hour cl=minute dh=second dl=1/100 second
        cmp dl, [prev_time]
        je gameloop
        mov [prev_time], dl
        
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
            add [racketx], 4
            jmp gameloop_calc
        key_a:
            sub [racketx], 4
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
            cmp ax, 50
            ja racket_boundry_through
            neg [ballspeedy]
            jmp gameloop_draw
        racket_boundry_through:
            cmp [bally], 197
            jge exit


    gameloop_draw:
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
        
        mov ax, offset bricks_array
        call draw_bricks

        jmp gameloop

exit:
    mov ah, 4Ch
    int 21h
END start
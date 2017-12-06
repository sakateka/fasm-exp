format elf64 executable 3

segment readable executable
entry main

main: ; lab4
        mov  rsi, kr_msg
        mov  rdx, kr_msg_size
        call print_msg

        mov rcx, elements_in_array
    next_x:
        mov rsi, elements_in_array
        sub si, cx
        mov rax, rsi
        call calc_y
        imul rsi,8
        mov [result_array+rsi], rax
        loop next_x

        mov  rsi, print_arr_msg
        mov  rdx, print_arr_msg_size
        call print_msg

        call print_arr

        mov  rsi, count_gt_1_msg
        mov  rdx, count_gt_1_msg_size
        call print_msg
        call count_gt_1 ; rax contains count
        mov rsi, 1      ; just print number without padding
        call print_num
        call print_nl
        call print_nl
        mov  rsi, kr_info_msg
        mov  rdx, kr_info_msg_size
        call print_msg
    ; exit
        xor rdi, 0   ; exit status == 0
        mov rax, 60  ; sys_exit
        syscall

print_msg:
        ; rsi message address
        ; rdx message size
        push rdi
        push rax
        push rcx   ; syscall modify rcx
        mov rdi, 1 ; write to stdout
        mov rax, 1 ; sys_write
        syscall
        pop rcx
        pop rax
        pop rdi

        ret

calc_y:
        ; argument 'x' in rax
        push rbx
        push rdx
        push rcx

        mov rcx, rax
        mul rcx                  ; возводим x в квадрат
        mul rcx                  ; возводим x в куб
        mov rdx, const_a
        mul rdx
        mov rbx, rax             ; сохраняем результат умножения
        mov rax, rcx             ; первый множитель (x)
        mov rdx, const_b         ; второй множитель (b)
        mul rdx                  ; умножаем b на х
        add rbx, rax             ; сумма a*x^3 + b*x
        mov rax, const_c
        sub rax, rcx             ; находим аргумент для функции exc()
        push rax

    ;exp: ; ported from glibc/sysdeps/i386/fpu/e_exp.S
        fild    qword [rsp]   ; x * log2(e)
        fldl2e
        fmul    st,st1        ; x * log2(e)
        fld     st
        frndint               ; int(x * log2(e))
        fsubr   st,st1        ; fract(x * log2(e))
        fxch
        f2xm1                 ; 2^(fract(x * log2(e))) - 1
        fld1
        faddp                 ; 2^(fract(x * log2(e)))
        fscale                ; e^x */
        fstp   st1
        fistp   qword [rsp]
        pop rax
        test rax,rax
        jns not_set_0
        mov rax, 0
    not_set_0:
        sub rbx, rax
        mov rax, rbx

        pop rcx
        pop rdx
        pop rbx
        ; return result in rax
        ret

; Считаем кол-во элементов массива, больших 1
count_gt_1:
        push rsi
        push rcx

        mov cx, elements_in_array
        xor rsi, rsi
        xor rax, rax       ; количество элементов массива > 1
    next:
        cmp [result_array+rsi], 1
        jle lessOrEqual
        inc rax
    lessOrEqual:
        add rsi, 8
        loop next      ; цикл по всем элементам массива

        pop rcx
        pop rsi
        ret

print_num:
        ; rax - число
        ; rsi - ширина поля вывода
        push rbx
        push rdx
        push rcx
        push rbp

        xor rcx,rcx
        mov rbp,rsp
        cmp rax,0
        jge @0
        neg rax                  ; rax:= | rax |
        mov rcx,'-'              ; запоминаем минус
    @0:
        mov dx, 0
        mov bx,10
        div bx        ; ax:= ax div 10 ; dx:= ax mod 10
        add dl,'0'    ; получение цифры числа
        mov [rsp],dl   ;  запись в стек цифры
        or ax,ax
        jz @1
        dec rsp
        jmp @0
    @1:
        cmp rcx,'-'
        jne @2
        dec rsp
        mov byte ptr rsp,cl   ; запись в стек пробела (или '-')
    @2:
        mov rax,rbp
        sub rax,rsp
        inc rax
        cmp rax,rsi
        jge @3          ; ширина >= длине числа
        dec rsp
        mov byte ptr rsp,' '   ; запись в стек пробела
        jmp @2
    @3:
        ; rsi - message address for print_msg
        ; rdx - message size for print_msg
        mov  rsi, rsp
        mov  rdx,rbp
        sub  rdx,rsp
        inc  rdx
        call print_msg
        mov  rsp,rbp        ; очистка стека
        pop  rbp
        pop  rcx
        pop  rdx
        pop  rbx
        ret

; Выводит массив на экран
print_arr:
        push rcx
        push rdi
        push rsi
        push rbx

        mov rbx, base_output_size
        mov cx, elements_in_array
        mov rdi, 0
    next_elem:
        mov rax, [result_array+rdi]
        mov rsi, number_size
        call print_num  ; выводим элемент массива
        add rdi, 8
        dec rbx
        jnz skip_spaces
        call print_nl
        mov ax, cx
        mov rbx,2
        div bl
        mov bl, al
        cmp al, 0
        jz skip_spaces
        call print_spaces
    skip_spaces:
        loop next_elem

        call print_nl

        pop rbx
        pop rsi
        pop rdi
        pop rcx
        ret

print_spaces:
        ; rcx - текущий элемент в массиве
        push rcx

        mov rcx, base_output_size
        sub cx, ax
        mov ax, cx
        mov rcx, number_size
        mul cl
        mov rcx,2
        div cl
        mov cx, ax
    next_space:
        mov  rsi, space_msg
        mov  rdx, space_msg_size
        call print_msg
    loop next_space

        pop rcx
        ret


print_nl: ; print new line
    push rsi
    push rdx
    mov  rsi, new_line_msg
    mov  rdx, new_line_msg_size
    call print_msg
    pop rdx
    pop rsi
    ret

segment readable writeable

space_msg db ' '
space_msg_size = $-space_msg
new_line_msg db 0xa
new_line_msg_size = $-new_line_msg

kr_msg db 'Курсовая работа: ЭВМ и периферийные устройства',0xa,0xa,\
          'Задание: рассчитать значение y при x от 0 до 10',0xa,\
          'Уравнение: y = 3x^3 - 2x - exp(1 - x)',0xa
kr_msg_size = $-kr_msg
print_arr_msg db 'Вывод массива с результатами вычислений:',0xa,0xa
print_arr_msg_size = $-print_arr_msg
count_gt_1_msg db 'Кол-во элементов массива, значение которых больше единицы: '
count_gt_1_msg_size = $-count_gt_1_msg
kr_info_msg db 'ФИО:     __AUTHOR__',0xa,\
               'Группа:  __GROUP__',0xa,\
               'Вариант: __TASK__',0xa
kr_info_msg_size = $-kr_info_msg

const_a = 3
const_b = -2
const_c = 1
number_size = 6
elements_in_array = 11
result_array rq elements_in_array
base_output_size = 5


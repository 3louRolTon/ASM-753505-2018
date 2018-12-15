CSEG segment
assume cs:CSEG, ds:CSEG, es:CSEG, ss:CSEG
org 100h 
Start:
;Переходим на метку инициализации. Нам нужно будет перехватить прерывание 21h,
;а также оставить программу резидентной в памяти
jmp Init 
 
;Ниже идет, собственно, код обработчика прерывания 21h (он будет резидентным). 
;После того как программа выйдет, процедура Int_21h_proc останется в памяти
;и будет контролировать функцию 09h прерывания 21h. 
;Мы выделим код обработчика полужирным шрифтом. 
 
Int_21h_proc proc 
cmp ah,9              ;Проверим: это функция 09h?
je Ok_09 
 
;Если нет, перейдем на оригинальный обработчик прерывания 21h.
;Все. На метку Ok_09 программа уже не вернется 
jmp dword ptr cs:[Int_21h_vect] 
 
Ok_09:
push ds               ;Сохраним регистры
push dx
push cs               ;Адрес строки должен быть в ds:dx 
pop ds 
 
;Выводим нашу строку (My_string) вместо той, которую должна была вывести 
;программа, вызывающая прерывание 21h 
mov dx,offset My_string 
pushf                 ;Эта инструкция здесь необходима... 
call dword ptr cs:[Int_21h_vect] 
 
pop dx                ;Восстановим использованные регистры
pop ds
iret                  ;Продолжим работу (выйдем из прерывания) 
;Программа, выводящая строку, считает, что на экран было выведено
;ее сообщение. Но на самом деле это не так! 
 
;Переменная для хранения оригинального адреса обработчика 21h 
Int_21h_vect dd ? 
 
My_string db 'Моя строка!$'
int_21h_proc endp 
;Со следующей метки нашей программы уже не будет в памяти (это нерезидентная 
;часть). Она затрется сразу после выхода (после вызова прерывания 27h) 
 
Init:
;Установим наш обработчик (Int_21h_proc) (адрес нашего обработчика)
;на  прерывание 21h. Это позволяет сделать функция 25h прерывания 21h. 
;Но прежде нам нужно запомнить оригинальный адрес этого прерывания.
;Для этого используется функция 35h прерывания 21h:  
 
;ah содержит номер функции
mov ah,35h
;al указывает номер прерывания, адрес (или вектор) которого нужно получить 
mov al,21h
int 21h 
;Теперь в es:bx адрес (вектор) прерывания 21h (es — сегмент, bx — смещение) 
 
;Обратите внимание на форму записи 
mov word ptr Int_21h_vect,bx
mov word ptr Int_21h_vect+2,es 
 
;Итак, адрес сохранили. Теперь перехватываем прерывание: 
mov ax,2521h
mov dx,offset Int_21h_proc    ;ds:dx должны указывать на наш обработчик                              
							  ;(т. е. Int_21h_proc)
int 21h 
 
;Все! Теперь, если какая-либо программа вызовет 21h, то вначале компьютер 
;попадет на наш обработчик (Int_21h_proc). Что осталось? Завершить программу, 
;оставив ее резидентной в памяти (чтобы никто не затер наш обработчик.
;Иначе компьютер просто зависнет.). 
 
mov dx,offset Init
int 27h 
;Прерывание 27h выходит в DOS (как 20h), при этом оставив нашу программу
;резидентной. dx должен указывать на последний байт, оставшийся в памяти
;(это как раз метка Init). То есть в памяти остается от 0000h до адреса,
;по которому находится метка Init.  
 
CSEG ends
end Start 

# Użyteczne bloki instrukcji

### Ustawienie wskaźnika pliku
- AL: 0 - od początku,  
&nbsp; &nbsp; 1 - od aktualnej pozycji,  
&nbsp; &nbsp; 2 - od końca  
- DX: ilość bajtów do pominięcia  
                
```
mov     ah,42h
mov     al,0
mov     cx, 0
mov     dx, 10050
int     21h
```

### Odczyt kolejnych wartości z pliku
- CX: Ilość bajtów do odczytania
- DX: Adres *buforu*, do którego będą zapisane dane

```
mov     ah,3Fh
mov     cx,4
lea     dx, buffer
int     21h
```

### [TODO] Odtworzenie dźwięku

```
push   ax
mov dx,42h
out dx,al
mov al,ah
out dx,al
```

### [TODO] Opóźnienie działania programu
Wstrzymuje działanie programu.
- CX: Czas wstrzymania [TODO]: jaka jednostka czasu?

```
mov     ah, 86h
xor     bx,bx 
xor     dx,dx  
mov     cx, 6
int     15h
```

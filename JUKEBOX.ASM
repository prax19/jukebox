    ;|=================================================|;
    ;|................Project..Jukebox.................|;
    ;|.......................by........................|;
    ;|..........Patryk.Piróg.&.Jakub.Dąbrowski.........|;
    ;|.................Styczeń.2022....................|;
    ;|.........Uniwersytet.Śląski.w.Katowicach.........|;
    ;|=================================================|;

            ;https://github.com/prax19/jukebox

Progr           segment

                assume  cs:Progr, ds:dane, ss:stosik

start:          mov     ax,dane
                mov     ds,ax
                mov     ax,stosik
                mov     ss,ax
                mov     ax,offset szczyt
                mov     sp,ax

                ;setup pliku
                call    setup_file

                xor     cx, cx
                mov     dx, 0
                mov     ah, 42h
                mov     al, 0
                mov     bx, file_access
                int     21h

                ;odczyt ilości tracków
                xor     cx, cx
                mov     dx, 10
                call skip_bytes

                call read_byte
                mov     ah, bl
                call read_byte
                mov     al, bl

                mov     track_num, ax
                call read_byte
                mov     ah, bl
                call read_byte
                mov     al, bl

                mov     time_division, ax

                mov     cx, track_num
                mov     ax, 14
                mov     di, 2

            srch:

                push    cx

                xor     cx, cx
                mov     dx, 6
                call skip_bytes
                add     ax, 6

                call read_byte
                mov     dh, bl
                call read_byte
                mov     dl, bl

                add     ax, 2
                add     ax, dx
                mov     track_pos + di, ax
                mov     pointer_pos + di, ax
                mov     track_active + di, 1
                inc     active_tracks

                xor     cx, cx
                call skip_bytes

                add     di, 2

                pop     cx

                dec     cx
                jnz     srch

                mov     cx, 0
                call    setup

                mov     cx, 1
                call    setup

                mov     cx, 2
                call    setup

                mov     ah, 02h
                mov     dl, 10
                int     21h

                ;mov     channel_key, 0

                mov     mode, 1
                dec     active_tracks

                pop     ax

                mov     ax, 0
            test10:
                push    ax
                call point_track 
                mov     di, ax
                add     di, ax
                call read_delta_time
                call save_pointer_pos
                pop     ax
                inc     ax
                cmp     ax, track_num
                jle     test10
                
                mov     di, 0
            test5:          
                mov     ax, time
                cmp     ax, next_event_time + di
                jb      test6
                call load_pointer_pos
                mov     mode, 1
                call next_event
                cmp     mode, 1
                je      test9
                mov     track_active + di, 0
                dec     active_tracks
                jmp     test6
            test9:
                call read_delta_time
                call save_pointer_pos
            test6:

                mov     ax, track_num
                add     ax, track_num

                cmp     di, ax
                jbe     test7
                mov     di, 0
                inc     time
                call delta_time
                jmp     test8
            test7:
                add     di, 2
            test8:
                cmp     track_active + di, 0
                je      test6

                ;jmp     test5

                ;wciskanie escape by wyjść
                mov     ah, 01h
                int     16h
                cmp     al, 27
                je      exit

                cmp     active_tracks, 0
                jg     test5
                ;;;;
exit:
                mov     ah,4ch
                mov     al,0
                int     21h
          ;========FINIFH========;

                ;Konfiguracja instrumentu
                setup proc
                push    ax bx cx dx
                mov     bl, 20h
                add     bl, cl
                mov     bh, 33h
                call    write_adlib
                mov     bl, 40h
                add     bl, cl
                mov     bh, 5ah
                call    write_adlib
                mov     bl, 60h
                add     bl, cl
                mov     bh, 0b2h
                call    write_adlib
                mov     bl, 80h
                add     bl, cl
                mov     bh, 050h
                call    write_adlib
                mov     bl, 0e0h
                add     bl, cl
                mov     bh, 000h
                call    write_adlib
                mov     bl, 0c0h
                add     bl, cl
                mov     bh, 000h
                call    write_adlib
                mov     bl, 23h
                add     bl, cl
                mov     bh, 31h
                call    write_adlib
                mov     bl, 43h
                add     bl, cl
                mov     bh, 000h
                call    write_adlib
                mov     bl, 63h
                add     bl, cl
                mov     bh, 0b1h
                call    write_adlib
                mov     bl, 83h
                add     bl, cl
                mov     bh, 0f5h
                call    write_adlib
                mov     bl, 0e3h
                add     bl, cl
                mov     bh, 000h
                call    write_adlib
                pop     dx cx bx ax
                ret
                setup endp

                ;Setup otwierania pliku
                setup_file proc
                mov     cl,es:[80h]
                dec     cl
                mov     si, offset file
                mov     di, 82h
            setupfile:       
                mov     al,es:[di]
                mov     ds:[si], al
				inc     di
                inc     si
				dec     cl
                jnz     setupfile

                mov     ax, 3D00h
                mov     dx, offset file
                int     21h
                jnc     fix1
                jmp     file_err
            fix1:
                mov     di, 0
                mov     file_access, ax
                ret
                setup_file endp

                ;błąd odczytu pliku
                file_err proc     
                mov     ah, 9
                mov     dx, offset strg_file_err
                int     21h
                mov     ah,4ch
                mov     al,0
                int     21h
                file_err endp

                ;Odczyt kolejnego bajtu z pliku
                ;Out | bl : odczytany bajt
                read_byte proc
                push    ax cx dx
                mov     ah, 3Fh
                mov     al, 0
                mov     bx, file_access
                mov     cx, 1
                lea     dx, buffer
                int     21h

                xor     bx, bx
                mov     bl, buffer

                pop     dx cx ax

                ret
                read_byte endp

                ;Ustaw wskaźnik pliku nad trackiem
                ;IN  | AX: numer ścieżki
                point_track proc
                push    ax bx cx dx

                mov     bx, 2
                mul     bx

                mov     di, ax

                xor     cx, cx
                mov     ah, 42h
                mov     al, 0
                mov     dx, track_pos + di
                mov     bx, file_access
                int     21h 

                xor     cx, cx
                mov     dx, 8
                call skip_bytes

                pop     dx cx bx ax

                ret
                point_track endp

                save_pointer_pos proc
                push ax bx cx
                mov     ah, 42h
                mov     al, 1h
                mov     bx, file_access
                mov     cx, 0
                mov     dx, 0
                int     21h
                mov     pointer_pos + di, ax
                pop cx bx ax
                ret
                save_pointer_pos endp

                load_pointer_pos proc
                push ax bx cx dx
                mov     ah, 42h
                mov     al, 0h
                mov     bx, file_access
                mov     cx, 0
                mov     dx, pointer_pos + di
                ;mov     pointer_pos + di, ax
                int     21h
                ;mov     
                pop dx cx bx ax
                ret
                load_pointer_pos endp
                
                ;Pomijanie bajtów w pliku
                ;In  | cx:dx : ilość bajtów do pominięcia
                skip_bytes proc
                push    ax bx
                mov     ah, 42h
                mov     al, 1
                mov     bx, file_access
                int     21h
                pop     bx ax
                ret
                skip_bytes endp

                ;Odczytaj kolejne wydarzenie pliku midi
                next_event proc
                push    ax bx cx dx

                call read_byte

                mov     al, bl
                mov     ah, bl
                and     ah, 11110000b 
                shr     ah, 4
                and     al, 00001111b 

                cmp     ah, 8h ;note off
                jz      event8

                cmp     ah, 9h ;note on
                jz      event9

                cmp     ah, 0Ah ;note aftertouch
                jz      event_4bit
                
                cmp     ah, 0Bh ;controller
                jz      event_4bit

                cmp     ah, 0Ch ;program change
                jz      event_3bit

                cmp     ah, 0Dh ;channel aftertouch
                jz      event_3bit

                cmp     ah, 0Eh ;pitch
                jz      event_4bit

                cmp     ah, 0Fh ;meta eventy
                jz      event_meta

                jmp     event_err

            event8: ;note off
                call read_byte
                mov     cl, al
                ;mov     cl, 0
                ;dec     channel_key
                ;add     cl, channel_key
                cmp     mode, 2
                je      event8_1
                call note_off
                event8_1:
                xor     cx, cx
                mov     dx, 1
                call skip_bytes
                jmp     event_r

            event9: ;note on
                call read_byte
                mov     cl, al
                ;mov     cl, 0
                ;add     cl, channel_key
                ;inc     channel_key
                sub     bx, 12
                mov     si, bx
                cmp     mode, 2
                je      event9_1
                call note_on
                event9_1:
                xor     cx, cx
                mov     dx, 1
                call skip_bytes
                jmp     event_r

            event_3bit: ;brak obsługi dla 3-bitowego eventu
                xor     cx, cx
                mov     dx, 1
                call skip_bytes
            jmp     event_r

            event_4bit: ;brak obsługi dla 4-bitowego eventu
                xor     cx, cx
                mov     dx, 2
                call skip_bytes
            jmp     event_r

            event_meta: ;meta eventy
                cmp     bl, 0FFh
                jnz     event_r
                call meta_event
                jmp     event_r

            event_err:
            jmp     event_r

            event_r:
                pop     dx cx bx ax

                ret
                next_event endp

                ;obsługa meta eventów
                ;IN  |
                meta_event proc

                xor     bx, bx
                call read_byte ;odczyt typu metaeventu

                xor     cx, cx
                mov     cl, bl  

                call read_byte ;odczyt długości me

                cmp     cl, 2
                jz      me_text

                cmp     cl, 3
                jz      me_text

                cmp     cl, 4
                jz      me_text

                cmp     cl, 5
                jz      me_text

                cmp     cl, 6
                jz      me_text

                cmp     cl, 7
                jz      me_text

                cmp     cl, 32
                jz      me_empty

                cmp     cl, 81
                jz      me_set_tempo

                cmp     cl, 84
                jz      me_empty

                cmp     cl, 88
                jz      me_empty
                
                cmp     cl, 89
                jz      me_empty

                cmp     cl, 127
                jz      me_empty

                cmp     cl, 2Fh ; koniec tracku
                jz      me_end_of_track

                jmp     me_err

            me_text:
                xor     cx, cx
                mov     cl, bl

                me_text_1: ;obsługa odczytu tekstu

                xor     bx, bx
                call read_byte

                mov     ah, 2h
                mov     dx, bx
                int     21h

                loop    me_text_1

                mov     ah, 02h
                mov     dl, 32
                int     21h

                jmp     me_r

            me_empty: ;pusty meta event
                xor     cx, cx
                xor     dx, dx
                mov     dl, bl
                
                call skip_bytes

                jmp     me_r

            me_set_tempo:
                call read_byte
                mov     tempo, bx
                call read_byte
                mov     ah, bl
                call read_byte
                mov     bh, ah
                mov     tempo + 2, bx
                
                jmp     me_r

            me_end_of_track:
                xor     cx, cx
                mov     cl, bl

                mov     mode, 0
                
                jmp     me_r
        
            me_text2:
                xor     cx, cx
                mov     cl, bl
                
                jmp     me_r

            me_err:
                jmp     me_r

            me_r:
                ret
                meta_event endp

                ;Odczytanie czasu delta
                ;In  | di : numer tracku * 2
                ;Out | dx : czas w tickach
                read_delta_time proc
                push    ax bx
                xor     ax, ax
                xor     dx, dx
                mov     si, 0
            ety1:
                call read_byte
                mov     bh, bl
                and     bh, 10000000b
                shr     bh, 7
                and     bl, 01111111b

                mov     dh, dl
                shr     dx, 1
                add     dl, bl

                cmp     bh, 1
                jz      ety1

                ;mov     track_delta + di, dx
                add     next_event_time + di, dx

                pop     bx ax

                ret
                read_delta_time endp

                ;Wstrzymanie odtwarzania
                ;In  | di numer tracku
                delta_time proc
                push    ax bx cx dx

                ;mov     cx ,track_delta + di
                mov     cx, 1

                mov     dx, tempo
                mov     ax, tempo + 2
                mov     bx, time_division

                div     bx
                mul     cx

                mov     cx, dx
                mov     dx, ax

                cmp     dx, 0
                jnz     dt_skip2
                cmp     cx, 0
                jz      dt_skip
            dt_skip2:
                mov     ah, 86h
                int     15h
            dt_skip:
                mov     ah, 2h
                mov     dl, 20h
                int     21h
                pop     dx cx bx ax
                ret
                delta_time endp

                ;Wyświetlanie nut
                disp_note proc
                push    ax bx cx dx si

                ;xor     bx, bx
                ;mov     ax, dx
                ;mov     bl, 12
                ;div     bl
                ;mov     al, 0
                ;mov     di, ax

                mov     ah, 2h
                ;mov     dl, dx
                int     21h

                pop     si dx cx bx ax
                ret
                disp_note endp

                ;Wyświetlenie tekstu z informacją
                start_msg proc
                push    bx cx dx

                mov     ah, 09h
                lea     dx, strg_start_msg1
                int     21h    

                mov     ax, track_num
                add     ax, 47
                mov     dx, ax

                mov     ah, 2h
                int     21h

                mov     ah, 09h
                lea     dx, strg_start_msg2
                int     21h    

            input:
                mov     ah, 08h
                int     21h
                cmp     al, 48
                jb      input
                xor     bx, bx
                mov     bx, track_num
                add     bx, 47
                cmp     al, bl
                ja      input

                mov     ah, 02h
                mov     dl, al
                int     21h

                push    ax

                mov     ah, 2h
                mov     dl, 10
                int     21h

                pop     ax

                pop dx cx bx
                ret
                start_msg endp

                ;Zwolnienie klawisza instrumentu
                ;In  | cx: kanał midi
                note_off proc
                push    bx
                mov     bl, 0b0h
                add     bl, cl
                mov     bh, 0h
                call    write_adlib
                pop     bx
                ret
                note_off endp

                ;Naciśnięcie klawisza instrumentu
                ;In  | si: id nuty midi, cx: kanał midi
                note_on proc
                push    ax bx cx dx

                mov     dx, si
                call disp_note

                shl     si, 1
                mov     ax, [note + si]

                mov     bl, 0a0h
                add     bl, cl
                mov     bh, al
                call    write_adlib

                mov     bl, 0b0h
                add     bl, cl
                mov     bh, 34h
                or      bh, ah
                call    write_adlib
                pop     dx cx bx ax
                ret
                note_on endp

                ;Modyfikacja rejestu urządzenie wyjściowego
                write_adlib proc
                push ax bx cx dx
			
                mov dx, 388h
                mov al, bl
                out dx, al

                mov dx, 389h

                mov cx, 6
            delay_1:
                in al, dx
                loop delay_1

                mov al, bh
                out dx, al

                mov cx, 35
            delay_2:
                in al, dx
                loop delay_2
                
                pop dx cx bx ax
                ret
                write_adlib endp

Progr           ends

dane            segment

;note_sign       db 67,67,68,68,69,70,70,71,71,65,65,72

                ;  C        C#      D       D#      E       F       F#      G       G#      A       A#      H
note            dw 8,       8,      9,      9,      10,     11,     11,     12,     13,     14,     15,     16
                dw 16,      17,     18,     19,     21,     22,     23,     25,     26,     28,     29,     31
                dw 33,      35,     37,     39,     41,     44,     46,     49,     52,     55,     58,     62
                dw 65,      69,     73,     78,     82,     87,     93,     98,     104,    110,    117,    123
                dw 131,     139,    146,    156,    165,    175,    185,    196,    208,    220,    233,    247
                dw 262,     277,    294,    311,    330,    349,    367,    392,    415,    440,    466,    494
                dw 523,     554,    587,    622,    659,    688,    740,    784,    831,    880,    932,    988
                dw 1047,    1109,   1175,   1245,   1319,   1397,   1480,   1568,   1661,   1760,   1865,   1976
                dw 2093,    2217,   2349,   2489,   2637,   2794,   2960,   3136,   3322,   3520,   3729,   3951
                dw 4186,    4435,   4699,   4978,   5274,   5588,   5920,   6272,   6645,   7040,   7459,   7902
                dw 8372,    8870,   9398,   9956,   10548,  11176,  11840,  12544

strg_file_err   db      'Podano zly plik$'

strg_start_msg1 db      'Podaj numer sciezki MIDI (0 - $'
strg_start_msg2 db      '): $'

file            db      80h dup(0)

file_access     dw      0h

tempo           dw      0000h, 0000h;3h, 0FB06h

time_division   dw      0

mode            db      2

;channel_key     db      0

track_num       dw      0 ;ilość tracków
active_tracks   dw      0 ;ilość aktywnych tracków

track_active    dw      0, 0, 0, 0, 0, 0, 0, 0

time            dw      0

next_event_time dw      0, 0, 0, 0, 0, 0, 0, 0

track_pos       dw      14, 0, 0, 0, 0, 0, 0, 0

pointer_pos     dw      14, 0, 0, 0, 0, 0, 0, 0

;track_delta     dw      0, 0, 0, 0, 0, 0, 0, 0

buffer          db      '$$$$$$$$$'

dane            ends

stosik          segment
                dw      100h dup(0)
szczyt          Label   word
stosik          ends

end start
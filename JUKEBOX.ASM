Progr           segment
                assume  cs:Progr, ds:dane, ss:stosik

start:          mov     ax,dane
                mov     ds,ax
                mov     ax,stosik
                mov     ss,ax
                mov     ax,offset szczyt
                mov     sp,ax
;==============================================================================================

                mov     cl,es:[80h]
                dec     cl
                mov     si, offset file
                mov     di, 82h
                
setupfile:       mov     al,es:[di]
                mov     ds:[si], al
				inc     di
                inc     si
				dec     cl
                jnz     setupfile

                mov     ax, 3D00h
                mov     dx, offset file
                int     21h
                jnc      fix1
                jmp      file_err
fix1:
                mov     bx, ax

                ;I/O start
                in      al,61h
                or      al,00000011b
                out     61h,al
                mov     ax,ds:[si]
                out     42h,al
                
                ;wczytanie nagłówka
                mov     ah,42h
                mov     al,0
                mov     cx, 0
                mov     dx, 0
                int     21h

                mov     ah,3Fh
                mov     cx,4
                lea     dx, buffer
                int     21h

;DEL
                mov     ah, 9
                mov     dx, offset buffer
                int     21h

                mov     ah, 2
                mov     dl, 0Ah
                int     21h

                mov     cx, 4

                mov     di, 0
cpy_var:
                xor     ax, ax
                mov     al, di[mark_mthd]
                mov     di[cmpbuffer], al
                inc     di
                dec     cx
                jnz     cpy_var
                
                mov     ah, 9
                mov     dx, offset cmpbuffer
                int     21h

                mov     ah, 2
                mov     dl, 0Ah
                int     21h
;DEL /
                mov     cx, 4

                mov     di, 0
                xor     ax, ax
cmp_char:               
                lea     bx, buffer
                mov     dh, ds:[bx+di]
                lea     bx, cmpbuffer
                mov     dl, ds:[bx+di]
                cmp     dh, dl
                jnz     cmp_fail
                inc     di
                cmp     di, cx
                jnz     cmp_char
                mov     al, 0
                jmp     cmp_end
cmp_fail:      
                mov     al, 1
cmp_end:

                add     al, 0
                jz      file_err


                ;push    bx
                ;mov     di, 0
                ;lea     bx, buffer
                ;mov     dl, ds:[bx+di]
                ;cmp     dl, 'G'
                ;jz      file_err    
                ;pop     bx

                ;mov     ah, 9
                ;mov     dx, offset buffer
                ;int     21h

                jmp     exit
                
file_err:       
                mov     ah, 9
                mov     dx, offset strg_file_err
                int     21h

exit:
;==============================================================================================
                mov     ah,4ch
                mov     al,0
                int     21h

Progr           ends

dane            segment

file            db      80h dup(0)

buffer          db      '$$$$$$$$$'
cmpbuffer      db      '$$$$$$$$$'

strg_test       db      'Test$'
strg_file_err   db      'Wrong file$'

                ;MIDI type msg
strg_midi0      db      'Single track MIDI$'
strg_midi1      db      'Multi track MIDI$'
strg_midi2      db      'This MIDI file type is not supported$'

mark_mthd       db      'MThd'
mark_mtrk       db      'MTrk'

dane            ends

stosik          segment
                dw    100h dup(0)
szczyt          Label word
stosik          ends

end start
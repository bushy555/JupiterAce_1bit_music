	output "buzzkick.bin" 

	; BUZZKICK - "just on time".
	;
	;  MUSIC: JUST ONE TIME";TAB 3;"AUTHOR: SHIRU,  01/19"
	;  MUSIC: REPEATING ITSELF";TAB 3;"AUTHOR: SHIRU,  01/21"


	org	$4000

start:	ld hl, musicData1
	di
	call play
	di
	ret


play:   di

	ld (readRow.drumList), hl

	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a

	xor a
	ld (songSpeedComp), a
	ld (soundLoop.ch1out), a
	ld (soundLoop.ch2out), a

	ld a, 128
	ld (soundLoop.ch1freq), a
	ld (soundLoop.ch2freq), a
	ld a, 1
	ld (soundLoop.ch1delay1), a
	ld (soundLoop.ch2delay1), a
	ld a, 16
	ld (soundLoop.ch1delay2), a
	ld (soundLoop.ch2delay2), a

	exx
	ld d, a
	ld e, a
	ld b, a
	ld c, a
	push hl
	exx

readRow:

	ld c, (hl)
	inc hl

	bit 7, c
	jr z, .noSpeed

	ld a, (hl)
	inc hl
	or a
	jr nz, .noLoop

	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	jr readRow

.noLoop:

	ld (songSpeed), a

.noSpeed:

	bit 6, c
	jr z, .noSustain1

	ld a, (hl)
	inc hl
	exx
	ld d, a
	ld e, a
	exx

.noSustain1:

	bit 5, c
	jr z, .noSustain2

	ld a, (hl)
	inc hl
	exx
	ld b, a
	ld c, a
	exx

.noSustain2:

	bit 4, c
	jr z, .noNote1

	ld a, (hl)
	ld d, a
	inc hl
	or a
	jr z, $+4
	ld a, $18
	ld (soundLoop.ch1out), a
	jr z, .noNote1

	ld a, d
	ld (soundLoop.ch1freq), a
	srl a
	srl a
	ld (soundLoop.ch1delay2), a
	ld a, 1
	ld (soundLoop.ch1delay1), a

	exx
	ld e, d
	exx

.noNote1:

	bit 3, c
	jr z, .noNote2

	ld a, (hl)
	ld e, a
	inc hl
	or a
	jr z, $+4
	ld a, $21
	ld (soundLoop.ch2out), a
	jr z, .noNote2

	ld a, e
	ld (soundLoop.ch2freq), a
	srl a
	srl a
	srl a
	ld (soundLoop.ch2delay2), a
	ld a, 1
	ld (soundLoop.ch2delay1), a

	exx
	ld c, b
	exx

.noNote2:

	ld a, c
	and 7
	jr z, .noDrum

.playDrum:

	push hl

	add a, a
	add a, a
	ld c, a
	ld b, 0
.drumList=$+1
	ld hl, 0
	add hl, bc

	ld a, (hl)				;length in 256-sample blocks
	ld b, a
	inc hl
	inc hl

	add a, a
	add a, a
	ld (songSpeedComp), a

	ld a, (hl)
	inc hl
	ld h, (hl)				;sample data
	ld l, a

	ld a, 1
	ld (.mask), a

	ld c, 0
.loop0:
	ld a, (hl)				;7
.mask=$+1
	and 0					;7
	sub 1					;7
	sbc a, a 				;4
       and $18                                 ;7
       out ($fe), a                             ;11

	jp nz, .HP1	;[10]

	in a, ($fe)	;[11]

	jp .LP1 	;[10]

.HP1:	out ($fe), a	;[11]

	jp .LP1 	;[10]
.LP1:

	ld a, (.mask)			;13
	rlc a					;8
	ld (.mask), a			;13
	jr nc, $+3				;7/12
	inc hl					;6

	jr $+2					;12
	jr $+2					;12
	jr $+2					;12
	jr $+2					;12
	nop						;4
	nop						;4
	ld a, 0					;7

	dec c					;4
	jr nz, .loop0			;7/12=[181] 168t
	djnz .loop0

	pop hl

.noDrum:

songSpeed=$+1
	ld a, 0
	ld b, a
songSpeedComp=$+1
	sub 0
	jr nc, $+3
	xor a
	ld c, a

	ld a, (songSpeedComp)
	sub b
	jr nc, $+3
	xor a
	ld (songSpeedComp), a

	ld a, c
	or a
	jp z, readRow

	ld c, a
	ld b, 64

soundLoop:

	ld a, 3				;7
	dec a				;4
	jr nz, $-1			;7/12=50t
	jr $+2				;12

	dec d				;4
	jp nz, .ch2			;10

.ch1freq=$+1
	ld d, 0				;7

.ch1delay1=$+1
	ld a, 0				;7
	dec a				;4
	jr nz, $-1			;7/12

.ch1out=$+1
	ld a, 0				;7
       out ($fe), a                     ;11

	and $21 	;[7]
	jp nz, .HP2	;[10]

	in a, ($fe)	;[11]

	jp .LP2 	;[10]

.HP2:	out ($fe), a	;[11]

	jp .LP2 	;[10]
.LP2:

.ch1delay2=$+1
	ld a, 0				;7
	dec a				;4
	jr nz, $-1			;7/12

       out ($fe), a                     ;11
	in a, ($fe)	;[11]

.ch2:

	ld a, 3				;7
	dec a				;4
	jr nz, $-1			;7/12=50t
	jr $+2				;12

	dec e				;4
	jp nz, .loop			;10

.ch2freq=$+1
	ld e, 0				;7

.ch2delay1=$+1
	ld a, 0				;7
	dec a				;4
	jr nz, $-1			;7/12

.ch2out=$+1
	ld a, 0				;7
       out ($fe), a                     ;11

	and $21 	;[7]
	jp nz, .HP3	;[10]

	in a, ($fe)	;[11]

	jp .LP3 	;[10]

.HP3:	out ($fe), a	;[11]

	jp .LP3 	;[10]
.LP3:

.ch2delay2=$+1
	ld a, 0				;7
	dec a				;4
	jr nz, $-1			;7/12

       out ($fe), a                     ;11
	in a, ($fe)	;[11]

.loop:

	dec b				;4
	jr nz, soundLoop 	;7/12=[222] 168t

	ld b, 64

envelopeDown:

	exx

	dec e
	jp nz, .noEnv1
	ld e, d

	ld hl, soundLoop.ch1delay2
	dec (hl)
	jr z, $+5
	ld hl, soundLoop.ch1delay1
	inc (hl)

.noEnv1:

	dec c
	jp nz, .noEnv2
	ld c, b

	ld hl, soundLoop.ch2delay2
	dec (hl)
	jr z, $+5
	ld hl, soundLoop.ch2delay1
	inc (hl)

.noEnv2:

	exx

	dec c
	jp nz, soundLoop

;	xor a
;	in a, ($fe)
;	cpl
;	and $1f
;	jp z, readRow
	jp	readRow


	pop hl
	exx
        ei
	ret



musicData1:
 dw .song, 0
.drums:
 dw 1, .drum0
 dw 2, .drum1
 dw 2, .drum2
 dw 3, .drum3
 dw 1, .drum4
 dw 1, .drum5
 dw 4, .drum6
.drum0:
 db $00, $00, $00, $00, $00, $00, $80, $00, $00, $cc, $ff, $ff, $bf, $ff, $ff, $ff
 db $ff, $ff, $1f, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.drum1:
 db $00, $00, $fc, $ff, $ff, $00, $00, $00, $40, $00, $00, $e0, $df, $ff, $ff, $1f
 db $07, $00, $00, $00, $00, $f8, $ff, $ff, $ff, $1b, $01, $00, $00, $00, $00, $00
 db $c0, $f0, $fe, $bf, $ff, $3f, $00, $00, $00, $00, $00, $c2, $c7, $ff, $ff, $bf
 db $00, $00, $00, $00, $00, $00, $84, $b6, $f7, $fe, $7f, $06, $00, $00, $00, $00
.drum2:
 db $c8, $1d, $03, $00, $00, $00, $00, $00, $18, $23, $8c, $fd, $ff, $ff, $ff, $1f
 db $00, $00, $00, $00, $00, $00, $00, $00, $fe, $ff, $ff, $ff, $ff, $bf, $00, $00
 db $00, $00, $00, $00, $00, $00, $e0, $ff, $ff, $ff, $ff, $ff, $ff, $f7, $00, $00
 db $00, $00, $00, $00, $00, $00, $c0, $f9, $ff, $ff, $ff, $ff, $9f, $00, $00, $00
.drum3:
 db $00, $00, $fc, $ff, $ff, $03, $00, $00, $00, $00, $00, $00, $fe, $ff, $ff, $ff
 db $ff, $09, $00, $00, $00, $00, $f0, $ff, $ff, $ff, $6f, $25, $00, $00, $00, $00
 db $00, $00, $00, $dc, $ff, $ff, $ff, $0f, $00, $00, $00, $00, $00, $80, $cf, $ff
 db $ff, $ff, $14, $00, $00, $00, $00, $00, $80, $a4, $ee, $ff, $fb, $7b, $13, $00
 db $00, $00, $00, $00, $00, $80, $fe, $cf, $7f, $b6, $01, $00, $00, $00, $00, $00
 db $00, $80, $b4, $69, $c9, $0b, $00, $00, $40, $00, $00, $00, $00, $00, $f0, $f2
.drum4:
 db $00, $00, $00, $00, $00, $78, $00, $00, $e0, $0f, $00, $00, $c0, $00, $00, $00
 db $1e, $00, $00, $b0, $01, $00, $00, $00, $00, $00, $80, $00, $00, $00, $00, $00
.drum5:
 db $00, $c0, $0f, $00, $e0, $07, $00, $e0, $00, $00, $00, $00, $00, $00, $00, $00
 db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.drum6:
.song:
 db 249, 23, 99, 99, 118, 88
 db 0
 db 0
 db 0
 db 25, 88, 0
 db 16, 0
 db 16, 88
 db 16, 0
 db 9, 88
 db 8, 0
 db 16, 88
 db 16, 0
 db 17, 88
 db 16, 0
 db 8, 88
 db 8, 0
 db 17, 88
 db 16, 0
 db 16, 88
 db 16, 0
 db 9, 88
 db 8, 0
 db 16, 88
 db 16, 0
 db 17, 88
 db 16, 0
 db 24, 118, 88
 db 0
 db 25, 118, 88
 db 0
 db 24, 133, 88
 db 0
 db 25, 118, 88
 db 0
 db 0
 db 0
 db 25, 88, 0
 db 16, 0
 db 16, 88
 db 16, 0
 db 9, 88
 db 8, 0
 db 16, 88
 db 16, 0
 db 17, 88
 db 16, 0
 db 8, 88
 db 8, 0
 db 17, 88
 db 16, 0
 db 16, 88
 db 16, 0
 db 9, 88
 db 8, 0
 db 16, 88
 db 16, 0
 db 17, 88
 db 16, 0
 db 24, 118, 88
 db 0
 db 25, 118, 88
 db 0
 db 24, 133, 88
 db 0
 db 25, 149, 111
 db 0
 db 0
 db 0
 db 25, 111, 0
 db 16, 0
 db 16, 111
 db 16, 0
 db 9, 111
 db 8, 0
 db 16, 111
 db 16, 0
 db 17, 111
 db 16, 0
 db 8, 111
 db 8, 0
 db 17, 111
 db 16, 0
 db 16, 111
 db 16, 0
 db 9, 111
 db 8, 0
 db 16, 111
 db 16, 0
 db 17, 111
 db 16, 0
 db 24, 149, 111
 db 0
 db 25, 149, 111
 db 0
 db 24, 158, 118
 db 0
 db 25, 149, 111
 db 0
 db 0
 db 0
 db 25, 111, 0
 db 16, 0
 db 8, 111
 db 8, 0
 db 25, 149, 111
 db 0
 db 0
 db 0
 db 25, 111, 0
 db 16, 0
 db 8, 111
 db 8, 0
 db 25, 133, 99
 db 0
 db 0
 db 0
 db 25, 99, 0
 db 16, 0
 db 8, 99
 db 8, 0
 db 25, 133, 99
 db 0
 db 0
 db 2
 db 25, 99, 0
 db 16, 0
 db 10, 99
 db 8, 0
 db 25, 118, 88
 db 0
 db 0
 db 1
 db 26, 88, 118
 db 24, 0, 0
 db 25, 88, 118
 db 8, 0
 db 24, 0, 88
 db 8, 0
 db 25, 88, 118
 db 24, 0, 0
 db 26, 88, 118
 db 0
 db 24, 0, 88
 db 8, 0
 db 25, 88, 118
 db 24, 0, 0
 db 24, 88, 118
 db 9, 0
 db 26, 0, 88
 db 8, 0
 db 25, 88, 118
 db 24, 0, 0
 db 24, 88, 118
 db 24, 0, 0
 db 25, 118, 88
 db 0
 db 26, 118, 88
 db 0
 db 24, 133, 88
 db 0
 db 25, 118, 88
 db 0
 db 0
 db 1
 db 26, 88, 118
 db 24, 0, 0
 db 25, 88, 118
 db 8, 0
 db 24, 0, 88
 db 8, 0
 db 25, 88, 118
 db 24, 0, 0
 db 26, 88, 118
 db 8, 0
 db 24, 0, 88
 db 8, 0
 db 25, 88, 118
 db 24, 0, 0
 db 24, 88, 118
 db 9, 0
 db 26, 0, 88
 db 8, 0
 db 25, 88, 118
 db 24, 0, 0
 db 24, 88, 118
 db 24, 0, 0
 db 25, 118, 88
 db 0
 db 26, 118, 88
 db 0
 db 26, 133, 88
 db 2
 db 25, 149, 111
 db 0
 db 0
 db 1
 db 26, 111, 149
 db 24, 0, 0
 db 25, 111, 149
 db 8, 0
 db 25, 0, 111
 db 8, 0
 db 24, 111, 149
 db 25, 0, 0
 db 26, 111, 149
 db 8, 0
 db 25, 0, 111
 db 8, 0
 db 25, 111, 149
 db 24, 0, 0
 db 24, 111, 149
 db 9, 0
 db 26, 0, 111
 db 8, 0
 db 25, 111, 149
 db 24, 0, 0
 db 25, 111, 149
 db 24, 0, 0
 db 24, 149, 111
 db 1
 db 26, 149, 111
 db 0
 db 25, 158, 118
 db 0
 db 25, 149, 111
 db 0
 db 1
 db 0
 db 25, 111, 149
 db 16, 0
 db 9, 111
 db 8, 0
 db 25, 149, 111
 db 0
 db 1
 db 0
 db 25, 111, 149
 db 16, 0
 db 9, 111
 db 8, 0
 db 26, 133, 99
 db 0
 db 2
 db 0
 db 26, 99, 133
 db 16, 0
 db 10, 99
 db 8, 0
 db 28, 133, 99
 db 4
 db 3
 db 3
 db 28, 99, 133
 db 20, 0
 db 11, 99
 db 11, 0
 db 121, 70, 25, 41, 118
 db 16, 39
 db 8, 0
 db 0
 db 10, 118
 db 24, 0, 0
 db 24, 39, 118
 db 0
 db 9, 39
 db 0
 db 9, 118
 db 24, 0, 0
 db 26, 39, 118
 db 0
 db 8, 39
 db 0
 db 25, 44, 118
 db 8, 0
 db 8, 118
 db 0
 db 10, 44
 db 0
 db 24, 49, 118
 db 8, 0
 db 9, 118
 db 8, 0
 db 9, 118
 db 0
 db 26, 88, 118
 db 0
 db 8, 133
 db 0
 db 25, 66, 118
 db 0
 db 8, 88
 db 0
 db 10, 118
 db 8, 0
 db 24, 29, 118
 db 0
 db 9, 66
 db 0
 db 9, 118
 db 8, 0
 db 26, 39, 118
 db 0
 db 8, 29
 db 0
 db 9, 118
 db 8, 0
 db 8, 118
 db 0
 db 10, 39
 db 0
 db 8, 118
 db 8, 0
 db 9, 118
 db 8, 0
 db 9, 118
 db 0
 db 10, 118
 db 0
 db 8, 133
 db 0
 db 25, 41, 149
 db 16, 39
 db 8, 0
 db 0
 db 10, 149
 db 24, 0, 0
 db 24, 39, 149
 db 0
 db 9, 39
 db 0
 db 9, 149
 db 16, 0
 db 26, 39, 149
 db 0
 db 8, 158
 db 0
 db 25, 44, 133
 db 0
 db 8, 39
 db 0
 db 10, 133
 db 8, 0
 db 24, 49, 133
 db 0
 db 9, 44
 db 0
 db 9, 133
 db 0
 db 26, 88, 133
 db 0
 db 8, 149
 db 0
 db 25, 88, 118
 db 16, 79
 db 8, 88
 db 0
 db 10, 118
 db 8, 0
 db 24, 79, 118
 db 0
 db 9, 79
 db 0
 db 9, 118
 db 8, 0
 db 26, 88, 118
 db 16, 79
 db 8, 79
 db 0
 db 9, 118
 db 8, 0
 db 11, 118
 db 3
 db 10, 79
 db 0
 db 11, 118
 db 8, 0
 db 12, 118
 db 8, 0
 db 11, 118
 db 0
 db 12, 118
 db 0
 db 12, 133
 db 0
 db 25, 41, 118
 db 16, 39
 db 8, 0
 db 0
 db 10, 118
 db 24, 0, 0
 db 24, 39, 118
 db 0
 db 9, 39
 db 0
 db 9, 118
 db 24, 0, 0
 db 26, 39, 118
 db 0
 db 8, 0
 db 0
 db 25, 44, 118
 db 8, 0
 db 8, 118
 db 0
 db 10, 39
 db 0
 db 24, 49, 118
 db 8, 0
 db 9, 118
 db 8, 0
 db 9, 118
 db 0
 db 26, 88, 118
 db 0
 db 8, 133
 db 0
 db 25, 66, 118
 db 0
 db 8, 88
 db 0
 db 10, 118
 db 8, 0
 db 24, 29, 118
 db 0
 db 9, 66
 db 0
 db 9, 118
 db 8, 0
 db 26, 39, 118
 db 0
 db 8, 29
 db 0
 db 9, 118
 db 8, 0
 db 8, 118
 db 0
 db 10, 39
 db 0
 db 8, 118
 db 10, 0
 db 9, 118
 db 8, 0
 db 9, 118
 db 0
 db 26, 39, 118
 db 0
 db 24, 37, 133
 db 0
 db 25, 33, 149
 db 0
 db 8, 37
 db 0
 db 10, 149
 db 24, 0, 0
 db 24, 33, 149
 db 0
 db 9, 33
 db 0
 db 9, 149
 db 16, 0
 db 26, 33, 149
 db 0
 db 8, 158
 db 0
 db 25, 29, 133
 db 0
 db 8, 33
 db 0
 db 10, 133
 db 8, 0
 db 8, 133
 db 0
 db 9, 29
 db 0
 db 25, 24, 133
 db 0
 db 26, 22, 133
 db 0
 db 24, 29, 149
 db 0
 db 9, 118
 db 0
 db 8, 29
 db 0
 db 10, 118
 db 8, 0
 db 8, 118
 db 2
 db 9, 29
 db 0
 db 9, 118
 db 8, 0
 db 10, 118
 db 0
 db 8, 0
 db 0
 db 11, 118
 db 3
 db 3
 db 0
 db 12, 0
 db 0
 db 4
 db 0
 db 1
 db 0
 db 1
 db 0
 db 1
 db 0
 db 1
 db 0
 db 121, 5, 99, 37, 149
 db 8, 0
 db 24, 39, 149
 db 8, 0
 db 29, 44, 149
 db 8, 37
 db 25, 59, 149
 db 8, 39
 db 26, 37, 149
 db 8, 44
 db 29, 39, 149
 db 8, 59
 db 25, 44, 149
 db 8, 37
 db 24, 59, 149
 db 8, 39
 db 29, 37, 149
 db 8, 44
 db 24, 39, 149
 db 8, 59
 db 25, 44, 149
 db 8, 37
 db 29, 59, 149
 db 8, 39
 db 26, 37, 149
 db 8, 44
 db 24, 39, 149
 db 8, 59
 db 29, 44, 149
 db 8, 37
 db 24, 59, 149
 db 8, 39
 db 25, 37, 133
 db 8, 44
 db 24, 39, 133
 db 8, 59
 db 29, 44, 133
 db 8, 37
 db 25, 59, 133
 db 8, 39
 db 26, 37, 133
 db 8, 44
 db 29, 39, 133
 db 8, 59
 db 25, 44, 133
 db 8, 37
 db 24, 59, 133
 db 8, 39
 db 24, 37, 177
 db 8, 44
 db 24, 39, 177
 db 8, 59
 db 29, 44, 177
 db 8, 37
 db 24, 59, 177
 db 8, 39
 db 26, 88, 177
 db 8, 44
 db 29, 79, 177
 db 8, 59
 db 28, 74, 177
 db 8, 88
 db 28, 59, 177
 db 8, 79
 db 25, 37, 149
 db 8, 74
 db 24, 39, 149
 db 8, 59
 db 29, 44, 149
 db 8, 37
 db 25, 59, 149
 db 8, 39
 db 26, 37, 149
 db 8, 44
 db 29, 39, 149
 db 8, 59
 db 25, 44, 149
 db 8, 37
 db 24, 59, 149
 db 8, 39
 db 29, 37, 149
 db 8, 44
 db 24, 39, 149
 db 8, 59
 db 25, 44, 149
 db 8, 37
 db 29, 59, 149
 db 8, 39
 db 26, 37, 149
 db 8, 44
 db 24, 39, 149
 db 8, 59
 db 29, 44, 149
 db 8, 37
 db 24, 59, 149
 db 8, 39
 db 25, 37, 133
 db 8, 44
 db 24, 39, 133
 db 8, 59
 db 29, 44, 133
 db 8, 37
 db 25, 59, 133
 db 8, 39
 db 26, 37, 133
 db 8, 44
 db 29, 39, 133
 db 8, 59
 db 25, 44, 133
 db 8, 37
 db 24, 59, 133
 db 8, 39
 db 25, 111, 111
 db 8, 44
 db 24, 88, 111
 db 10, 59
 db 28, 79, 111
 db 8, 111
 db 27, 74, 111
 db 8, 88
 db 27, 55, 118
 db 8, 79
 db 27, 44, 118
 db 8, 74
 db 27, 39, 118
 db 8, 55
 db 27, 37, 118
 db 8, 44
 db 25, 59, 88
 db 8, 39
 db 30, 49, 88
 db 14, 37
 db 28, 44, 88
 db 8, 59
 db 25, 39, 88
 db 8, 49
 db 30, 59, 88
 db 8, 44
 db 25, 49, 88
 db 8, 39
 db 28, 44, 88
 db 8, 59
 db 30, 39, 88
 db 8, 49
 db 25, 59, 88
 db 8, 44
 db 30, 49, 88
 db 14, 39
 db 28, 44, 88
 db 8, 59
 db 25, 39, 88
 db 8, 49
 db 30, 37, 88
 db 8, 44
 db 25, 39, 88
 db 8, 39
 db 28, 44, 88
 db 8, 37
 db 26, 49, 88
 db 10, 39
 db 25, 55, 133
 db 8, 44
 db 30, 49, 133
 db 14, 49
 db 28, 44, 133
 db 8, 55
 db 25, 39, 133
 db 8, 49
 db 30, 55, 133
 db 8, 44
 db 25, 49, 133
 db 8, 39
 db 28, 44, 133
 db 8, 55
 db 30, 39, 133
 db 8, 49
 db 25, 55, 99
 db 8, 44
 db 30, 49, 99
 db 14, 39
 db 28, 44, 99
 db 8, 55
 db 25, 39, 99
 db 8, 49
 db 30, 88, 99
 db 8, 44
 db 25, 79, 99
 db 8, 39
 db 28, 74, 99
 db 12, 88
 db 28, 59, 99
 db 12, 79
 db 25, 59, 88
 db 8, 74
 db 30, 49, 88
 db 14, 59
 db 28, 44, 88
 db 8, 59
 db 25, 39, 88
 db 8, 49
 db 30, 59, 88
 db 8, 44
 db 25, 49, 88
 db 8, 39
 db 28, 44, 88
 db 8, 59
 db 30, 39, 88
 db 8, 49
 db 25, 59, 88
 db 8, 44
 db 30, 49, 88
 db 14, 39
 db 28, 44, 88
 db 8, 59
 db 25, 39, 88
 db 8, 49
 db 30, 37, 88
 db 8, 44
 db 25, 39, 88
 db 8, 39
 db 28, 44, 88
 db 8, 37
 db 24, 49, 88
 db 8, 39
 db 28, 55, 133
 db 8, 44
 db 25, 59, 133
 db 8, 49
 db 28, 66, 133
 db 8, 55
 db 25, 74, 133
 db 8, 59
 db 28, 55, 133
 db 8, 66
 db 25, 59, 133
 db 8, 74
 db 28, 66, 133
 db 8, 37
 db 25, 74, 133
 db 8, 39
 db 28, 59, 118
 db 10, 44
 db 28, 55, 118
 db 8, 59
 db 28, 44, 118
 db 8, 55
 db 28, 39, 118
 db 0
 db 8, 44
 db 0
 db 24, 0, 39
 db 0
 db 8, 0
 db 0
 db 0
 db 0
 db 121, 70, 25, 41, 118
 db 16, 39
 db 8, 0
 db 0
 db 10, 118
 db 24, 0, 0
 db 24, 39, 118
 db 0
 db 13, 39
 db 0
 db 9, 118
 db 24, 0, 0
 db 26, 39, 118
 db 0
 db 13, 39
 db 0
 db 25, 44, 118
 db 8, 0
 db 8, 118
 db 0
 db 10, 44
 db 0
 db 24, 49, 118
 db 8, 0
 db 13, 118
 db 8, 0
 db 9, 118
 db 0
 db 26, 88, 118
 db 0
 db 8, 133
 db 0
 db 9, 118
 db 0
 db 8, 88
 db 0
 db 26, 66, 118
 db 8, 0
 db 8, 118
 db 0
 db 29, 29, 66
 db 0
 db 9, 118
 db 8, 0
 db 26, 39, 118
 db 0
 db 13, 29
 db 0
 db 9, 118
 db 8, 0
 db 8, 118
 db 0
 db 10, 39
 db 0
 db 8, 118
 db 8, 0
 db 13, 118
 db 8, 0
 db 9, 118
 db 0
 db 10, 118
 db 0
 db 8, 133
 db 0
 db 25, 41, 149
 db 16, 39
 db 8, 0
 db 0
 db 10, 149
 db 24, 0, 0
 db 24, 39, 149
 db 0
 db 13, 39
 db 0
 db 9, 149
 db 16, 0
 db 26, 39, 149
 db 0
 db 13, 158
 db 0
 db 25, 44, 133
 db 0
 db 8, 39
 db 0
 db 10, 133
 db 8, 0
 db 24, 49, 133
 db 0
 db 13, 44
 db 0
 db 9, 133
 db 0
 db 26, 88, 133
 db 0
 db 8, 149
 db 0
 db 25, 88, 118
 db 16, 79
 db 8, 88
 db 0
 db 10, 118
 db 8, 0
 db 24, 79, 118
 db 0
 db 13, 79
 db 0
 db 9, 118
 db 8, 0
 db 26, 88, 118
 db 16, 79
 db 13, 79
 db 0
 db 9, 118
 db 8, 0
 db 11, 118
 db 3
 db 10, 79
 db 0
 db 11, 118
 db 8, 0
 db 12, 118
 db 8, 0
 db 11, 118
 db 0
 db 12, 118
 db 0
 db 12, 133
 db 0
 db 25, 41, 118
 db 16, 39
 db 8, 0
 db 0
 db 12, 118
 db 24, 0, 0
 db 24, 39, 118
 db 0
 db 13, 39
 db 0
 db 9, 118
 db 24, 0, 0
 db 28, 39, 118
 db 0
 db 13, 0
 db 0
 db 25, 44, 118
 db 8, 0
 db 8, 118
 db 0
 db 12, 39
 db 0
 db 24, 49, 118
 db 8, 0
 db 13, 118
 db 8, 0
 db 9, 118
 db 0
 db 28, 88, 118
 db 0
 db 8, 133
 db 0
 db 25, 66, 118
 db 0
 db 8, 88
 db 0
 db 12, 118
 db 8, 0
 db 24, 29, 118
 db 0
 db 13, 66
 db 0
 db 9, 118
 db 8, 0
 db 28, 39, 118
 db 0
 db 13, 29
 db 0
 db 9, 118
 db 8, 0
 db 8, 118
 db 0
 db 12, 39
 db 0
 db 8, 118
 db 10, 0
 db 13, 118
 db 8, 0
 db 9, 118
 db 0
 db 28, 39, 118
 db 0
 db 24, 37, 133
 db 0
 db 25, 33, 149
 db 0
 db 8, 37
 db 0
 db 12, 149
 db 24, 0, 0
 db 24, 33, 149
 db 0
 db 13, 33
 db 0
 db 9, 149
 db 16, 0
 db 28, 33, 149
 db 0
 db 13, 158
 db 0
 db 25, 29, 133
 db 0
 db 8, 33
 db 0
 db 12, 133
 db 8, 0
 db 8, 133
 db 0
 db 13, 29
 db 0
 db 25, 24, 133
 db 0
 db 28, 22, 133
 db 0
 db 24, 29, 149
 db 0
 db 9, 118
 db 0
 db 8, 29
 db 0
 db 12, 118
 db 8, 0
 db 8, 118
 db 2
 db 13, 29
 db 0
 db 9, 118
 db 8, 0
 db 12, 118
 db 0
 db 13, 0
 db 0
 db 27, 79, 118
 db 27, 79, 118
 db 27, 79, 118
 db 24, 0, 0
 db 0
 db 0
 db 27, 79, 118
 db 27, 79, 118
 db 28, 79, 118
 db 0
 db 24, 0, 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 25, 44, 149
 db 16, 39
 db 8, 149
 db 0
 db 14, 44
 db 8, 39
 db 8, 149
 db 8, 39
 db 10, 149
 db 0
 db 14, 0
 db 0
 db 24, 49, 149
 db 0
 db 8, 149
 db 0
 db 30, 0, 49
 db 0
 db 8, 149
 db 8, 49
 db 9, 149
 db 0
 db 8, 0
 db 0
 db 26, 59, 149
 db 0
 db 8, 149
 db 0
 db 29, 44, 59
 db 0
 db 5
 db 0
 db 9, 133
 db 8, 44
 db 8, 133
 db 0
 db 14, 0
 db 0
 db 8, 133
 db 0
 db 26, 49, 133
 db 0
 db 30, 59, 0
 db 0
 db 24, 66, 133
 db 8, 49
 db 8, 133
 db 8, 59
 db 14, 177
 db 8, 66
 db 8, 177
 db 0
 db 25, 59, 0
 db 0
 db 8, 177
 db 8, 59
 db 10, 177
 db 0
 db 24, 66, 59
 db 0
 db 13, 177
 db 0
 db 13, 66
 db 0
 db 25, 0, 149
 db 0
 db 8, 149
 db 0
 db 26, 39, 0
 db 0
 db 9, 149
 db 8, 39
 db 26, 0, 149
 db 0
 db 26, 49, 39
 db 0
 db 9, 149
 db 8, 49
 db 24, 0, 149
 db 0
 db 26, 59, 49
 db 0
 db 9, 149
 db 8, 59
 db 25, 0, 149
 db 0
 db 8, 59
 db 0
 db 26, 49, 149
 db 0
 db 8, 149
 db 0
 db 29, 33, 49
 db 0
 db 5
 db 0
 db 9, 133
 db 8, 33
 db 8, 133
 db 0
 db 29, 37, 0
 db 0
 db 9, 133
 db 8, 37
 db 26, 39, 133
 db 0
 db 13, 37
 db 0
 db 25, 59, 133
 db 8, 39
 db 8, 133
 db 8, 59
 db 9, 88
 db 0
 db 8, 88
 db 0
 db 12, 0
 db 0
 db 8, 88
 db 2
 db 11, 88
 db 0
 db 10, 0
 db 0
 db 28, 49, 88
 db 0
 db 28, 44, 0
 db 0
 db 25, 39, 149
 db 8, 49
 db 14, 149
 db 8, 44
 db 12, 149
 db 8, 39
 db 25, 37, 149
 db 8, 39
 db 14, 149
 db 8, 0
 db 9, 149
 db 8, 37
 db 28, 59, 149
 db 8, 37
 db 14, 149
 db 8, 0
 db 25, 0, 149
 db 8, 59
 db 14, 149
 db 8, 59
 db 28, 79, 149
 db 24, 74, 0
 db 9, 149
 db 8, 0
 db 30, 59, 149
 db 8, 37
 db 25, 0, 149
 db 8, 59
 db 28, 49, 149
 db 8, 0
 db 10, 149
 db 10, 0
 db 25, 39, 133
 db 8, 49
 db 14, 133
 db 8, 0
 db 12, 133
 db 8, 39
 db 25, 37, 133
 db 8, 39
 db 14, 133
 db 8, 0
 db 9, 133
 db 8, 37
 db 28, 44, 133
 db 8, 37
 db 14, 133
 db 8, 0
 db 25, 0, 177
 db 8, 44
 db 14, 177
 db 8, 0
 db 28, 99, 177
 db 24, 88, 0
 db 9, 177
 db 24, 0, 0
 db 28, 79, 177
 db 8, 88
 db 9, 177
 db 8, 0
 db 28, 74, 177
 db 12, 79
 db 12, 177
 db 12, 0
 db 26, 39, 149
 db 8, 74
 db 9, 149
 db 8, 0
 db 14, 149
 db 8, 39
 db 26, 37, 149
 db 8, 39
 db 9, 149
 db 8, 0
 db 14, 149
 db 8, 37
 db 26, 49, 149
 db 8, 37
 db 9, 149
 db 8, 0
 db 30, 0, 149
 db 8, 49
 db 14, 149
 db 8, 0
 db 28, 79, 149
 db 24, 74, 0
 db 9, 149
 db 8, 74
 db 30, 59, 149
 db 8, 0
 db 9, 149
 db 8, 59
 db 28, 33, 149
 db 8, 0
 db 8, 149
 db 8, 66
 db 28, 37, 133
 db 8, 0
 db 9, 133
 db 8, 37
 db 28, 0, 133
 db 8, 37
 db 25, 49, 133
 db 8, 0
 db 12, 133
 db 8, 49
 db 25, 0, 133
 db 8, 49
 db 28, 49, 133
 db 24, 44, 0
 db 9, 133
 db 8, 0
 db 28, 44, 177
 db 24, 0, 44
 db 28, 44, 177
 db 24, 0, 44
 db 28, 44, 177
 db 24, 0, 44
 db 28, 88, 177
 db 0
 db 8, 88
 db 0
 db 16, 0
 db 0
 db 0
 db 0
 db 0
 db 8, 0
.loop:
 db 0
 db 0
 db 0
 db 0
 dw $0080, .loop

musicData2:
 dw .song, 0
.drums:
 dw 3, .drum0
 dw 1, .drum1
 dw 1, .drum2
 dw 1, .drum3
 dw 1, .drum4
 dw 4, .drum5
 dw 4, .drum6
.drum0:
 db $00, $00, $fc, $ff, $ff, $00, $00, $00, $40, $00, $00, $e0, $df, $ff, $ff, $1f
 db $07, $00, $00, $00, $00, $f8, $ff, $ff, $ff, $1b, $01, $00, $00, $00, $00, $00
 db $c0, $f0, $fe, $bf, $ff, $3f, $00, $00, $00, $00, $00, $c2, $c7, $ff, $ff, $bf
 db $00, $00, $00, $00, $00, $00, $84, $b6, $f7, $fe, $7f, $06, $00, $00, $00, $00
 db $00, $00, $50, $ff, $f9, $4f, $11, $00, $00, $00, $00, $00, $02, $40, $69, $6b
 db $0b, $03, $00, $00, $20, $00, $02, $00, $00, $00, $28, $01, $48, $80, $00, $10
.drum1:
 db $00, $00, $00, $00, $00, $04, $f0, $f7, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
 db $ff, $ff, $ff, $ff, $0f, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.drum2:
 db $00, $00, $00, $00, $00, $00, $c0, $ff, $3f, $00, $00, $f0, $ff, $07, $00, $00
 db $fe, $7f, $00, $00, $e0, $ff, $0f, $00, $00, $f8, $ff, $01, $00, $00, $ff, $1f
.drum3:
 db $00, $01, $a0, $25, $a2, $12, $00, $00, $00, $80, $00, $00, $02, $20, $00, $00
 db $02, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.drum4:
 db $00, $1f, $f0, $00, $ff, $00, $07, $f0, $00, $7f, $00, $03, $f0, $00, $3f, $00
 db $00, $e0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $07, $f0, $00, $00
.drum5:
.drum6:
.song:
 db 250, 23, 10, 99, 22, 133
 db 0
 db 27, 133, 88
 db 0
 db 89, 1, 133, 22
 db 0
 db 90, 10, 22, 133
 db 0
 db 27, 133, 88
 db 0
 db 90, 1, 133, 22
 db 0
 db 89, 10, 22, 133
 db 0
 db 26, 133, 88
 db 0
 db 26, 133, 22
 db 0
 db 27, 133, 88
 db 0
 db 89, 1, 133, 88
 db 0
 db 90, 10, 133, 88
 db 0
 db 27, 133, 88
 db 0
 db 90, 1, 133, 88
 db 0
 db 89, 10, 133, 88
 db 0
 db 26, 133, 88
 db 0
 db 26, 29, 177
 db 0
 db 27, 177, 118
 db 0
 db 89, 1, 177, 29
 db 0
 db 90, 10, 29, 177
 db 0
 db 27, 177, 118
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 118
 db 0
 db 26, 27, 167
 db 0
 db 27, 167, 111
 db 0
 db 89, 1, 167, 27
 db 0
 db 91, 10, 27, 167
 db 0
 db 26, 149, 99
 db 0
 db 90, 1, 149, 27
 db 0
 db 89, 10, 24, 149
 db 0
 db 25, 149, 99
 db 0
 db 26, 22, 133
 db 0
 db 27, 133, 88
 db 0
 db 89, 1, 133, 22
 db 0
 db 90, 10, 22, 133
 db 0
 db 27, 133, 88
 db 0
 db 90, 1, 133, 22
 db 0
 db 89, 10, 22, 133
 db 0
 db 26, 133, 88
 db 0
 db 26, 133, 22
 db 0
 db 27, 133, 88
 db 0
 db 89, 1, 133, 88
 db 0
 db 90, 10, 133, 88
 db 0
 db 27, 133, 88
 db 0
 db 90, 1, 133, 88
 db 0
 db 89, 10, 133, 88
 db 0
 db 26, 133, 88
 db 0
 db 26, 29, 177
 db 0
 db 27, 177, 118
 db 0
 db 89, 1, 177, 29
 db 0
 db 90, 10, 29, 177
 db 0
 db 27, 177, 118
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 118
 db 0
 db 26, 27, 167
 db 0
 db 27, 167, 111
 db 0
 db 89, 1, 167, 168
 db 0
 db 91, 10, 27, 167
 db 0
 db 25, 149, 27
 db 0
 db 90, 1, 149, 150
 db 0
 db 89, 10, 24, 149
 db 0
 db 25, 149, 24
 db 1
 db 26, 22, 133
 db 0
 db 27, 133, 88
 db 0
 db 89, 1, 133, 22
 db 0
 db 90, 10, 22, 133
 db 0
 db 27, 133, 88
 db 0
 db 90, 1, 133, 22
 db 0
 db 89, 10, 22, 133
 db 0
 db 26, 133, 88
 db 0
 db 26, 133, 22
 db 0
 db 27, 133, 88
 db 0
 db 89, 1, 133, 88
 db 0
 db 90, 10, 133, 88
 db 0
 db 27, 133, 88
 db 0
 db 90, 1, 133, 88
 db 0
 db 89, 10, 133, 88
 db 0
 db 26, 133, 88
 db 0
 db 26, 29, 177
 db 0
 db 27, 177, 118
 db 0
 db 89, 1, 177, 29
 db 0
 db 90, 10, 29, 177
 db 0
 db 27, 177, 118
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 118
 db 0
 db 26, 27, 167
 db 0
 db 27, 167, 111
 db 0
 db 89, 1, 167, 27
 db 0
 db 91, 10, 27, 167
 db 0
 db 26, 149, 99
 db 0
 db 90, 1, 149, 27
 db 0
 db 89, 10, 24, 149
 db 0
 db 25, 149, 99
 db 0
 db 26, 22, 133
 db 0
 db 27, 133, 88
 db 0
 db 89, 1, 133, 22
 db 0
 db 90, 10, 22, 133
 db 0
 db 27, 133, 88
 db 0
 db 90, 1, 133, 22
 db 0
 db 89, 10, 22, 133
 db 0
 db 26, 133, 88
 db 0
 db 26, 133, 22
 db 0
 db 27, 133, 88
 db 0
 db 89, 1, 133, 88
 db 0
 db 90, 10, 133, 88
 db 0
 db 27, 133, 88
 db 0
 db 90, 1, 133, 88
 db 0
 db 89, 10, 133, 88
 db 0
 db 26, 133, 88
 db 0
 db 26, 29, 177
 db 0
 db 27, 177, 118
 db 0
 db 89, 1, 177, 29
 db 0
 db 90, 10, 29, 177
 db 0
 db 27, 177, 118
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 118
 db 0
 db 25, 27, 167
 db 0
 db 89, 99, 111, 167
 db 0
 db 25, 111, 167
 db 0
 db 89, 10, 27, 55
 db 0
 db 89, 99, 99, 149
 db 1
 db 26, 99, 149
 db 2
 db 89, 10, 24, 49
 db 1
 db 90, 99, 99, 149
 db 2
 db 122, 10, 10, 27, 133
 db 0
 db 24, 27, 133
 db 8, 27
 db 57, 1, 29, 133
 db 40, 10, 27
 db 24, 33, 133
 db 8, 29
 db 24, 0, 133
 db 8, 33
 db 58, 1, 37, 133
 db 0
 db 57, 10, 0, 133
 db 8, 37
 db 24, 37, 133
 db 0
 db 26, 33, 133
 db 8, 37
 db 26, 33, 133
 db 8, 33
 db 57, 1, 37, 133
 db 40, 10, 33
 db 24, 33, 133
 db 8, 37
 db 8, 133
 db 8, 33
 db 58, 1, 0, 133
 db 0
 db 41, 10, 133
 db 0
 db 8, 133
 db 0
 db 26, 27, 149
 db 0
 db 24, 27, 149
 db 8, 27
 db 57, 1, 29, 149
 db 40, 10, 27
 db 24, 33, 149
 db 8, 29
 db 24, 0, 149
 db 8, 33
 db 58, 1, 37, 149
 db 0
 db 57, 10, 44, 149
 db 8, 37
 db 24, 0, 149
 db 8, 44
 db 26, 49, 149
 db 0
 db 10, 149
 db 8, 49
 db 41, 1, 149
 db 0
 db 56, 10, 44, 149
 db 0
 db 8, 149
 db 8, 44
 db 42, 1, 149
 db 0
 db 57, 10, 41, 149
 db 0
 db 8, 149
 db 8, 41
 db 90, 50, 27, 167
 db 0
 db 24, 27, 167
 db 8, 27
 db 57, 1, 29, 167
 db 40, 10, 27
 db 24, 33, 167
 db 8, 29
 db 24, 0, 167
 db 8, 33
 db 58, 1, 37, 167
 db 0
 db 57, 10, 0, 167
 db 8, 37
 db 24, 37, 167
 db 0
 db 26, 33, 167
 db 8, 37
 db 26, 33, 167
 db 8, 33
 db 57, 1, 37, 167
 db 40, 10, 33
 db 24, 33, 167
 db 8, 37
 db 8, 167
 db 8, 33
 db 58, 1, 0, 167
 db 0
 db 41, 10, 167
 db 0
 db 8, 167
 db 0
 db 26, 49, 177
 db 0
 db 8, 177
 db 8, 49
 db 41, 1, 177
 db 40, 10, 49
 db 24, 44, 177
 db 0
 db 8, 177
 db 8, 44
 db 42, 1, 177
 db 40, 10, 44
 db 25, 49, 177
 db 0
 db 24, 44, 177
 db 8, 49
 db 10, 167
 db 8, 44
 db 10, 167
 db 0
 db 57, 1, 88, 167
 db 0
 db 40, 10, 167
 db 0
 db 9, 149
 db 0
 db 58, 1, 83, 149
 db 0
 db 41, 10, 149
 db 0
 db 9, 149
 db 1
 db 122, 99, 99, 27, 133
 db 0
 db 28, 27, 133
 db 40, 10, 27
 db 57, 99, 29, 66
 db 40, 10, 27
 db 60, 99, 33, 133
 db 40, 10, 29
 db 56, 99, 0, 133
 db 40, 10, 33
 db 58, 99, 37, 66
 db 0
 db 25, 0, 133
 db 40, 10, 37
 db 59, 99, 37, 66
 db 0
 db 26, 33, 133
 db 40, 10, 37
 db 58, 99, 33, 133
 db 40, 10, 33
 db 57, 99, 29, 66
 db 40, 10, 33
 db 59, 99, 27, 133
 db 40, 10, 29
 db 40, 99, 133
 db 40, 10, 27
 db 58, 99, 0, 66
 db 8, 27
 db 9, 133
 db 0
 db 11, 66
 db 0
 db 58, 90, 27, 149
 db 0
 db 28, 27, 149
 db 40, 10, 27
 db 57, 90, 29, 74
 db 40, 10, 27
 db 60, 90, 33, 74
 db 40, 10, 29
 db 56, 90, 0, 149
 db 40, 10, 33
 db 58, 90, 37, 149
 db 0
 db 25, 44, 74
 db 40, 10, 37
 db 59, 90, 0, 74
 db 40, 10, 44
 db 58, 90, 49, 149
 db 0
 db 10, 149
 db 40, 10, 49
 db 41, 90, 74
 db 0
 db 59, 10, 37, 74
 db 0
 db 8, 149
 db 8, 37
 db 42, 90, 149
 db 0
 db 25, 33, 74
 db 0
 db 11, 74
 db 40, 10, 33
 db 58, 90, 27, 167
 db 0
 db 28, 27, 167
 db 40, 10, 27
 db 57, 90, 29, 83
 db 40, 10, 27
 db 60, 90, 33, 83
 db 40, 10, 29
 db 56, 90, 0, 167
 db 40, 10, 33
 db 58, 90, 37, 167
 db 0
 db 25, 0, 83
 db 40, 10, 37
 db 59, 90, 37, 83
 db 0
 db 26, 33, 167
 db 40, 10, 37
 db 58, 90, 33, 167
 db 40, 10, 33
 db 57, 90, 29, 83
 db 40, 10, 33
 db 59, 90, 27, 83
 db 40, 10, 29
 db 40, 90, 167
 db 40, 10, 27
 db 58, 90, 0, 167
 db 8, 27
 db 9, 83
 db 0
 db 11, 83
 db 0
 db 26, 24, 177
 db 0
 db 12, 177
 db 40, 10, 24
 db 41, 90, 88
 db 40, 10, 24
 db 60, 90, 22, 88
 db 0
 db 8, 177
 db 40, 10, 22
 db 42, 90, 177
 db 40, 10, 22
 db 121, 1, 90, 177, 88
 db 0
 db 27, 177, 88
 db 32, 10
 db 121, 99, 90, 22, 167
 db 32, 10
 db 41, 90, 22
 db 0
 db 41, 10, 83
 db 0
 db 25, 20, 83
 db 0
 db 9, 20
 db 0
 db 10, 167
 db 2
 db 10, 83
 db 0
 db 10, 83
 db 0
 db 122, 10, 99, 22, 133
 db 0
 db 27, 133, 134
 db 0
 db 89, 1, 133, 22
 db 0
 db 90, 10, 22, 133
 db 0
 db 27, 133, 134
 db 0
 db 90, 1, 133, 22
 db 0
 db 89, 10, 22, 133
 db 0
 db 26, 133, 134
 db 0
 db 26, 133, 22
 db 0
 db 27, 133, 88
 db 0
 db 89, 1, 133, 88
 db 0
 db 90, 10, 133, 88
 db 0
 db 27, 133, 88
 db 0
 db 90, 1, 133, 88
 db 0
 db 89, 10, 88, 133
 db 0
 db 26, 88, 133
 db 0
 db 26, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 89, 1, 177, 29
 db 0
 db 90, 10, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 178
 db 0
 db 26, 27, 167
 db 0
 db 27, 167, 168
 db 0
 db 89, 1, 167, 27
 db 0
 db 91, 10, 27, 167
 db 0
 db 26, 149, 150
 db 0
 db 90, 1, 149, 27
 db 0
 db 89, 10, 24, 149
 db 0
 db 25, 149, 99
 db 0
 db 26, 22, 133
 db 0
 db 27, 133, 134
 db 0
 db 89, 1, 133, 22
 db 0
 db 90, 10, 22, 133
 db 0
 db 27, 133, 134
 db 0
 db 90, 1, 133, 22
 db 0
 db 89, 10, 22, 133
 db 0
 db 26, 133, 134
 db 0
 db 26, 133, 22
 db 0
 db 27, 133, 88
 db 0
 db 89, 1, 133, 88
 db 0
 db 90, 10, 133, 88
 db 0
 db 27, 133, 88
 db 0
 db 90, 1, 133, 88
 db 0
 db 89, 10, 88, 133
 db 0
 db 26, 88, 133
 db 0
 db 26, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 89, 1, 177, 29
 db 0
 db 90, 10, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 178
 db 0
 db 26, 27, 167
 db 0
 db 27, 167, 168
 db 0
 db 89, 1, 167, 168
 db 0
 db 91, 10, 27, 167
 db 0
 db 25, 149, 150
 db 0
 db 90, 1, 149, 150
 db 0
 db 89, 10, 24, 149
 db 0
 db 25, 149, 24
 db 1
 db 26, 55, 133
 db 0
 db 27, 133, 134
 db 8, 55
 db 89, 1, 88, 22
 db 8, 55
 db 90, 10, 22, 133
 db 0
 db 27, 59, 134
 db 0
 db 90, 1, 133, 22
 db 8, 59
 db 89, 10, 88, 133
 db 8, 59
 db 26, 133, 134
 db 0
 db 26, 55, 22
 db 0
 db 27, 133, 88
 db 8, 55
 db 89, 1, 88, 88
 db 8, 55
 db 90, 10, 133, 88
 db 0
 db 27, 59, 88
 db 0
 db 90, 1, 133, 88
 db 8, 59
 db 89, 10, 88, 88
 db 8, 59
 db 26, 133, 88
 db 0
 db 26, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 89, 1, 177, 29
 db 0
 db 90, 10, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 178
 db 0
 db 26, 27, 167
 db 0
 db 27, 167, 168
 db 0
 db 89, 1, 167, 27
 db 0
 db 91, 10, 27, 167
 db 0
 db 26, 149, 150
 db 0
 db 90, 1, 149, 27
 db 0
 db 89, 10, 24, 149
 db 0
 db 25, 149, 99
 db 0
 db 26, 55, 133
 db 0
 db 27, 133, 134
 db 8, 55
 db 89, 1, 88, 22
 db 8, 55
 db 90, 10, 22, 133
 db 0
 db 27, 59, 134
 db 0
 db 90, 1, 133, 22
 db 8, 59
 db 89, 10, 88, 133
 db 8, 59
 db 26, 133, 134
 db 0
 db 26, 55, 22
 db 0
 db 27, 133, 88
 db 8, 55
 db 89, 1, 88, 88
 db 8, 55
 db 90, 10, 133, 88
 db 0
 db 27, 59, 88
 db 0
 db 90, 1, 133, 88
 db 8, 59
 db 89, 10, 55, 88
 db 8, 59
 db 26, 133, 88
 db 8, 55
 db 26, 49, 177
 db 0
 db 27, 177, 178
 db 8, 49
 db 89, 1, 177, 29
 db 8, 49
 db 90, 10, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 178
 db 0
 db 25, 27, 168
 db 0
 db 25, 167, 168
 db 0
 db 89, 1, 167, 168
 db 0
 db 89, 10, 27, 55
 db 0
 db 25, 149, 150
 db 1
 db 89, 1, 149, 150
 db 1
 db 89, 10, 24, 49
 db 1
 db 25, 149, 150
 db 1
 db 26, 27, 133
 db 0
 db 28, 27, 133
 db 8, 27
 db 25, 29, 133
 db 8, 27
 db 26, 33, 133
 db 8, 29
 db 24, 0, 133
 db 8, 33
 db 26, 37, 133
 db 0
 db 25, 0, 133
 db 8, 37
 db 28, 37, 133
 db 0
 db 26, 33, 133
 db 8, 37
 db 26, 33, 133
 db 8, 33
 db 25, 37, 133
 db 8, 33
 db 26, 33, 133
 db 8, 37
 db 8, 133
 db 8, 33
 db 26, 0, 133
 db 0
 db 9, 133
 db 0
 db 12, 133
 db 0
 db 26, 27, 149
 db 0
 db 28, 27, 149
 db 8, 27
 db 25, 29, 149
 db 8, 27
 db 26, 33, 149
 db 8, 29
 db 24, 0, 149
 db 8, 33
 db 26, 37, 149
 db 0
 db 25, 44, 149
 db 8, 37
 db 28, 0, 149
 db 8, 44
 db 26, 49, 149
 db 0
 db 10, 149
 db 8, 49
 db 9, 149
 db 8, 49
 db 26, 44, 149
 db 0
 db 8, 149
 db 8, 44
 db 10, 149
 db 8, 44
 db 25, 41, 149
 db 0
 db 12, 149
 db 8, 41
 db 90, 50, 27, 167
 db 0
 db 28, 27, 167
 db 8, 27
 db 25, 29, 167
 db 8, 27
 db 26, 33, 167
 db 8, 29
 db 24, 0, 167
 db 8, 33
 db 26, 37, 167
 db 0
 db 25, 0, 167
 db 8, 37
 db 28, 37, 167
 db 0
 db 26, 33, 167
 db 8, 37
 db 26, 33, 167
 db 8, 33
 db 25, 37, 167
 db 8, 33
 db 26, 33, 167
 db 8, 37
 db 8, 167
 db 8, 33
 db 26, 0, 167
 db 0
 db 9, 167
 db 0
 db 12, 167
 db 0
 db 26, 52, 177
 db 16, 49
 db 12, 177
 db 8, 49
 db 9, 177
 db 8, 49
 db 26, 44, 177
 db 0
 db 8, 177
 db 8, 44
 db 10, 177
 db 8, 44
 db 25, 49, 177
 db 0
 db 28, 47, 177
 db 24, 44, 49
 db 10, 167
 db 0
 db 10, 167
 db 8, 44
 db 89, 10, 22, 167
 db 80, 20, 44
 db 88, 30, 22, 167
 db 88, 40, 44, 22
 db 89, 50, 22, 149
 db 88, 60, 44, 22
 db 90, 70, 20, 149
 db 80, 80, 41
 db 89, 90, 20, 149
 db 24, 41, 20
 db 25, 20, 149
 db 25, 41, 20
 db 90, 99, 27, 133
 db 0
 db 28, 27, 133
 db 8, 27
 db 25, 29, 66
 db 8, 27
 db 29, 33, 133
 db 13, 29
 db 28, 44, 133
 db 24, 0, 33
 db 26, 37, 66
 db 0
 db 25, 44, 133
 db 24, 0, 37
 db 27, 37, 66
 db 0
 db 26, 33, 133
 db 8, 37
 db 26, 33, 133
 db 8, 33
 db 25, 29, 66
 db 8, 33
 db 29, 27, 133
 db 13, 29
 db 11, 133
 db 8, 27
 db 29, 44, 66
 db 5
 db 25, 44, 133
 db 16, 0
 db 27, 44, 66
 db 0
 db 26, 27, 149
 db 0
 db 28, 27, 149
 db 8, 27
 db 25, 29, 74
 db 8, 27
 db 29, 33, 74
 db 13, 29
 db 28, 49, 149
 db 24, 0, 33
 db 26, 37, 149
 db 0
 db 25, 49, 74
 db 24, 0, 37
 db 27, 99, 74
 db 8, 44
 db 26, 49, 149
 db 0
 db 10, 149
 db 8, 49
 db 25, 49, 74
 db 8, 49
 db 27, 37, 74
 db 0
 db 13, 149
 db 8, 37
 db 29, 49, 149
 db 8, 37
 db 25, 33, 74
 db 0
 db 10, 74
 db 8, 33
 db 26, 27, 167
 db 0
 db 28, 27, 167
 db 8, 27
 db 25, 29, 83
 db 8, 27
 db 29, 33, 83
 db 13, 29
 db 28, 55, 167
 db 24, 0, 33
 db 26, 37, 167
 db 0
 db 25, 55, 83
 db 24, 0, 37
 db 27, 37, 83
 db 0
 db 26, 33, 167
 db 8, 37
 db 26, 33, 167
 db 8, 33
 db 25, 29, 83
 db 8, 33
 db 29, 27, 83
 db 13, 29
 db 11, 167
 db 8, 27
 db 29, 55, 167
 db 5
 db 25, 55, 83
 db 16, 0
 db 27, 55, 83
 db 0
 db 26, 24, 177
 db 0
 db 12, 177
 db 8, 24
 db 25, 59, 88
 db 8, 24
 db 29, 22, 88
 db 5
 db 12, 177
 db 8, 22
 db 26, 59, 177
 db 8, 22
 db 89, 1, 177, 88
 db 0
 db 27, 177, 88
 db 0
 db 89, 99, 22, 167
 db 0
 db 9, 22
 db 0
 db 25, 55, 83
 db 0
 db 25, 20, 83
 db 0
 db 9, 20
 db 0
 db 26, 55, 167
 db 2
 db 26, 20, 83
 db 0
 db 10, 83
 db 0
 db 90, 10, 55, 133
 db 0
 db 27, 133, 134
 db 8, 55
 db 89, 1, 88, 22
 db 8, 55
 db 90, 10, 22, 133
 db 0
 db 27, 59, 134
 db 0
 db 90, 1, 133, 22
 db 8, 59
 db 89, 10, 88, 133
 db 8, 59
 db 26, 133, 134
 db 0
 db 26, 55, 22
 db 0
 db 27, 133, 88
 db 8, 55
 db 89, 1, 88, 88
 db 8, 55
 db 90, 10, 133, 88
 db 0
 db 27, 59, 88
 db 0
 db 90, 1, 133, 88
 db 8, 59
 db 89, 10, 88, 88
 db 8, 59
 db 26, 133, 88
 db 0
 db 26, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 89, 1, 177, 29
 db 0
 db 90, 10, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 178
 db 0
 db 26, 27, 167
 db 0
 db 27, 167, 168
 db 0
 db 89, 1, 167, 27
 db 0
 db 91, 10, 27, 167
 db 0
 db 26, 149, 150
 db 0
 db 93, 1, 149, 27
 db 5
 db 89, 10, 24, 149
 db 0
 db 29, 149, 99
 db 5
 db 26, 55, 133
 db 0
 db 27, 133, 134
 db 8, 55
 db 89, 1, 88, 22
 db 8, 55
 db 90, 10, 22, 133
 db 0
 db 27, 59, 134
 db 0
 db 90, 1, 133, 22
 db 8, 59
 db 89, 10, 88, 133
 db 8, 59
 db 26, 133, 134
 db 0
 db 26, 55, 22
 db 0
 db 27, 133, 88
 db 8, 55
 db 89, 1, 88, 88
 db 8, 55
 db 90, 10, 133, 88
 db 0
 db 27, 59, 88
 db 0
 db 90, 1, 133, 88
 db 8, 59
 db 89, 10, 55, 88
 db 8, 59
 db 26, 133, 88
 db 8, 55
 db 26, 59, 177
 db 8, 55
 db 27, 177, 178
 db 8, 59
 db 89, 1, 177, 29
 db 8, 59
 db 90, 10, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 178
 db 0
 db 26, 27, 167
 db 0
 db 29, 167, 168
 db 5
 db 89, 1, 167, 168
 db 0
 db 93, 10, 27, 167
 db 5
 db 25, 149, 150
 db 0
 db 93, 1, 149, 150
 db 5
 db 89, 10, 24, 149
 db 0
 db 29, 149, 24
 db 0
 db 26, 55, 133
 db 0
 db 27, 133, 134
 db 8, 27
 db 89, 1, 88, 22
 db 8, 27
 db 90, 10, 22, 133
 db 0
 db 27, 59, 134
 db 0
 db 90, 1, 133, 22
 db 8, 29
 db 89, 10, 88, 133
 db 8, 29
 db 26, 133, 134
 db 0
 db 26, 55, 22
 db 0
 db 27, 133, 88
 db 8, 27
 db 89, 1, 88, 88
 db 8, 27
 db 90, 10, 133, 88
 db 0
 db 27, 59, 88
 db 0
 db 90, 1, 133, 88
 db 8, 29
 db 89, 10, 88, 88
 db 8, 29
 db 26, 133, 88
 db 0
 db 26, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 89, 1, 177, 29
 db 0
 db 90, 10, 29, 177
 db 0
 db 27, 177, 178
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 178
 db 0
 db 26, 27, 167
 db 0
 db 27, 167, 168
 db 0
 db 89, 1, 167, 27
 db 0
 db 91, 10, 27, 167
 db 0
 db 26, 149, 150
 db 0
 db 93, 1, 149, 27
 db 5
 db 89, 10, 24, 149
 db 0
 db 29, 149, 99
 db 5
 db 26, 55, 133
 db 0
 db 27, 133, 134
 db 8, 27
 db 89, 1, 88, 22
 db 8, 27
 db 90, 10, 22, 133
 db 0
 db 27, 59, 134
 db 0
 db 90, 1, 133, 22
 db 8, 29
 db 89, 10, 88, 133
 db 8, 29
 db 26, 133, 134
 db 0
 db 26, 55, 22
 db 0
 db 27, 133, 88
 db 8, 27
 db 89, 1, 88, 88
 db 8, 27
 db 90, 10, 133, 88
 db 0
 db 27, 59, 88
 db 0
 db 90, 1, 133, 88
 db 8, 29
 db 89, 10, 55, 88
 db 8, 29
 db 26, 133, 88
 db 8, 27
 db 26, 49, 177
 db 8, 27
 db 11, 178
 db 8, 55
 db 89, 1, 177, 29
 db 8, 55
 db 90, 10, 29, 177
 db 8, 55
 db 27, 177, 178
 db 0
 db 90, 1, 177, 29
 db 0
 db 89, 10, 29, 177
 db 0
 db 26, 177, 178
 db 0
 db 25, 27, 56
 db 0
 db 90, 99, 111, 168
 db 0
 db 25, 111, 168
 db 0
 db 90, 10, 27, 55
 db 0
 db 89, 99, 99, 150
 db 1
 db 26, 99, 150
 db 2
 db 89, 10, 24, 49
 db 1
 db 90, 99, 99, 150
 db 2
 db 121, 20, 20, 34, 133
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 24, 0, 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
.loop:
 db 0
 db 0
 db 0
 db 0
 dw $0080, .loop


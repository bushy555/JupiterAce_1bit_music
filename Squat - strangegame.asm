	; Forward to infinity. - Shiru.
	; Squat.


	output "Squat - strangegame.bin"
	org	$4000
;squat by Shiru, 06'17
;Squeeker like, just without the output value table
;4 channels of tone with different duty cycle
;sample drums, non-interrupting
;customizeable noise percussion, interrupting


;music data is all 16-bit words, first control then a few optional ones

;control word is PSSSSSSS DDDN4321, where P=percussion,S=speed, D=drum, N=noise mode, 4321=channels
;D triggers non-interruping sample drum
;P trigger
;if 1, channel 1 freq follows
;if 2, channel 2 freq follows
;if 3, channel 3 freq follows
;if 4, channel 4 freq follows
;if N, channel 4 mode follows, it is either $0000 (normal) or $04cb (noise)
;if P, percussion follows, LSB=volume, MSB=pitch



RLC_H=$04cb		;to enable noise mode
NOP_2=$0000		;to disable noise mode
RLC_HL=$06cb		;to enable sample reading
ADD_IX_IX=$29dd 	;to disable sample reading


; For Jupiter Ace as a binary file assembled to $4000.
;
; Jupiter Ace emulator. 
; 	Load in as memory block at $4000.
; 	Back in fourth prompt, type in:    16384 CALL
;	sit back and listen to the noise!
;
;---
; Assemble with SJASMPLUS.	sjasmplus %1.asm
;
;
;---


start:	ld 	hl, music_data
	call 	play
	ei
	ret




play:	di
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (pattern_ptr),de
	
	ld e,(hl)
	inc hl
	ld d,(hl)
	
	ld (loop_ptr),de

	dec hl
	ld (sample_list),hl
	
	ld hl,ADD_IX_IX
	ld (sample_read),hl
	ld hl,NOP_2				;normal mode
	ld (noise_mode),hl
	
	ld ix,0 				;needs to be 0 to skip sample reading

	ld c,0
	exx
	ld de,$0808				;sample bit counter and reload value

play_loop:

pattern_ptr=$+1
	ld sp,0
	
return_loop:

	pop bc					;control word
						;B=duration of the row (0=loop)
						;C=flags DDDN4321 (Drum, Noise, 1-4 channel update)
	ld a,b
	or a
	jp nz,no_loop
	
loop_ptr=$+1
	ld sp,0
	
	jp return_loop
	
no_loop:

	ld a,c
	
	rra
	jr nc,skip_note_0
	
	pop hl
	ld (ch0_add),hl
	
skip_note_0:

	rra
	jr nc,skip_note_1

	pop hl
	ld (ch1_add),hl
	
skip_note_1:

	rra
	jr nc,skip_note_2
	
	pop hl
	ld (ch2_add),hl
	
skip_note_2:

	rra
	jr nc,skip_note_3
	
	pop hl
	ld (ch3_add),hl
	
skip_note_3:

	rra
	jr nc,skip_mode_change
	
	pop hl					;nop:nop or rlc h
	ld (noise_mode),hl

skip_mode_change:

	and 7
	jp z,skip_drum
	
sample_list=$+1
	ld hl,0 				;sample_list-2
	add a,a
	add a,l
	ld l,a
	ld a,(hl)
	inc l
	ld h,(hl)
	ld l,a
	ld (sample_ptr),hl
	ld hl,RLC_HL
	ld (sample_read),hl

skip_drum:

	bit 7,b 				;check percussion flag
	jp z,skip_percussion

	res 7,b 				;clear percussion flag
	dec b					;compensate speed

	ld (noise_bc),bc
	ld (noise_de),de

	pop hl					;read percussion parameters

	ld a,l					;noise volume
	ld (noise_volume),a
	ld b,h					;noise pitch
	ld c,h
	ld de,$2174				;utz's rand seed			
	exx
	ld bc,811				;noise duration, takes as long as inner sound loop

noise_loop:

	exx				;4
	dec c				;4
	jr nz,noise_skip		;7/12
	ld c,b				;4
	add hl,de			;11
	rlc h				;8	utz's noise generator idea
	inc d				;4	improves randomness
	jp noise_next			;10
	
noise_skip:

	jr $+2				;12
	jr $+2				;12
	nop				;4
	nop				;4
	
noise_next:

	ld a,h				;4
	
noise_volume=$+1
	cp $80				;7
        sbc a,a                         ;4
        out ($fe),a                     ;11

	jp c,.HP	;[10]

	in a,($fe)	;[11]
	jp .LP		;[10]

.HP:	out ($fe),a	;[11]
	jp .LP		;[10]
.LP:
	exx				;4

	dec bc				;6
	ld a,b				;4
	or c				;4
	jp nz,noise_loop		;10=106t

	exx

noise_bc=$+1
	ld bc,0
noise_de=$+1
	ld de,0



skip_percussion:

	ld (pattern_ptr),sp

sample_ptr=$+1
	ld hl,0

	ld c,0					;internal loop runs 256 times

sound_loop:

sample_read=$
	rlc (hl)			;15	rotate sample bits in place, rl (hl) or add ix,ix (dummy operation)
	sbc a,a 			;4	sbc a,a to make bit into 0 or 255, or xor a to keep it 0

	dec e				;4--+	count bits
	jp z,sample_cycle		;10 |
	jp sample_next			;10

sample_cycle:

	ld e,d				;4  |	reload counter
	inc hl				;6--+	advance pointer --24t

sample_next:

	exx				;4	squeeker type unrolled code
	ld b,a				;4	sample mask
	xor a				;4
	
	ld sp,sound_list		;10
		
	pop de				;10	ch0_acc
	pop hl				;10	ch0_add
	add hl,de			;11
	rla				;4
	ld (ch0_acc),hl 		;16
						
	pop de				;10	ch1_acc
	pop hl				;10	ch1_add
	add hl,de			;11
	rla				;4
	ld (ch1_acc),hl 		;16
	
	pop de				;10	ch2_acc
	pop hl				;10	ch2_add
	add hl,de			;11
	rla							;4
	ld (ch2_acc),hl 		;16

	pop de				;10	ch3_acc
	pop hl				;10	ch3_add
	add hl,de			;11
	


noise_mode=$
        ds 2,0                          ;8      rlc h for noise effects
;	rb 2

	rla				;4
	ld (ch3_acc),hl 		;16

	add a,c 			;4	no table like in Squeeker, channels summed as is, for uneven 'volume'
	add a,$ff			;7
	sbc a,$ff			;7
	ld c,a				;4
	sbc a,a 			;4

	or b				;4	mix sample
	
        out ($fe),a                     ;11

	and $21 	;[7]
	jp nz,.HP	;[10]

	in a,($fe)	;[11]
	jp .LP		;[10]

.HP:	out ($fe),a	;[11]
	jp .LP		;[10]
.LP:

	exx				;4

	dec c				;4
	jp nz,sound_loop		;10=374  ;336t


	dec hl					;last byte of a 256/8 byte sample packet is $80 means it was the last packet
	ld a,(hl)
	inc hl
	cp $80
	jr nz,sample_no_stop

	ld hl,ADD_IX_IX
	ld (sample_read),hl			;disable sample reading

sample_no_stop:

	djnz sound_loop

	ld (sample_ptr),hl
	
	jp play_loop
	

	
;variables in the sound_list can't be reordered because of stack-based fetching

sound_list

ch0_add		dw 0
ch0_acc		dw 0
ch1_add		dw 0
ch1_acc		dw 0
ch2_add		dw 0
ch2_acc		dw 0
ch3_add		dw 0
ch3_acc		dw 0


	align 2

music_data
	dw .pattern
	dw .loop
;sample data

.sample_list
	dw .sample_1
	dw .sample_2
	dw .sample_3
	dw .sample_4
	dw .sample_5
	dw .sample_6
	dw .sample_7
	align 256/8

.sample_1
	db 0,15,255,248,0,0,7,255,240,0,0,7,255,248,0,0
	db 0,127,255,224,0,0,0,15,255,255,128,0,0,0,7,255
	db 255,252,0,0,0,0,0,255,255,255,224,0,0,0,0,0
	db 7,255,255,255,240,0,0,0,0,0,0,15,255,255,255,254
	db 0,0,0,0,0,0,0,0,255,255,255,255,255,0,0,0
	db 0,0,0,0,0,0,255,255,255,255,255,255,0,0,0,0
	db 0,0,0,0,0,0,31,255,255,255,255,240,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,128
.sample_2
	db 3,249,0,0,191,255,0,0,0,0,63,255,255,224,0,0
	db 0,127,255,255,0,0,0,0,0,127,247,90,128,0,0,1
	db 119,127,202,0,0,0,0,134,95,253,0,0,0,0,39,255
	db 104,0,0,0,0,27,255,208,0,0,0,0,1,223,80,0
	db 0,0,0,0,70,40,0,0,0,0,0,5,109,0,0,0
	db 0,2,0,178,64,0,0,0,0,8,128,64,0,0,0,0
	db 0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,128
.sample_3
	db 10,29,148,0,0,0,127,255,160,0,0,1,159,248,0,0
	db 0,0,0,1,255,255,255,255,224,0,0,0,0,0,0,15
	db 255,255,255,255,255,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,128
.sample_4
.sample_5
.sample_6
.sample_7

.pattern
.loop
	dw $31f,$cd,$19b,$c5,$66e,NOP_2
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $30b,$0,$cd,$cdc
	dw $30e,$0,$cd,$337
	dw $30c,$0,$7a5
	dw $308,$337
	dw $308,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $30b,$19b,$337,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $30b,$0,$0,$7a5
	dw $308,$337
	dw $30b,$134,$268,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $30a,$0,$7a5
	dw $309,$0,$337
	dw $30b,$cd,$19b,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $308,$7a5
	dw $30a,$0,$337
	dw $30b,$122,$245,$917
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$122f
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$917
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$122f
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$917
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$122f
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $30b,$0,$0,$917
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$122f
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $30b,$f4,$1cd,$7a5
	dw $30a,$1e9,$3d2
	dw $308,$917
	dw $308,$3d2
	dw $308,$f4a
	dw $308,$3d2
	dw $308,$917
	dw $308,$3d2
	dw $308,$7a5
	dw $308,$3d2
	dw $308,$917
	dw $308,$3d2
	dw $308,$f4a
	dw $308,$3d2
	dw $308,$917
	dw $308,$3d2
	dw $308,$7a5
	dw $308,$3d2
	dw $308,$917
	dw $308,$3d2
	dw $30b,$0,$0,$f4a
	dw $308,$3d2
	dw $308,$917
	dw $30b,$d9,$1b3,$3d2
	dw $308,$7a5
	dw $30a,$0,$3d2
	dw $30b,$f4,$1e9,$917
	dw $308,$3d2
	dw $30a,$0,$f4a
	dw $30b,$d9,$1b3,$3d2
	dw $308,$917
	dw $30a,$0,$3d2
	dw $30f,$cd,$19b,$c5,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $30b,$0,$cd,$cdc
	dw $30e,$0,$cd,$337
	dw $30c,$0,$7a5
	dw $308,$337
	dw $308,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $30b,$184,$308,$66e
	dw $30b,$19b,$337,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $30b,$0,$0,$7a5
	dw $308,$337
	dw $30b,$134,$268,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $30b,$122,$245,$337
	dw $30b,$112,$225,$7a5
	dw $30b,$0,$0,$337
	dw $30b,$cd,$19b,$66e
	dw $308,$337
	dw $308,$7a5
	dw $308,$337
	dw $308,$cdc
	dw $308,$337
	dw $308,$7a5
	dw $30a,$0,$337
	dw $30b,$122,$225,$917
	dw $30a,$245,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$122f
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$917
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$122f
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$917
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$122f
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $30b,$0,$0,$917
	dw $308,$48b
	dw $308,$ad0
	dw $308,$48b
	dw $308,$122f
	dw $308,$48b
	dw $30b,$f4,$1a1,$ad0
	dw $30b,$ac,$1e9,$48b
	dw $30b,$f4,$1e9,$7a5
	dw $308,$3d2
	dw $308,$917
	dw $308,$3d2
	dw $308,$f4a
	dw $308,$3d2
	dw $308,$917
	dw $308,$3d2
	dw $308,$7a5
	dw $308,$3d2
	dw $308,$917
	dw $308,$3d2
	dw $308,$f4a
	dw $308,$3d2
	dw $308,$917
	dw $308,$3d2
	dw $308,$7a5
	dw $308,$3d2
	dw $308,$917
	dw $308,$3d2
	dw $30b,$0,$0,$f4a
	dw $308,$3d2
	dw $308,$917
	dw $30b,$d9,$1b3,$3d2
	dw $308,$7a5
	dw $30a,$0,$3d2
	dw $30b,$f4,$1e9,$917
	dw $308,$3d2
	dw $30a,$0,$f4a
	dw $30b,$d9,$1b3,$3d2
	dw $308,$917
	dw $30a,$0,$3d2
	dw $327,$cd,$19b,$c5
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $340
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $320
	dw $300
	dw $340
	dw $300
	dw $300
	dw $300
	dw $340
	dw $300
	dw $340
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $340
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $340
	dw $340
	dw $340
	dw $340
	dw $340
	dw $340
	dw $340
	dw $348,$0
	dw $307,$cd,$19b,$c5
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $340
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $320
	dw $300
	dw $340
	dw $300
	dw $300
	dw $300
	dw $340
	dw $300
	dw $340
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $340
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $320
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $340
	dw $340
	dw $300
	dw $340
	dw $340
	dw $300
	dw $340
	dw $340
	dw $32f,$19b,$19b,$66e,$337
	dw $303,$cd,$cd
	dw $30c,$737,$39b
	dw $303,$19b,$19b
	dw $30f,$cd,$cd,$7a5,$3d2
	dw $320
	dw $32f,$19b,$19b,$66e,$337
	dw $323,$cd,$cd
	dw $34c,$737,$39b
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$7a5,$3d2
	dw $300
	dw $32f,$19b,$19b,$66e,$337
	dw $303,$cd,$cd
	dw $32c,$337,$19b
	dw $303,$19b,$19b
	dw $30f,$cd,$cd,$0,$0
	dw $300
	dw $303,$19b,$19b
	dw $303,$cd,$cd
	dw $300
	dw $303,$19b,$19b
	dw $323,$cd,$cd
	dw $300
	dw $343,$19b,$19b
	dw $303,$cd,$cd
	dw $300
	dw $303,$19b,$19b
	dw $343,$cd,$cd
	dw $300
	dw $343,$19b,$19b
	dw $303,$cd,$cd
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $32c,$737,$895
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$7a5,$9a2
	dw $300
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $34c,$737,$895
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$7a5,$9a2
	dw $300
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $32c,$737,$895
	dw $303,$19b,$19b
	dw $30f,$cd,$cd,$66e,$7a5
	dw $300
	dw $30f,$19b,$19b,$337,$3d2
	dw $303,$cd,$cd
	dw $30c,$0,$0
	dw $303,$19b,$19b
	dw $303,$cd,$cd
	dw $300
	dw $343,$337,$337
	dw $343,$19b,$19b
	dw $300
	dw $343,$337,$337
	dw $343,$19b,$19b
	dw $300
	dw $343,$337,$337
	dw $343,$19b,$19b
	dw $32f,$19b,$19b,$7a5,$66e
	dw $303,$cd,$cd
	dw $32c,$895,$737
	dw $303,$19b,$193
	dw $32f,$cd,$cd,$9a2,$7a5
	dw $300
	dw $32f,$19b,$19b,$7a5,$66e
	dw $303,$cd,$cd
	dw $34c,$895,$737
	dw $303,$19b,$193
	dw $32f,$cd,$cd,$9a2,$7a5
	dw $300
	dw $32f,$19b,$19b,$7a5,$66e
	dw $303,$cd,$cd
	dw $32c,$3d2,$337
	dw $303,$19b,$193
	dw $30f,$cd,$cd,$0,$0
	dw $300
	dw $303,$19b,$193
	dw $303,$cd,$cd
	dw $300
	dw $303,$19b,$193
	dw $323,$cd,$cd
	dw $300
	dw $343,$19b,$193
	dw $303,$cd,$cd
	dw $300
	dw $303,$19b,$19b
	dw $303,$cd,$cd
	dw $300
	dw $343,$19b,$19b
	dw $303,$cd,$cd
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $32c,$737,$895
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$7a5,$9a2
	dw $300
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $34c,$737,$895
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$7a5,$9a2
	dw $300
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $32c,$737,$895
	dw $303,$19b,$19b
	dw $30f,$cd,$cd,$66e,$7a5
	dw $300
	dw $30f,$19b,$19b,$337,$3d2
	dw $303,$cd,$cd
	dw $30c,$0,$0
	dw $303,$19b,$19b
	dw $303,$cd,$cd
	dw $300
	dw $343,$337,$32f
	dw $343,$19b,$19b
	dw $300
	dw $303,$337,$32f
	dw $343,$19b,$19b
	dw $300
	dw $343,$337,$32f
	dw $343,$19b,$19b
	dw $32f,$225,$225,$895,$44a
	dw $303,$112,$112
	dw $32c,$9a2,$4d1
	dw $303,$225,$225
	dw $32f,$112,$112,$a34,$51a
	dw $300
	dw $32f,$225,$225,$895,$44a
	dw $303,$112,$112
	dw $34c,$9a2,$4d1
	dw $303,$225,$225
	dw $32f,$112,$112,$a34,$51a
	dw $300
	dw $32f,$225,$225,$895,$44a
	dw $303,$112,$112
	dw $32c,$44a,$225
	dw $303,$225,$225
	dw $30f,$112,$112,$0,$0
	dw $300
	dw $303,$225,$225
	dw $303,$112,$112
	dw $300
	dw $303,$225,$225
	dw $323,$112,$112
	dw $300
	dw $323,$225,$225
	dw $303,$112,$112
	dw $300
	dw $303,$225,$225
	dw $343,$112,$112
	dw $300
	dw $343,$225,$225
	dw $303,$112,$112
	dw $32f,$225,$225,$895,$a34
	dw $303,$112,$112
	dw $32c,$9a2,$b74
	dw $303,$225,$225
	dw $34f,$112,$112,$a34,$cdc
	dw $300
	dw $32f,$225,$225,$895,$a34
	dw $303,$112,$112
	dw $32c,$9a2,$b74
	dw $303,$225,$225
	dw $34f,$112,$112,$a34,$cdc
	dw $300
	dw $32f,$225,$225,$895,$a34
	dw $303,$112,$112
	dw $32c,$9a2,$b74
	dw $303,$225,$225
	dw $32f,$112,$112,$895,$a34
	dw $300
	dw $32f,$225,$225,$9a2,$b74
	dw $303,$112,$112
	dw $34c,$a34,$cdc
	dw $303,$225,$225
	dw $32f,$112,$112,$895,$a34
	dw $300
	dw $34f,$44a,$44a,$9a2,$b74
	dw $303,$225,$225
	dw $34c,$a34,$cdc
	dw $303,$44a,$44a
	dw $34f,$225,$225,$895,$a34
	dw $300
	dw $34f,$44a,$44a,$9a2,$b74
	dw $343,$225,$225
	dw $32f,$19b,$19b,$7a5,$66e
	dw $323,$cd,$cd
	dw $32c,$895,$737
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$9a2,$7a5
	dw $300
	dw $32f,$19b,$19b,$7a5,$66e
	dw $303,$cd,$cd
	dw $34c,$895,$737
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$9a2,$7a5
	dw $300
	dw $32f,$19b,$19b,$7a5,$66e
	dw $303,$cd,$cd
	dw $32c,$3d2,$337
	dw $303,$19b,$19b
	dw $30f,$cd,$cd,$0,$0
	dw $300
	dw $303,$19b,$19b
	dw $303,$cd,$cd
	dw $300
	dw $303,$19b,$19b
	dw $323,$cd,$cd
	dw $300
	dw $343,$19b,$19b
	dw $303,$cd,$cd
	dw $300
	dw $303,$19b,$19b
	dw $343,$cd,$cd
	dw $300
	dw $343,$19b,$19b
	dw $303,$cd,$cd
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $32c,$737,$895
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$7a5,$9a2
	dw $300
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $34c,$737,$895
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$7a5,$9a2
	dw $300
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $32c,$737,$895
	dw $303,$19b,$19b
	dw $30f,$cd,$cd,$66e,$7a5
	dw $300
	dw $30f,$19b,$19b,$337,$3d2
	dw $303,$cd,$cd
	dw $30c,$0,$0
	dw $303,$19b,$19b
	dw $303,$cd,$cd
	dw $300
	dw $343,$337,$337
	dw $343,$19b,$19b
	dw $300
	dw $343,$337,$337
	dw $343,$19b,$19b
	dw $300
	dw $343,$337,$337
	dw $343,$19b,$19b
	dw $32f,$268,$268,$9a2,$4d1
	dw $303,$134,$134
	dw $30c,$ad0,$568
	dw $303,$268,$268
	dw $30f,$134,$134,$b74,$5ba
	dw $320
	dw $32f,$268,$268,$9a2,$4d1
	dw $323,$134,$134
	dw $34c,$ad0,$568
	dw $303,$268,$268
	dw $32f,$134,$134,$b74,$5ba
	dw $300
	dw $32f,$268,$268,$9a2,$4d1
	dw $303,$134,$134
	dw $32c,$ad0,$568
	dw $303,$268,$268
	dw $30f,$134,$134,$9a2,$4d1
	dw $300
	dw $30f,$268,$268,$ad0,$568
	dw $303,$134,$134
	dw $30c,$b74,$5ba
	dw $303,$268,$268
	dw $32f,$134,$134,$9a2,$4d1
	dw $320
	dw $34f,$268,$268,$ad0,$568
	dw $303,$134,$134
	dw $30c,$b74,$5ba
	dw $303,$268,$268
	dw $34f,$134,$134,$9a2,$4d1
	dw $300
	dw $34f,$268,$268,$ad0,$568
	dw $303,$134,$134
	dw $32f,$268,$268,$9a2,$b74
	dw $303,$134,$134
	dw $32c,$ad0,$cdc
	dw $303,$268,$268
	dw $32f,$134,$134,$b74,$e6e
	dw $300
	dw $32f,$268,$268,$9a2,$b74
	dw $303,$134,$134
	dw $34c,$ad0,$cdc
	dw $303,$268,$268
	dw $32f,$134,$134,$b74,$e6e
	dw $300
	dw $32f,$268,$268,$9a2,$b74
	dw $303,$134,$134
	dw $32c,$ad0,$cdc
	dw $303,$268,$268
	dw $30f,$134,$134,$9a2,$b74
	dw $300
	dw $30f,$268,$268,$4d1,$5ba
	dw $303,$134,$134
	dw $30c,$0,$0
	dw $303,$268,$268
	dw $303,$134,$134
	dw $300
	dw $343,$4d1,$4d1
	dw $303,$268,$268
	dw $340
	dw $343,$4d1,$4d1
	dw $343,$268,$268
	dw $300
	dw $343,$4d1,$4d1
	dw $303,$268,$268
	dw $32f,$225,$21d,$a34,$895
	dw $303,$112,$10a
	dw $32c,$b74,$9a2
	dw $303,$225,$21d
	dw $32f,$112,$112,$cdc,$a34
	dw $300
	dw $32f,$225,$21d,$a34,$895
	dw $303,$112,$112
	dw $34c,$b74,$9a2
	dw $303,$225,$21d
	dw $32f,$112,$112,$cdc,$a34
	dw $300
	dw $32f,$225,$21d,$a34,$895
	dw $303,$112,$112
	dw $32c,$b74,$9a2
	dw $303,$225,$225
	dw $30f,$112,$112,$a34,$895
	dw $300
	dw $30f,$225,$225,$b74,$9a2
	dw $303,$112,$112
	dw $30c,$cdc,$a34
	dw $303,$225,$225
	dw $32f,$112,$112,$a34,$895
	dw $300
	dw $34f,$225,$225,$b74,$9a2
	dw $303,$112,$112
	dw $30c,$cdc,$a34
	dw $303,$225,$225
	dw $34f,$112,$112,$a34,$895
	dw $300
	dw $34f,$225,$225,$b74,$9a2
	dw $303,$112,$112
	dw $32f,$225,$215,$895,$a34
	dw $303,$112,$112
	dw $32c,$9a2,$b74
	dw $303,$225,$215
	dw $32f,$112,$112,$a34,$cdc
	dw $300
	dw $32f,$225,$215,$895,$a34
	dw $303,$112,$112
	dw $34c,$9a2,$b74
	dw $303,$225,$215
	dw $32f,$112,$112,$a34,$cdc
	dw $300
	dw $32f,$225,$215,$895,$a34
	dw $303,$112,$112
	dw $32c,$9a2,$b74
	dw $303,$225,$20d
	dw $30f,$112,$112,$895,$a34
	dw $300
	dw $30f,$225,$20d,$44a,$51a
	dw $303,$112,$112
	dw $30c,$0,$0
	dw $303,$225,$20d
	dw $303,$112,$112
	dw $300
	dw $34f,$44a,$66e,$432,$cdc
	dw $34d,$225,$225,$0
	dw $300
	dw $345,$44a,$432
	dw $34f,$225,$7a5,$225,$f4a
	dw $308,$0
	dw $345,$44a,$432
	dw $345,$225,$225
	dw $32f,$19b,$9a2,$19b,$1344
	dw $30d,$cd,$cd,$66e
	dw $30a,$895,$112a
	dw $30d,$19b,$19b,$737
	dw $30f,$cd,$9a2,$cd,$1344
	dw $368,$7a5
	dw $36d,$19b,$19b,$337
	dw $36d,$cd,$cd,$f4a
	dw $348,$39b
	dw $30f,$19b,$19b,$9a2,$f4a
	dw $30b,$cd,$cd,$3d2
	dw $308,$f4a
	dw $36b,$19b,$19b,$337
	dw $303,$cd,$cd
	dw $32c,$737,$39b
	dw $30b,$19b,$19b,$9a2
	dw $30f,$cd,$cd,$66e,$337
	dw $308,$9a2
	dw $30f,$19b,$19b,$737,$39b
	dw $303,$cd,$cd
	dw $30c,$7a5,$3d2
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$66e,$337
	dw $300
	dw $34f,$19b,$19b,$737,$39b
	dw $303,$cd,$cd
	dw $30c,$7a5,$3d2
	dw $303,$19b,$19b
	dw $30f,$cd,$cd,$66e,$337
	dw $300
	dw $34f,$19b,$19b,$737,$cdc
	dw $30b,$cd,$cd,$f4a
	dw $32f,$19b,$b74,$19b,$16e9
	dw $30d,$cd,$cd,$0
	dw $308,$895
	dw $307,$19b,$19b,$b74
	dw $32b,$cd,$cd,$9a2
	dw $300
	dw $32b,$19b,$19b,$7a5
	dw $303,$cd,$cd
	dw $34c,$737,$895
	dw $307,$19b,$19b,$b74
	dw $32f,$cd,$cd,$7a5,$9a2
	dw $308,$b74
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $32c,$737,$895
	dw $303,$19b,$19b
	dw $30f,$cd,$895,$cd,$112a
	dw $308,$0
	dw $30d,$19b,$19b,$895
	dw $305,$cd,$cd
	dw $308,$9a2
	dw $307,$19b,$19b,$895
	dw $30b,$cd,$cd,$7a5
	dw $300
	dw $34f,$337,$337,$737,$895
	dw $347,$19b,$19b,$895
	dw $30c,$7a5,$9a2
	dw $34b,$337,$337,$895
	dw $34f,$19b,$19b,$66e,$7a5
	dw $300
	dw $34f,$337,$337,$737,$895
	dw $343,$19b,$19b
	dw $32f,$28d,$7a5,$28d,$f4a
	dw $30d,$146,$146,$0
	dw $308,$737
	dw $305,$28d,$285
	dw $36d,$146,$146,$7a5
	dw $300
	dw $36d,$28d,$28d,$66e
	dw $305,$146,$146
	dw $348,$737
	dw $305,$28d,$285
	dw $32f,$146,$146,$9a2,$7a5
	dw $300
	dw $32b,$28d,$737,$e6e
	dw $309,$146,$0
	dw $32a,$7a5,$f4a
	dw $30d,$28d,$285,$0
	dw $30d,$146,$146,$66e
	dw $300
	dw $30d,$28d,$285,$737
	dw $305,$146,$146
	dw $308,$7a5
	dw $307,$28d,$285,$7a5
	dw $32b,$146,$146,$66e
	dw $300
	dw $34b,$28d,$285,$737
	dw $303,$146,$146
	dw $308,$7a5
	dw $303,$28d,$28d
	dw $30b,$146,$146,$66e
	dw $300
	dw $34b,$28d,$28d,$737
	dw $303,$146,$146
	dw $32f,$28d,$28d,$66e,$7a5
	dw $303,$146,$146
	dw $32c,$737,$895
	dw $303,$28d,$28d
	dw $32f,$146,$146,$7a5,$9a2
	dw $300
	dw $32f,$28d,$28d,$66e,$7a5
	dw $303,$146,$146
	dw $34c,$737,$895
	dw $303,$28d,$28d
	dw $32f,$146,$146,$7a5,$9a2
	dw $300
	dw $32f,$28d,$28d,$66e,$7a5
	dw $303,$146,$146
	dw $32c,$737,$895
	dw $303,$28d,$28d
	dw $30f,$146,$146,$66e,$7a5
	dw $300
	dw $30f,$28d,$28d,$337,$3d2
	dw $303,$146,$146
	dw $30c,$0,$0
	dw $303,$28d,$28d
	dw $303,$146,$146
	dw $300
	dw $343,$51a,$512
	dw $343,$28d,$28d
	dw $300
	dw $343,$51a,$512
	dw $343,$28d,$28d
	dw $300
	dw $343,$51a,$512
	dw $343,$28d,$28d
	dw $32f,$225,$a34,$225,$1469
	dw $30d,$112,$112,$44a
	dw $30a,$9a2,$1344
	dw $30d,$225,$225,$4d1
	dw $30f,$112,$a34,$112,$1469
	dw $308,$51a
	dw $325,$225,$225
	dw $30d,$112,$112,$44a
	dw $348,$4d1
	dw $307,$225,$225,$a34
	dw $32b,$112,$112,$51a
	dw $300
	dw $32b,$225,$225,$44a
	dw $303,$112,$112
	dw $32c,$0,$a34
	dw $30b,$225,$225,$a34
	dw $30f,$112,$112,$0,$44a
	dw $308,$a34
	dw $30b,$225,$225,$4d1
	dw $303,$112,$112
	dw $308,$51a
	dw $303,$225,$225
	dw $32b,$112,$112,$44a
	dw $300
	dw $34b,$225,$225,$4d1
	dw $303,$112,$112
	dw $308,$51a
	dw $303,$225,$225
	dw $34b,$112,$112,$44a
	dw $300
	dw $34f,$225,$895,$225,$112a
	dw $30d,$112,$112,$4d1
	dw $32f,$225,$cdc,$225,$19b8
	dw $30d,$112,$112,$a34
	dw $308,$b74
	dw $305,$225,$225
	dw $34d,$112,$112,$cdc
	dw $300
	dw $32f,$225,$225,$cdc,$a34
	dw $303,$112,$112
	dw $328,$b74
	dw $303,$225,$225
	dw $30f,$112,$112,$a34,$cdc
	dw $300
	dw $30f,$225,$225,$895,$a34
	dw $30b,$112,$112,$cdc
	dw $32a,$895,$112a
	dw $30d,$225,$225,$b74
	dw $32f,$112,$b74,$112,$16e9
	dw $308,$a34
	dw $30d,$225,$225,$b74
	dw $305,$112,$112
	dw $348,$cdc
	dw $307,$225,$225,$b74
	dw $32b,$112,$112,$a34
	dw $300
	dw $34f,$44a,$44a,$9a2,$b74
	dw $303,$225,$225
	dw $34c,$a34,$cdc
	dw $30b,$44a,$44a,$b74
	dw $34f,$225,$895,$225,$a34
	dw $300
	dw $34f,$44a,$9a2,$44a,$b74
	dw $345,$225,$225
	dw $36f,$19b,$895,$19b,$112a
	dw $36d,$cd,$cd,$66e
	dw $368,$737
	dw $305,$19b,$19b
	dw $32d,$cd,$cd,$7a5
	dw $300
	dw $32d,$19b,$19b,$66e
	dw $305,$cd,$cd
	dw $348,$737
	dw $307,$19b,$19b,$895
	dw $32b,$cd,$cd,$7a5
	dw $300
	dw $32f,$19b,$9a2,$19b,$1344
	dw $30d,$cd,$cd,$66e
	dw $32a,$66e,$cdc
	dw $30d,$19b,$19b,$737
	dw $30d,$cd,$cd,$66e
	dw $300
	dw $30d,$19b,$19b,$737
	dw $305,$cd,$cd
	dw $308,$7a5
	dw $307,$19b,$19b,$66e
	dw $32b,$cd,$cd,$66e
	dw $300
	dw $34b,$19b,$19b,$737
	dw $303,$cd,$cd
	dw $308,$7a5
	dw $303,$19b,$19b
	dw $34b,$cd,$cd,$66e
	dw $300
	dw $34b,$19b,$19b,$737
	dw $303,$cd,$cd
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $32c,$737,$895
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$7a5,$9a2
	dw $300
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $34c,$737,$895
	dw $303,$19b,$19b
	dw $32f,$cd,$cd,$7a5,$9a2
	dw $300
	dw $32f,$19b,$19b,$66e,$7a5
	dw $303,$cd,$cd
	dw $32c,$737,$895
	dw $303,$19b,$19b
	dw $30f,$cd,$cd,$66e,$7a5
	dw $300
	dw $30f,$19b,$19b,$337,$3d2
	dw $303,$cd,$cd
	dw $30c,$0,$0
	dw $303,$19b,$19b
	dw $303,$cd,$cd
	dw $300
	dw $343,$337,$337
	dw $343,$19b,$19b
	dw $300
	dw $343,$337,$337
	dw $343,$19b,$19b
	dw $300
	dw $343,$337,$337
	dw $343,$19b,$19b
	dw $32f,$268,$268,$b74,$16e9
	dw $30b,$134,$134,$4d1
	dw $30c,$ad0,$15a0
	dw $30b,$268,$268,$568
	dw $30f,$134,$134,$b74,$16e9
	dw $328,$5ba
	dw $327,$268,$268,$9a2
	dw $32b,$134,$134,$b74
	dw $34c,$b74,$568
	dw $303,$268,$268
	dw $32f,$134,$134,$ad0,$5ba
	dw $300
	dw $32f,$268,$268,$b74,$4d1
	dw $303,$134,$134
	dw $32c,$9a2,$568
	dw $303,$268,$268
	dw $30f,$134,$134,$e6e,$1cdd
	dw $308,$4d1
	dw $30f,$268,$268,$cdc,$19b8
	dw $30b,$134,$134,$568
	dw $30c,$e6e,$1cdd
	dw $30b,$268,$268,$5ba
	dw $32f,$134,$134,$9a2,$4d1
	dw $320
	dw $34f,$268,$268,$e6e,$568
	dw $303,$134,$134
	dw $30c,$cdc,$5ba
	dw $303,$268,$268
	dw $34f,$134,$134,$e6e,$4d1
	dw $300
	dw $34f,$268,$268,$9a2,$568
	dw $303,$134,$134
	dw $32f,$268,$268,$cdc,$19b8
	dw $30b,$134,$134,$b74
	dw $32c,$b74,$16e9
	dw $30b,$268,$268,$cdc
	dw $32f,$134,$134,$cdc,$19b8
	dw $308,$e6e
	dw $32f,$268,$268,$9a2,$b74
	dw $303,$134,$134
	dw $34c,$cdc,$cdc
	dw $303,$268,$268
	dw $32f,$134,$134,$b74,$e6e
	dw $300
	dw $32f,$268,$268,$cdc,$b74
	dw $303,$134,$134
	dw $32c,$9a2,$cdc
	dw $303,$268,$268
	dw $30f,$134,$134,$b74,$b74
	dw $300
	dw $30f,$268,$268,$ad0,$5ba
	dw $303,$134,$134
	dw $30c,$b74,$0
	dw $303,$268,$268
	dw $307,$134,$134,$9a2
	dw $300
	dw $347,$4d1,$4d1,$b74
	dw $343,$268,$268
	dw $304,$ad0
	dw $343,$4d1,$4d1
	dw $347,$268,$268,$b74
	dw $300
	dw $347,$4d1,$4d1,$895
	dw $343,$268,$268
	dw $32f,$225,$21d,$a34,$1469
	dw $30b,$112,$10a,$895
	dw $32c,$9a2,$1344
	dw $30b,$225,$21d,$9a2
	dw $32f,$112,$112,$a34,$1469
	dw $308,$a34
	dw $327,$225,$21d,$895
	dw $30b,$112,$112,$895
	dw $34c,$a34,$1469
	dw $30b,$225,$21d,$9a2
	dw $32f,$112,$112,$9a2,$1344
	dw $308,$a34
	dw $32f,$225,$21d,$a34,$1469
	dw $30b,$112,$112,$895
	dw $324,$895
	dw $30b,$225,$225,$9a2
	dw $30f,$112,$112,$cdc,$19b8
	dw $308,$895
	dw $30f,$225,$225,$b74,$16e9
	dw $30b,$112,$112,$9a2
	dw $30c,$cdc,$19b8
	dw $30b,$225,$225,$a34
	dw $327,$112,$112,$895
	dw $308,$895
	dw $34f,$225,$225,$cdc,$19b8
	dw $30b,$112,$112,$9a2
	dw $30c,$b74,$16e9
	dw $30b,$225,$225,$a34
	dw $34f,$112,$112,$cdc,$19b8
	dw $308,$895
	dw $347,$225,$225,$895
	dw $30b,$112,$112,$9a2
	dw $32f,$225,$215,$b74,$16e9
	dw $30b,$112,$112,$a34
	dw $32c,$a34,$1469
	dw $30b,$225,$215,$b74
	dw $32f,$112,$112,$b74,$16e9
	dw $308,$cdc
	dw $327,$225,$215,$895
	dw $30b,$112,$112,$a34
	dw $34c,$b74,$16e9
	dw $30b,$225,$215,$b74
	dw $32f,$112,$112,$a34,$1469
	dw $308,$cdc
	dw $32f,$225,$215,$b74,$16e9
	dw $30b,$112,$112,$a34
	dw $324,$895
	dw $30b,$225,$20d,$b74
	dw $30f,$112,$112,$a34,$1469
	dw $308,$a34
	dw $30f,$225,$20d,$9a2,$1344
	dw $30b,$112,$112,$51a
	dw $30c,$a34,$1469
	dw $30b,$225,$20d,$0
	dw $307,$112,$112,$895
	dw $300
	dw $34f,$44a,$432,$a34,$1469
	dw $34b,$225,$225,$0
	dw $30c,$9a2,$1344
	dw $30b,$44a,$432,$0
	dw $34f,$225,$225,$a34,$1469
	dw $308,$0
	dw $347,$44a,$432,$895
	dw $303,$225,$225
	dw $36f,$cd,$19b,$193,$7a5
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $369,$0,$0
	dw $303,$0,$0
	dw $306,$0,$0
	dw $304,$0
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $200
	dw $227,$cd,$19b,$c5
	dw $220
	dw $400
	dw $220
	dw $220
	dw $400
	dw $227,$0,$0,$0
	dw $220
	dw $407,$cd,$19b,$c5
	dw $220
	dw $220
	dw $400
	dw $220
	dw $220
	dw $402,$0
	dw $224,$0
	dw $227,$cd,$19b,$c5
	dw $400
	dw $35f,$0,$0,$0,$7a5,RLC_H
	dw $308,$7a5
	dw $318,$0,NOP_2
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $200
	dw $208,$0
	dw $36f,$337,$66e,$32f,$0
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $360
	dw $361,$0
	dw $302,$0
	dw $304,$0
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $300
	dw $227,$895,$112a,$88d
	dw $223,$917,$122f
	dw $403,$0,$0
	dw $227,$895,$112a,$88d
	dw $223,$917,$122f
	dw $403,$0,$0
	dw $227,$895,$112a,$88d
	dw $223,$917,$122f
	dw $403,$0,$0
	dw $227,$895,$112a,$88d
	dw $223,$917,$122f
	dw $403,$0,$0
	dw $227,$895,$112a,$88d
	dw $223,$917,$122f
	dw $403,$0,$0
	dw $227,$895,$112a,$88d
	dw $223,$917,$122f
	dw $403,$0,$0
	dw $31f,$0,$183e,$0,$7a5,RLC_H
	dw $30a,$183e,$7a5
	dw $31e,$1836,$19b8,$0,NOP_2
	dw $306,$1836,$19b8
	dw $306,$182e,$19b8
	dw $306,$182e,$19b8
	dw $306,$1826,$19b8
	dw $306,$1826,$19b8
	dw $306,$181e,$19b8
	dw $306,$181e,$19b8
	dw $346,$1816,$19b8
	dw $346,$1816,$19b8
	dw $346,$180e,$19b8
	dw $346,$180e,$19b8
	dw $346,$1806,$19b8
	dw $346,$1806,$19b8
	dw $346,$17fe,$19b8
	dw $34e,$17fe,$19b8,$0
	dw $42f,$19b,$193,$0,$19b8
	dw $403,$cd,$c5
	dw $400
	dw $403,$19b,$193
	dw $403,$cd,$c5
	dw $400
	dw $463,$19b,$193
	dw $463,$cd,$c5
	dw $443,$19b,$193
	dw $403,$cd,$c5
	dw $400
	dw $403,$19b,$193
	dw $403,$cd,$c5
	dw $400
	dw $403,$19b,$193
	dw $403,$cd,$c5
	dw $423,$0,$0
	dw $400
	dw $400
	dw $500
	dw $303,$19b,$19b
	dw $403,$cd,$cd
	dw $423,$19b,$19b
	dw $403,$cd,$cd
	dw $443,$19b,$19b
	dw $403,$cd,$cd
	dw $408,$1846
	dw $44b,$19b,$19b,$16e9
	dw $40b,$cd,$cd,$15a0
	dw $408,$1469
	dw $44b,$19b,$19b,$1344
	dw $40b,$cd,$cd,$f4a
	dw $842b,$19b,$19b,$cdc,$720
	dw $8403,$cd,$cd,$720
	dw $8400,$720
	dw $8403,$19b,$19b,$720
	dw $8403,$cd,$cd,$720
	dw $8400,$720
	dw $8423,$19b,$19b,$720
	dw $8423,$cd,$cd,$720
	dw $8443,$19b,$19b,$720
	dw $8403,$cd,$cd,$720
	dw $8400,$720
	dw $8403,$19b,$19b,$720
	dw $8403,$cd,$cd,$720
	dw $8400,$720
	dw $8443,$19b,$19b,$720
	dw $8403,$cd,$cd,$720
	dw $8423,$0,$0,$720
	dw $8400,$720
	dw $8400,$720
	dw $8500,$720
	dw $8323,$19b,$19b,$720
	dw $8403,$cd,$cd,$720
	dw $8423,$19b,$19b,$720
	dw $8403,$cd,$cd,$720
	dw $8447,$19b,$19b,$d9f,$720
	dw $8407,$cd,$cd,$e6e,$720
	dw $8404,$f4a,$720
	dw $8447,$19b,$19b,$1033,$720
	dw $8407,$cd,$cd,$112a,$720
	dw $8404,$122f,$720
	dw $8447,$19b,$19b,$1344,$720
	dw $8447,$cd,$cd,$15a0,$720
	dw $42f,$19b,$19b,$16e9,$19b8
	dw $403,$cd,$cd
	dw $400
	dw $403,$19b,$19b
	dw $403,$cd,$cd
	dw $400
	dw $463,$19b,$19b
	dw $463,$cd,$cd
	dw $443,$19b,$19b
	dw $403,$cd,$cd
	dw $400
	dw $403,$19b,$19b
	dw $403,$cd,$cd
	dw $400
	dw $403,$19b,$19b
	dw $403,$cd,$cd
	dw $423,$0,$0
	dw $400
	dw $400
	dw $500
	dw $303,$193,$19b
	dw $403,$c5,$cd
	dw $423,$193,$19b
	dw $403,$c5,$cd
	dw $443,$193,$19b
	dw $403,$c5,$cd
	dw $408,$1846
	dw $44b,$193,$19b,$16e9
	dw $40b,$c5,$cd,$15a0
	dw $408,$1469
	dw $44b,$193,$19b,$1344
	dw $40b,$c5,$cd,$f4a
	dw $842b,$19b,$19b,$cdc,$540
	dw $8403,$cd,$cd,$540
	dw $8400,$540
	dw $8403,$19b,$19b,$540
	dw $8403,$cd,$cd,$540
	dw $8400,$540
	dw $8423,$19b,$19b,$540
	dw $8423,$cd,$cd,$540
	dw $8443,$19b,$19b,$540
	dw $8403,$cd,$cd,$540
	dw $8400,$540
	dw $8403,$19b,$19b,$540
	dw $8403,$cd,$cd,$540
	dw $8400,$540
	dw $8443,$19b,$19b,$540
	dw $8403,$cd,$cd,$540
	dw $8423,$0,$0,$540
	dw $8400,$540
	dw $8400,$540
	dw $8500,$540
	dw $8323,$19b,$19b,$540
	dw $8403,$cd,$cd,$540
	dw $8423,$19b,$19b,$540
	dw $8403,$cd,$cd,$540
	dw $8443,$19b,$19b,$540
	dw $840b,$cd,$cd,$d9f,$540
	dw $8408,$e6e,$540
	dw $844b,$19b,$19b,$f4a,$540
	dw $840b,$cd,$cd,$1033,$540
	dw $8408,$112a,$540
	dw $844b,$19b,$19b,$122f,$540
	dw $844b,$cd,$cd,$1344,$540
	dw $42f,$19b,$19b,$1469,$19b8
	dw $403,$cd,$cd
	dw $400
	dw $403,$19b,$19b
	dw $403,$cd,$cd
	dw $400
	dw $463,$19b,$19b
	dw $463,$cd,$cd
	dw $443,$19b,$19b
	dw $403,$cd,$cd
	dw $400
	dw $403,$19b,$19b
	dw $403,$cd,$cd
	dw $400
	dw $403,$19b,$19b
	dw $403,$cd,$cd
	dw $423,$0,$0
	dw $400
	dw $400
	dw $500
	dw $303,$19b,$19b
	dw $403,$cd,$cd
	dw $423,$19b,$19b
	dw $403,$cd,$cd
	dw $443,$19b,$19b
	dw $403,$cd,$cd
	dw $408,$1846
	dw $44b,$19b,$19b,$16e9
	dw $40b,$cd,$cd,$15a0
	dw $408,$1469
	dw $44b,$19b,$19b,$1344
	dw $40b,$cd,$cd,$f4a
	dw $842b,$19b,$19b,$cdc,$380
	dw $8403,$cd,$cd,$380
	dw $8400,$380
	dw $8403,$19b,$19b,$380
	dw $8403,$cd,$cd,$380
	dw $8400,$380
	dw $8423,$19b,$19b,$380
	dw $8423,$cd,$cd,$380
	dw $8443,$19b,$19b,$380
	dw $8403,$cd,$cd,$380
	dw $8400,$380
	dw $8403,$19b,$19b,$380
	dw $8403,$cd,$cd,$380
	dw $8400,$380
	dw $8443,$19b,$19b,$380
	dw $8403,$cd,$cd,$380
	dw $8423,$0,$0,$380
	dw $8400,$380
	dw $8400,$380
	dw $8500,$380
	dw $8323,$19b,$19b,$380
	dw $8403,$cd,$cd,$380
	dw $8423,$19b,$19b,$380
	dw $8403,$cd,$cd,$380
	dw $8443,$19b,$19b,$380
	dw $8403,$cd,$cd,$380
	dw $8408,$d9f,$380
	dw $844b,$19b,$19b,$e6e,$380
	dw $840b,$cd,$cd,$f4a,$380
	dw $8408,$1033,$380
	dw $844b,$19b,$19b,$112a,$380
	dw $844b,$cd,$cd,$122f,$380
	dw $42f,$19b,$19b,$1344,$19b8
	dw $403,$cd,$cd
	dw $400
	dw $403,$19b,$19b
	dw $403,$cd,$cd
	dw $400
	dw $463,$19b,$19b
	dw $463,$cd,$cd
	dw $443,$19b,$19b
	dw $403,$cd,$cd
	dw $400
	dw $403,$19b,$19b
	dw $403,$cd,$cd
	dw $400
	dw $403,$19b,$19b
	dw $403,$cd,$cd
	dw $423,$0,$0
	dw $400
	dw $400
	dw $500
	dw $303,$19b,$19b
	dw $403,$cd,$cd
	dw $423,$19b,$19b
	dw $403,$cd,$cd
	dw $443,$19b,$19b
	dw $403,$cd,$cd
	dw $408,$1846
	dw $44b,$19b,$19b,$16e9
	dw $40b,$cd,$cd,$15a0
	dw $408,$1469
	dw $44b,$19b,$19b,$1344
	dw $40b,$cd,$cd,$f4a
	dw $842b,$19b,$19b,$cdc,$120
	dw $8403,$cd,$cd,$120
	dw $8400,$120
	dw $8403,$19b,$19b,$120
	dw $8403,$cd,$cd,$120
	dw $8400,$120
	dw $8423,$19b,$19b,$120
	dw $8423,$cd,$cd,$120
	dw $8443,$19b,$19b,$120
	dw $8403,$cd,$cd,$120
	dw $8400,$120
	dw $8403,$19b,$19b,$120
	dw $8403,$cd,$cd,$120
	dw $8400,$120
	dw $8443,$19b,$19b,$120
	dw $8403,$cd,$cd,$120
	dw $8423,$0,$0,$120
	dw $8400,$120
	dw $8400,$120
	dw $8500,$120
	dw $8323,$19b,$19b,$120
	dw $8403,$cd,$cd,$120
	dw $8423,$19b,$19b,$120
	dw $8403,$cd,$cd,$120
	dw $8443,$19b,$19b,$120
	dw $8403,$cd,$cd,$120
	dw $8400,$120
	dw $8443,$19b,$19b,$120
	dw $8403,$cd,$cd,$120
	dw $8400,$120
	dw $8443,$19b,$19b,$120
	dw $8443,$cd,$cd,$120
	dw $227,$19b,$193,$1344
	dw $204,$9a2
	dw $20f,$cd,$c5,$f4a,$0
	dw $20c,$7a5,$1344
	dw $20c,$cdc,$0
	dw $20c,$66e,$f4a
	dw $20f,$19b,$193,$f4a,$0
	dw $20c,$7a5,$cdc
	dw $20f,$cd,$c5,$1469,$0
	dw $20c,$a34,$f4a
	dw $20c,$f4a,$0
	dw $20c,$7a5,$1469
	dw $26f,$19b,$193,$cdc,$0
	dw $20c,$66e,$f4a
	dw $26f,$cd,$c5,$f4a,$0
	dw $20c,$7a5,$cdc
	dw $24f,$19b,$193,$1344,$0
	dw $20c,$9a2,$f4a
	dw $20f,$cd,$c5,$f4a,$0
	dw $20c,$7a5,$1344
	dw $20c,$cdc,$0
	dw $20c,$66e,$f4a
	dw $20f,$19b,$193,$f4a,$0
	dw $20c,$7a5,$cdc
	dw $20f,$cd,$c5,$112a,$0
	dw $20c,$895,$f4a
	dw $20c,$f4a,$0
	dw $20c,$7a5,$112a
	dw $20f,$19b,$193,$cdc,$0
	dw $20c,$66e,$f4a
	dw $20f,$cd,$c5,$f4a,$0
	dw $20c,$7a5,$cdc
	dw $22f,$0,$0,$1344,$0
	dw $20c,$9a2,$f4a
	dw $20c,$f4a,$0
	dw $20c,$7a5,$1344
	dw $20c,$cdc,$0
	dw $20c,$66e,$f4a
	dw $20c,$f4a,$0
	dw $20c,$7a5,$cdc
	dw $20f,$19b,$19b,$1469,$0
	dw $20c,$a34,$f4a
	dw $20f,$cd,$cd,$f4a,$0
	dw $20c,$7a5,$1469
	dw $22f,$19b,$19b,$cdc,$0
	dw $20c,$66e,$f4a
	dw $20f,$cd,$cd,$f4a,$0
	dw $20c,$7a5,$cdc
	dw $24f,$19b,$19b,$1344,$0
	dw $20c,$9a2,$f4a
	dw $20f,$cd,$cd,$f4a,$0
	dw $20c,$7a5,$1344
	dw $20c,$cdc,$0
	dw $20c,$66e,$f4a
	dw $24f,$19b,$19b,$f4a,$0
	dw $20c,$7a5,$cdc
	dw $20f,$cd,$cd,$112a,$0
	dw $20c,$895,$f4a
	dw $20c,$f4a,$0
	dw $20c,$7a5,$112a
	dw $24f,$19b,$19b,$cdc,$0
	dw $20c,$66e,$f4a
	dw $20f,$cd,$cd,$f4a,$0
	dw $20c,$7a5,$cdc
	dw $822f,$19b,$19b,$f4a,$0,$720
	dw $208,$f4a
	dw $820f,$cd,$cd,$cdc,$0,$720
	dw $208,$f4a
	dw $820c,$9a2,$0,$720
	dw $208,$cdc
	dw $820f,$19b,$19b,$cdc,$0,$720
	dw $208,$9a2
	dw $820f,$cd,$cd,$112a,$0,$720
	dw $208,$cdc
	dw $820c,$cdc,$0,$720
	dw $208,$112a
	dw $822f,$19b,$19b,$9a2,$0,$720
	dw $208,$cdc
	dw $822f,$cd,$cd,$cdc,$0,$720
	dw $208,$9a2
	dw $824f,$19b,$19b,$f4a,$0,$720
	dw $208,$cdc
	dw $820f,$cd,$cd,$cdc,$0,$720
	dw $208,$f4a
	dw $820c,$9a2,$0,$720
	dw $208,$cdc
	dw $820f,$19b,$19b,$cdc,$0,$720
	dw $208,$9a2
	dw $820f,$cd,$cd,$e6e,$0,$720
	dw $208,$cdc
	dw $820c,$cdc,$0,$720
	dw $208,$e6e
	dw $824f,$19b,$19b,$9a2,$0,$720
	dw $208,$cdc
	dw $820f,$cd,$cd,$cdc,$0,$720
	dw $208,$9a2
	dw $822f,$0,$0,$f4a,$0,$720
	dw $208,$cdc
	dw $820c,$cdc,$0,$720
	dw $208,$f4a
	dw $820c,$9a2,$0,$720
	dw $208,$cdc
	dw $820c,$cdc,$0,$720
	dw $208,$9a2
	dw $822f,$19b,$19b,$112a,$0,$720
	dw $208,$cdc
	dw $820f,$cd,$cd,$cdc,$0,$720
	dw $208,$112a
	dw $822f,$19b,$19b,$9a2,$0,$720
	dw $208,$cdc
	dw $820f,$cd,$cd,$cdc,$0,$720
	dw $208,$9a2
	dw $824f,$19b,$19b,$f4a,$0,$720
	dw $208,$cdc
	dw $820f,$cd,$cd,$cdc,$0,$720
	dw $208,$f4a
	dw $820c,$9a2,$0,$720
	dw $208,$cdc
	dw $824f,$19b,$19b,$cdc,$0,$720
	dw $208,$9a2
	dw $820f,$cd,$cd,$e6e,$0,$720
	dw $208,$cdc
	dw $820c,$cdc,$0,$720
	dw $208,$e6e
	dw $824f,$19b,$19b,$9a2,$0,$720
	dw $208,$cdc
	dw $824f,$cd,$cd,$cdc,$0,$720
	dw $208,$9a2
	dw $22f,$19b,$19b,$cdc,$0
	dw $20c,$66e,$cdc
	dw $20f,$cd,$cd,$9a2,$0
	dw $20c,$4d1,$cdc
	dw $20c,$7a5,$0
	dw $20c,$3d2,$9a2
	dw $20f,$19b,$19b,$9a2,$0
	dw $20c,$4d1,$7a5
	dw $20f,$cd,$cd,$e6e,$0
	dw $20c,$737,$9a2
	dw $20c,$9a2,$0
	dw $20c,$4d1,$e6e
	dw $26f,$19b,$19b,$7a5,$0
	dw $20c,$3d2,$9a2
	dw $26f,$cd,$cd,$9a2,$0
	dw $20c,$4d1,$7a5
	dw $24f,$19b,$19b,$f4a,$0
	dw $20c,$7a5,$9a2
	dw $20f,$cd,$cd,$9a2,$0
	dw $20c,$4d1,$f4a
	dw $20c,$7a5,$0
	dw $20c,$3d2,$9a2
	dw $20f,$19b,$19b,$9a2,$0
	dw $20c,$4d1,$7a5
	dw $20f,$cd,$cd,$112a,$0
	dw $20c,$895,$9a2
	dw $20c,$9a2,$0
	dw $20c,$4d1,$112a
	dw $20f,$19b,$19b,$7a5,$0
	dw $20c,$3d2,$9a2
	dw $20f,$cd,$cd,$9a2,$0
	dw $20c,$4d1,$7a5
	dw $22f,$0,$0,$1344,$0
	dw $20c,$9a2,$9a2
	dw $20c,$9a2,$0
	dw $20c,$4d1,$1344
	dw $20c,$7a5,$0
	dw $20c,$3d2,$9a2
	dw $20c,$9a2,$0
	dw $20c,$4d1,$7a5
	dw $20f,$193,$19b,$112a,$0
	dw $20c,$895,$9a2
	dw $20f,$c5,$cd,$9a2,$0
	dw $20c,$4d1,$112a
	dw $22f,$193,$19b,$7a5,$0
	dw $20c,$3d2,$9a2
	dw $20f,$c5,$cd,$9a2,$0
	dw $20c,$4d1,$7a5
	dw $24f,$193,$19b,$f4a,$0
	dw $20c,$7a5,$9a2
	dw $20f,$c5,$cd,$9a2,$0
	dw $20c,$4d1,$f4a
	dw $20c,$7a5,$0
	dw $20c,$3d2,$9a2
	dw $24f,$193,$19b,$9a2,$0
	dw $20c,$4d1,$7a5
	dw $20f,$c5,$cd,$e6e,$0
	dw $20c,$737,$9a2
	dw $20c,$9a2,$0
	dw $20c,$4d1,$e6e
	dw $24f,$193,$19b,$7a5,$0
	dw $20c,$3d2,$9a2
	dw $20f,$c5,$cd,$9a2,$0
	dw $20c,$4d1,$7a5
	dw $822f,$19b,$19b,$cdc,$0,$540
	dw $20c,$66e,$9a2
	dw $820f,$cd,$cd,$a34,$0,$540
	dw $20c,$51a,$cdc
	dw $820c,$895,$0,$540
	dw $20c,$44a,$a34
	dw $820f,$19b,$19b,$a34,$0,$540
	dw $20c,$51a,$895
	dw $820f,$cd,$cd,$e6e,$0,$540
	dw $20c,$737,$a34
	dw $820c,$a34,$0,$540
	dw $20c,$51a,$e6e
	dw $822f,$19b,$19b,$895,$0,$540
	dw $20c,$44a,$a34
	dw $822f,$cd,$cd,$a34,$0,$540
	dw $20c,$51a,$895
	dw $824f,$19b,$19b,$f4a,$0,$540
	dw $20c,$7a5,$a34
	dw $820f,$cd,$cd,$a34,$0,$540
	dw $20c,$51a,$f4a
	dw $820c,$895,$0,$540
	dw $20c,$44a,$a34
	dw $820f,$19b,$19b,$a34,$0,$540
	dw $20c,$51a,$895
	dw $820f,$cd,$cd,$112a,$0,$540
	dw $20c,$895,$a34
	dw $820c,$a34,$0,$540
	dw $20c,$51a,$112a
	dw $824f,$19b,$19b,$895,$0,$540
	dw $20c,$44a,$a34
	dw $820f,$cd,$cd,$a34,$0,$540
	dw $20c,$51a,$895
	dw $822f,$0,$0,$1344,$0,$540
	dw $20c,$9a2,$a34
	dw $820c,$a34,$0,$540
	dw $20c,$51a,$1344
	dw $820c,$895,$0,$540
	dw $20c,$44a,$a34
	dw $820c,$a34,$0,$540
	dw $20c,$51a,$895
	dw $822f,$19b,$19b,$112a,$0,$540
	dw $20c,$895,$a34
	dw $820f,$cd,$cd,$a34,$0,$540
	dw $20c,$51a,$112a
	dw $822f,$19b,$19b,$895,$0,$540
	dw $20c,$44a,$a34
	dw $820f,$cd,$cd,$a34,$0,$540
	dw $20c,$51a,$895
	dw $824f,$19b,$19b,$f4a,$0,$540
	dw $20c,$7a5,$a34
	dw $820f,$cd,$cd,$a34,$0,$540
	dw $20c,$51a,$f4a
	dw $820c,$895,$0,$540
	dw $20c,$44a,$a34
	dw $824f,$19b,$19b,$a34,$0,$540
	dw $20c,$51a,$895
	dw $820f,$cd,$cd,$e6e,$0,$540
	dw $20c,$737,$a34
	dw $820c,$a34,$0,$540
	dw $20c,$51a,$e6e
	dw $824f,$19b,$19b,$895,$0,$540
	dw $20c,$44a,$a34
	dw $824f,$cd,$cd,$a34,$0,$540
	dw $20c,$51a,$895
	dw $22f,$19b,$19b,$1469,$0
	dw $20c,$a34,$a34
	dw $20f,$cd,$cd,$1344,$0
	dw $204,$9a2
	dw $204,$1469
	dw $204,$a34
	dw $203,$19b,$19b
	dw $200
	dw $203,$cd,$cd
	dw $200
	dw $200
	dw $200
	dw $263,$19b,$19b
	dw $200
	dw $263,$cd,$cd
	dw $200
	dw $24b,$19b,$19b,$1469
	dw $208,$a34
	dw $20b,$cd,$cd,$1344
	dw $208,$9a2
	dw $208,$1469
	dw $208,$a34
	dw $203,$19b,$19b
	dw $200
	dw $203,$cd,$cd
	dw $200
	dw $200
	dw $200
	dw $203,$19b,$19b
	dw $200
	dw $207,$cd,$cd,$112a
	dw $204,$895
	dw $227,$0,$0,$19b8
	dw $204,$cdc
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $203,$19b,$19b
	dw $200
	dw $203,$cd,$cd
	dw $200
	dw $223,$19b,$19b
	dw $200
	dw $20f,$cd,$cd,$112a,$112a
	dw $20c,$895,$895
	dw $24f,$19b,$19b,$16e9,$19b8
	dw $20c,$b74,$cdc
	dw $203,$cd,$cd
	dw $200
	dw $200
	dw $200
	dw $243,$19b,$19b
	dw $200
	dw $203,$cd,$cd
	dw $200
	dw $200
	dw $200
	dw $243,$19b,$19b
	dw $208,$112a
	dw $20b,$cd,$cd,$895
	dw $208,$16e9
	dw $822f,$19b,$19b,$1344,$b74,$380
	dw $204,$9a2
	dw $8207,$cd,$cd,$112a,$380
	dw $204,$895
	dw $8204,$1344,$380
	dw $204,$9a2
	dw $8203,$19b,$19b,$380
	dw $200
	dw $8203,$cd,$cd,$380
	dw $200
	dw $8200,$380
	dw $200
	dw $8223,$19b,$19b,$380
	dw $200
	dw $8223,$cd,$cd,$380
	dw $200
	dw $824b,$19b,$19b,$1344,$380
	dw $208,$9a2
	dw $820b,$cd,$cd,$112a,$380
	dw $208,$895
	dw $8208,$1344,$380
	dw $208,$9a2
	dw $8203,$19b,$19b,$380
	dw $200
	dw $8203,$cd,$cd,$380
	dw $200
	dw $8200,$380
	dw $200
	dw $8247,$19b,$19b,$112a,$380
	dw $204,$895
	dw $8207,$cd,$cd,$1344,$380
	dw $204,$9a2
	dw $8227,$0,$0,$cdc,$380
	dw $204,$66e
	dw $8200,$380
	dw $200
	dw $8200,$380
	dw $200
	dw $8200,$380
	dw $200
	dw $8223,$19b,$19b,$380
	dw $200
	dw $8203,$cd,$cd,$380
	dw $200
	dw $822b,$19b,$19b,$112a,$380
	dw $208,$895
	dw $820b,$cd,$cd,$1344,$380
	dw $208,$9a2
	dw $824b,$19b,$19b,$cdc,$380
	dw $208,$66e
	dw $8203,$cd,$cd,$380
	dw $200
	dw $8200,$380
	dw $200
	dw $8243,$19b,$19b,$380
	dw $200
	dw $8203,$cd,$cd,$380
	dw $200
	dw $8200,$380
	dw $200
	dw $8243,$19b,$19b,$380
	dw $200
	dw $8243,$cd,$cd,$380
	dw $200
	dw $227,$19b,$19b,$b74
	dw $200
	dw $207,$cd,$cd,$cdc
	dw $200
	dw $204,$f4a
	dw $200
	dw $207,$19b,$19b,$112a
	dw $200
	dw $207,$cd,$cd,$b74
	dw $200
	dw $204,$cdc
	dw $200
	dw $267,$19b,$19b,$f4a
	dw $200
	dw $267,$cd,$cd,$112a
	dw $200
	dw $247,$19b,$19b,$b74
	dw $200
	dw $207,$cd,$cd,$cdc
	dw $200
	dw $204,$f4a
	dw $200
	dw $207,$19b,$19b,$112a
	dw $200
	dw $207,$cd,$cd,$b74
	dw $200
	dw $204,$cdc
	dw $200
	dw $207,$19b,$19b,$f4a
	dw $200
	dw $207,$cd,$cd,$112a
	dw $200
	dw $227,$0,$0,$b74
	dw $200
	dw $204,$cdc
	dw $200
	dw $204,$f4a
	dw $200
	dw $204,$112a
	dw $200
	dw $207,$19b,$19b,$b74
	dw $200
	dw $207,$cd,$cd,$cdc
	dw $200
	dw $227,$19b,$19b,$f4a
	dw $200
	dw $207,$cd,$cd,$112a
	dw $200
	dw $247,$19b,$19b,$b74
	dw $200
	dw $207,$cd,$cd,$cdc
	dw $200
	dw $204,$f4a
	dw $200
	dw $247,$19b,$19b,$112a
	dw $200
	dw $207,$cd,$cd,$b74
	dw $200
	dw $204,$cdc
	dw $200
	dw $247,$19b,$19b,$f4a
	dw $200
	dw $207,$cd,$cd,$112a
	dw $200
	dw $8227,$19b,$19b,$cdc,$320
	dw $200
	dw $8207,$cd,$cd,$e6e,$320
	dw $200
	dw $8204,$f4a,$320
	dw $200
	dw $8207,$19b,$19b,$112a,$320
	dw $200
	dw $8207,$cd,$cd,$cdc,$320
	dw $200
	dw $8204,$e6e,$320
	dw $200
	dw $8227,$19b,$19b,$f4a,$320
	dw $200
	dw $8227,$cd,$cd,$112a,$320
	dw $200
	dw $8247,$19b,$19b,$cdc,$320
	dw $200
	dw $8207,$cd,$cd,$e6e,$320
	dw $200
	dw $8204,$f4a,$320
	dw $200
	dw $8207,$19b,$19b,$112a,$320
	dw $200
	dw $8207,$cd,$cd,$cdc,$320
	dw $200
	dw $8204,$e6e,$320
	dw $200
	dw $8247,$19b,$19b,$f4a,$320
	dw $200
	dw $8207,$cd,$cd,$112a,$320
	dw $200
	dw $8227,$0,$0,$cdc,$320
	dw $200
	dw $8204,$e6e,$320
	dw $200
	dw $8204,$f4a,$320
	dw $200
	dw $8204,$112a,$320
	dw $200
	dw $8227,$19b,$19b,$cdc,$320
	dw $200
	dw $8207,$cd,$cd,$e6e,$320
	dw $200
	dw $8227,$19b,$19b,$f4a,$320
	dw $200
	dw $8207,$cd,$cd,$112a,$320
	dw $200
	dw $8247,$19b,$19b,$cdc,$320
	dw $200
	dw $8207,$cd,$cd,$e6e,$320
	dw $200
	dw $8204,$f4a,$320
	dw $200
	dw $8247,$19b,$19b,$112a,$320
	dw $200
	dw $8207,$cd,$cd,$cdc,$320
	dw $200
	dw $8204,$e6e,$320
	dw $200
	dw $8247,$19b,$19b,$f4a,$320
	dw $200
	dw $8247,$cd,$cd,$112a,$320
	dw $200
	dw $8227,$19b,$19b,$f4a,$340
	dw $200
	dw $8207,$cd,$cd,$112a,$340
	dw $200
	dw $8204,$1344,$340
	dw $200
	dw $8207,$19b,$19b,$1469,$340
	dw $200
	dw $8207,$cd,$cd,$f4a,$340
	dw $200
	dw $8204,$112a,$340
	dw $200
	dw $8267,$19b,$19b,$1344,$340
	dw $200
	dw $8267,$cd,$cd,$1469,$340
	dw $200
	dw $8247,$19b,$19b,$f4a,$340
	dw $200
	dw $8207,$cd,$cd,$112a,$340
	dw $200
	dw $8204,$1344,$340
	dw $200
	dw $8207,$19b,$19b,$1469,$340
	dw $200
	dw $8207,$cd,$cd,$f4a,$340
	dw $200
	dw $8204,$112a,$340
	dw $200
	dw $8207,$19b,$19b,$1344,$340
	dw $200
	dw $8207,$cd,$cd,$1469,$340
	dw $200
	dw $8227,$0,$0,$f4a,$340
	dw $200
	dw $8204,$112a,$340
	dw $200
	dw $8204,$1344,$340
	dw $200
	dw $8204,$1469,$340
	dw $200
	dw $8207,$19b,$19b,$f4a,$340
	dw $200
	dw $8207,$cd,$cd,$112a,$340
	dw $200
	dw $8227,$19b,$19b,$1344,$340
	dw $200
	dw $8207,$cd,$cd,$1469,$340
	dw $200
	dw $8247,$19b,$19b,$f4a,$340
	dw $200
	dw $8207,$cd,$cd,$112a,$340
	dw $200
	dw $8204,$1344,$340
	dw $200
	dw $8247,$19b,$19b,$1469,$340
	dw $200
	dw $8207,$cd,$cd,$f4a,$340
	dw $200
	dw $8204,$112a,$340
	dw $200
	dw $8247,$19b,$19b,$1344,$340
	dw $200
	dw $8207,$cd,$cd,$1469,$340
	dw $200
	dw $8227,$19b,$19b,$1344,$380
	dw $200
	dw $8207,$cd,$cd,$1469,$380
	dw $200
	dw $8204,$1846,$380
	dw $200
	dw $8207,$19b,$19b,$19b8,$380
	dw $200
	dw $8207,$cd,$cd,$1344,$380
	dw $200
	dw $8204,$1469,$380
	dw $200
	dw $8227,$19b,$19b,$1846,$380
	dw $200
	dw $8227,$cd,$cd,$19b8,$380
	dw $200
	dw $8247,$19b,$19b,$1344,$380
	dw $200
	dw $8207,$cd,$cd,$1469,$380
	dw $200
	dw $8204,$1846,$380
	dw $200
	dw $8207,$19b,$19b,$19b8,$380
	dw $200
	dw $8207,$cd,$cd,$1344,$380
	dw $200
	dw $8204,$1469,$380
	dw $200
	dw $8247,$19b,$19b,$1846,$380
	dw $200
	dw $8207,$cd,$cd,$19b8,$380
	dw $200
	dw $8227,$0,$0,$1344,$380
	dw $8200,$380
	dw $8204,$1469,$380
	dw $8200,$380
	dw $8204,$1846,$380
	dw $8200,$380
	dw $8204,$19b8,$380
	dw $8200,$380
	dw $8227,$19b,$19b,$1344,$380
	dw $8200,$380
	dw $8207,$cd,$cd,$1469,$380
	dw $8200,$380
	dw $8227,$19b,$19b,$1846,$380
	dw $8200,$380
	dw $8207,$cd,$cd,$19b8,$380
	dw $8200,$380
	dw $8247,$19b,$19b,$1344,$380
	dw $8200,$380
	dw $8207,$cd,$cd,$1469,$380
	dw $8200,$380
	dw $8204,$1846,$380
	dw $8200,$380
	dw $8247,$19b,$19b,$19b8,$380
	dw $8200,$380
	dw $8207,$cd,$cd,$1344,$380
	dw $8200,$380
	dw $8204,$1469,$380
	dw $8200,$380
	dw $8247,$19b,$19b,$1846,$380
	dw $8200,$380
	dw $8247,$cd,$cd,$19b8,$380
	dw $8200,$380
	dw $822f,$19b,$337,$0,$19b8,$780
	dw $200
	dw $8223,$cd,$19b,$780
	dw $200
	dw $8220,$780
	dw $200
	dw $8220,$780
	dw $200
	dw $8221,$c2,$780
	dw $200
	dw $8222,$184,$780
	dw $200
	dw $8220,$780
	dw $200
	dw $8221,$b7,$780
	dw $200
	dw $200
	dw $200
	dw $202,$16e
	dw $200
	dw $201,$ad
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $8201,$a3,$580
	dw $200
	dw $8202,$15a,$580
	dw $200
	dw $8200,$580
	dw $200
	dw $8200,$580
	dw $200
	dw $209,$9a,$1846
	dw $208,$16e9
	dw $208,$15a0
	dw $208,$1469
	dw $8208,$1344,$580
	dw $20c,$d9f,$122f
	dw $820e,$146,$e6e,$112a,$580
	dw $20c,$f4a,$1033
	dw $820c,$1033,$f4a,$580
	dw $20c,$112a,$e6e
	dw $20d,$91,$122f,$d9f
	dw $20c,$1344,$cdc
	dw $204,$1469
	dw $204,$15a0
	dw $204,$16e9
	dw $204,$1846
	dw $204,$19b8
	dw $200
	dw $200
	dw $200
	dw $203,$89,$134
	dw $200
	dw $200
	dw $200
	dw $8200,$380
	dw $200
	dw $8200,$380
	dw $200
	dw $8200,$380
	dw $200
	dw $8200,$380
	dw $200
	dw $8201,$81,$380
	dw $200
	dw $8206,$122,$1846,$380
	dw $204,$16e9
	dw $8204,$15a0,$380
	dw $204,$1469
	dw $8204,$1344,$380
	dw $204,$122f
	dw $8204,$112a,$580
	dw $204,$1033
	dw $820c,$f4a,$d9f,$580
	dw $20c,$e6e,$e6e
	dw $820d,$7a,$d9f,$f4a,$580
	dw $20c,$cdc,$1033
	dw $8208,$112a,$580
	dw $208,$122f
	dw $20a,$112,$1344
	dw $208,$1469
	dw $208,$15a0
	dw $208,$16e9
	dw $208,$1846
	dw $208,$19b8
	dw $200
	dw $200
	dw $200
	dw $200
	dw $201,$73
	dw $200
	dw $8200,$780
	dw $200
	dw $8200,$780
	dw $200
	dw $8202,$103,$780
	dw $200
	dw $8200,$780
	dw $220
	dw $8220,$780
	dw $220
	dw $8220,$780
	dw $220
	dw $8221,$6c,$780
	dw $220
	dw $8220,$780
	dw $220
	dw $8220,$780
	dw $220
	dw $8220,$780
	dw $200
	dw $8202,$f4,$580
	dw $200
	dw $8200,$580
	dw $200
	dw $821a,$e6,$19b8,RLC_H,$580
	dw $200
	dw $8200,$580
	dw $200
	dw $8203,$66,$d9,$580
	dw $200
	dw $8200,$580
	dw $200
	dw $8202,$cd,$580
	dw $200
	dw $8200,$580
	dw $200
	dw $8200,$580
	dw $200
	dw $200
	dw $200
	dw $208,$51a
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $208,$40c
	dw $200
	dw $220
	dw $220
	dw $220
	dw $220
	dw $220
	dw $220
	dw $220
	dw $220
	dw $220
	dw $220
	dw $220
	dw $220
	dw $220
	dw $220
	dw $228,$1b3
	dw $220
	dw $220
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $240
	dw $240
	dw $240
	dw $240
	dw $240
	dw $200
	dw $208,$122
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $208,$1cd
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $204,$c23
	dw $204,$b74
	dw $204,$ad0
	dw $204,$a34
	dw $204,$9a2
	dw $204,$917
	dw $204,$895
	dw $204,$819
	dw $204,$7a5
	dw $204,$737
	dw $204,$6cf
	dw $204,$66e
	dw $204,$611
	dw $204,$5ba
	dw $204,$568
	dw $204,$51a
	dw $204,$4d1
	dw $204,$48b
	dw $204,$44a
	dw $204,$40c
	dw $204,$3d2
	dw $204,$39b
	dw $204,$367
	dw $204,$337
	dw $204,$308
	dw $204,$2dd
	dw $204,$2b4
	dw $204,$28d
	dw $204,$268
	dw $204,$245
	dw $204,$225
	dw $204,$206
	dw $204,$1e9
	dw $204,$1cd
	dw $204,$1b3
	dw $204,$19b
	dw $204,$184
	dw $204,$16e
	dw $204,$15a
	dw $204,$146
	dw $204,$134
	dw $204,$122
	dw $204,$112
	dw $204,$103
	dw $204,$f4
	dw $204,$e6
	dw $204,$d9
	dw $204,$cd
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $208,$64
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $21c,$d9,$e6,NOP_2
	dw $20c,$cd,$d9
	dw $20c,$c2,$cd
	dw $20c,$b7,$c2
	dw $20c,$ad,$b7
	dw $20c,$a3,$ad
	dw $20c,$9a,$a3
	dw $20c,$91,$9a
	dw $20c,$89,$91
	dw $20c,$81,$89
	dw $20c,$7a,$81
	dw $20c,$73,$7a
	dw $20f,$0,$0,$6c,$73
	dw $20c,$66,$6c
	dw $208,$0
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw $200
	dw 0


end

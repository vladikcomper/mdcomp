; ---------------------------------------------------------------------------
; Original by snkenjoi, this much faster version written by Flamewing
; ---------------------------------------------------------------------------
; FUNCTION:
; 	SNKDec
;
; DESCRIPTION
; 	snkenjoi's RLE Decompressor
;
; INPUT:
; 	a0	Source address
; 	a1	Destination address
; ===========================================================================
; Note on preconditions:
; The following preconditions are conditions satisfied by the decoding logic at
; various points in the routine. They are referred to by their code.
; 	 (1)	There is an even number of bytes left to decompress.
; 	 (1')	There is an odd number of bytes left to decompress.
; 	 (2)	Last character read is in d3.
; 	 (2')	Last character read is in d6.
; 	 (3)	d3 was printed to the buffer (d6).
; 	 (3')	The buffer (d6) is empty.
; 	 (3")	The buffer (d3) is empty.
; 	 (3*)	The buffer (d6) has the last character written twice.
; 	 (3^)	The buffer (d6) has two different characters
; 	 (4)	We are at an even position on the output stream.
; 	 (5)	The two bytes of the low word of d6 are equal to d3.
; ===========================================================================

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; ---------------------------------------------------------------------------
SNKDec:
	;16 words = 1 tile
	move.w	#$FE,d0							;  8(2/0)
	moveq	#0,d1							;  4(1/0)
	moveq	#0,d4							;  4(1/0)
	move.w	(a0)+,d1						;  8(2/0)
	lea	SNKDec_CopyLUT_End(pc),a4			;  8(2/0)
	; PRECONDITIONS: (1), (3'), and (4) hold.

.fetch_new_char:
	; PRECONDITIONS: (1), (3'), and (4) hold
	; Read and print the character to the temporary buffer (d6).
	movep.w	0(a0),d6						; 16(4/0)
	; Read the character again for ease of comparison.
	move.b	(a0)+,d3						;  8(2/0)
	; PRECONDITIONS: (1) and (4) still hold; (2) now also holds, and (3') is
	; replaced by (3).

.main_loop:
	; PRECONDITIONS: (1), (2), (3), and (4) hold.
	; Read and print new character to the buffer.
	move.b	(a0)+,d6						;  8(2/0)
	; We now have a word on the buffer. Write it to output stream.
	move.w	d6,(a1)+						;  8(1/1)
	subq.w	#2,d1							;  4(1/0)
	; PRECONDITIONS: (1), (2), (3) and (4) still hold.
	; Branch if decompression was finished.
	beq.s	SNKDecEnd						; T: 10(2/0); N:  8(1/0)
	; Is this a run of identical bytes?
	cmp.b	d3,d6							;  4(1/0)
	; Branch if not.
	bne.s	.main_loop_buffer_clear			; T: 10(2/0); N:  8(1/0)
	; PRECONDITIONS: (1), (2), and (4) still hold; (3) is replaced by (3*).
	; We have a run. Fetch number of repetitions.
	move.b	(a0)+,d5						;  8(2/0)
	; Zero repetitions means we wrote what was required and emptied our buffer.
	beq.s	.main_loop_buffer_clear			; T: 10(2/0); N:  8(1/0)
	; PRECONDITIONS: (1), (2), (3*), and (4) still hold.
	; Given all preconditions, we just have to write d6 several times.
	; Save count for later.
	move.b	d5,d4							;  4(1/0)
	; Strip off low bit, as well as junk in high bits. We will write words.
	and.w	d0,d5							;  4(1/0)
	; Prepare for loop unroll.
	neg.w	d5								;  4(1/0)
	; Copy with lookup table.
	jsr	(a4,d5.w)							; 22(2/2)
	; NOTE: because of the preconditions in effect, then we have the theorem:
	; (A)	if the copy count is odd, we haven't finished the decompression.
	; Therefore, if we have reached the end of file, we don't have to worry
	; about the low bit of the copy count we saved above.
	; Factor in all bytes we wrote.
	sub.w	d4,d1							;  4(1/0)
	; Branch if decompression is over.
	beq.s	SNKDecEnd						; T: 10(2/0); N:  8(1/0)
	; Was the copy count an odd number?
	moveq	#1,d5							;  4(1/0)
	and.b	d4,d5							;  4(1/0)
	; Branch if not.
	beq.s	.no_single_byte					; T: 10(2/0); N:  8(1/0)
	; PRECONDITIONS: (2), (3*), and (4) still hold; (1) is replaced by (1').
	; Implicitly print byte at d3 to buffer at d6 by doing (almost) nothing.
	; Add a byte back to count because we haven't put it into the output stream.
	addq.w	#1,d1							;  4(1/0)
	; PRECONDITIONS: (1), (2), (3*), and (4) still hold.
	; Was the copy count 255?
	addq.b	#1,d4							;  4(1/0)
	; Branch if not.
	bne.s	.main_loop						; T: 10(2/0); N:  8(1/0)
	; We need to read in a new character, and we have one printed to the buffer.
	; Read and print new character to the buffer.
	move.b	(a0)+,d6						;  8(2/0)
	; PRECONDITIONS: (1), and (4) still hold; (2) is replaced by (2'), and (3*)
	; is replaced by (3^).
	; Write both to output stream.
	move.w	d6,(a1)+						;  8(1/1)
	subq.w	#2,d1							;  4(1/0)
	; PRECONDITIONS: (1), (2'), and (4) still hold; (3) is replaced by (3").
	; Branch if decompression was finished.
	beq.s	SNKDecEnd						; T: 10(2/0); N:  8(1/0)
	bra.s	.main_loop_buffer_clear			; 10(2/0)
;----------------------------------------------------------------------------
.no_single_byte:
	; PRECONDITIONS: (1), and (4) still hold; (2) is replaced by (2'), and (3*)
	; is replaced by (3").
	; If copy count is 255, we need to fetch a new byte and write it to the
	; buffer.
	; Was the copy count 255?
	addq.b	#1,d4							;  4(1/0)
	; Branch if yes.
	beq.s	.fetch_new_char					; T: 10(2/0); N:  8(1/0)

.main_loop_buffer_clear:
	; PRECONDITIONS: (1), (2'), (3"), and (4) hold.
	; Swap (empty) buffer to d6 and last character read to d6.
	move.b	d6,d3							;  4(1/0)
	; PRECONDITIONS: (1), and (4) still hold; (2') is replaced by (2),
	; and (3") is replaced by (3').
	; Read and print new character to the buffer (d6).
	movep.w	0(a0),d6						; 16(4/0)
	; Print it again to buffer for ease of comparison.
	move.b	(a0)+,d6						;  8(2/0)
	; PRECONDITIONS: (1), (2), and (4) still hold; (3') is replaced by (3*).
	; Is this a run of identical bytes?
	cmp.b	d6,d3							;  4(1/0)
	; Branch if not.
	bne.s	.main_loop						; T: 10(2/0); N:  8(1/0)
	; We have a run. Fetch number of repetitions.
	move.b	(a0)+,d5						;  8(2/0)
	; Zero repetitions means we just need to print the character to the buffer.
	beq.s	.main_loop						; T: 10(2/0); N:  8(1/0)
	; By precondition (3*), we now have a word with two identical bytes on the
	; buffer. Write it to output stream.
	move.w	d6,(a1)+						;  8(1/1)
	subq.w	#2,d1							;  4(1/0)
	; PRECONDITIONS: (1), (2), (3*) and (4) still hold.
	; Deduct one byte from the copy count since we printed it above.
	subq.b	#1,d5
	; Save count for later.
	move.b	d5,d4							;  4(1/0)
	; Strip off low bit, as well as junk in high bits. We will write words.
	and.w	d0,d5							;  4(1/0)
	; Prepare for loop unroll.
	neg.w	d5								;  4(1/0)
	; Copy with lookup table.
	jsr	(a4,d5.w)							; 22(2/2)
	; NOTE: because of the preconditions in effect, then we have the theorem:
	; (B)	if the copy count was even, we haven't finished the decompression.
	; Therefore, if we have reached the end of file, we don't have to worry
	; about the low bit of the copy count we saved above.
	; Factor in all bytes we wrote.
	sub.w	d4,d1							;  4(1/0)
	; Branch if decompression is over.
	beq.s	SNKDecEnd						; T: 10(2/0); N:  8(1/0)
	; Add 1 back to use some common code.
	addq.b	#1,d4							;  4(1/0)
	; Was the copy count an odd number?
	moveq	#1,d5							;  4(1/0)
	and.b	d4,d5							;  4(1/0)
	; Branch if yes.
	bne.s	.no_single_byte					; T: 10(2/0); N:  8(1/0)
	; PRECONDITIONS: (2), (3*), and (4) still hold; (1) is replaced by (1').
	; Implicitly print byte at d3 to buffer at d6 by doing (almost) nothing.
	; Add a byte back to count because we haven't put it into the output stream.
	addq.w	#1,d1							;  4(1/0)
	; PRECONDITIONS: (2), (3*), and (4) still hold; (1') is replaced by (1).
	; Was the copy count 255?
	addq.b	#1,d4							;  4(1/0)
	; Branch if not.
	bne.s	.main_loop						; T: 10(2/0); N:  8(1/0)
	; We need to read in a new character, and we have one printed to the buffer.
	; Read and print new character to the buffer.
	move.b	(a0)+,d6						;  8(2/0)
	; PRECONDITIONS: (1), and (4) still hold; (2) is replaced by (2'), and (3*)
	; is replaced by (3^).
	; Write both to output stream.
	move.w	d6,(a1)+						;  8(1/1)
	subq.w	#2,d1							;  4(1/0)
	; PRECONDITIONS: (1), (2'), and (4) still hold; (3) is replaced by (3").
	; Branch if decompression was not finished.
	bne.s	.main_loop_buffer_clear			; T: 10(2/0); N:  8(1/0)

SNKDecEnd:
	rts
; ===========================================================================
SNKDec_CopyLUT:
    rept 127
	move.w	d6,(a1)+						;  8(1/1)
    endm
SNKDec_CopyLUT_End:
	rts
; ===========================================================================

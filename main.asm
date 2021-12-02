BasicUpstart2(start)

// zero page allocation
//$BB
.label digit = $bb
//$FB/$FC
.label int = $fb
//$FD/$FE
.label parsed_ptr = $fd

start:
	lda #<input
	sta input_ptr
	lda #>input
	sta input_ptr+1

	lda #<parsed
	sta parsed_ptr
	lda #>parsed
	sta parsed_ptr+1

	lda #0
	sta digit

	// do {
parse:
	lda input_ptr:$ffff

	sec
	sbc #'0'
	cmp #10
	bcs !else+

	// if last char digit
	ldx digit
	bne !+
		// Write first digit
		sta int
		lda #0
		sta int+1

		lda #1
		sta digit
		jmp !endif+
	!: // else
		asl int
		rol int+1
		asl int
		rol int+1
		asl int
		rol int+1
		asl int
		rol int+1

		ora int
		sta int
	jmp !endif+
!else:
	lda digit
	beq !endif+

	ldy #0
	lda int
	sta (parsed_ptr), y
	iny
	lda int+1
	sta (parsed_ptr), y

	// parsed_ptr += 2 (aligned)
	inc parsed_ptr
	inc parsed_ptr
	bne !+
	inc parsed_ptr+1
!:

	lda #0
	sta digit
!endif:

	// ++input_ptr
	inc input_ptr
	bne !+
	inc input_ptr+1
!:

	lda input_ptr
	cmp #<input_end
	bne !continue+
	lda input_ptr+1
	cmp #>input_end
	beq !done+
!continue:
	jmp parse
	// } while(input_ptr != input_end)
!done:

	// parsed_end = parsed_ptr
	lda parsed_ptr
	sta parsed_end
	lda parsed_ptr+1
	sta parsed_end+1

	lda #1
	jsr part
	// print result
	lda int
	ldy #2
	jsr print_hex
	lda int+1
	ldy #0
	jsr print_hex

	lda #3
	jsr part
	// print result
	lda int
	ldy #42
	jsr print_hex
	lda int+1
	ldy #40
	jsr print_hex
	rts

	// a offset
	// returns result in int
part:
	// offset = a*2
	asl
	sta offset

	// parsed_ptr = parsed
	lda #<parsed
	sta parsed_ptr
	lda #>parsed
	sta parsed_ptr+1

	// end = parsed_end
	lda parsed_end
	sta end_low
	lda parsed_end+1
	sta end_hi

	// end -= offset
	ldy offset
!loop:
	ldx end_low
	bne !+
	dec end_hi
!:
	dec end_low
	dey
	bne !loop-

	// int = 0
	lda #0
	sta int
	sta int+1

	// do {
calculate:
	// if (parsed_ptr[0] < parsed_ptr[offsed/2]) {
	ldy #1
	lda (parsed_ptr), y
	ldy offset
	iny
	cmp (parsed_ptr), y
	beq !compare_low+
	bcc !increased+
	jmp !endif+
!compare_low:
	ldy #0
	lda (parsed_ptr), y
	ldy offset
	cmp (parsed_ptr), y
	beq !endif+
	bcs !endif+

!increased:
		// ++int (bcd enabled)
		sed
		clc
		lda #1
		adc int
		sta int
		lda #0
		adc int+1
		sta int+1
		cld
!endif:
	// }

	// parsed_ptr += 2 (aligned)
	inc parsed_ptr
	inc parsed_ptr
	bne !+
	inc parsed_ptr+1
!:

	lda parsed_ptr
	cmp end_low:#0
	bne !continue+
	lda parsed_ptr+1
	cmp end_hi:#0
	beq !done+
!continue:
	jmp calculate
	// } while(parsed_ptr != end)
!done:

	rts

	// a = number y = position
	// modifies x
print_hex:
	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda hexChar,x
	sta $0400+480,y
	//lda #1
	//sta colorRam+40*24,y
	pla
	and #%1111
	tax
	lda hexChar,x
	sta $0401+480,y
	//lda #1
	//sta colorRam+40*24+1,y
	rts

hexChar:
	.text "0123456789abcdef"
offset:
	.byte 1

	.align 2
parsed_end:
	.word 0
parsed:
	.word 0 // buffer then reuse parsed data
input:
	.import text "input.txt"
input_end:

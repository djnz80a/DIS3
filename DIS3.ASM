
;
;	Dis-Assembler
;
;	subroutine header make
;

READ_BYTES	EQU	400H
WRITE_BYTES	EQU	400H

	ORG	100H

	LD	A,(005DH)
	CP	20H+1
	JP	NC,N_HELP

	LD	C,09H
	LD	DE,HELP_MES
	CALL	0005H
	RET

HELP_MES:
	DB	'DIS3.COM',0DH,0AH
	DB	'usage : DIS <FILENAME> [<OUTPUT-FILENAME>] / options',0DH,0AH
	DB	'/A<top address(hex)>',0DH,0AH
	DB	'/B .. BSAVE file',0DH,0AH
	DB	'/C<cut size>',0DH,0AH
	DB	'/S<segment-top>:<segment-end>',0DH,0AH
	DB	'/V .. RST nnH -> RST nnH/DW <word>',0DH,0AH
	DB	'$'

N_HELP:	LD	HL,005CH
	LD	DE,FILE1
	LD	BC,12
	LDIR

	LD	A,(006DH)
	CP	21H
	LD	HL,005CH
	JR	C,$+5
	LD	HL,006CH
	LD	DE,FILE2
	LD	BC,12
	LDIR

	LD	HL,0FFFFH
	LD	(SEGMENT_TOP),HL
	LD	(SEGMENT_END),HL

	LD	HL,0100H
	LD	(OFFSET),HL

	LD	HL,6000H
	LD	(CUT_SIZE),HL

	LD	HL,0080H
	LD	C,(HL)
	LD	B,H
	INC	HL
	ADD	HL,BC
	LD	(HL),B

	LD	DE,0081H

OPTION:	LD	A,(DE)
	INC	DE
	OR	A
	JR	Z,OPTION_END
	CP	'/'
	JR	NZ,OPTION

	LD	A,(DE)
	CALL	UPPER
	INC	DE
	CP	'A'
	JR	Z,OPT.10
	CP	'C'
	JR	Z,OPT.20
	CP	'S'
	JR	Z,OPT.30
	CP	'B'
	JR	Z,OPT.40
	CP	'V'
	JR	Z,OPT.50
	JR	OPTION

OPT.10:	CALL	GETHEX
	LD	(OFFSET),HL
	JR	OPTION

OPT.20:
	CALL	GETHEX
	LD	(CUT_SIZE),HL
	JR	OPTION

OPT.30:
	CALL	GETHEX
	LD	(SEGMENT_TOP),HL
	INC	DE		;skip ':'
	CALL	GETHEX
	LD	(SEGMENT_END),HL
	JR	OPTION

OPT.40:
	LD	A,0FFH
	LD	(BIN_FLAG),A
	JR	OPTION

OPT.50:
	LD	A,0FFH
	LD	(VIEW_FLAG),A
	JR	OPTION

OPTION_END:

	LD	C,09H
	LD	DE,MES_CSROFF
	CALL	0005H

	LD	C,0FH
	LD	DE,FILE1
	CALL	0005H
	OR	A
	JP	NZ,ERR_OPEN

MAKE:
	LD	HL,FILE2+9
	LD	A,'0'
	LD	(HL),A
	INC	HL
	LD	(HL),A
	INC	HL
	LD	(HL),'1'

	LD	C,16H
	LD	DE,FILE2
	CALL	0005H
	OR	A
	JP	NZ,ERR_MAKE

	LD	A,(0FCC1H)
	LD	HL,0007H
	CALL	000CH
	LD	(WRVDP),A

	CALL	FILL

	LD	A,1
	LD	(PASS),A

	CALL	PASS_MAIN

	LD	A,2
	LD	(PASS),A

	CALL	PASS_MAIN

	LD	C,1AH
	LD	DE,W_WORK
	CALL	0005H

	LD	HL,(W_LEFT)
	LD	A,H
	OR	L
	JR	Z,PROG_END.10

	LD	C,26H
	LD	DE,FILE2
	CALL	0005H

PROG_END.10:
	LD	C,10H
	LD	DE,FILE2
	CALL	0005H

	JP	0000H

;
;
;

PASS_MAIN:
	LD	A,(PASS)
	ADD	A,'0'
	LD	C,02H
	LD	E,A
	CALL	0005H

	XOR	A
	LD	(R_FLG),A
	LD	HL,0000H
	LD	(R_LEFT),HL
	LD	(FILE1+33),HL
	LD	(FILE1+35),HL
	INC	L
	LD	(FILE1+14),HL

	LD	HL,W_WORK
	LD	(W_PNT),HL
	LD	HL,0000H
	LD	(W_LEFT),HL
	LD	(FILE2+33),HL
	LD	(FILE2+35),HL
	INC	L
	LD	(FILE2+14),HL

	LD	HL,0
	LD	(FILE_SIZE_CNT),HL

	LD	C,1AH
	LD	DE,WORK
	CALL	0005H

	LD	HL,(FILE1+16)
	LD	(FILE_SIZE),HL

	LD	A,(BIN_FLAG)
	OR	A
	JR	Z,NOT_BIN

	LD	C,27H
	LD	DE,FILE1
	LD	HL,7
	CALL	0005H
	LD	A,(WORK+0)
	CP	0FEH
	JP	NZ,ERR_BIN
	LD	HL,(WORK+1)
	LD	(OFFSET),HL

	LD	HL,(FILE1+16)
	LD	DE,7
	OR	A
	SBC	HL,DE
	LD	(FILE_SIZE),HL

NOT_BIN:

	LD	C,27H
	LD	DE,FILE1
;	LD	HL,(FILE1+16)
	LD	HL,(FILE_SIZE)
	CALL	0005H

	LD	HL,(OFFSET)
	LD	(TOP_ADR),HL
	LD	A,(PASS)
	CP	2
	JR	NZ,PASS_MAIN.10
	LD	DE,(SEGMENT_TOP)
	LD	A,D
	AND	E
	INC	A
	JR	Z,PASS_MAIN.10
	EX	DE,HL
PASS_MAIN.10:
	LD	(ADR),HL

;	LD	HL,(FILE1+16)
	LD	HL,(FILE_SIZE)
	LD	A,(PASS)
	CP	2
	JR	NZ,PASS_MAIN.20
	LD	DE,(SEGMENT_TOP)
	LD	A,D
	AND	E
	INC	A
	JR	Z,PASS_MAIN.20
	LD	HL,(SEGMENT_END)
	OR	A
	SBC	HL,DE
	INC	HL
PASS_MAIN.20:
	LD	DE,(ADR)
	ADD	HL,DE
	DEC	HL
	LD	(WRITE_END_ADR),HL	;END_ADR = OFFSET + FILE_SIZE - 1

;	LD	HL,(FILE1+16)
	LD	HL,(FILE_SIZE)
	LD	DE,(TOP_ADR)
	ADD	HL,DE
	DEC	HL
	LD	(END_ADR),HL

	LD	HL,(ADR)
	LD	DE,(TOP_ADR)
	OR	A
	SBC	HL,DE
	LD	DE,WORK
	ADD	HL,DE
;	LD	HL,WORK
	LD	(PNT),HL

	LD	DE,(TOP_ADR)
	CALL	SET_LABEL

;	LD	(SP_PNT),SP

MAIN:
;	LD	HL,0
;	ADD	HL,SP
;SP_PNT	EQU	$+1
;	LD	DE,0
;	OR	A
;	SBC	HL,DE
;	JR	Z,MAIN.01
;
;	LD	A,2
;	LD	(PASS),A
;	LD	HL,(ADR)
;	LD	A,H
;	CALL	B_PUTHEX
;	LD	A,L
;	CALL	B_PUTHEX
;
;	LD	C,09H
;	LD	DE,MES_SP
;	CALL	0005H
;	JP	0
;
;MES_SP:	DB	'SP error$'

MAIN.01:
	CALL	CLEAR_WORK

	LD	HL,(ADR)
	CALL	VPEEK
	BIT	1,A
	JR	Z,MAIN.10

	LD	HL,HEAD_STR
	CALL	DOS02_STR
	JR	MAIN.10

HEAD_STR:
	DB	0DH,0AH
	DB	';',0DH,0AH
	DB	';',0DH,0AH
	DB	';',0DH,0AH
	DB	0DH,0AH
	DB	0

MAIN.10:

	LD	HL,(ADR)
	CALL	SEARCH_LABEL
	JR	C,MAIN.15

	LD	A,'_'
	CALL	PUTCHR
	CALL	PUTHEX
	LD	A,':'
	CALL	PUTCHR

MAIN.15:
	CALL	TAB2

	CALL	BYTE_1

	LD	IX,(PNT)

	LD	A,(NEXTDW_FLAG)
	OR	A
	JP	NZ,NDW

	LD	A,(IX+0)
	CP	18H
	JR	Z,MAIN_JP
	CP	0C3H
	JR	Z,MAIN_JP
	CP	0C9H
	JR	Z,MAIN_JP

	CP	0CDH
	JR	Z,MAIN_CALL

	JP	MAIN.50


MAIN_JP:
	LD	A,0FFH
	LD	(CRLF_FLAG),A
	JP	MAIN.50

MAIN_CALL:
	PUSH	HL
	LD	L,(IX+1)
	LD	H,(IX+2)
	LD	A,02H
	CALL	BIT_LABEL
	POP	HL


MAIN.50:LD	A,(IX+0)
	INC	IX
	CP	0EDH
	JP	Z,NED
	CP	0CBH
	JP	Z,NCB
	CP	0DDH
	JP	Z,NDD
	CP	0FDH
	JP	Z,NFD

	LD	(CODE),A

	CP	40H
	JP	C,N00
	CP	0C0H
	JP	NC,NC0

;	40 -- BF

	CP	76H
	JP	Z,N_HALT

	SUB	40H
	CP	40H
	JP	NC,N80

	LD	A,@LD
	CALL	PUTSTR
	CALL	TAB

	LD	A,(CODE)
	RRCA
	RRCA
	RRCA
	AND	07H
	ADD	A,128
	CALL	PUTSTR
	CALL	COMMA
	LD	A,(CODE)
	AND	07H
	ADD	A,128
	CALL	PUTSTR
	JP	MAIN_N


N_HALT:	LD	A,@HALT
	CALL	PUTSTR
	JP	MAIN_N

NDW:	XOR	A
	LD	(NEXTDW_FLAG),A
	CALL	BYTE_2

	LD	L,(IX+0)
	LD	H,(IX+1)
	PUSH	HL
	LD	A,'D'
	CALL	PUTCHR
	LD	A,'W'
	CALL	PUTCHR
	CALL	TAB2
	POP	HL
	CALL	PUTHEX2
	LD	A,'H'
	CALL	PUTCHR
	JP	MAIN_N

;	80 -- BF

N80:	SUB	40H
	LD	(CODE),A
	RRCA
	RRCA
	RRCA
	AND	07H
	PUSH	AF
	LD	H,0
	LD	L,A
	LD	DE,N80_TBL
	ADD	HL,DE
	LD	A,(HL)
	CALL	PUTSTR
	CALL	TAB
	POP	AF
	CP	4
	JR	NC,N80.10
	CP	2
	JR	Z,N80.10
	LD	A,@A
	CALL	PUTSTR
	CALL	COMMA
N80.10:	LD	A,(CODE)
	AND	07H
	ADD	A,128
	CALL	PUTSTR
	JP	MAIN_N


N80_TBL:
	DB	@ADD
	DB	@ADC
	DB	@SUB
	DB	@SBC
	DB	@AND
	DB	@XOR
	DB	@OR
	DB	@CP

;
;	RST n
;

NRST:	LD	A,B
	SUB	0C0H
	AND	38H
	PUSH	AF
	LD	A,@RST
	CALL	PUTSTR
	CALL	TAB
	POP	AF
	PUSH	AF
	CALL	PUTHEX_A2
	LD	A,'H'
	CALL	PUTCHR
	LD	A,(VIEW_FLAG)
	OR	A
	JR	NZ,NRST.10
	POP	AF
	JP	MAIN_N

NRST.10:
	LD	A,0FFH
	LD	(NEXTDW_FLAG),A
	POP	AF
	JP	MAIN_N

;	C0 -- FF

NC0:	LD	B,A
	AND	07H
	CP	07H
	JR	Z,NRST

	LD	A,B
	SUB	0C0H
	LD	HL,TBLC0
	JR	SUB

;	00 -- 3F

N00:	LD	HL,TBL00
	JR	SUB

;
;
;

SUB:	LD	B,A
	INC	B

N00.1:	DEC	B
	JR	Z,N00.10
	LD	A,127
N00.2:
	INC	HL
;	LD	A,(HL)
;	CP	128
;	JP	NC,N00.2
	CP	(HL)
	JP	C,N00.2

;	JP	N00.1
	DJNZ	N00.2

N00.10:
	LD	A,(HL)		;96-10 bug fix
	CP	@ERROR
	JP	Z,UNDEF

	LD	A,(HL)
	PUSH	HL
	CALL	PUTSTR
	POP	HL

	XOR	A
	LD	(COUNT),A

N00.15:
	INC	HL
	LD	A,(HL)
	CP	128
	JP	C,N00.90

	CP	200
	JR	NC,N00.20

	PUSH	HL

	PUSH	AF
	CALL	SEP
	POP	AF

	CALL	PUTSTR
	POP	HL
	JR	N00.15


N00.20:
	CP	@N
	JR	NZ,N00.22

	PUSH	HL
	CALL	SEP

	LD	A,(IX+0)
	INC	IX

	CALL	PUTHEX_A2
	LD	A,'H'
	CALL	PUTCHR
	CALL	INC_BYTE
	POP	HL
	JP	N00.15

N00.22:	CP	@NN
	JR	NZ,N00.24

	PUSH	HL
	CALL	SEP

	LD	A,(IX+0)
	INC	IX

	PUSH	AF
	LD	A,(IX+0)
	INC	IX
	LD	H,A
	POP	AF
	LD	L,A
	CALL	PUTINT

	CALL	INC_BYTE
	CALL	INC_BYTE
	POP	HL
	JP	N00.15

N00.24:	CP	@<N>
	JR	NZ,N00.26

	PUSH	HL
	CALL	SEP
	LD	A,'('
	CALL	PUTCHR
	LD	A,(IX+0)
	INC	IX
	CALL	INC_BYTE
	CALL	PUTHEX_A2
	LD	A,'H'
	CALL	PUTCHR
	LD	A,')'
	CALL	PUTCHR
	POP	HL
	JP	N00.15

N00.26:	CP	@<NN>
	JR	NZ,N00.28

	PUSH	HL
	CALL	SEP
	LD	A,'('
	CALL	PUTCHR
	LD	A,(IX+0)
	INC	IX
	CALL	INC_BYTE
	PUSH	AF
	LD	A,(IX+0)
	INC	IX
	CALL	INC_BYTE
	LD	H,A
	POP	AF
	LD	L,A
	CALL	PUTINT

	LD	A,')'
	CALL	PUTCHR
	POP	HL
	JP	N00.15

N00.28:	CP	@EE
	JR	NZ,N00.30

	PUSH	HL
	CALL	SEP
	LD	A,(IX+0)
	INC	IX
	CALL	INC_BYTE
	PUSH	IX
	POP	HL
	LD	DE,WORK
	OR	A
	SBC	HL,DE
	LD	DE,(OFFSET)
	ADD	HL,DE
	CP	80H
	JR	NC,N00.282
	LD	D,0
	LD	E,A
	ADD	HL,DE
	JR	N00.285
N00.282:
	LD	D,0FFH
	LD	E,A
	ADD	HL,DE
N00.285:
	CALL	PUTINT
	POP	HL
	JP	N00.15

N00.30:	CP	@DD
	JR	NZ,N00.32

	PUSH	HL
	CALL	SEP
	LD	A,(FLG_IX_IY)
	CALL	PUTSTR
	LD	A,(IX+0)
	INC	IX
	CALL	INC_BYTE
	CP	128
	JR	NC,N00.302
	PUSH	AF
	LD	A,'+'
	CALL	PUTCHR
	POP	AF
	CALL	PUTHEX_A2
	JR	N00.305
N00.302:
	PUSH	AF
	LD	A,'-'
	CALL	PUTCHR
	POP	AF
	NEG
	CALL	PUTHEX_A2
N00.305:
	LD	A,'H'
	CALL	PUTCHR
	LD	A,')'
	CALL	PUTCHR
	POP	HL
	JP	N00.15

N00.32:
	JP	N00.15


N00.90:
	JP	MAIN_N

;
;	ED nn
;

NED:
	CALL	BYTE_2

	LD	A,(IX+0)
	INC	IX
	CP	40H
	JP	C,UNDEF
	CP	0BCH
	JP	NC,UNDEF
	CP	80H
	JR	NC,NED80

	LD	B,00H
	CP	46H
	JR	Z,NIM
	INC	B
	CP	56H
	JR	Z,NIM
	INC	B
	CP	5EH
	JR	Z,NIM

	SUB	40H
	LD	HL,TBLED
	JP	SUB

NED80:	SUB	0A0H
	JP	C,UNDEF
	LD	HL,TBLEDA0
	JP	SUB

;	IM n

NIM:	PUSH	BC
	LD	A,@IM
	CALL	PUTSTR
	CALL	TAB
	POP	BC
	LD	A,B
	ADD	A,'0'
	CALL	PUTCHR
	JP	MAIN_N

;
;	CB nn
;

NCB:
	CALL	BYTE_2

	LD	A,(IX+0)
	INC	IX

	LD	B,@SET
	CP	0C0H
	JP	NC,NCB_SUB
	LD	B,@RES
	CP	80H
	JP	NC,NCB_SUB
	LD	B,@BIT
	CP	40H
	JP	NC,NCB_SUB

	PUSH	AF
	RRCA
	RRCA
	RRCA
	AND	07H
	CP	06H
	JP	Z,NCB.10
	LD	H,0
	LD	L,A
	LD	DE,NCB_TBL
	ADD	HL,DE
	LD	A,(HL)
	CALL	PUTSTR
	CALL	TAB
	POP	AF
	AND	07H
	ADD	A,128
	CALL	PUTSTR
	JP	MAIN_N

NCB.10:
	POP	AF
	JP	UNDEF

NCB_TBL:
	DB	@RLC
	DB	@RRC
	DB	@RL
	DB	@RR
	DB	@SLA
	DB	@SRA
	DB	@OTHER
	DB	@SRL

NCB_SUB:
	PUSH	AF
	LD	A,B
	CALL	PUTSTR
	CALL	TAB
	POP	AF

	PUSH	AF
	RRCA
	RRCA
	RRCA
	AND	07H
	ADD	A,'0'
	CALL	PUTCHR
	CALL	COMMA
	POP	AF
	AND	07H
	ADD	A,128
	CALL	PUTSTR
	JP	MAIN_N

;
;	FD nn
;

NFD:	LD	A,@<IY
	JR	NDD.1

;
;	DD nn
;

NDD:	LD	A,@<IX
	JR	NDD.1

;
;
;

NDD.1:	LD	(FLG_IX_IY),A

	CALL	BYTE_2

	LD	A,(IX+0)
	INC	IX

	CP	0CBH
	JP	Z,NDDFDCB

	LD	B,39
	LD	HL,NDD_TBL
NDD.2:	CP	(HL)
	JR	Z,NDD.10
	INC	HL
	DJNZ	NDD.2
	JP	UNDEF
NDD.10:
	LD	A,39
	SUB	B
	LD	HL,TBLDD
	JP	SUB

;
;	DD FD CB nn
;

NDDFDCB:

	CALL	BYTE_4

	INC	IX
	LD	A,(IX+0)
	DEC	IX

	SUB	06H
	LD	C,A
	AND	07H
	JP	NZ,UNDEF
	LD	A,C
	LD	B,@SET
	CP	0C0H
	JR	NC,NDDSUB
	LD	B,@RES
	CP	80H
	JR	NC,NDDSUB
	LD	B,@BIT
	CP	40H
	JR	NC,NDDSUB

	LD	B,@RLC
	CP	00H
	JR	Z,NDDSUB2
	LD	B,@RRC
	CP	08H
	JR	Z,NDDSUB2
	LD	B,@RL
	CP	10H
	JR	Z,NDDSUB2
	LD	B,@RR
	CP	18H
	JR	Z,NDDSUB2
	LD	B,@SLA
	CP	20H
	JR	Z,NDDSUB2
	LD	B,@SRA
	CP	28H
	JR	Z,NDDSUB2

	LD	B,@SRL
	CP	38H
	JR	Z,NDDSUB2
	JP	UNDEF

NDDSUB2:
	PUSH	BC
	LD	A,B
	CALL	PUTSTR
	CALL	TAB
	POP	BC
	JR	NDDSUB.5

NDDSUB:	PUSH	BC
	LD	A,B
	CALL	PUTSTR
	CALL	TAB
	POP	BC
	LD	A,C
	RRCA
	RRCA
	RRCA
	AND	07H
	ADD	A,'0'
	CALL	PUTCHR
	CALL	COMMA
NDDSUB.5:
	LD	A,(FLG_IX_IY)
	CALL	PUTSTR
	LD	A,(IX+0)
	INC	IX
	CP	80H
	JR	NC,NDDSUB.10
	PUSH	AF
	LD	A,'+'
	CALL	PUTCHR
	POP	AF
	CALL	PUTHEX_A2
	JR	NDDSUB.20
NDDSUB.10:
	PUSH	AF
	LD	A,'-'
	CALL	PUTCHR
	POP	AF
	NEG
	CALL	PUTHEX_A2
NDDSUB.20:
	LD	A,'H'
	CALL	PUTCHR
	LD	A,')'
	CALL	PUTCHR
	JP	MAIN_N


NDD_TBL:
	DB	09H
	DB	19H
	DB	21H
	DB	22H
	DB	23H
	DB	29H
	DB	2AH
	DB	2BH
	DB	34H
	DB	35H
	DB	36H
	DB	39H
	DB	46H
	DB	4EH
	DB	56H
	DB	5EH
	DB	66H
	DB	6EH
	DB	70H
	DB	71H
	DB	72H
	DB	73H
	DB	74H
	DB	75H
	DB	77H
	DB	7EH
	DB	86H
	DB	8EH
	DB	96H
	DB	9EH
	DB	0A6H
	DB	0AEH
	DB	0B6H
	DB	0BEH
	DB	0E1H
	DB	0E3H
	DB	0E5H
	DB	0E9H
	DB	0F9H

;
;	Undefined Mnemonic
;

UNDEF:
	LD	A,'D'
	CALL	PUTCHR
	LD	A,'B'
	CALL	PUTCHR
	CALL	TAB2

	LD	HL,(PNT)
	LD	A,(BYTES)
	LD	B,A
	INC	B
UNDEF.10:
	DEC	B
	JR	Z,UNDEF.15
	PUSH	HL
	PUSH	BC
	LD	A,(HL)
	CALL	PUTHEX_A2
	LD	A,'H'
	CALL	PUTCHR
	POP	BC
	POP	HL
	INC	HL
	DEC	B
	LD	A,','
	CALL	NZ,PUTCHR
	INC	B
	JR	UNDEF.10
UNDEF.15:
	JR	MAIN_N

;
;
;

MAIN_N:
;	LD	A,30
;	LD	(X),A

	JR	MAIN_N.1

	LD	A,';'
	CALL	PUTCHR

MAIN_N.1:
	LD	HL,(ADR)
	LD	A,(BYTES)
	LD	C,A
	LD	B,0
MAIN_N.2:
	INC	HL
	INC	B
	DEC	C
	JP	Z,MAIN_N.5
	PUSH	HL
	PUSH	BC
	CALL	SEARCH_LABEL
	POP	BC
	POP	HL
	JP	C,MAIN_N.2

MAIN_N.4:
	LD	A,'_'
	CALL	DOS02
	LD	A,H
	CALL	B_PUTHEX
	LD	A,L
	CALL	B_PUTHEX
	PUSH	HL
	LD	HL,STR_EQU
	CALL	DOS02_STR
	POP	HL
	LD	A,B
	ADD	A,'0'
	CALL	DOS02
	CALL	CRLF
	JP	MAIN_N.2

STR_EQU:DB	09H,'EQU',09H,'$+',0

MAIN_N.5:
	LD	A,(BYTES)
	LD	C,A
	LD	B,0
	LD	HL,(PNT)
	ADD	HL,BC
	LD	(PNT),HL

	LD	HL,(ADR)
	ADD	HL,BC
	LD	(ADR),HL

	LD	A,(MAX_X)
	LD	C,A
	LD	B,0
	LD	HL,BUFFER
	ADD	HL,BC
	INC	HL
	LD	(HL),00H

	LD	B,0
	LD	HL,BUFFER
MAIN_N.20:
	LD	A,(HL)
	OR	A
	JR	Z,MAIN_N.30
	CALL	DOS02
	CP	09H
	JR	Z,MAIN_N.25
	INC	B
	INC	HL
	JR	MAIN_N.20
MAIN_N.25:
	INC	B
	INC	HL
	LD	A,B
	AND	07H
	JR	NZ,MAIN_N.25
	JR	MAIN_N.20

MAIN_N.30:

	CALL	CRLF

	LD	A,(CRLF_FLAG)
	OR	A
	CALL	NZ,CRLF
	XOR	A
	LD	(CRLF_FLAG),A

	LD	DE,(ADR)
	LD	HL,(WRITE_END_ADR)
	OR	A
	SBC	HL,DE
	JR	C,MAIN_END	;if ADR > END_ADR

	JP	MAIN

MAIN_END:
	RET

;
;
;

B_PUTHEX:
	PUSH	AF
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	B_PUTHEX.1
	POP	AF
B_PUTHEX.1:
	AND	0FH
	CP	10
	JR	C,$+4
	ADD	A,7
	ADD	A,'0'
	JP	DOS02

;
;
;

SEP:	LD	A,(COUNT)
	OR	A
	JR	NZ,SEP.1
	CALL	TAB
	JR	SEP.2
SEP.1:	LD	A,','
	CALL	PUTCHR;DOS02
SEP.2:	LD	A,(COUNT)
	INC	A
	LD	(COUNT),A
	RET

;
;
;

PUTSTR:	CP	128
	JR	NC,PUTSTR2
	LD	DE,DATA
PUTSTR.1:
	LD	H,0
	LD	L,A
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,DE
	LD	B,4
PUTSTR.2:
	LD	A,(HL)
	CP	' '
	JR	Z,PUTSTR.3
	CALL	PUTCHR;DOS02
	INC	HL
	DJNZ	PUTSTR.2
PUTSTR.3:
	RET
PUTSTR2:
	CP	@IX
	JR	Z,PUTSTR2.10
	CP	@<IX
	JR	Z,PUTSTR2.10
	CP	@<IX>
	JR	Z,PUTSTR2.10
PUTSTR2.5:
	SUB	128
	LD	DE,DATA2
	JR	PUTSTR.1
PUTSTR2.10:
	PUSH	BC
	LD	B,A
	LD	A,(FLG_IX_IY)
	CP	@<IX
	JR	Z,$+3
	INC	B
	LD	A,B
	POP	BC
	JR	PUTSTR2.5

;
;
;

PUTHEX:	LD	A,H
	CALL	PUTHEX_A
	LD	A,L
	CALL	PUTHEX_A
	RET

;
;	Put Hex. 2 byte
;

PUTHEX2:
	PUSH	HL

	LD	A,H
	CP	0A0H
	JR	C,PUTHEX2.10
	LD	A,'0'
	CALL	PUTCHR
PUTHEX2.10:
	CALL	PUTHEX

	POP	HL
	RET

;
;
;

PUTHEX_A:
	PUSH	AF
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	PUTHEX_A.1
	POP	AF
PUTHEX_A.1:
	AND	0FH
	CP	10
	JR	C,$+4
	ADD	A,7
	ADD	A,'0'
	CALL	PUTCHR;DOS02
	RET

;
;	Put Hex. 1 byte
;

PUTHEX_A2:
	CP	0A0H
	JR	C,PUTHEX_A2.10
	PUSH	AF
	LD	A,'0'
	CALL	PUTCHR
	POP	AF
PUTHEX_A2.10:
	CALL	PUTHEX_A
	RET

;
;
;

CRLF:	LD	A,0DH
	CALL	DOS02
	LD	A,0AH
	JP	DOS02

COMMA:	LD	A,','
	JP	PUTCHR		;DOS02

;
;
;

TAB:	JR	TAB2

	LD	A,(X)
	LD	B,A
TAB.10:
	INC	B
	LD	A,' '
	CALL	PUTCHR
	LD	A,B
	AND	07H
	JR	NZ,TAB.10

	LD	A,B
	LD	(X),A
	RET

;

TAB2:	LD	A,(X)
	LD	B,A
	LD	A,09H
TAB2.10:
	INC	B
	CALL	PUTCHR
	LD	A,B
	AND	07H
	LD	A,' '
	JR	NZ,TAB.10

	LD	A,B
	LD	(X),A
	RET

;
;
;

PUTCHR:	PUSH	HL
	PUSH	BC

	LD	B,A
	LD	A,(X)
	LD	C,A
	INC	A
	LD	(X),A		;X ++
	LD	A,(MAX_X)
	CP	C
	JR	NC,PUTCHR.10	;if X <= MAX_X
	LD	A,C
	LD	(MAX_X),A	;MAX_X = X
PUTCHR.10:
	LD	A,B
	LD	B,0
	LD	HL,BUFFER
	ADD	HL,BC
	LD	(HL),A		;( BUFFER + X ) = A

	POP	BC
	POP	HL
	RET

;
;
;

DOS02_STR:
	LD	A,(HL)
	OR	A
	RET	Z
	CALL	DOS02
	INC	HL
	JR	DOS02_STR

;
;
;

DOS02:	PUSH	IX
	PUSH	IY
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF

	CALL	WRITE

;	LD	C,02H
;	LD	E,A
;	CALL	0005H

	POP	AF
	POP	BC
	POP	DE
	POP	HL
	POP	IY
	POP	IX
	RET
;
;
;
INC_BYTE:
	PUSH	AF
	LD	A,(BYTES)
	INC	A
	LD	(BYTES),A
	POP	AF
	RET

BYTE_1:	PUSH	AF
	LD	A,1
	JR	SET_BYTE
BYTE_2:	PUSH	AF
	LD	A,2
	JR	SET_BYTE
BYTE_3:	PUSH	AF
	LD	A,3
	JR	SET_BYTE
BYTE_4:	PUSH	AF
	LD	A,4
	JR	SET_BYTE

SET_BYTE:
	LD	(BYTES),A
	POP	AF
	RET

;
;
;

INC_NAME:
	LD	HL,FILE2+12
	LD	B,25H-12
	XOR	A
INC_NAME.10:
	LD	(HL),A
	INC	HL
	DJNZ	INC_NAME.10

	LD	HL,FILE2+11
	LD	B,3
INC_NAME.20:
	LD	A,(HL)
	INC	A
	LD	(HL),A
	CP	'9'+1
	RET	C
	LD	(HL),'0'
	DEC	HL
	DJNZ	INC_NAME.20
	RET
;
;
;

WRITE:	LD	HL,PASS
	BIT	0,(HL)
	RET	NZ

;	LD	E,A
;	LD	C,02H
;	CALL	0005H
;	RET

	LD	HL,(W_PNT)
	LD	(HL),A
	INC	HL
	LD	(W_PNT),HL
	LD	HL,(W_LEFT)
	INC	HL
	LD	A,H
	CP	WRITE_BYTES/100H
	JR	Z,WRITE.1
	LD	(W_LEFT),HL
	RET
WRITE.1:
	LD	C,1AH
	LD	DE,W_WORK
	LD	(W_PNT),DE
	CALL	0005H
	LD	HL,0000H
	LD	(W_LEFT),HL
	LD	C,26H
	LD	DE,FILE2
	LD	HL,WRITE_BYTES
	CALL	0005H
	OR	A
	JR	NZ,ERR_WRITE
	LD	HL,(FILE_SIZE_CNT)
	LD	DE,WRITE_BYTES
	ADD	HL,DE
	LD	(FILE_SIZE_CNT),HL
	LD	DE,(CUT_SIZE)
	OR	A
	SBC	HL,DE
	JR	NC,WRITE.20
	RET

WRITE.20:
	LD	HL,0
	LD	(FILE_SIZE_CNT),HL
	LD	C,10H
	LD	DE,FILE2
	CALL	0005H
	CALL	INC_NAME
	LD	C,16H
	LD	DE,FILE2
	CALL	0005H
	OR	A
	JP	NZ,ERR_MAKE
	LD	HL,W_WORK
	LD	(W_PNT),HL
	LD	HL,0
	LD	(W_LEFT),HL
	LD	(FILE2+33),HL
	LD	(FILE2+35),HL
	INC	L
	LD	(FILE2+14),HL
	RET

ERR_WRITE:
	LD	C,10H
	LD	DE,FILE2
	CALL	0005H
	LD	DE,EMES_WRITE
	JP	ERROR

EMES_WRITE:
	DB	'Write error!$'

;
;
;

READ:	LD	HL,(R_LEFT)
	LD	A,H
	OR	L
	JR	Z,READ.1
	DEC	HL
	LD	(R_LEFT),HL
	LD	HL,(R_PNT)
	LD	A,(HL)
	INC	HL
	LD	(R_PNT),HL
	OR	A
	RET

READ.1:	LD	A,(R_FLG)
	OR	A
	JR	NZ,READ.2
	LD	C,1AH
	LD	DE,READ_BUFFER
	LD	(R_PNT),DE
	CALL	0005H
	LD	C,27H
	LD	DE,FILE1
	LD	HL,READ_BYTES
	CALL	0005H
	LD	(R_LEFT),HL
	LD	(R_FLG),A
	JR	READ
READ.2:	SCF
	RET

;
;
;

ERR_OPEN:
	LD	DE,MES_OPEN
	JP	ERROR

ERR_MAKE:
	LD	DE,MES_MAKE
	JP	ERROR

ERROR:	LD	C,09H
	CALL	0005H
	JP	0000H

MES_OPEN:
	DB	'File open error!$'

MES_MAKE:
	DB	'File make error!$'

;
;	00H - 3FH
;

TBL00:	DB	@NOP
	DB	@LD,@BC,@NN
	DB	@LD,@<BC>,@A
	DB	@INC,@BC
	DB	@INC,@B
	DB	@DEC,@B
	DB	@LD,@B,@N
	DB	@RLCA
	DB	@EX,@AF,@AF2
	DB	@ADD,@HL,@BC
	DB	@LD,@A,@<BC>
	DB	@DEC,@BC
	DB	@INC,@C
	DB	@DEC,@C
	DB	@LD,@C,@N
	DB	@RRCA

	DB	@DJNZ,@EE
	DB	@LD,@DE,@NN
	DB	@LD,@<DE>,@A
	DB	@INC,@DE
	DB	@INC,@D
	DB	@DEC,@D
	DB	@LD,@D,@N
	DB	@RLA
	DB	@JR,@EE
	DB	@ADD,@HL,@DE
	DB	@LD,@A,@<DE>
	DB	@DEC,@DE
	DB	@INC,@E
	DB	@DEC,@E
	DB	@LD,@E,@N
	DB	@RRA

	DB	@JR,@NZ,@EE
	DB	@LD,@HL,@NN
	DB	@LD,@<NN>,@HL
	DB	@INC,@HL
	DB	@INC,@H
	DB	@DEC,@H
	DB	@LD,@H,@N
	DB	@DAA
	DB	@JR,@Z,@EE
	DB	@ADD,@HL,@HL
	DB	@LD,@HL,@<NN>
	DB	@DEC,@HL
	DB	@INC,@L
	DB	@DEC,@L
	DB	@LD,@L,@N
	DB	@CPL

	DB	@JR,@NC,@EE
	DB	@LD,@SP,@NN
	DB	@LD,@<NN>,@A
	DB	@INC,@SP
	DB	@INC,@<HL>
	DB	@DEC,@<HL>
	DB	@LD,@<HL>,@N
	DB	@SCF
	DB	@JR,@C,@EE
	DB	@ADD,@HL,@SP
	DB	@LD,@A,@<NN>
	DB	@DEC,@SP
	DB	@INC,@A
	DB	@DEC,@A
	DB	@LD,@A,@N
	DB	@CCF

;
;	C0H - FFH
;

TBLC0:	DB	@RET,@NZ
	DB	@POP,@BC
	DB	@JP,@NZ,@NN
	DB	@JP,@NN
	DB	@CALL,@NZ,@NN
	DB	@PUSH,@BC
	DB	@ADD,@A,@N
	DB	@RST,@OTHER
	DB	@RET,@Z
	DB	@RET
	DB	@JP,@Z,@NN
	DB	@M.OTHER	;CB
	DB	@CALL,@Z,@NN
	DB	@CALL,@NN
	DB	@ADC,@A,@N
	DB	@RST,@OTHER

	DB	@RET,@NC
	DB	@POP,@DE
	DB	@JP,@NC,@NN
	DB	@OUT,@<N>,@A
	DB	@CALL,@NC,@NN
	DB	@PUSH,@DE
	DB	@SUB,@N
	DB	@RST,@OTHER
	DB	@RET,@C
	DB	@EXX
	DB	@JP,@C,@NN
	DB	@IN,@A,@<N>
	DB	@CALL,@C,@NN
	DB	@M.OTHER	;DD
	DB	@SBC,@A,@N
	DB	@RST,@OTHER

	DB	@RET,@PO
	DB	@POP,@HL
	DB	@JP,@PO,@NN
	DB	@EX,@<SP>,@HL
	DB	@CALL,@PO,@NN
	DB	@PUSH,@HL
	DB	@AND,@N
	DB	@RST,@OTHER
	DB	@RET,@PE
	DB	@JP,@<HL>
	DB	@JP,@PE,@NN
	DB	@EX,@DE,@HL
	DB	@CALL,@PE,@NN
	DB	@M.OTHER	;ED
	DB	@XOR,@N
	DB	@RST,@OTHER

	DB	@RET,@P
	DB	@POP,@AF
	DB	@JP,@P,@NN
	DB	@DI
	DB	@CALL,@P,@NN
	DB	@PUSH,@AF
	DB	@OR,@N
	DB	@RST,@OTHER
	DB	@RET,@M
	DB	@LD,@SP,@HL
	DB	@JP,@M,@NN
	DB	@EI
	DB	@CALL,@M,@NN
	DB	@M.OTHER	;FD
	DB	@CP,@N
	DB	@RST,@OTHER

;
;	ED nn
;

TBLED:	DB	@IN,@B,@<C>
	DB	@OUT,@<C>,@B
	DB	@SBC,@HL,@BC
	DB	@LD,@<NN>,@BC
	DB	@NEG
	DB	@RETN
	DB	@IM,@OTHER	;IM 0
	DB	@LD,@I,@A
	DB	@IN,@C,@<C>
	DB	@OUT,@<C>,@C
	DB	@ADC,@HL,@BC
	DB	@LD,@BC,@<NN>
	DB	@ERROR,@OTHER
	DB	@RETI
	DB	@ERROR,@OTHER
	DB	@LD,@R,@A

	DB	@IN,@D,@<C>
	DB	@OUT,@<C>,@D
	DB	@SBC,@HL,@DE
	DB	@LD,@<NN>,@DE
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@IM,@OTHER	;IM 1
	DB	@LD,@A,@I
	DB	@IN,@E,@<C>
	DB	@OUT,@<C>,@E
	DB	@ADC,@HL,@DE
	DB	@LD,@DE,@<NN>
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@IM,@OTHER	;IM 2
	DB	@LD,@A,@R

	DB	@IN,@H,@<C>
	DB	@OUT,@<C>,@H
	DB	@SBC,@HL,@HL
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@RRD
	DB	@IN,@L,@<C>
	DB	@OUT,@<C>,@L
	DB	@ADC,@HL,@HL
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@RLD

	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@SBC,@HL,@SP
	DB	@LD,@<NN>,@SP
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@IN,@A,@<C>
	DB	@OUT,@<C>,@A
	DB	@ADC,@HL,@SP
	DB	@LD,@SP,@<NN>
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER

;
;	ED A0 - BF
;

TBLEDA0:
	DB	@LDI
	DB	@CPI
	DB	@INI
	DB	@OUTI
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@LDD
	DB	@CPD
	DB	@IND
	DB	@OUTD
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER

	DB	@LDIR
	DB	@CPIR
	DB	@INIR
	DB	@OTIR
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@LDDR
	DB	@CPDR
	DB	@INDR
	DB	@OTDR
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER
	DB	@ERROR,@OTHER

;
;	DD nn
;

TBLDD:	DB	@ADD,@IX,@BC
	DB	@ADD,@IX,@DE
	DB	@LD,@IX,@NN
	DB	@LD,@<NN>,@IX
	DB	@INC,@IX
	DB	@ADD,@IX,@IX
	DB	@LD,@IX,@<NN>
	DB	@DEC,@IX
	DB	@INC,@DD
	DB	@DEC,@DD
	DB	@LD,@DD,@N
	DB	@ADD,@IX,@SP
	DB	@LD,@B,@DD
	DB	@LD,@C,@DD
	DB	@LD,@D,@DD
	DB	@LD,@E,@DD
	DB	@LD,@H,@DD
	DB	@LD,@L,@DD
	DB	@LD,@DD,@B
	DB	@LD,@DD,@C
	DB	@LD,@DD,@D
	DB	@LD,@DD,@E
	DB	@LD,@DD,@H
	DB	@LD,@DD,@L
	DB	@LD,@DD,@A
	DB	@LD,@A,@DD
	DB	@ADD,@A,@DD
	DB	@ADC,@A,@DD
	DB	@SUB,@DD
	DB	@SBC,@A,@DD
	DB	@AND,@DD
	DB	@XOR,@DD
	DB	@OR,@DD
	DB	@CP,@DD
	DB	@POP,@IX
	DB	@EX,@<SP>,@IX
	DB	@PUSH,@IX
	DB	@JP,@<IX>
	DB	@LD,@SP,@IX
;
;
;
@ADC	EQU	0
@ADD	EQU	1
@AND	EQU	2
@BIT	EQU	3
@CALL	EQU	4
@CCF	EQU	5
@CP	EQU	6
@CPD	EQU	7
@CPDR	EQU	8
@CPI	EQU	9
@CPIR	EQU	10
@CPL	EQU	11
@DAA	EQU	12
@DEC	EQU	13
@DI	EQU	14
@DJNZ	EQU	15
@EI	EQU	16
@EX	EQU	17
@EXX	EQU	18
@HALT	EQU	19
@IM	EQU	20
@IN	EQU	21
@INC	EQU	22
@IND	EQU	23
@INDR	EQU	24
@INI	EQU	25
@INIR	EQU	26
@JP	EQU	27
@JR	EQU	28
@LD	EQU	29
@LDD	EQU	30
@LDDR	EQU	31
@LDI	EQU	32
@LDIR	EQU	33
@NEG	EQU	34
@NOP	EQU	35
@OR	EQU	36
@OTDR	EQU	37
@OTIR	EQU	38
@OUT	EQU	39
@OUTD	EQU	40
@OUTI	EQU	41
@POP	EQU	42
@PUSH	EQU	43
@RES	EQU	44
@RET	EQU	45
@RETI	EQU	46
@RETN	EQU	47
@RL	EQU	48
@RLA	EQU	49
@RLC	EQU	50
@RLCA	EQU	51
@RLD	EQU	52
@RR	EQU	53
@RRA	EQU	54
@RRC	EQU	55
@RRCA	EQU	56
@RRD	EQU	57
@RST	EQU	58
@SBC	EQU	59
@SCF	EQU	60
@SET	EQU	61
@SLA	EQU	62
@SRA	EQU	63
@SRL	EQU	64
@SUB	EQU	65
@XOR	EQU	66

@ERROR	EQU	126
@M.OTHER EQU	127

@B	EQU	128
@C	EQU	129
@D	EQU	130
@E	EQU	131
@H	EQU	132
@L	EQU	133
@<HL>	EQU	134
@A	EQU	135

@I	EQU	136
@R	EQU	137
@BC	EQU	138
@DE	EQU	139
@HL	EQU	140
@SP	EQU	141
@IX	EQU	142
@IY	EQU	143
@AF	EQU	144
@AF2	EQU	145
@<C>	EQU	146
@<BC>	EQU	147
@<DE>	EQU	148
;@<HL>	EQU	149
@<SP>	EQU	150
@<IX>	EQU	151
@<IY>	EQU	152
@<IX	EQU	153
@<IY	EQU	154
@NZ	EQU	155
@Z	EQU	156
@NC	EQU	157
;@C	EQU	158
@PO	EQU	159
@PE	EQU	160
@P	EQU	161
@M	EQU	162

@N	EQU	200
@NN	EQU	201
@<N>	EQU	202
@<NN>	EQU	203
@EE	EQU	204
@DD	EQU	205

@OTHER	EQU	255

DATA:	DB	'ADC '
	DB	'ADD '
	DB	'AND '
	DB	'BIT '
	DB	'CALL'
	DB	'CCF '
	DB	'CP  '
	DB	'CPD '
	DB	'CPDR'
	DB	'CPI '
	DB	'CPIR'
	DB	'CPL '
	DB	'DAA '
	DB	'DEC '
	DB	'DI  '
	DB	'DJNZ'
	DB	'EI  '
	DB	'EX  '
	DB	'EXX '
	DB	'HALT'
	DB	'IM  '
	DB	'IN  '
	DB	'INC '
	DB	'IND '
	DB	'INDR'
	DB	'INI '
	DB	'INIR'
	DB	'JP  '
	DB	'JR  '
	DB	'LD  '
	DB	'LDD '
	DB	'LDDR'
	DB	'LDI '
	DB	'LDIR'
	DB	'NEG '
	DB	'NOP '
	DB	'OR  '
	DB	'OTDR'
	DB	'OTIR'
	DB	'OUT '
	DB	'OUTD'
	DB	'OUTI'
	DB	'POP '
	DB	'PUSH'
	DB	'RES '
	DB	'RET '
	DB	'RETI'
	DB	'RETN'
	DB	'RL  '
	DB	'RLA '
	DB	'RLC '
	DB	'RLCA'
	DB	'RLD '
	DB	'RR  '
	DB	'RRA '
	DB	'RRC '
	DB	'RRCA'
	DB	'RRD '
	DB	'RST '
	DB	'SBC '
	DB	'SCF '
	DB	'SET '
	DB	'SLA '
	DB	'SRA '
	DB	'SRL '
	DB	'SUB '
	DB	'XOR '

DATA2:	DB	'B   '
	DB	'C   '
	DB	'D   '
	DB	'E   '
	DB	'H   '
	DB	'L   '
	DB	'(HL)'
	DB	'A   '
	DB	'I   '
	DB	'R   '
	DB	'BC  '
	DB	'DE  '
	DB	'HL  '
	DB	'SP  '
	DB	'IX  '
	DB	'IY  '
	DB	'AF  '
	DB	"AF' "
	DB	'(C) '
	DB	'(BC)'
	DB	'(DE)'
	DB	'(HL)'
	DB	'(SP)'
	DB	'(IX)'
	DB	'(IY)'
	DB	'(IX '
	DB	'(IY '
	DB	'NZ  '
	DB	'Z   '
	DB	'NC  '
	DB	'C   '
	DB	'PO  '
	DB	'PE  '
	DB	'P   '
	DB	'M   '

;
;
;

UPPER:	CP	'a'
	RET	C
	CP	'z'+1
	RET	NC
	SUB	20H
	RET

;
;	Get Hex. Value
;
;	[DE] -> HL
;

GETHEX:
	LD	HL,0000H
	DEC	DE
GETHEX.10:
	INC	DE
	LD	A,(DE)
	CP	'0'
	RET	C
	CP	'9'+1
	JR	C,GETHEX.15
	CALL	UPPER
	CP	'A'
	RET	C
	CP	'F'+1
	RET	NC
	SUB	7
GETHEX.15:
	SUB	'0'
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	OR	L
	LD	L,A
	JR	GETHEX.10



VPOKE:
	PUSH	BC
	PUSH	HL
	PUSH	AF
	LD	A,40H
	CALL	SETV_ADR
	POP	AF
	POP	HL
	OUT	(C),A
	POP	BC
	RET

VPEEK:
	PUSH	BC
	PUSH	HL
	LD	A,00H
	CALL	SETV_ADR
	POP	HL
	IN	A,(C)
	POP	BC
	RET

SETV_ADR:
	PUSH	AF
	PUSH	HL
	LD	BC,(WRVDP)
	INC	C
	LD	A,1
	ADD	HL,HL
	ADC	A,A
	ADD	HL,HL
	ADC	A,A
	DI
	OUT	(C),A
	LD	A,8EH
	OUT	(C),A
	POP	HL
	OUT	(C),L
	LD	A,H
	AND	3FH
	LD	H,A
	POP	AF
	OR	H
	OUT	(C),A
	EI
	DEC	C
	RET


PUTINT:
	LD	A,(PASS)
	CP	2
	JR	Z,PUTINT.10

	CALL	CHECK_L
	JR	PUTINT.15
PUTINT.10:
	CALL	SEARCH_LABEL
	JR	NC,PUTINT.20
PUTINT.15:
	CALL	PUTHEX2
	LD	A,'H'
	CALL	PUTCHR
	RET
PUTINT.20:
	LD	A,'_'
	CALL	PUTCHR
	CALL	PUTHEX
	RET



CHECK_L:
	PUSH	HL
	PUSH	DE

	LD	DE,(TOP_ADR)
	LD	A,L
	SUB	E
	LD	A,H
	SBC	A,D
	JR	C,PUTHEX2.15

	LD	DE,(END_ADR)
	INC	DE
	LD	A,L
	SUB	E
	LD	A,H
	SBC	A,D
	JR	NC,PUTHEX2.15

	EX	DE,HL
	CALL	SET_LABEL
	EX	DE,HL
PUTHEX2.15:
	POP	DE
	POP	HL
	RET

;
;	HL:adr
;	CY = 1 .. Not Defined Label
;

SEARCH_LABEL:
	PUSH	BC
	LD	B,A
	LD	A,(PASS)
	CP	2
	JR	NZ,SEARCH_LABEL.10
	CALL	VPEEK
	BIT	0,A
	JR	Z,SEARCH_LABEL.10
	LD	A,B
	POP	BC
	OR	A
	RET
SEARCH_LABEL.10:
	LD	A,B
	POP	BC
	SCF
	RET
;
;
;
PASS1:

	CALL	FILL

;	LD	HL,(END_ADR)
;	LD	DE,(ADR)
;	OR	A
;	SBC	HL,DE
;	LD	DE,WORK
;	ADD	HL,DE
;
;	LD	DE,LABEL_TBL
;	OR	A
;	SBC	HL,DE
;	JP	NC,ERR_PASS1.WORK

	LD	IX,WORK
;	LD	IY,LABEL_TBL

	LD	HL,(END_ADR)
	LD	DE,(ADR)
	OR	A
	SBC	HL,DE

	LD	DE,WORK
	ADD	HL,DE
	LD	B,H
	LD	C,L		;BC = Check End Address on Memory

	LD	DE,(ADR)
	CALL	SET_LABEL

PASS1.10:
	LD	A,(IX+0)
	LD	E,A
	AND	07H
	JR	NZ,PASS1.20
	LD	A,E
	CP	10H
	JR	C,PASS1.20
	CP	40H
	JR	NC,PASS1.20
	LD	A,(IX+1)
	PUSH	IX
	POP	HL
	INC	HL
	INC	HL
	CP	80H
	JR	NC,PASS1.15
	LD	D,0
	LD	E,A
	ADD	HL,DE
	JR	PASS1.16
PASS1.15:
	LD	D,0FFH
	LD	E,A
	ADD	HL,DE
PASS1.16:
	LD	DE,WORK
	OR	A
	SBC	HL,DE
	LD	DE,(ADR)
	ADD	HL,DE
	EX	DE,HL
	CALL	SET_LABEL


PASS1.20:
	LD	E,(IX+0)
	LD	D,(IX+1)

	LD	HL,(ADR)
	OR	A
	SBC	HL,DE
	JR	NC,PASS1.50

	LD	HL,(END_ADR)
	INC	HL
	OR	A
	SBC	HL,DE
	JR	C,PASS1.50

	CALL	SET_LABEL

PASS1.50:
	INC	IX
	PUSH	IX
	POP	HL
	OR	A
	SBC	HL,BC
	JP	C,PASS1.10

;	LD	(IY+0),00H
;	LD	(IY+1),00H

	RET

;
;	DE:adr
;

SET_LABEL:
	EX	DE,HL
	CALL	VPEEK
;	LD	A,00H
	SET	0,A
	CALL	VPOKE
	EX	DE,HL
	RET

;	LD	(IY+0),E
;	LD	(IY+1),D
;	INC	IY
;	INC	IY
;	PUSH	IY
;	POP	HL
;	LD	DE,0D000H
;	OR	A
;	SBC	HL,DE
;	JR	NC,ERR_PASS1
;	RET



BIT_LABEL:
	PUSH	BC
	PUSH	AF
	CALL	VPEEK
	LD	B,A
	POP	AF
	OR	B
	CALL	VPOKE
	POP	BC
	RET



FILL:
	LD	HL,0000H
FILL.10:
	PUSH	HL
	LD	A,40H
	CALL	SETV_ADR

	LD	HL,4000H
	LD	B,00H
FILL.20:
	OUT	(C),B
	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,FILL.20

	POP	HL
	LD	DE,4000H
	ADC	HL,DE
	JR	NZ,FILL.10

	RET


CLEAR_WORK:
	XOR	A
	LD	(X),A
	LD	(MAX_X),A

	LD	HL,BUFFER
	LD	B,40
	LD	A,' '
CLEAR_WORK.10:
	LD	(HL),A
	INC	HL
	DJNZ	CLEAR_WORK.10
	RET



ERR_PASS1.WORK:
	LD	DE,EMES_PASS1.WORK
	JP	ERROR

ERR_PASS1:
	LD	DE,EMES_PASS1
	JP	ERROR

ERR_BIN:
	LD	DE,EMES_BIN
	JP	ERROR

EMES_PASS1.WORK:
	DB	'Too large Program !$'

EMES_PASS1:
	DB	'Too many Labels !$'

EMES_BIN:
	DB	'Not binary file !$'

MES_CSROFF:
	DB	1BH,'x5','$'

WRVDP:	DS	1

PASS:	DS	1

X:	DS	1
MAX_X:	DS	1
BUFFER:	DS	200


OFFSET:	DS	2	;File Top OFFSET ADDRESS

PNT:	DS	2	;Get Data Pointer in Memory  WORK ~ WORK+SIZE-1

TOP_ADR:DS	2
END_ADR:DS	2	;Dis-assemble END ADDRESS  OFFSET+SIZE-1
ADR:	DS	2	;Current ADDRESS  OFFSET ~ END ADDRESS

WRITE_END_ADR:DS	2
SEGMENT_TOP:DS	2
SEGMENT_END:DS	2

CRLF_FLAG:DS	1

COUNT:	DS	1

FLG_IX_IY:
	DS	1

BYTES:	DS	1

CODE:	DS	1

;	file

FILE1:	DS	25H
FILE2:	DS	25H

R_LEFT:	DS	2
R_PNT:	DS	2
R_FLG:	DS	1

W_LEFT:	DS	2
W_PNT:	DS	2

W_WORK:	DS	WRITE_BYTES

FILE_SIZE_CNT:DS	2
CUT_SIZE:	DS	2

NEXTDW_FLAG:DS	1
VIEW_FLAG:DS	1
BIN_FLAG:DS	1
FILE_SIZE:DS	2

READ_BUFFER:

;

WORK:

* getty - get tty
*
* Itagaki Fumihiko 27-Jan-92  Create.
*
* Usage: getty [ type [ tty [ logname ] ] ]

.include doscall.h
.include chrcode.h
.include limits.h

.xref DecodeHUPAIR
.xref EncodeHUPAIR
.xref SetHUPAIR
.xref isalnum
.xref utoa
.xref strlen
.xref strchr
.xref strmove
.xref memmovi
.xref strfor1
.xref strazbot
.xref cat_pathname
.xref getenv
.xref setenv
.xref getcwd
.xref fclose
.xref chdir

** �ϒ萔
MAXLOGNAME	equ	64
CMDLINE_SIZE	equ	256

STACKSIZE	equ	512

.text

start:
		bra.s	start1
		dc.b	'#HUPAIR',0			*  HUPAIR�K���錾
start1:
		move.l	8(a0),a5			*  A5 := �^����ꂽ�������̒�
		lea	bsstop(pc),a6			*  A6 := BSS�̐擪�A�h���X
		lea	stack_bottom(a6),a7		*  A7 := �X�^�b�N�̒�
		move.l	a3,getty_envp(a6)		*  ���̃A�h���X���L������
		clr.l	user_envp(a6)
	*
	*  getty���g�̃J�����g�E�f�B���N�g����ۑ�����
	*
		lea	getty_cwd(a6),a0
		bsr	getcwd
	*
	*  �W�����͂��[�����ǂ������`�F�b�N����
	*
		clr.l	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		btst	#7,d0				*  character=1/block=0
		beq	not_a_tty
	*
	*  �������f�R�[�h���C���߂���
	*
		clr.b	logname(a6)

		lea	envarg_top(a6),a1	*  A1 := �������т��i�[����G���A�̐擪�A�h���X
		lea	1(a2),a0		*  A0 := �R�}���h���C���̕�����̐擪�A�h���X
		bsr	strlen			*  D0.L �� A0 ������������̒��������߁C
		add.l	a1,d0			*    �i�[�G���A�̗e�ʂ�
		cmp.l	a5,d0			*    �`�F�b�N����
		bhs	insufficient_memory

		bsr	DecodeHUPAIR			*  �f�R�[�h����
	*
	*  �c��̈������X�^�b�N�̒���ɕۑ�����
	*
		move.l	d0,d1
		lea	envarg_top(a6),a0
		bra	move_envarg_continue

move_envarg_loop:
		bsr	strmove
move_envarg_continue:
		subq.l	#1,d1
		bcc	move_envarg_loop
	*
	*  ��L��������؂�l�߂�
	*
		DOS	_GETPDB
		movea.l	d0,a1				*  A1 : PDB�A�h���X
		move.l	a0,d0
		sub.l	a1,d0
		move.l	d0,-(a7)
		move.l	a1,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
	*
	*  �V�O�i���������[�`����ݒ肷��
	*
		st	in_me
		pea	manage_interrupt_signal(pc)
		move.w	#_CTRLVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7
		pea	manage_abort_signal(pc)
		move.w	#_ERRJVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7
re_ask_logname:
	*
	*  ���O�C��������͂���
	*
		lea	msg_login(pc),a1
		lea	logname(a6),a0
		moveq	#MAXLOGNAME,d0
		bsr	getname
		bmi	done_getty_0

		bsr	put_newline
check_logname_loop:
		move.b	(a0)+,d0
		beq	re_ask_logname

		bsr	isalnum
		bne	check_logname_loop
	*
	*  ���[�U�̃V�F���ƃp�����[�^�����肷��
	*
		lea	default_login(pc),a1
		lea	program_pathname(a6),a0
		bsr	make_sys_pathname
		bmi	too_long_program_name

		lea	program_args(a6),a0
		move.l	#CMDLINE_SIZE,d0
		lea	str_p(pc),a1
		moveq	#1,d1
		bsr	EncodeHUPAIR
		bmi	too_long_args_for_program

		lea	logname(a6),a1
		moveq	#1,d1
		bsr	EncodeHUPAIR
		bmi	too_long_args_for_program

		lea	program_args(a6),a1
		lea	program_pathname(a6),a2
		move.l	#CMDLINE_SIZE,d1
		bsr	SetHUPAIR
		bmi	too_long_args_for_program
	*
	*  ���[�U�̊����쐬����
	*
		*
		*  ���[�U�̊��̂��߂ɍő�u���b�N���m�ۂ���
		*
		move.l	#$00ffffff,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		sub.l	#$81000000,d0
		move.l	d0,d1				*  D1.L : �m�ۉ\�ȑ傫��
		cmp.l	#5,d1
		blo	insufficient_memory

		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	insufficient_memory

		move.l	d0,user_envp(a6)
		movea.l	d0,a3				*  A3 : ���[�U�̊�
		movea.l	a3,a2
		move.l	d1,(a2)+
		subq.l	#5,d1
		*
		*  getty�̊����p������
		*
		movea.l	getty_envp(a6),a0
		cmpa.l	#-1,a0
		beq	dupenv_done

		addq.l	#4,a0
dupenv_loop:
		tst.b	(a0)
		beq	dupenv_done

		bsr	strlen
		addq.l	#1,d0
		sub.l	d0,d1
		bcs	insufficient_memory

		movea.l	a0,a1
		movea.l	a2,a0
		bsr	memmovi
		movea.l	a0,a2
		movea.l	a1,a0
		bra	dupenv_loop

dupenv_next:
		bsr	strfor1
		bra	dupenv_loop

dupenv_done:
		clr.b	(a2)
		*
		*  ���[�U�̊���؂�l�߂�
		*
		lea	4(a3),a0
		bsr	strazbot
		addq.l	#2,a0
		move.l	a0,d0
		sub.l	a3,d0
		bclr	#0,d0
		move.l	d0,(a3)
		move.l	d0,-(a7)
		move.l	a3,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
	*
	*  ���[�U�̃V�F����exec����
	*
		sf	in_me
		move.l	user_envp(a6),-(a7)		*  ���[�U�̊��̃A�h���X
		pea	program_args(a6)		*  �N������v���O�����ւ̈����̃A�h���X
		pea	program_pathname(a6)		*  �N������v���O�����̃p�X���̃A�h���X
		clr.w	-(a7)				*  �t�@���N�V�����FLOAD&EXEC
		DOS	_EXEC
		lea	14(a7),a7
		lea	bsstop(pc),a6
		st	in_me
		tst.l	d0
		bpl	done_getty_0

		lea	program_pathname(a6),a0
		lea	msg_unable_to_execute(pc),a1
		bsr	werror2
		moveq	#1,d0
		bra	done_getty

done_getty_0:
		moveq	#0,d0
done_getty:
	*
	*  �I������
	*
		bsr	reset_getty
do_exit:
		move.w	d0,-(a7)
		DOS	_EXIT2
*****************************************************************
manage_abort_signal:
		move.l	#$3fc,d0		* D0 = 000003FC
		cmp.w	#$100,d1
		bcs	manage_signals

		addq.l	#1,d0			* D0 = 000003FD
		cmp.w	#$200,d1
		bcs	manage_signals

		addq.l	#2,d0			* D0 = 000003FF
		cmp.w	#$ff00,d1
		bcc	manage_signals

		cmp.w	#$f000,d1
		bcc	manage_signals

		move.b	d1,d0
		bra	manage_signals

manage_interrupt_signal:
		move.l	#$200,d0		* D0 = 00000200
manage_signals:
		tst.b	in_me
		beq	do_exit

		lea	bsstop(pc),a6
		lea	stack_bottom(a6),a7
		bra	done_getty
*****************************************************************
reset_getty:
		move.l	d0,-(a7)
		move.l	user_envp(a6),d0
		beq	free_envp_ok

		move.l	d0,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
		clr.l	user_envp(a6)
free_envp_ok:
		bsr	xfclose
		lea	getty_cwd(a6),a0
		bsr	chdir
		move.l	(a7)+,d0
		rts
*****************************************************************
insufficient_memory:
		lea	msg_insufficient_memory(pc),a0
werror_exit:
		bsr	werror
		move.w	#1,-(a7)
		DOS	_EXIT2

not_a_tty:
		lea	msg_not_a_tty(pc),a0
		bra	werror_exit

too_long_program_name:
		lea	msg_too_long_program_name(pc),a0
		bra	werror_exit

too_long_args_for_program:
		lea	msg_too_long_args_for_program(pc),a0
		bra	werror_exit
*****************************************************************
werror2:
		move.l	a0,-(a7)
		movea.l	a1,a0
		bsr	werror
		lea	msg_space_quote(pc),a0
		bsr	werror
		move.l	(a7)+,a0
		bsr	werror
		lea	msg_quote_crlf(pc),a0
werror:
		movea.l	a0,a1
werror_1:
		tst.b	(a1)+
		bne	werror_1

		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		rts
*****************************************************************
xfclose:
		move.l	d0,-(a7)
		move.w	file_handle(a6),d0
		bmi	xfclose_done

		bsr	fclose
		move.w	#-1,file_handle(a6)
xfclose_done:
		move.l	(a7)+,d0
		rts
****************************************************************
* getname - �W�����͂���G�R�[�t����1�s���͂���iCR�܂���LF�܂Łj
*
* CALL
*      A0     ���̓o�b�t�@
*      D0.L   �ő���̓o�C�g���iCR��LF�͊܂܂Ȃ��j
*
* RETURN
*      D0.L   ���͕������iCR��LF�͊܂܂Ȃ��j
*             ������ EOF �Ȃ� -1
*      CCR    TST.L D0
****************************************************************
getname:
		movem.l	d1-d2/a0-a2,-(a7)
		move.l	d0,d2
getname_restart:
		move.l	a1,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		moveq	#0,d1
		movea.l	a0,a2
getname_loop:
		cmp.l	d2,d1
		beq	getname_done

		DOS	_INKEY
		tst.l	d0
		bmi	getname_done

		cmp.b	#CR,d0
		beq	getname_done

		cmp.b	#LF,d0
		beq	getname_done

		cmp.b	#$03,d0				*  $03 == ^C : Interrupt
		beq	getname_cancel

		cmp.b	#$04,d0				*  $04 == ^D : EOF
		beq	getname_eof

		cmp.b	#$15,d0				*  $15 == ^U : Kill
		beq	getname_cancel

		move.b	d0,(a2)+
		addq.l	#1,d1
		move.w	d0,-(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
		bra	getname_loop

getname_cancel:
		bsr	put_newline
		bra	getname_restart

getname_eof:
		moveq	#-1,d1
getname_done:
		clr.b	(a2)
		move.l	d1,d0
		movem.l	(a7)+,d1-d2/a0-a2
		rts
*****************************************************************
put_newline:
		moveq	#CR,d0
		bsr	putchar
		moveq	#LF,d0
putchar:
		move.w	d0,-(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
		rts
*****************************************************************
make_sys_pathname:
		movem.l	d0/a0-a4,-(a7)
		movea.l	a0,a4
		movea.l	a1,a2
		movea.l	getty_envp(a6),a3
		cmpa.l	#-1,a3
		beq	make_sys_pathname_sysroot_null

		lea	word_SYSROOT(pc),a0
		bsr	getenv
		bne	make_sys_pathname_cat
make_sys_pathname_sysroot_null:
		lea	str_nul,a0
		move.l	a0,d0
make_sys_pathname_cat:
		movea.l	d0,a1
		movea.l	a4,a0
		bsr	cat_pathname
make_sys_pathname_return:
		movem.l	(a7)+,d0/a0-a4
return:
		rts
*****************************************************************
.data

	dc.b	0
	dc.b	'## getty 0.0 ##  Copyright(C)1992 by Itagaki Fumihiko',0

word_SYSROOT:			dc.b	'SYSROOT',0
msg_login:			dc.b	CR,LF,'getto',CR,LF,'login: ',0
msg_not_a_tty:			dc.b	'Not character device.',CR,LF,0
msg_insufficient_memory:	dc.b	'getty: Insufficient memory.',CR,LF,0
msg_unable_to_execute:		dc.b	'Unable to execute',0
msg_too_long_program_name:	dc.b	'Too long program pathname',CR,LF,0
msg_too_long_args_for_program:	dc.b	'Too long argument for program',CR,LF,0
msg_space_quote:		dc.b	' "',0
msg_quote_crlf:			dc.b	'"',CR,LF
str_nul:			dc.b	0

default_login:			dc.b	'/bin/login.x',0
str_p:				dc.b	'-p',0
*****************************************************************
.bss

in_me:		ds.b	1

.even
bsstop:
.offset 0

getty_envp:		ds.l	1
user_envp:		ds.l	1
file_handle:		ds.w	1
logname:		ds.b	MAXLOGNAME+1
program_pathname:	ds.b	MAXPATH+1
program_args:		ds.b	1+255+1
getty_cwd:		ds.b	MAXPATH+1
lbuf:			ds.b	12

		ds.b	STACKSIZE
.even
stack_bottom:
envarg_top:
*****************************************************************
.end start

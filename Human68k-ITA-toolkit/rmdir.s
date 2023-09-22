* rmdir - remove directory
*
* Itagaki Fumihiko  8-Jul-91  Create.
*
* Usage: rmdir <�f�B���N�g��> ...

.include doscall.h
.include error.h
.include chrcode.h

.xref DecodeHUPAIR
.xref strlen
.xref headtail
.xref drvchkp

STACKSIZE	equ	256

.text
start:
		bra.s	start1
		dc.b	'#HUPAIR',0
start1:
		movea.l	8(a0),a5			*  A5 := �^����ꂽ�������̒�
		lea	bsstop(pc),a6
		lea	stack(a6),a7
		movea.l	a7,a1		*  A1 := �������т��i�[����G���A�̐擪�A�h���X
		lea	1(a2),a0	*  A0 := �R�}���h���C���̕�����̐擪�A�h���X
		bsr	strlen		*  D0.L �� A0 ������������̒��������߁C
		add.l	a1,d0		*    �i�[�G���A�̗e�ʂ�
		cmp.l	a5,d0		*    �`�F�b�N����D
		bhs	insufficient_memory
		*
		bsr	DecodeHUPAIR	*  �f�R�[�h����D
		movea.l	a1,a0				*  A0 : �����|�C���^
		move.w	d0,d7				*  D7.W : �����J�E���^
		beq	too_few_args

		moveq	#0,d6				*  D6.W : �G���[�E�R�[�h
		subq.w	#1,d7
loop:
		bsr	drvchkp
		bmi	fail

		move.l	a0,-(a7)
		DOS	_RMDIR
		addq.l	#4,a7
		tst.l	d0
		bpl	next
fail:
		bsr	perror
		moveq	#3,d6
next:
		tst.b	(a0)+
		bne	next
		dbra	d7,loop
exit_program:
		move.w	d6,-(a7)
		DOS	_EXIT2
****************
too_few_args:
		bsr	werror_myname
		lea	msg_too_few_args(pc),a0
		bsr	werror
usage:
		lea	msg_usage(pc),a0
		bsr	werror
		moveq	#1,d6
		bra	exit_program
*****************************************************************
insufficient_memory:
		bsr	werror_myname
		lea	msg_no_memory(pc),a0
		bsr	werror
		moveq	#2,d6
		bra	exit_program
*****************************************************************
perror:
		move.l	a0,-(a7)
		bsr	werror_myname
		movea.l	(a7),a0
		bsr	werror
		lea	msg_colon(pc),a0
		bsr	werror
		not.l	d0		* -1 -> 0, -2 -> 1, ...
		cmp.l	#25,d0
		bls	perror_2

		cmp.l	#256,d0
		blo	perror_1

		sub.l	#256,d0
		cmp.l	#4,d0
		bhi	perror_1

		lea	perror_table_2(pc),a0
		bra	perror_3

perror_1:
		moveq	#25,d0
perror_2:
		lea	perror_table(pc),a0
perror_3:
		lsl.l	#2,d0
		movea.l	(a0,d0),a0
		bsr	werror
		lea	msg_newline(pc),a0
		bsr	werror
		movea.l	(a7)+,a0
		rts
*****************************************************************
werror_myname:
		lea	msg_myname(pc),a0
werror:
		movea.l	a0,a1
werror_1:
		tst.b	(a1)+
		bne	werror_1
werror_2:
		move.l	d0,-(a7)
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		move.l	(a7)+,d0
		rts
*****************************************************************
.data

	dc.b	0
	dc.b	'## rmdir 1.0 ##  Copyright(C)1991 by Itagaki Fumihiko',0

.even
perror_table:
	dc.l	msg_err			*   0 ( -1)
	dc.l	msg_nodir		*   1 ( -2)  ENOFILE
	dc.l	msg_notdir		*   2 ( -3)  ENODIR
	dc.l	msg_err			*   3 ( -4)
	dc.l	msg_err			*   4 ( -5)
	dc.l	msg_err			*   5 ( -6)
	dc.l	msg_err			*   6 ( -7)
	dc.l	msg_err			*   7 ( -8)
	dc.l	msg_err			*   8 ( -9)
	dc.l	msg_err			*   9 (-10)
	dc.l	msg_err			*  10 (-11)
	dc.l	msg_err			*  11 (-12)
	dc.l	msg_bad_filename	*  12 (-13)
	dc.l	msg_err			*  13 (-14)
	dc.l	msg_bad_drive		*  14 (-15)
	dc.l	msg_current		*  15 (-16)
	dc.l	msg_err			*  16 (-17)
	dc.l	msg_err			*  17 (-18)
	dc.l	msg_write_disabled	*  18 (-19)
	dc.l	msg_err			*  19 (-20)
	dc.l	msg_not_empty		*  20 (-21)
	dc.l	msg_err			*  21 (-22)
	dc.l	msg_err			*  22 (-23)
	dc.l	msg_err			*  23 (-24)
	dc.l	msg_err			*  24 (-25)
	dc.l	msg_err			*  25 (-26)
.even
perror_table_2:
	dc.l	msg_bad_drivename	* 256 (-257)
	dc.l	msg_no_drive		* 257 (-258)
	dc.l	msg_no_media_in_drive	* 258 (-259)
	dc.l	msg_media_set_miss	* 259 (-260)
	dc.l	msg_drive_not_ready	* 260 (-261)

msg_nodir:		dc.b	'���̂悤�ȃf�B���N�g���͂���܂���',0
msg_notdir:		dc.b	'�f�B���N�g���ł͂���܂���',0
msg_bad_filename:	dc.b	'���O�������ł�',0
msg_bad_drive:		dc.b	'�h���C�u�̎w�肪�����ł�',0
msg_current:		dc.b	'�J�����g�E�f�B���N�g���ł��̂ō폜�ł��܂���',0
msg_write_disabled:	dc.b	'�폜�͋�����Ă��܂���',0
msg_not_empty:		dc.b	'�f�B���N�g������łȂ��̂ō폜�ł��܂���',0
msg_bad_drivename:	dc.b	'�h���C�u���������ł�',0
msg_no_drive:		dc.b	'�h���C�u������܂���',0
msg_no_media_in_drive:	dc.b	'�h���C�u�Ƀ��f�B�A���Z�b�g����Ă��܂���',0
msg_media_set_miss:	dc.b	'�h���C�u�Ƀ��f�B�A���������Z�b�g����Ă��܂���',0
msg_drive_not_ready:	dc.b	'�h���C�u�̏������ł��Ă��܂���',0
msg_err:		dc.b	'�폜�ł��܂���ł���',0

msg_myname:		dc.b	'rmdir'
msg_colon:		dc.b	': ',0
msg_no_memory:		dc.b	'������������܂���',CR,LF,0
msg_illegal_option:	dc.b	'�s���ȃI�v�V���� -- ',0
msg_too_few_args:	dc.b	'����������܂���',0
msg_usage:		dc.b	CR,LF,'�g�p�@:  rmdir <�f�B���N�g��> ...'
msg_newline:		dc.b	CR,LF,0
*****************************************************************
.bss
.even
bsstop:
.offset 0
		ds.b	STACKSIZE
.even
stack:
*****************************************************************

.end start

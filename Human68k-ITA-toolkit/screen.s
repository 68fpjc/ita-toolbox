*****************************************************************
*								*
*	screen set command					*
*								*
*	SCREEN <width> <graphicmode> <displaymode>		*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h

STACKSIZE	equ	128

.text

cmd_screen:
		lea	stack(pc),a7
		clr.w	d2
		move.b	(a2)+,d2
		bsr	skip_space
		beq	initialize

		moveq	#1,d1
		bsr	getarg1
		move.w	d0,d3
		moveq	#3,d1
		bsr	getarg1
		move.w	d0,d4
		moveq	#3,d1
		bsr	getarg2
		bne	error

		move.w	d0,d5
		and.w	d3,d0
		and.w	d4,d0
		not.w	d0				* cmp.l #-1,d0 �̑���
		beq	screen_end			* ���ׂĂ� -1 �i���w��j
********************************
		moveq	#1,d1				* �Đݒ�t���O �� ON �ɂ��Ă���
		cmp.w	#-1,d3
		beq	get_current			* width �͖��w��

		cmp.w	#-1,d4
		beq	get_current			* graphicmode �͖��w��
		*
		*  width �� graphicmode �̗������w��L��
		*
		move.w	d4,d2
		tst.w	d3
		beq	change_graphicmode_on_width_0

		bra	change_graphicmode_on_width_1
****************
get_current:
		*
		*  width �� graphicmode �̏��Ȃ��Ƃ��ǂ��炩�͖��w��
		*
		move.w	#-1,-(a7)
		move.w	#16,-(a7)
		DOS	_CONCTRL
		addq.l	#4,a7
		move.w	d0,d2				* ���݂̃��[�h�� D2 ��
		cmp.w	#-1,d3
		bne	width_specified			* width �͎w��L��

		cmp.w	#-1,d4
		bne	graphicmode_specified		* graphicmode �͎w��L��
		*
		* width �� graphicmode ���ύX���Ȃ�
		*
		clr.w	d1				* �Đݒ�t���O OFF
		bra	width_and_graphicmode_ok
****************
graphicmode_specified:
		*
		* width ��ς����� graphicmode ���w��l�ɕύX����
		*
		cmp.w	#2,d2
		blo	change_graphicmode_on_width_0

		move.w	d4,d2				* ���݂� width �� 1 �ł��邩��
		bra	change_graphicmode_on_width_1	* ���[�h�� 2 + graphicmode �Ƃ���

change_graphicmode_on_width_0:
		cmp.w	#2,d4				* ���݂� width �� 0 �ł��邩��
		bhs	error				* 2 �ȏ�� graphicmode �̓G���[

		move.w	d4,d2
		bra	width_and_graphicmode_ok	* ���[�h�� graphicmode �Ƃ���
****************
width_specified:
		*
		*  graphicmode ��ς����� width ���w��l�ɕύX
		*
		tst.w	d3
		beq	change_width_to_0

change_width_to_1:
		*
		* graphicmode ��ς����� width �� 1 �ɕύX
		*
		cmp.w	#2,d2				* ���݂̃��[�h�� 2 �ȏ�Ȃ��
		bhs	width_and_graphicmode_ok	* ���̂܂܂� OK

change_graphicmode_on_width_1:
		add.w	#2,d2				* ���[�h�� 2 ��������
		bra	width_and_graphicmode_ok

change_width_to_0:
		*
		* graphicmode ��ς����� width �� 0 �ɕύX
		*
		cmp.w	#2,d2				* ���݂̃��[�h�� 0 �� 1 �Ȃ��
		blo	width_and_graphicmode_ok	* ���̂܂܂� OK

		sub.w	#2,d2				* 2 �Ȃ�� 0 �ɁA3 �Ȃ�� 1 �ɁA
		cmp.w	#2,d2
		blo	width_and_graphicmode_ok

		moveq	#1,d2				* 4 �ȏ�Ȃ�� 1 �ɂ���
****************
width_and_graphicmode_ok:
		cmp.w	#-1,d5
		beq	all_fixed

		tst.w	d2
		beq	check_graphic

		cmp.w	#2,d2
		bne	all_fixed
check_graphic:
		btst	#0,d5			* ���[�h�� 0 �܂��� 2 �ł���ꍇ�A
		bne	error			* displaymode �� 1 �܂��� 3 ���w�肷�邱�Ƃ͂ł��Ȃ�
all_fixed:
		tst.w	d1
		beq	change_displaymode
change_mode:
		move.w	d2,-(a7)
		move.w	#16,-(a7)
		DOS	_CONCTRL
		addq.l	#4,a7
change_displaymode:
		cmp.w	#-1,d5
		beq	screen_end

		move.l	#$93,d0
		move.w	#$ffff,d1
		trap	#15
		and.w	#$ffa0,d0
		bset	#5,d0
		btst	#0,d5
		beq	change_displaymode_1

		or.w	#$1f,d0
change_displaymode_1:
		btst	#1,d5
		beq	change_displaymode_2

		bset	#6,d0
change_displaymode_2:
		move.w	d0,d1
		move.l	#$93,d0
		trap	#15
screen_end:
		clr.w	-(a7)
		DOS	_EXIT2
********************************
initialize:
		clr.w	d2
		clr.w	d5
		bra	change_mode
****************************************************************
getarg1:
		move.w	#-1,d0
		tst.w	d2
		beq	getarg_done

		cmpi.b	#',',(a2)
		beq	noarg1

		bsr	getarg2
		beq	getarg_done

		cmpi.b	#',',(a2)
		bne	getarg_done
noarg1:
		addq.l	#1,a2
		subq.w	#1,d2
		bra	skip_space
********************************
getarg2:
		move.w	#-1,d0
		tst.w	d2
		beq	getarg_done

		moveq	#0,d0
		move.b	(a2)+,d0
		sub.b	#'0',d0
		blo	error

		cmp.w	d1,d0
		bhi	error

		subq.w	#1,d2
		beq	getarg_done

		cmpi.b	#'0',(a2)
		blo	getarg_ok

		cmpi.b	#'9',(a2)
		bls	error
getarg_ok:
skip_space:
		tst.w	d2
		beq	skip_space_return

		cmpi.b	#' ',(a2)
		beq	skip_space_continue

		cmp.b	#HT,(a2)
		beq	skip_space_continue

		cmpi.b	#CR,(a2)
		beq	skip_space_continue

		cmpi.b	#LF,(a2)
		beq	skip_space_continue

		cmpi.b	#VT,(a2)
		bne	skip_space_return
skip_space_continue:
		addq.l	#1,a2
		subq.w	#1,d2
		bne	skip_space
skip_space_return:
getarg_done:
		rts
********************************
error:
		move.l	#(msg_bad_arg_bottom-msg_bad_arg),-(a7)	* length
		pea	msg_bad_arg(pc)
		move.w	#2,-(a7)
		DOS	_WRITE
		move.w	#1,(a7)
		DOS	_EXIT2
****************************************************************
.data

msg_bad_arg:	dc.b	"�p�����|�^�������ł�",CR,LF,LF
		dc.b	"�g�p�@: screen [[��ʕ�],[[�O���t�B�b�N���[�h],[�\�����[�h]]]",CR,LF,LF
		dc.b	"��ʕ�:",CR,LF
		dc.b	HT,"0: ��96�����i�O���t�B�b�N768x512�h�b�g�j���[�h",CR,LF
		dc.b	HT,"1: ��64�����i�O���t�B�b�N512x512�h�b�g�j���[�h",CR,LF,LF
		dc.b	"�O���t�B�b�N���[�h:",CR,LF
		dc.b	HT,"0: �O���t�B�b�N����",CR,LF
		dc.b	HT,"1: �O���t�B�b�N16�F",CR,LF
		dc.b	HT,"2: �O���t�B�b�N256�F",CR,LF
		dc.b	HT,"3: �O���t�B�b�N65536�F",CR,LF
		dc.b	"�i��ʕ���'0'�̂Ƃ��C�O���t�B�b�N���[�h'2'��'3'�͖����j",CR,LF,LF
		dc.b	"�\�����[�h:",CR,LF
		dc.b	HT,"0: �e�L�X�g��\��",CR,LF
		dc.b	HT,"1: �e�L�X�g�C�O���t�B�b�N��\��",CR,LF
		dc.b	HT,"2: �e�L�X�g�C�X�v���C�g��\��",CR,LF
		dc.b	HT,"3: �e�L�X�g�C�O���t�B�b�N�C�X�v���C�g��\��",CR,LF
		dc.b	"�i�O���t�B�b�N���[�h��'0'�̂Ƃ��C�\�����[�h'1'��'3'�͖����j",CR,LF,LF
		dc.b	"�ȗ������p�����[�^�͌��݂̐ݒ�̂܂܂Ƃ��܂�",CR,LF
		dc.b	"�������C�p�����[�^����ؖ����ꍇ�͊e�p�����[�^��'0'�Ƃ��܂�",CR,LF
msg_bad_arg_bottom:
****************************************************************
.bss
		ds.b	STACKSIZE
.even
stack:
****************************************************************

.end cmd_screen

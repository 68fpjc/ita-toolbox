*****************************************************************
*								*
*	volume name command					*
*								*
*	VOL [<drive>:]						*
*       VOL -c [<drive>:]					*
*       VOL -s [<drive>:]<name>					*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h
.include filemode.h

STACKSIZE	equ	512

.text

cmd_vol:
		lea	stack(pc),a7
		move.b	(a2)+,d2			* A2�̓p�����[�^�BD2�͂��̒���
	**
	**  �X�C�b�`�̉���
	**
		clr.b	d3				* D3�� -c�t���O�B���Z�b�g���Ă���
		clr.b	d4				* D4�� -s�t���O�B���Z�b�g���Ă���
		bsr	skip_space
		beq	nomore_sw

		cmpi.b	#'-',(a2)
		bne	nomore_sw

		cmp.b	#2,d2
		blo	arg_error			* Bad switch arg.

		move.b	1(a2),d0
		cmp.b	#'s',d0
		beq	sw_set

		cmp.b	#'c',d0
		bne	arg_error			* Unknown switch.
sw_clr:
		moveq	#1,d3				* -c�t���O���Z�b�g����
		bra	sw_ok
sw_set:
		moveq	#1,d4				* -s�t���O���Z�b�g����
sw_ok:
		addq.l	#2,a2
		subq.b	#2,d2
		beq	nomore_sw

		movea.l	a2,a0
		bsr	skip_space
		cmpa.l	a0,a2
		beq	arg_error			* Bad switch arg.
nomore_sw:
	**
	**  �����̐��̃`�F�b�N
	**  D1.B �ɂ͎��̌�̒������Z�b�g�����
	**
		movea.l	a2,a0				* ��̐擪�A�h���X�� A0 �ɃZ�[�u
		clr.b	d1				* D1�͌�̒���
find_tail:
		movea.l	a2,a3
		bsr	skip_space
		beq	tail_ok

		cmpa.l	a3,a2
		bne	arg_error			* ��̌��ɍX�Ɉ���������

		addq.b	#1,d1
		addq.l	#1,a2
		subq.b	#1,d2
		bne	find_tail
tail_ok:
		**	�����܂ŗ���΁A���� A2/D2 �͗v��Ȃ��B
		**	A0/D1 �� �����ł���B
	**
	**  <drive>: �𒲂ׂ�
	**  ��������΁A�啶���ɂ��� D5.W �ɃZ�b�g����
	**  �Ȃ���� D5.W �� 0 �Ƃ���
	**
		clr.w	d5				* D5�͎w��h���C�u���B0 �Ƃ��Ă���
		cmp.b	#2,d1
		blo	drivename_skipped

		cmpi.b	#':',1(a0)
		bne	drivename_skipped

		move.b	(a0),d0
		cmp.b	#'a',d0
		bcs	tou_e

		cmp.b	#'z',d0
		bhi	tou_e

		sub.b	#$20,d0
tou_e:
		cmp.b	#'A',d0
		blo	drive_error			* Bad drive name

		move.b	d0,d5				* D5�Ɏw��̃h���C�u�����Z�b�g
		addq.l	#2,a0
		subq.b	#2,d1

drivename_skipped:
	**
	**  <name>�𒲂ׂ�
	**
		tst.b	d1
		bne	name_specified

		*
		*  <name>�͖���
		*
		tst.b	d4				* -s �̂Ƃ��ɂ�
		bne	arg_error			* �����̓G���[��

		bra	arg_ok

name_specified:
		*  <name>������
		*
		tst.b	d4				* -s �łȂ����
		beq	arg_error			* �����̓G���[��

		cmp.b	#21,d1
		bhi	vol_errn			* <name> �����߂���
		*
		*  <name> ���A���������`�F�b�N���Ȃ��� new_volume_label �ɃZ�b�g����
		*  19 �����߂̑O�ɂ� . ��t������
		*
		lea	new_volume_label+3(pc),a1
		clr.b	d2				* D2�͕������J�E���^
make_volume_name_loop_0:
		clr.b	d7				* D3�͊����J�E���^
make_volume_name_loop:
		tst.b	d1
		beq	make_volume_name_done

		cmp.b	#18,d2
		bne	make_volume_name_1

		move.b	#'.',(a1)+
make_volume_name_1:
		subq.b	#1,d1
		move.b	(a0)+,d0
		move.b	d0,(a1)+
		addq.b	#1,d2
		cmp.b	#':',d0
		beq	vol_errn			* �s���ȕ���

		cmp.b	#'.',d0
		beq	vol_errn			* �s���ȕ���

		cmp.b	#'*',d0
		beq	vol_errn			* �s���ȕ���

		cmp.b	#'?',d0
		beq	vol_errn			* �s���ȕ���

		cmp.b	#'/',d0
		beq	vol_errn			* �s���ȕ���

		cmp.b	#'\',d0
		beq	vol_errn			* �s���ȕ���

		tst.b	d7
		bne	make_volume_name_loop_0

		cmp.b	#$80,d0
		blo	make_volume_name_loop

		cmp.b	#$a0,d0
		blo	make_volume_name_2Bcode

		cmp.b	#$e0,d0
		blo	make_volume_name_loop
make_volume_name_2Bcode:
		cmp.b	#18,d2
		beq	vol_errn			* �������啔�Ɗg���q�Ɍׂ��Ă���

		cmp.b	#21,d2
		beq	vol_errn			* �������������݂͂łĂ���

		move.b	#1,d7
		bra	make_volume_name_loop

make_volume_name_done:
		clr.b	(a1)				* �R�s�[����

arg_ok:
	**
	**  �Ώۃh���C�u�����߂�
	**
		DOS	_CURDRV
		tst.w	d5
		beq	for_current_drive

		move.w	d0,d1		* ��� _CURDRV �̒l
		move.w	d5,d2
		sub.b	#'A',d2
		move.w	d2,-(a7)
		DOS	_CHGDRV
		addq.l	#2,a7
		cmp.w	d2,d0
		bls	drive_error			* Bad specified drivename.

		move.w	d1,-(a7)
		DOS	_CHGDRV
		addq.l	#2,a7
		bra	drive_ok

for_current_drive:
		add.b	#'A',d0
		move.b	d0,d5
drive_ok:
		lea	findbuf(pc),a0				* �ǂ̏ꍇ�ɂ��g����
		bsr	set_drive_name
		move.b	#'*',(a0)+
		move.b	#'.',(a0)+
		move.b	#'*',(a0)+
		clr.b	(a0)

		lea	delete_name_buf(pc),a0			* erase �� change �Ŏg����
		bsr	set_drive_name

		tst.b	d4					* -s
		bne	change_volume

		tst.b	d3					* -c
		bne	erase_volume
********************************
show_volume:
		pea	msg_volume1(pc)
		DOS	_PRINT
		move.w	d5,-(a7)
		DOS	_PUTCHAR
		pea	msg_volume2(pc)
		DOS	_PRINT
		lea	10(a7),a7

		bsr	find_volume
		bmi	show_volume_none

		bsr	put_a_space
		lea	filebuf_packedname(pc),a0
		move.w	#22,d1
		subq.l	#2,a7
		moveq	#0,d0
vol_prlp:
		tst.w	d1
		beq	vol_p2

		move.b	(a0)+,d0
		beq	vol_pr1

		cmp.b	#'.',d0
		beq	vol_prx

		move.w	d0,(a7)
		DOS	_PUTCHAR
vol_prx:
		dbra	d1,vol_prlp

vol_pr0:
		bsr	put_a_space
vol_pr1:
		dbra	d1,vol_pr0
vol_p2:
		addq.l	#2,a7
		pea	msg_datetime3(pc)
		bra	show_volume_done

show_volume_none:
		pea	msg_novolume(pc)
show_volume_done:
		DOS	_PRINT
		addq.l	#4,a7
		bra	vol_exit
********************************
erase_volume:
		bsr	vol_clr_sub
		beq	vol_errf
		bmi	vol_errd1
		bra	vol_exit
********************************
change_volume:
		lea	new_volume_label(pc),a0
		bsr	set_drive_name
		*
		*  ���{�����[���E���x����T���ă^�C���E�X�^���v��D1�ɓ���
		*
		clr.l	d1
		bsr	find_volume
		bmi	find_current_volume_done

		lea	filebuf_datime(pc),a0
		move.l	(a0),d1
		swap	d1
find_current_volume_done:
		*
		*  �V�{�����[���E���x�����Ɠ������O��
		*  �f�B���N�g���E�G���g���i�{�����[���E���x���������j��
		*  �������Ƃ��`�F�b�N����
		*
		move.w	#$3f,-(a7)
		pea	new_volume_label(pc)
		pea	filebuf(pc)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
find_same_name_entry:
		bmi	vol_change_2			* ����

		btst.b	#FILEMODE_VOLUME,filebuf_atr(pc)
		beq	vol_errm			* ����I

		bsr	findnext
		bra	find_same_name_entry
vol_change_2:
		*
		*  �V�{�����[���E���x�����Ɠ������O��
		*  �f�o�C�X���������Ƃ��`�F�b�N����
		*
		move.w	#2,-(a7)
		pea	new_volume_label(pc)
		DOS	_OPEN
		addq.l	#6,a7
		tst.l	d0
		bpl	vol_errcm
		*
		*  ���{�����[���E���x�����폜����
		*
		bsr	vol_clr_sub
		bmi	vol_errd
		*
		*  �V�����{�����[���E���x����V�K�쐬����
		*
		move.w	#8,-(a7)
		pea	new_volume_label(pc)
		DOS	_CREATE
		addq.l	#6,a7
		tst.l	d0
		bmi	vol_errm
		*
		*  �V�����{�����[���E���x���̃^�C���E�X�^���v��
		*  ���{�����[���E���x���i��������΁j�ɍ��킹��
		*
		move.l	d1,-(a7)	* D1 �� 0 �̂Ƃ����A�擾�ƂȂ邾����������v
		move.w	d0,-(a7)
		DOS	_FILEDATE
		move.l	d0,d1
		move.w	(a7)+,d0
		addq.l	#4,a7
		swap	d1
		cmp.w	#$ffff,d1
		beq	vol_errcm

		move.w	d0,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
		tst.l	d0
		bmi	vol_errm
vol_exit:
		clr.w	-(a7)
		DOS	_EXIT2
****************
vol_errcm:
		move.l	d0,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
vol_errm:
		lea	msg_volnomake(pc),a0
		move.w	#$502,-(a7)
		bra	error_exit
drive_error:
		lea	msg_drive_err(pc),a0
		move.w	#$500,-(a7)
		bra	error_exit
arg_error:
		lea	msg_bad_arg(pc),a0
		move.w	#$500,-(a7)
		bra	error_exit
vol_errd:
		lea	msg_volnodel(pc),a0
		move.w	#$502,-(a7)
		bra	error_exit
vol_errd1:
		lea	msg_volnodel1(pc),a0
		move.w	#$502,-(a7)
		bra	error_exit
vol_errn:
		lea	msg_volume_err(pc),a0
		move.w	#$500,-(a7)
		bra	error_exit
vol_errf:
		lea	msg_volnofound(pc),a0
		move.w	#$503,-(a7)
error_exit:
		movea.l	a0,a1
strlen_loop:
		tst.b	(a1)+
		bne	strlen_loop

		move.l	a1,d0
		subq.l	#1,d0
		sub.l	a0,d0
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		DOS	_EXIT2
****************************************************************
set_drive_name:
		move.b	d5,(a0)+
		move.b	#':',(a0)+
		move.b	#'\',(a0)+
		rts
****************************************************************
vol_clr_sub:
		bsr	find_volume
		bmi	vol_clr_none
vol_clr_sub_1:
		btst.b	#FILEMODE_READONLY,filebuf_atr(pc)
		bne	vol_clr_rerr

		lea	delete_name_buf+3(pc),a0
		lea	filebuf_packedname(pc),a1
		move.w	#18+1+3+1-1,d0
set_delete_name:
		move.b	(a1)+,(a0)+
		dbra	d0,set_delete_name

		clr.w	-(a7)
		pea	delete_name_buf(pc)
		DOS	_CHMOD
		addq.l	#6,a7
		tst.l	d0
		bmi	vol_clr_err

		pea	delete_name_buf(pc)
		DOS	_DELETE
		addq.l	#4,a7
		tst.l	d0
		bmi	vol_clr_err

		bsr	findnext
		bpl	vol_clr_sub_1

		moveq	#1,d0
		rts

vol_clr_none:
		clr.l	d0
		rts

vol_clr_rerr:
		moveq	#-1,d0
vol_clr_err:
		rts
****************************************************************
find_volume:
		move.w	#$08,-(a7)
		pea	findbuf(pc)
		pea	filebuf(pc)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
		rts
****************************************************************
findnext:
		pea	filebuf(pc)
		DOS	_NFILES
		addq.l	#4,a7
		tst.l	d0
		rts
****************************************************************
put_a_space:
		move.w	#' ',-(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
		rts
****************************************************************
skip_space:
		tst.b	d2
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
		rts
****************************************************************
.data

msg_volume1:	dc.b	'�h���C�u ',0
msg_volume2:	dc.b	': �̃{�����|�����x����',0
msg_datetime3:	dc.b	' �ł�',CR,LF,0
msg_novolume:	dc.b	'����܂���',CR,LF,0
msg_volume_err:	dc.b	'�{�����|�����x���������ł�',CR,LF,0
msg_volnomake:	dc.b	'�{�����|�����x�������܂���',CR,LF,0
msg_drive_err:	dc.b	'�h���C�u���������ł�',CR,LF,0
msg_bad_arg:	dc.b	'�p�����|�^�������ł�',CR,LF,0
msg_volnodel:	dc.b	'��'
msg_volnodel1:	dc.b	'�{�����|�����x���������ł��܂���',CR,LF,0
msg_volnofound:	dc.b	'�{�����|�����x����������܂���',CR,LF,0
****************************************************************
.bss

.even
filebuf:
filebuf_sys_atr:	ds.b	1		* 0
filebuf_sys_driveno:	ds.b	1		* 1
filebuf_sys_dircls:	ds.w	1		* 2
filebuf_sys_dirfat:	ds.w	1		* 4
filebuf_sys_dirsec:	ds.w	1		* 6
filebuf_sys_dirpos:	ds.w	1		* 8
filebuf_sys_filename:	ds.b	8		* 10
filebuf_sys_ext:	ds.b	3		* 18
filebuf_atr:		ds.b	1		* 21
filebuf_datime:
filebuf_time:		ds.w	1		* 22
filebuf_date:		ds.w	1		* 24
filebuf_filelen:	ds.l	1		* 26
filebuf_packedname:	ds.b	18+1+3+1	* 30

new_volume_label:	ds.b	26		* '?:\(18).(3)',0
findbuf:		ds.b	7		* '?:\*.*',0
delete_name_buf:	ds.b	26

			ds.b	STACKSIZE
.even
stack:
****************************************************************

.end cmd_vol

* humanver.s
*
* Itagaki Fumihiko 27-Jan-91  Create.
****************************************************************
*  Name
*       humanver - print version number of human68k
*
*  Synopsis
*       humanver
****************************************************************

.include doscall.h
.include chrcode.h

STACKSIZE	equ	2+16

.text

start:
		lea	stack(pc),a7
		DOS	_VERNUM
		move.w	d0,d1
		ext.w	d1
		ext.l	d1
		divu	#10,d1
		move.l	d1,d2
		lsr	#8,d0
		swap	d2
		and.b	#%1111,d0
		add.b	#'0',d0
		and.b	#%1111,d1
		add.b	#'0',d1
		and.b	#%1111,d2
		add.b	#'0',d2
		move.w	d0,-(a7)
		DOS	_PUTCHAR
		move.w	#'.',(a7)
		DOS	_PUTCHAR
		move.w	d1,(a7)
		DOS	_PUTCHAR
		move.w	d2,(a7)
		DOS	_PUTCHAR
		move.w	#CR,(a7)
		DOS	_PUTCHAR
		move.w	#LF,(a7)
		DOS	_PUTCHAR
		clr.w	(a7)
		DOS	_EXIT2
****************************************************************
.bss
		ds.b	STACKSIZE
.even
stack:
****************************************************************

.end start

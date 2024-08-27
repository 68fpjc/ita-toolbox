	.text

	.even
getlnenv::
* SAVREGS	.reg	a0-a1/a4-a5
SAVREGS		.reg	a0-a1/a5	* a4 は壊れない
	movem.l	SAVREGS,-(sp)
	.dc.w	$ff51			* DOS _GETPDB
	movea.l	d0,a0
	lea	-16(a0),a0
	pea	_keepchk(pc)
	.dc.w	$fff6			* DOS _SUPER_JSR
	addq	#4,sp
	tst.l	d0
	beq	@f
	addi.l	#240,d0
@@:
	movem.l	(sp)+,SAVREGS
	rts

*	↓ LNDRV126.LZH/lnsrc126.lzh/tsrend.s より ここから
*---------------------------------------------------------------*
*	_keepchk - 常駐チェックルーチン
*		常駐チェックは、常駐識別文字列によって行なう。
*		_SUPER_JSR するか _SUPER してコールすること
*		in  : a0.l	自分自身の PSP(メモリ管理ポインタ)
*		out : d0.l	0...常駐していない other...常駐アドレス(PDBADR)
*		broken : a1, a4, a5

	.even
_keepchk:
	move.l	a0,a1
	move.l	#'LNDR',d0
_keeploop:
	move.l	(a1),a1
	tst.l	4(a1)
	beq	_nonkeep
	lea	$100(a1),a5
	cmpa.l	8(a1),a5
	bge	_keeploop
	cmp.l	(a5),d0
	bne	_keeploop
	lea.l	$10(a1),a1
	move.l	a1,d0
	rts
_nonkeep:
	moveq.l	#0,d0
	rts

*---------------------------------------------------------------*
*	↑ LNDRV126.LZH/lnsrc126.lzh/tsrend.s より ここまで

	.end

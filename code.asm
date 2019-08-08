		LIST P=16f84, R=HEX
		__FUSES _XT_OSC & _WDT_OFF & _CP_OFF & _PWRTE_ON
		include "C:\Program Files (x86)\gputils\header\P16F84.inc"
		cblock 0x0023	;variables
			code		;code displayed on LED
			uncode		;unlock code
			att         ;number of attempts
		endc
		
		;start
		clrf PORTB		
		bsf STATUS, RP0	;change register
		clrf TRISB		; declare PORTB as output
		bcf TRISA,0		;declare PORTA,0 as output
		bsf TRISA,1		;declare PORTA,1 as input
		bsf TRISA,2		;declare PORTA,2 as input
		bsf TRISA,3		;declare PORTA,3 as input
		bsf TRISA,4		;declare PORTA,4 as input
		bcf STATUS, RP0	; return to previous register
		movlw B'00000000'; this line can be changed to any master unlock code (which is why it is seperated from other lines despite in this case being redundant)
		movwf uncode	;set uncode as '00000000'--- generic number can be changed and set to any reset code 
		movlw B'00000000'
		movwf code		;set code as '00000000'
		movwf att		;set att as '00000000'
loop	
	btfss PORTA,4	; see if RA4 is pressed
	call codecheck	;copare code to the unlockcode
	btfss PORTA,3	; see if RA3 is presed
	call unlockcheck; make sure lock is in unlocked state
	btfss PORTA,1	;see if button RA1 is pressed
	call bup		;increase code by 1 bit	
	btfss PORTA,2	; see if button RA2 is pressed
	call bown		; decrease code by 1 bit
	movlw B'00001111'
	andwf code,W	;retrieve a pure code (no att)
	addwf att,W		;combine att and code
	movwf PORTB		; display code in portb
	call attemptcheck; make sure the user can still attempt to unlock system
	goto loop
	
codecheck
	movlw b'00001111'
	andwf code,W	;copy code and mask bits (use reverse thinking)	
	subwf uncode,W	;sub uncode from entered code
	btfsc STATUS,Z	;test if zero
	call unorl		;lock or unlock system
	movlw B'01000000'
	btfss PORTA,0	;make sure in locked state
	addwf att		;increase att
	call test1		; check if button is released
	return	
unorl
	btfss PORTA,0 	;see whether the lock is locked 
	call unlock		;lock is locked call un sequence
	call relock		; lock is open call relock sequence
	return			;return to codecheck	
	
unlock 
	bsf PORTA,0		;turn on light A0
	movlw b'00000000';
	movwf att		; reset attempts
	call test1		; check if button is released

relock
	bcf PORTA,0		;turn off light A0
	movlw b'00000000'
	movwf code		;reset code at 0 
	call test1		; check if button is released

unlockcheck
	btfsc PORTA,0	; see if lock is unlocked
	call codechange	; change the unlock code
	return			;else return to main loop
codechange
	movlw b'00001111'
	andwf code,W	;take code
	movwf uncode	;replace unlock code by code
	call test1 		; make sure button is released
	return			;return to unlockcheck	

bup
	incf code 		;increase number in code
	movlw B'00010000'
	btfsc code,4	;if number is too big ->
	subwf code	; take offset off of code to return to 0000
	goto test1		;make sure button is released
	return			;return to main loop

bown
	decf code		;decrease number in code
	movlw B'00010000'
	btfsc code,4	; if number is below 0 ->
	addwf code		; add number to code to return to 1111
	goto test1		; make sure button is released
	return			;return to main loop

test1	
	btfss PORTA,1	; if button is still pressed 
	goto test1		;loop 
	btfss PORTA,2	; if button is pressed
	goto test1		;loop 
	btfss PORTA,3	; if button is pressed
	goto test1		;loop 
	btfss PORTA,4	; if button is pressed
	goto test1		;loop 
	goto loop   	; else release
	
attemptcheck	
	movlw b'11000000'
	andwf att	;take the att (pure without any other number)
	subwf att,W	;sub max attempts from attemps
	btfsc STATUS,Z	;test if zero
	call block	; if zero block all code
	return		;return to main loop	
block
	call block
		END
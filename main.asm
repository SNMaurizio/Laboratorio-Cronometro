;*******************************************************************
;* This stationery serves as the framework for a user application. *
;* For a more comprehensive program that demonstrates the more     *
;* advanced functionality of this processor, please see the        *
;* demonstration applications, located in the examples             *
;* subdirectory of the "Freescale CodeWarrior for HC08" program    *
;* directory.                                                      *
;*******************************************************************

; Include derivative-specific definitions
; En el archivo " derivative,inc"  se referencia a " MC68HC908QY4.inc" que contiene
; todas las definiciones de los registros, puertos y tabla de vectores de interrupciones

            INCLUDE 'derivative.inc'

; export symbols

            XDEF _Startup, main
            ; we export both '_Startup' and 'main' as symbols. Either can
            ; be referenced in the linker .prm file or from C/C++ later on

            XREF __SEG_END_SSTACK   ; symbol defined by the linker for the end of the stack


; variable/data section
MY_ZEROPAGE: SECTION  SHORT         ; Insert here your data definitio

;#######################AQUI SE DEFINEN LAS VARIABLES######################
		
medio_seg           ds 1 ; variable aux para medir 1 interrupcion/seg
contador_seg	    ds 1 ; contador de segundos
contador_min 	    ds 1 ; contador de minutos
status		 		ds 1 ; define el estado del cronometro (0 apagado / 1 contando)
dot			 		ds 1 ; variable auxiliar para el punto
puntero		 		ds 1 ; puntero para la tabla
aux 				ds 2 ; variable auxiliar para mostrar numeros en 7segmentos
conteo				ds 1 ; variable auxiliar para rutinas de retencion de display
conteo1				ds 1 ; variable auxiliar para rutinas de retencion de display
conteo2				ds 1 ; variable auxiliar para rutinas de pulso de buzzer
conteo3 			ds 1 ; variable auxiliar para rutinas de pulso de buzzer

;#######################AQUI SE DEFINEN LAS VARIABLES######################

;#################################STARTUP##################################

; code section
MyCode:     SECTION
main:
_Startup:

;Definir I/O en los Puertos

            LDHX 	#__SEG_END_SSTACK 		; initialize the stack pointer
            TXS							
	        CLRX							; limpio registro indice
            RSP
            CLRX
            LDA 	#%00010001				; directivas para poder simular
            STA 	CONFIG1	 				; directivas para poder simular
            CLI  	            			; habilito las interrupciones
            LDA  	#$FF					; 
            STA  	DDRB					; todos los bits del PuertoB como salidas
            LDA  	#%11110000				; 
            STA  	DDRD					; asigno I/O del PuertoD
            
;Limpio la salida del PTB (punto)
	
			BCLR	7,PTD
			
;Limpio los 7 segmentos            
           
           	CLR 	PTB
	   		
;Inicializo variables	
	   		
	   		CLR  	puntero					; limpio el puntero
			CLR  	aux						; limpio variable auxiliar
            ClR  	contador_seg			; limpio contador de segundos
            CLR  	contador_min    		; limpio contador de minutos
            CLR  	status 					; setea status en cero
            CLR  	medio_seg       		; setea medio_seg en cero
			CLR	 	dot	 					; limpia el status del puntito
            CLR		conteo					; limpia conteo
			CLR		conteo1					; limpia conteo 1
			CLR		conteo2					; limpia conteo 2		
			CLR		conteo3					; limpia conteo 3

;Setear el timer (TIM)

			LDA  	#%00110000				; Resetea y para el contador
			STA  	TSC						; inicializa el timer
			LDA  	#$96		
			STA  	TMODH					; guardo numero en parte alta
			LDA  	#$00
			STA  	TMODL					; guardo numero en parte baja
			LDA 	#%01000110			    ; seteo que el timer divida por 64 su frecuencia y empiece a contar
			STA  	TSC						; guardo en TSC	
			
;Muestra las iniciales de cada docente al conectar el microcontrolador			
iniciales

;"S"			
			LDA  	#%11101100				; cargo la inicial "S"
			STA  	PTB						; guardo en la salida PTB
			BCLR 	6,PTD					; selecciono el display 4
			BCLR	5,PTD
			BSET	7,PTD
			JSR  	delay					; subrutina de delay para apreciar el display
;"G"			
			LDA  	#%11111100				; cargo la inicial "G"
			STA  	PTB						; guardo en la salida PTB
			BCLR	6,PTD					; selecciono el display 3
			BSET	5,PTD
			BSET	7,PTD
			JSR  	delay					; subrutina de delay para apreciar el display

;"J"			
			LDA  	#%00011110				; cargo la inicial "J"
			STA  	PTB						; guardo en la salida PTB
			BSET	6,PTD					; selecciono el display 2
			BCLR	5,PTD	
			BSET	7,PTD	
			JSR  	delay					; subrutina de delay para apreciar el display
			
;"L"			
			LDA  	#%00111000				; cargo la inicial "L"
			STA  	PTB						; guardo en la salida PTB
			BSET	6,PTD					; selecciono el display 1
			BSET	5,PTD
			BSET	7,PTD
			JSR  	delay					; subrutina de delay para apreciar el display
			
			LDA		conteo					; carga contador	
			ADD		#$01					; le suma 1
			STA		conteo					; lo guarda
			CMPA	#$ff					; lo compara con 255 	
			BEQ		repite_bucle			; salta si conteo= 255
			;si no
			BRA		iniciales				; salto incondicional a iniciales
			
repite_bucle
			CLR		conteo					; limpia el contador conteo	
			LDA		conteo1					; luego carga el contador conteo 1
			ADD		#$01					; le suma 1
			STA		conteo1					; lo guarda
			CMPA	#$03					; lo compara con 3	
			BEQ		fin_iniciales			; salta si conteo = 3
			;si no
			BRA		iniciales				; salto incondicional a iniciales			
			
fin_iniciales
	
			CLR		PTB						; apaga los display
			CLR		conteo
			CLR		conteo1					; limpia ambos conteos
			
;#################################STARTUP##################################					  				            

;################################MAINLOOP##################################

mainLoop: 				
			feed_watchdog					; perro guardian

;Se chequea el estado de los switches	
			
;Chequeo el Pulsador 1 (NC)	
				
			BRSET	3,PTD,no_press1			; si esta pulsado activar AntiBounce sino continuar a SW2 (no_press1)
			JSR		delay					; retardo
			JSR		delay					; rutina de anti-rebote para el SW1
			BRSET	3,PTD,no_press1			; si fue pulsado realmente atiendo con Subrutina sino continua a SW2
			JSR 	pulsador1				; atiendo pulsador 1			
no_press1

;Chequeo el Pulsador 2 (NC)
	
			BRSET	1,PTD,no_press2			; si fue pulsado activar AntiBounce sino continuar con 7segmentos
			JSR 	delay					; retardo
			JSR		delay					; rutina de anti-rebote para el SW2
			BRSET	1,PTD,no_press2			; si fue pulsado realmente atiendo con Subrutina sino continuar con 7segmentos
			JSR 	pulsador2				; atiendo pulsador 2							
no_press2			

;Se muestran en los 7segmentos los numeros de la cuenta

;Unidades Segundos			
			
			LDHX 	#tablaDigitos			; tomo la 1ra pos. de la tabla (2 bytes)
			LDA  	contador_seg			; cargo contador segundos
			AND  	#$0F					; enmascaro el nibble BAJO
			STA  	puntero					; guardo en el puntero
			STHX 	aux						; guardo la 1ra pos. de la tabla en aux (2 bytes)
			LDA  	aux+1					; cargo parte baja de aux (1 byte)
			ADD  	puntero					; sumo puntero que contiene el numero a mostrar
			STA  	aux+1			
			LDA  	aux						; cargo parte alta de aux (1 byte)
			ADC  	#$00					; sumo SOLO el Carry en caso de existir
			STA  	aux
			LDHX 	aux						; cargo aux que contiene (1ra pos. de la tabla)+(puntero)
			LDA  	0,X						; obtengo el codigo para mostrar el numero 
			STA  	PTB						; guardo en la salida PTB
			BCLR 	6,PTD
			BCLR	5,PTD					; selecciono el display 4
			JSR  	delay					; subrutina de delay para apreciar el display
			
;Decenas Segundos
		
			LDHX 	#tablaDigitos			; tomo la 1ra pos. de la tabla (2 bytes)
			LDA  	contador_seg			; cargo contador segundos
			AND  	#$F0		    		; enmascaro el nibble ALTO
			NSA 							; invierto nibble alto con bajo
			STA  	puntero					; guardo en el puntero
			STHX 	aux						; guardo la 1ra pos. de la tabla en aux (2 bytes)
			LDA  	aux+1					; cargo parte baja de aux (1 byte)
			ADD  	puntero					; sumo puntero que contiene el numero a mostrar
			STA  	aux+1			
			LDA  	aux						; cargo parte alta de aux (1 byte)
			ADC  	#$00					; sumo SOLO el Carry en caso de existir
			STA  	aux
			LDHX 	aux						; cargo aux que contiene (1ra pos. de la tabla)+(puntero)
			LDA  	0,X						; obtengo el codigo para mostrar el numero
			STA  	PTB						; guardo en la salida PTB
			BCLR	6,PTD
			BSET	5,PTD					; selecciono el display 3				
			JSR  	delay					; subrutina de delay para apreciar el display
			
;Unidades Minutos
			
			LDHX 	#tablaDigitos			; tomo la 1ra pos. de la tabla (2 bytes)
			LDA  	contador_min			; cargo contador segundos
			AND  	#$0F					; enmascaro el nibble BAJO
			STA  	puntero					; guardo en el puntero
			STHX 	aux						; guardo la 1ra pos. de la tabla en aux (2 bytes)
			LDA 	aux+1					; cargo parte baja de aux (1 byte)
			ADD  	puntero					; sumo puntero que contiene el numero a mostrar
			STA  	aux+1			
			LDA  	aux						; cargo parte alta de aux (1 byte)
			ADC  	#$00					; sumo SOLO el Carry en caso de existir
			STA  	aux
			LDHX 	aux						; cargo aux que contiene (1ra pos. de la tabla)+(puntero)
			LDA  	0,X						; obtengo el codigo para mostrar el numero 
			STA  	PTB						; guardo en la salida PTB
			BSET	6,PTD					
			BCLR	5,PTD					; selecciono el display 2
			LDA		dot						; carga el flag dot
			CMPA	#$00					; lo compara con cero
			BEQ		dot_en_0				; si es cero salta a dot en 0
			BSET	7,PTD					; enciende el punto
			JSR  	delay					; subrutina de delay para apreciar el display
dot_en_0		
			BCLR	7,PTD					; apaga el punto
			JSR		delay					; subrutina de delay para apreciar el display
			
;Decenas Minutos
			
			LDHX 	#tablaDigitos	   		; inicializo puntero en
			LDA  	contador_min			; cargo contador segundos
			AND  	#$F0		   			; enmascaro el nibble ALTO
			NSA 							; invierto nibble alto con bajo
			STA  	puntero					; guardo en el puntero
			STHX 	aux						; guardo la 1ra pos. de la tabla en aux (2 bytes)
			LDA  	aux+1					; cargo parte baja de aux (1 byte)
			ADD  	puntero					; sumo puntero que contiene el numero a mostrar
			STA  	aux+1			
			LDA  	aux						; cargo parte alta de aux (1 byte)
			ADC  	#$00					; sumo SOLO el Carry en caso de existir
			STA  	aux
			LDHX 	aux						; cargo aux que contiene (1ra pos. de la tabla)+(puntero)
			LDA  	0,X						; obtengo el codigo para mostrar el numero
			STA  	PTB						; guardo en la salida PTB
			BCLR	7,PTD					; limpia el punto que mostro la unidad de minutos
			BSET	6,PTD
			BSET	5,PTD					; selecciono el display 1
			JSR  	delay					; subrutina de delay para apreciar el display	
		
;Vuelve a repetirse todo otra vez
	  	   		
	  	   	JMP  	mainLoop	

;################################MAINLOOP##################################	

;########################INTERRUPCIONES Y SUBRUTINAS#######################		

;Timer Cristal (interrupcion cada 1/2 seg)

INT_TIMER	
			BCLR 	7,TSC 					; limpia el bit 7 del TSC (TOF)
			LDA  	medio_seg				; cargo medio_seg
			CMPA 	#$01					; medio_seg = 1?
			BEQ  	temporizador			; branch si cero (paso 1 seg) a temporizador
			; sino
			ADD  	#$01					; sumo 1
			STA  	medio_seg				; guardo medio_seg
			RTI								; termina la atencion a interrupcion

;Cuento segundos
		
temporizador	
			LDA  	status					; cargo status
			CMPA 	#$00 					; status = 0?
			BEQ  	al_loop					; si status = 0 no debe contar (vuelvo al loop) 
			; sino	
			COM		dot						; complemento el punto
			LDA  	contador_seg			; cargo contador_seg
			CMPA 	#$59					; segundos = 59?
			BEQ  	cuenta_min				; si segundos = 59 debo contar 1 minuto
			; sino
			ADD  	#$01					; suma 1 segundo
			DAA								; ajuste decimal
			STA  	contador_seg			; guardo contador_seg
			CLR  	medio_seg				; reseteo medio_seg para el prox. segundo
			RTI
al_loop
			CLR  	medio_seg				; reseteo medio_seg para el prox. segundo
			RTI								; termina la atencion a interrupcion	
			
;Cuento	minutos		

cuenta_min
			CLR  	contador_seg			; limpio contador segundos
			LDA  	contador_min			; cargo contador_min
			CMPA 	#$59					; minutos = 59?
			BEQ  	reset					; si minutos = 59 se resetea la cuenta
			; sino
			ADD  	#$01					; suma 1
			DAA								; ajuste decimal
			STA  	contador_min			; guardo contador_min
			CLR  	medio_seg				; reseteo medio_seg para el prox. segundo
			RTI								; termina la atencion a interrupcion
													
;Reseteo en la hora

reset		
			CLR  	medio_seg				; limpio contaodres			 
			CLR  	contador_min			; limpio contadores
			CLR  	status					; limpia status
			JSR 	destello				; salto a subrutina de destello del display
			RTI								; termina la atencion a interrupcion

;Retardo para mostrar los numeros en display o Antibounce (10 ms)	

delay	

   		 	LDHX 	#$2500   				; Cargar X con $2500, 3 ciclos
DELAY_LOOP
			NOP         					; 1 ciclo 
   		 	NOP         					; 1 ciclo 
   		 	NOP         					; 1 ciclo 
   		 	NOP         					; 1 ciclo 
   		 	DECX         					; Decrementa X (1 ciclo)
   		 	BNE  	DELAY_LOOP 				; Salta a DELAY_LOOP si X no es cero (3 ciclos)
  		 	RTS         					; Return from Subroutine (4 ciclos)
  		 	
;Retardo para el buzzer (0.3 ms)

delay2

   		 	LDHX 	#$0130					; Cargar X con $0130, 3 ciclos 
DELAY_LOOP2
 		 	NOP         					; 1 ciclo
   		 	NOP         					; 1 ciclo
   		 	NOP         					; 1 ciclo
   		 	NOP         					; 1 ciclo
   		 	DECX         					; Decrementa X (1 ciclo)
   		 	BNE  	DELAY_LOOP2 			; Salta a DELAY_LOOP si X no es cero (3 ciclos)
  		 	RTS         					; retorna de la subrutina (4 ciclos)	
	

;Subrutina del Pulsador 1 (1 Play / 0 Pausa)

pulsador1
			COM		status					; switchea entre 1 (play) / 0 (pausa) el status
			RTS								; retorno a subrutina

;Subrutina del Pulsador 2 (Reset)

pulsador2	
			CLR  	status					; limpia status
			CLR  	medio_seg				; limpio contadores
			CLR  	contador_seg			; limpio contadores
			CLR  	contador_min			; limpio contadores
			CLR  	dot						; limpio contadores	
			BCLR	7,PTD					; limpio el puntito
			JSR 	destello				; salto a subrutina de destello display
			RTS								; retorno a subrutina

;Subrutina de destello		
	
destello	
			CLR  	PTB						; limpio el remanente en puerto PTB	
			COM		PTB						; lo complemento
		
destellocom
			
;multiplexo el contenido en PTB
								
			BCLR 	6,PTD					
			BCLR	5,PTD					; selecciono el display 4	
			JSR  	delay					; subrutina de delay para apreciar el display
		
			BCLR	6,PTD					
			BSET	5,PTD					; selecciono el display 3
			JSR  	delay					; subrutina de delay para apreciar el display
			 
			BSET	6,PTD
			BCLR	5,PTD					; selecciono el display 2
			JSR  	delay					; subrutina de delay para apreciar el display
			
			BSET	6,PTD					
			BSET	5,PTD					; selecciono el display 1
			JSR  	delay					; subrutina de delay para apreciar el display
			
			LDA		conteo					; carga contador	
			ADD		#$01					; le suma 1
			STA		conteo					; lo guarda
			CMPA	#$30					; lo compara con 48	
			BEQ		se_va_la_primera		; salta si conteo = 48
			;si no
			BRA		destellocom				; salto incondicional a destellocom
			
se_va_la_primera 
	
			JSR		buzzer					; atiendo subrutina de buzzer (aca una vez que mostró muestra hace piiiiii)
			COM		PTB						; complemento el PTB
			CLR		conteo					; limpia conteo	
			LDA		conteo1					; carga conteo1
			ADD		#$01					; le suma 1
			STA		conteo1					; lo guarda
			CMPA	#$06					; lo compara con 6 pues quiero que prenda y apague	
			BEQ		arranca_la_segunda		; salta si conteo=$6
			; si no
			BRA		destellocom				; salto incondicional a iniciales
				
arranca_la_segunda

			CLR		PTB						; apaga los display
			CLR		conteo					; limpia el conteo
			CLR		conteo1					; limpio conteo1
			BCLR 	6,PTD					; limpia decos 
			BCLR	5,PTD
			RTS								; retorno de subrutina
	
;Subrutina de buzzer
			
buzzer
			CLR  	PTD						; limpio el remanente que quedo en el PTD			
			CLR		conteo2					; limpio conteo 2 y 3
			CLR		conteo3
			BSET	4,PTD					
buzzercom	
			JSR  	delay2					; subrutina de delay para mantener flanco
			BRSET	4,PTD,on				; salta si esta el buzzer en 1
			;si no
			BSET	4,PTD					; lo setea y continua
			BRA		continuar
						
on			
			BCLR	4,PTD					; pone en cero el buzzer y continua	
			
continuar
			LDA		conteo2					; carga contador	
			ADD		#$01					; le suma 1
			STA		conteo2					; lo guarda
			CMPA	#$FF					; lo compara con 255 mediociclos ciclos completos	
			BEQ		vuelta1					; salta si conteo= 255
			;si no
			BRA		buzzercom				; salto incondicional a buzzercom
			
vuelta1	
			CLR		conteo2					; limpia contador y carga contador 3	
			LDA		conteo3
			ADD		#$01					; le suma 1
			STA		conteo3					; lo guarda
			CMPA	#$03					; lo compara con 3 (para alargar duracion de buzzer)	
			BEQ		vuelta2					; salta si conteo=$64
			BRA		buzzercom				; salto incondicional a iniciales
				
vuelta2	
			CLR		PTD						; apaga los display
			CLR		conteo2					; limpia los conteos
			CLR		conteo3
			RTS
			
			BRA FIN							; salto incondicional a FIN
;################################################################			

			rts
  		
;########################INTERRUPCIONES Y SUBRUTINAS#######################	

tablaDigitos
		  DC.B $BE	; 0
 		  DC.B $06	; 1
		  DC.B $DA	; 2
		  DC.B $CE	; 3
		  DC.B $66	; 4
		  DC.B $EC	; 5
		  DC.B $FC	; 6
		  DC.B $86	; 7 	 
		  DC.B $FE	; 8
		  DC.B $EE	; 9	
FIN:
			rti
;****************************************************************************** 
;*   Atencion de Interrupciones, no hacer nada por ahora
  
Vacio            
            rti          ; retorna sin hacer nada

;*****************************************************************************

            org  INT_ADC  ; a partir de $FFDE

       		dcw   Vacio              ;FFDE+FFDF, (direccion de atencion de INT_ADC)
      		dcw   Vacio              ;FFE0+FFE1, (direccion atencion de INT KBI)
      		dcw   Vacio              ;FFE2+FFE3, (reservado 2, no usado)
        	dcw   Vacio              ;FFE4+FFE5, (reservado 3, no usado)
        	dcw   Vacio              ;FFE6+FFE7, (reservado 4, no usado)
        	dcw   Vacio              ;FFE8+FFE9, (reservado 5, no usado)
        	dcw   Vacio              ;FFEA+FFEB, (reservado 6, no usado)
        	dcw   Vacio              ;FFEC+FFED, (reservado 7, no usado)
        	dcw   Vacio              ;FFEE+FFEF, (reservado 8, no usado)
        	dcw   Vacio              ;FFE0+FFE1, (reservado 9, no usado)
        	dcw   INT_TIMER		     ;FFF2+FFF3, (direccion por TIMOvr) 
        	dcw   Vacio              ;FFF4+FFF5, (direccion por TIM Channel 1) 
        	dcw   Vacio              ;FFF6+FFF7, (direccion por TIM Channel 0) 
        	dcw   Vacio              ;FFE8+FFE9, (reservado 13, no usado)
        	dcw   Vacio              ;FFFA+FFFB, (direccion atencion por IRQ)
        	dcw   Vacio              ;FFFC+FFFD, (direccion atencion por SWI)
;        	dcw   main               ;FFFE+FFFF, (direccion programa,RESET)
; ya esta definida main, por eso se muestra la l nea comentada
;*******************************************************************************
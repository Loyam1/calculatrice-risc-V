.data
bienvenue: .asciz "\nbienvenue dans le programme calculatrice en risc-v créer par Loyam (V2)\ntu peux entrer des calcul décimaux de type x(+-*/)y ou des commendes (/help)"
quel: .asciz "\n\tquel est ton calcul ?\t"
syntaxe: .asciz "erreur de syntaxe taper /help pour les commendes"
help: .asciz "/help"
MChelp: .asciz "/help : affiche cette aide\n/stop : arrette le programe"
stop: .asciz "/stop"
#e==>/help	t==>/stop	i==>/historique		


.global main
.text

main:
	addi sp,sp,-28		#réserve de la mémoir
	la a0,bienvenue		#charge le text de bienvenue dans t0
	call message		#appelle la fonction message
	mv a2,sp
	call save_adresse
	la a0,quel		#charge le text de quel dans a0
	call message		#appelle la fonctin message
	call ecoute		#appelle la fonction ecoute
	mv s0,a0		#mets dans s0 le calcul de l'utilisateur au format ascci
	call longueur		#calcul la longeur du calcul de l'utilisateur
	addi s1,t3,-1		#corige la longeur du calcul de l'utilisateur
	call calcul		#appelle la fonction calcul
	j restart

message:			#ecrit dans la console le text dans a2
	li a7,4
	ecall
	ret

résultat:			#affiche le résulta stocké dans fs2
	fcvt.d.w ft0,zero	#affiche le résultat
	fadd.d fa0,fs2,ft0	#affiche le résultat
	li a7,3			#affiche le résultat
	ecall
	ret

ecoute:				#écoute le calcule de l'utilisateur avec 16 octet max et le sauvegarde dans a0
	addi a0, sp, 16
	li a7,8
	li a1,16
	ecall
	ret

longueur:
	lb t2, 0(a0)		# Récupère le caractère
	beqz t2, exit		# Si caractère == '\0', fin
	addi t3, t3, 1		# Compteur++
	addi a0,a0, 1		# Caractère suivant
	j longueur

calcul:
	addi a2,sp,4		#décalle l'adresse retour de 4 et l'enregistre dans a2
	li a3,0			#met a3 a 0
	call save_adresse	#appelle save_adresse
	add t1,s0,a3		#met un décalage de longueur a3(un conteur) de s0 (l'oppération) dans t1
	lb a2,0(t1)		#prrestartt le premier caractère de t1 et le sauvgarde dans a2 due au décalage il augmente d'un caractère a chaque itération
	call signe		#appelle signe
	addi a3,a3,1		#incrémente de 1 le conteur (a3)
	bge a3,s1,restart	#si fin de l'opération exit
	lw ra,4(sp)		#récupère de la ram l'adresse de retour (après call save _adresse)
	ret			#va a l'adresse de retour

signe:				#verifit si le caractère dans a2 est un signe math si oui appelle la fonction dédié avec l'amplacement du signe dans a3
	li t2,43
	beq a2,t2,addition
	li t2,45
	beq a2,t2,soustraction
	li t2,42
	beq a2,t2,multiplication
	li t2,47
	beq a2,t2,pré_division
	ret

pré_division:			#verifit si c'est une commend sinon envoit pour la division
	beq a3,zero,commende
	j division

addition:			#additionnne si demandé par l'utilisateur
	mv s2,a3		#met a3 dans s2 pour sauvgarder la position du signe
	call s_c		#appelle s_c
	fadd.d fs2,fs0,fs1	#fait l'addition
	call résultat		#appelle résultat
	j restart		#saut a restart

soustraction:			#soustrais si demandé par l'utilisateur
	mv s2,a3		#cf addition
	call s_c		#cf addition
	li t1,-1		#prépart la soustraction en multipliant par -1 un terme
	fcvt.d.w ft1,t1
	fmul.d fs1,fs1,ft1	#prépart la soustraction en multipliant par -1 un terme
	fadd.d fs2,fs0,fs1		#additionne 
	call résultat		#cf addition
	j restart		#cf addition

multiplication:			#multiplie si demandé par l'utilisateur
	addi s2,a3,0		#cf addition
	call s_c		#cf addition
	fmul.d fs2,fs0,fs1		#multiplie les deux nombre
	call résultat		#cf addition
	j restart		#cf addition

division:			#divise si l'utilisateur le demende
	mv s2,a3		#cf addition
	call s_c		#cf addition
	fdiv.d fs2,fs0,fs1	#divise
	call résultat		#affiche le résultat
	j restart		#cf addition

exposant_prépa:			#met t0 a a0 a la puissance de a1
	li t0,1
	beq a1,zero,exit
	mv t0,a0
	blt a1,zero,exposant_neg
	li t1,-1
	j exposant_calcul
exposant_neg:
	li t1,-1
	mul a1,a1,t1
	li t1,1
	mv t3,ra
	call exposant_calcul
	mv ra,t3
	fcvt.d.w ft0,t0
	li t1,1
	fcvt.d.w ft1,t1
	fdiv.d ft0,ft1,ft0
	ret 
exposant_calcul:
	add a1,a1,t1
	beq a1,zero,exit
	mul t0,t0,a0
	j exposant_calcul

s_c:				#sépart se qu'il y a avant et après le signe 
	li s6,0			#initialise s6 pour la position d'une possible point
	sw ra,8(sp)		#sauvgarde l'adresse retour
	mv a1,s2		#organise les variable pour pouvoir les mosifier (s2=position du signe)
	mv a0,s0		#organise les variable pour pouvoir les mosifier (s0=sésit utilisateur)
	li t3,0			#initialise un conteur
	li a2,0			#initialise a2 qui contiendra la partie transformé en nombre
	call convertie		#appelle convertie
	mv s6,s7		#enregistre la position d'une possible point
	li s7,0			#réinistalise la position
	mv s3,a2		#enregistre le résultat
	li a2,0			#réinitialise a2 qui contiendra la partie transformé en nombre
	addi a0,a0,1		#passe le signe qu'il ne faut pas transformé
	addi t3,t3,1		#ajoute 1 au conteur de tour
	mv a1,s1		#organise les variable pour pouvoir les mosifier (s1=longueur de la sesit utilisateur)
	call convertie		#appelle convertie
	mv s4,a2		#enregistre le résultat
	j conv_cal_flaut

conv_cal_flaut:
	mv a1,s6
	li a0,10
	call exposant_prépa
	fcvt.d.w fs0,s3
	fcvt.d.w ft0,t0
	fdiv.d fs0,fs0,ft0
	mv a1,s7
	call exposant_prépa
	fcvt.d.w fs1,s4
	fcvt.d.w ft0,t0
	fdiv.d fs1,fs1,ft0
	lw ra,8(sp)		#récupère l'adresse retour
	ret			#vas a l'adresse retour
	

convertie:			#convertie ascii vers nombre
	bge t3,a1,exit		#verifit si la sélection a convertir et fini appelle exit si oui
	li t5,46		#verifit si le caractère et un point
	lb t0,0(a0)		#récupère le caractère
	beq t0,t5,point		#compare le caractère avec selui du point
	li t1,10		#prépart le décalage du nombre déja convertie
	mul a2,a2,t1		#décale le nombre
	addi t0,t0,-48		#converti le caractère vers un chifre
	add a2,a2,t0		#additionne se chifre et le nombre
	addi t3,t3,1		#augmente e conteur de 1
	addi a0,a0,1		#décale le caractère a convertire
	j convertie		#recomence la boucle

point:				#point
	li t1,-1
	addi t3,t3,1
	mul t5,t3,t1
	add t5,a1,t5
	addi a0,a0,1
	mv s7,t5
	j convertie

save_adresse:			#sauvegarde l'adresse retour dans l'emplacement mémoir contenue dans a2
	sw ra,0(a2)
	ret
exit:				#sorte d'une boucle et va a l'adresse de retour
	ret

restart:			#prepare les variables puis relance
	lw ra,0(sp)
	li a0,0
	li a1,0
	li a2,0
	li a3,0
	li a7,0
	li t0,0
	li t1,0
	li t2,0
	li t3,0
	li t4,0
	li s0,0
	li s1,0
	li s2,0
	li s3,0
	li s4,0
	li s5,0
	li s6,0
	li s7,0
	fcvt.d.w ft0,zero
	fcvt.d.w ft1,zero
	fcvt.d.w fs0,zero
	fcvt.d.w fs1,zero
	fcvt.d.w fs2,zero
	fcvt.d.w fa0,zero
	ret

commende:			#gère les commende
	la t0,help
	lb t0,2(t0)
	lb t1,2(s0)
	beq t1,t0,Chelp
	la t0,stop
	lb t0,2(t0)
	beq t1,t0,Cstop
	la a0,syntaxe
	call message
	j restart

Chelp:				#affiche le texte de help
	la a0,MChelp
	call message
	j restart

Cstop:				#arrete le programme

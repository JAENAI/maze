.data

lf: .asciiz "\n"
sp: .asciiz " "
vals: .space 16

.text

__start:

main:
move $t1 $a1 #t1 contient l'adresse d'un tableau de pointeurs vers les arguments
lw $t2 ($t1)
move $a0 $t2
jal convert_str_int
move $s7 $v0
move $a0 $s7
jal creer_labyrinthe
move $s0 $v0 #$s0 contiendra l'adresse du labyrinthe
mul $a0 $a0 $a0 #la pile contiendra au plus N*N + 1 elements
addi $a0 $a0 1
jal st_creer
move $s1 $v0 #$s1 contiendra l'adresse de la pile
li $s2 0 #$s2 contiendra l'indice de la cellule courante, C0 pour commencer
move $a0 $s0
move $a1 $s2
jal marquer_cell_visite
move $a0 $s1
move $a1 $s2
jal st_empiler
boucle_main:
move $a0 $s1
jal st_est_vide
beq $v0 1 fin_boucle_main
move $a0 $s2
move $a1 $s7
move $a2 $s0
jal cell_voisines_non_visitees
beq $v1 0 si_pas_voisin
move $a0 $s2
move $a1 $s7
move $a2 $s0
jal voisin_alea
move $s3 $v0 #on casse le mur entre C et C'
move $a0 $s2
move $a1 $s3
move $a2 $s7
move $a3 $s0
jal casser_mur_entre_cell
move $s2 $s3 #on marque la cellule C' comme visite
move $a0 $s0
move $a1 $s2
jal marquer_cell_visite
move $a0 $s1
move $a1 $s2
jal st_empiler #on empile C'
j boucle_main
si_pas_voisin:
move $a0 $s1
jal st_depiler #on depile
jal st_sommet #on marque C' du sommet de la pile comme cellule courante
move $s2 $v0
j boucle_main
fin_boucle_main:
li $s2 0 #on marque C0 comme debut
move $a0 $s0
move $a1 $s2
jal marquer_cell_debut
move $s2 $s7 #on marque CN comme fin
mul $s2 $s2 $s2
addi $s2 $s2 -1
move $a0 $s0
move $a1 $s2
jal marquer_cell_fin
move $a0 $s0
move $a1 $s7
jal affiche_laby

j exit


cell_lecture_bit:
#parametres:
#$a0: n
#$a1: i
#retour: 
#$v0 contient le i-eme bit de n en comptant à partir de 0

#prologue
addi $sp $sp -24
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
sw $t1 16($sp)
sw $t2 20($sp)
#corps
move $t0 $a0
srlv $t1 $t0 $a1 #le i-eme bit de $t0 devient le 1er bit de $t1
andi $t2 $t1 1 #mask avec 1 pour garder le 1er bit
move $v0 $t2 
#epilogue
lw $t2 20($sp)
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 24
jr $ra

cell_mettre_bit_a1:
#parametres:
#$a0: n
#$a1: i
#retour: 
#$v0 contient n avec i-eme bit à 1

#prologue
addi $sp $sp -20
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
sw $t1 16($sp)
#corps
jal cell_lecture_bit
move $t0 $v0
move $v0 $a0 #on prépare le retour de n si jamais le i-eme bit est déjà 1
bnez $t0 fin_mettre_bit_a1 #si le bit est déjà 1 inutile de continuer
addi $t0 $t0 1
sllv $t1 $t0 $a1
add $a0 $a0 $t1 #on ajoute 2^i à n
move $v0 $a0 
#epilogue
fin_mettre_bit_a1:
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 20
jr $ra

cell_mettre_bit_a0:
#parametres:
#$a0: n
#$a1: i
#retour: 
#$v0 contient n avec i-eme bit à 0

#prologue
addi $sp $sp -20
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
sw $t1 16($sp)
#corps
jal cell_lecture_bit
move $t0 $v0
move $v0 $a0 #on prépare le retour de n si jamais le i-eme bit est déjà 0
beqz $t0 fin_mettre_bit_a0 #si le bit est déjà 0 inutile de continuer
sllv $t1 $t0 $a1
sub $a0 $a0 $t1 #on soustrait 2^i à n
move $v0 $a0 
#epilogue
fin_mettre_bit_a0:
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 20
jr $ra

st_creer:
#parametres:
#$a0: le nombre maximal n d'entiers que la pile pourra contenir
#retour:
#$v0 contient l'adresse de la pile

#prologue
addi $sp $sp -24
sw $ra 0($sp)
sw $a0 4($sp)
sw $t0 8($sp)
sw $t1 12($sp)
sw $t2 16($sp)
sw $t3 20($sp)
#corps
li $t0 4 #On represente le nombre de bits pour un entier en mips
mul $a0 $a0 $t0 #On represente dans $a0 le nombre de bits à allouer pour n entiers
li $v0 9 #On fait un appel systeme pour allouer de la place dans le tas
syscall
li $t1 0
li $t3 -1
lw $a0 4($sp)
boucle_remplir_pile:
beq $t1 $a0 fin_boucle_remplir_pile
move $t2 $t1
mul $t2 $t2 4
add $t2 $t2 $v0
sw $t3 0($t2)
addi $t1 $t1 1
j boucle_remplir_pile
fin_boucle_remplir_pile:
#epilogue
lw $t3 20($sp)
lw $t2 16($sp)
lw $t1 12($sp)
lw $t0 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 24
jr $ra

st_est_vide:
#arguments:
#$a0: l'adresse de la pile
#retour:
#$v0: egal à 1 si la pile est vide ou 0 sinon

#prologue
addi $sp $sp -20
sw $ra 0($sp)
sw $a0 4($sp)
sw $t0 8($sp)
sw $t1 12($sp)
sw $t2 16($sp)
#corps
li $t2 -1
lw $t1 0($a0) #On met dans $t1 la valeur de l'élément au bout de la pile(dans ce cas du tas)
beq $t1 $t2 vide #On vérifie si elle égale à -1 et si oui on va au label vide
li $t0 0
move $v0 $t0 #On met 0 comme valeur de retour car la pile n'est pas vide
j ep #On saute à l'épilogue pour que l'instruction de vide ne soit pas executée
vide:
li $t0 1 
move $v0 $t0 #On met 1 comme valeur de retour car la pile est vide
#epilogue
ep:
lw $t2 16($sp)
lw $t1 12($sp)
lw $t0 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 20
jr $ra

st_sommet:
#precondition: la pile n'est pas vide
#arguments:
#$a0: l'adresse de la pile
#retour:
#$v0: contient la valeur du sommet de la pile

#prologue
addi $sp $sp -24
sw $ra 0($sp)
sw $a0 4($sp)
sw $t0 8($sp)
sw $t1 12($sp)
sw $t2 16($sp)
sw $t3 20($sp)
#corps
move $v0 $a0
li $t0 0
li $t3 -1
boucle_st_sommet: #on parcour les éléments de la pile jusqu'à tomber sur un 0
add $t1 $t0 $a0 #$t0 correspont à l'offset que l'on augmente de 4 à chaque tour
lw $t2 0($t1) #$t2 contient la valeur à l'adresse $t1 = $a0 + $t0
beq $t2 $t3 fin_boucle_st_sommet
addi $t0 $t0 4
j boucle_st_sommet
fin_boucle_st_sommet:
addi $t1 $t1 -4 #$t1 est l'adresse du 1er élément nul trouvé, on enleve 4 pour avoir l'adresse du sommet
lw $v0 0($t1)
#epilogue
lw $t3 20($sp)
lw $t2 16($sp)
lw $t1 12($sp)
lw $t0 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 24
jr $ra

st_est_pleine:
#arguments:
#$a0: l'adresse de la pile
#$a1: la taille maximale de la pile
#retour:
#$v0: egal à 1 si la pile est pleine ou 0 sinon

#prologue
addi $sp $sp -28
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
sw $t1 16($sp)
sw $t2 20($sp)
sw $t3 24($sp)
#corps
li $v0 0
li $t3 -1
move $t0 $a1 #calcul de l'adresse du dernier emplacement mémoire alloué à la pile
li $t1 4
addi $t0 $t0 -1
mul $t0 $t0 $t1
add $t0 $t0 $a0
lw $t2 0($t0) #$t2 contient le dernier élément de l'emplacement mémoire alloué
beq $t2 $t3 fin_st_est_pleine #si $t2 vaut 0 alors la pile n'est pas pleine
li $v0 1
#epilogue
fin_st_est_pleine:
lw $t3 24($sp)
lw $t2 20($sp)
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 28
jr $ra

st_empiler:
#précondition:
#la pile n'est pas pleine (à vérifier avant d'appeler cette fonction)
#arguments:
#$a0: l'adresse de la pile
#$a1: l'élément à empiler
#retour:
#$v0: contient l'adresse de la pile

#prologue
addi $sp $sp -28
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
sw $t1 16($sp)
sw $t2 20($sp)
sw $t3 24($sp)
#corps
move $v0 $a0
li $t0 0
li $t3 -1
boucle_st_empiler: #on parcour les éléments de la pile jusqu'à tomber sur un 0
add $t1 $t0 $a0 #$t0 correspont à l'offset que l'on augmente de 4 à chaque tour
lw $t2 0($t1) #$t2 contient la valeur à l'adresse $t1 = $a0 + $t0
beq $t2 $t3 fin_boucle_st_empiler
addi $t0 $t0 4
j boucle_st_empiler
fin_boucle_st_empiler:
sw $a1 0($t1) #$t1 est l'adresse du 1er élément nul trouvé, on le remplace par $a1
#epilogue
lw $t3 24($sp)
lw $t2 20($sp)
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 28
jr $ra

st_depiler:
#précondition:
#la pile n'est pas vide (à vérifier avant d'appeler cette fonction)
#arguments:
#$a0: l'adresse de la pile
#retour:
#$v0: contient l'adresse de la pile

#prologue
addi $sp $sp -24
sw $ra 0($sp)
sw $a0 4($sp)
sw $t0 8($sp)
sw $t1 12($sp)
sw $t2 16($sp)
sw $t3 20($sp)
#corps
move $v0 $a0
li $t0 0
li $t3 -1
boucle_st_depiler: #on parcour les éléments de la pile jusqu'à tomber sur un -1
add $t1 $t0 $a0 #$t0 correspont à l'offset que l'on augmente de 4 à chaque tour
lw $t2 0($t1) #$t2 contient la valeur à l'adresse $t1 = $a0 + $t0
beq $t2 $t3 fin_boucle_st_depiler
addi $t0 $t0 4
j boucle_st_depiler
fin_boucle_st_depiler:
addi $t1 $t1 -4 #on a trouvé l'élément qui vient après le dernier donc on retire 4 pour l'avoir 
sw $t3 0($t1) #$t1 est l'adresse du sommet de la pile, on le remplace par -1
#epilogue
lw $t3 20($sp)
lw $t2 16($sp)
lw $t1 12($sp)
lw $t0 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 24
jr $ra

st_affiche:
#précondition:
#la pile n'est pas vide (à vérifier avant d'appeler cette fonction)
#arguments:
#$a0: l'adresse de la pile
#retour:
#$v0: contient l'adresse de la pile

#prologue
addi $sp $sp -28
sw $ra 0($sp)
sw $a0 4($sp)
sw $t0 8($sp)
sw $t1 12($sp)
sw $t2 16($sp)
sw $t3 20($sp)
sw $t4 24($sp)
#corps
move $v0 $a0
li $t0 0
li $t3 -1
boucle_st_affiche: #on parcour les éléments de la pile jusqu'à tomber sur un 0
add $t1 $t0 $a0 #$t0 correspont à l'offset que l'on augmente de 4 à chaque tour
lw $t2 0($t1) #$t2 contient la valeur à l'adresse $t1 = $a0 + $t0
beq $t2 $t3 fin_boucle_st_affiche
move $t3 $a0 #on stock $a0 et $v0 dans $t3 et $t4 pour pas les perdre
move $t4 $v0
move $a0 $t2 #on affiche $t2
li $v0 1
syscall
la $a0 lf #on saute une ligne
li $v0 4
syscall
move $a0 $t3
move $v0 $t4
addi $t0 $t0 4
j boucle_st_affiche
fin_boucle_st_affiche:
#epilogue
lw $t4 24($sp)
lw $t3 20($sp)
lw $t2 16($sp)
lw $t1 12($sp)
lw $t0 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 28
jr $ra


cell_deja_visite:
#parametres:
#$a0: n
#retour: 
#$v0 contient 1 si la cellule a déjà été visité, 0 sinon

#prologue
addi $sp $sp -8
sw $ra 0($sp)
sw $a0 4($sp)
#corps
li $a1 6
jal cell_lecture_bit
#epilogue
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 8
jr $ra

creer_labyrinthe:
#arguments:
#$a0: contient la taille du labyrinthe
#retour:
#$v0: contient l'adresse du labyrinthe

#prologue
addi $sp $sp -16
sw $ra 0($sp)
sw $a0 4($sp)
sw $t0 8($sp)
sw $t1 12($sp)
#corps
li $t1 0
mul $a0 $a0 $a0 # On calcule le nombre total de cellules pour un labyrinthe NxN avec N->$a0
jal st_creer #On crée une pile contenant toutes les cellules
move $t0 $a0
move $a0 $v0 #On met l'adresse de la pile en $a0 pour pouvoir la prendre comme argument
li $a1 15
boucle_remplir: 
beq $t1 $t0 fin_boucle_remplir #On vérifie que l'on n'a fini la pile
addi $t1 $t1 1
jal st_empiler #On empile une cellule 
j boucle_remplir
fin_boucle_remplir: 
#epilogue
lw $t1 12($sp)
lw $t0 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 16
jr $ra

affiche_laby:
#précondition:
#la pile n'est pas vide (à vérifier avant d'appeler cette fonction)
#arguments:
#$a0: l'adresse du labyrinthe
#$a1: taille  du labyrinthe
#retour:
#$v0: contient l'adresse de la pile

#prologue
addi $sp $sp -36
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
sw $t1 16($sp)
sw $t2 20($sp)
sw $t3 24($sp)
sw $t4 28($sp)
sw $t5 32($sp)
#corps
move $t0 $a0 # On garde temporairement la valeur de $a0
move $a0 $a1 #On affiche la taille du labyrinthe
li $v0 1
syscall
la $a0 lf # On fait un saut a la ligne
li $v0 4
syscall
move $a0 $t0 # On remet dans $a0 sa valeur
move $v0 $a0
li $t0 0
li $t5 0
boucle_affiche_laby: #on parcour les éléments de la pile jusqu'à la fin
add $t1 $t0 $a0 #$t0 correspont à l'offset que l'on augmente de 4 à chaque tour
lw $t2 0($t1) #$t2 contient la valeur à l'adresse $t1 = $a0 + $t0
beq $t2 -1 fin_boucle_affiche_laby
move $t3 $a0 #on stock $a0 et $v0 dans $t3 et $t4 pour pas les perdre
move $t4 $v0
if:
bge $t5 $a1 elif
addi $t5 $t5 1
j next
elif:
beq $t5 $a1 else
sub $t5 $t5 $a1
j if
else:
addi $t5 $t5 1
la $a0 lf #on saute une ligne
li $v0 4
syscall
next:
move $a0 $t2 #on affiche $t2
li $v0 1
syscall
la $a0 sp
li $v0 4
syscall
move $a0 $t3
move $v0 $t4
addi $t0 $t0 4
j boucle_affiche_laby
fin_boucle_affiche_laby:
#epilogue
lw $t5 32($sp)
lw $t4 28($sp)
lw $t3 24($sp)
lw $t2 20($sp)
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 36
jr $ra

valeur_cell:
#precondition:
#l'indice est retrouvable dans le labyrinthe
#arguments:
#$a0: l'adresse du labyrinthe
#$a1: l'indice de la cellule
#retour:
#$v0: valeur de la cellule

#prologue
addi $sp $sp -24
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
sw $t1 16($sp)
sw $t2 20($sp)
#corps
li $t0 4
mul $t1 $t0 $a1 # On multiplie par 4 l'indice car chaque cellule vaut 4 bits
add $t1 $t1 $a0 # On ajoute la taille du nombre de cellules � l'adresse
lw $t2 0($t1) #On sauvegarde la valeur dans la cellule d'indice recherch�
move $v0 $t2
#epilogue
lw $t2 20($sp)
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 24
jr $ra

changer_valeur_cell:
#precondition:
#l'indice est retrouvable dans le labyrinthe
#arguments:
#$a0: l'adresse du labyrinthe
#$a1: l'indice de la cellule
#$a2: la nouvelle valeur � mettre dans la cellule
#retour:

#prologue
addi $sp $sp -24
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $a2 12($sp)
sw $t0 16($sp)
sw $t1 20($sp)
#corps
li $t0 4
mul $t1 $t0 $a1 # On multiplie par 4 l'indice car chaque cellule vaut 4 bits
add $t1 $t1 $a0 # On ajoute la taille du nombre de cellules � l'adresse
sw $a2 0($t1) #On met une nouvelle valeur dans l'adresse
#epilogue
lw $t1 20($sp)
lw $t0 16($sp)
lw $a2 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 24
jr $ra

cell_voisines:
#arguments:
#$a0: l'indice de la cellule
#$a1: taille du labyrinthe
#retour:
#$v0: l'adresse du tableau contenant les indices du voisins
#prologue
addi $sp $sp -44
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
sw $t1 16($sp)
sw $t2 20($sp)
sw $t3 24($sp)
sw $t4 28($sp)
sw $t5 32($sp)
sw $t6 36($sp)
sw $t7 40($sp)
#corps
li $s5 -1
la $v0 vals # On garde l'adresse du tableau contenant les cellules voisines
mul $t0 $a1 $a1 # On calcule le nombre total des cellules
addi $t1 $a1 -1 # On calcule l'indice maximale de la premiere ligne
if1: 
bge $a0 $a1 else1 # On v�rifie si on est sur la premiere ligne
beq $a0 $t1 if2 # On v�rifie si on est � la fin de la premiere ligne 
beqz $a0 if3 # On v�rifie si on est au debut de la premiere ligne
addi $t2 $a0 -1
addi $t3 $a0 1
add $t4 $a0 $a1
j trois_voisins
if2:# On calcule les indices voisins si on est � la fin de la premiere ligne 
addi $t2 $a0 -1
add $t3 $a0 $a1
j deux_voisins
if3:# On calcule les indices si on est au d�but de la premiere ligne
addi $t2 $a0 1
add $t3 $a0 $a1
j deux_voisins
else1: 
rem $t6 $a0 $a1
beqz $t6 elif1 # On v�rifie si on est � la premiere colonne
addi $t7 $a1 -1
beq $t6 $t7 elif3 # On v�rifie si on est � la derniere colonne
addi $t2 $a0 -1
addi $t3 $a0 1
add $t4 $a0 $a1
sub $t5 $a0 $a1
j quatres_voisins
elif1: # On calcule les voisins si on est � la premiere colonne
mul $t7 $a1 $a1
sub $t7 $t7 $a0
beq $t7 $a1 elif2 #On v�rifie si on est � la fin de la premiere colonne
add $t2 $a0 $a1
addi $t3 $a0 1
sub $t4 $a0 $a1
j trois_voisins
elif2: # On calcule les voisins si on est � la fin de la premiere colonne
sub $t2 $a0 $a1
addi $t3 $a0 1 
j deux_voisins
elif3:# On calcule les voisins si on est � la derniere colonne
mul $t7 $a1 $a1
addi $t7 $t7 -1
beq $t7 $a0 elif4 #On v�rifie si on est au dernier indice
sub $t2 $a0 $a1
addi $t3 $a0 -1
add $t4 $a0 $a1
j trois_voisins
elif4: #On calcule les voisins si on est au dernier indice
sub $t2 $a0 $a1
addi $t3 $a0 -1
deux_voisins:
sw $t2 0($v0)
sw $t3 4($v0)
sw $s5 8($v0)
sw $s5 12($v0)
j fin
trois_voisins:
sw $t2 0($v0)
sw $t3 4($v0)
sw $t4 8($v0)
sw $s5 12($v0)
j fin
quatres_voisins:
sw $t2 0($v0)
sw $t3 4($v0)
sw $t4 8($v0)
sw $t5 12($v0)
fin:
#epilogue
lw $t7 40($sp)
lw $t6 36($sp)
lw $t5 32($sp)
lw $t4 28($sp)
lw $t3 24($sp)
lw $t2 20($sp)
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 44
jr $ra

cell_voisines_non_visitees:
#arguments:
#$a0: l'indice de la cellule
#$a1: taille du labyrinthe
#$a2: l'adresse du labyrinthe
#retour:
#$v0: l'adresse de la pile contenant les indices des voisins non visités
#$v1: le nombre de voisins non visités
#prologue
addi $sp $sp -40
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $a2 12($sp)
sw $t0 16($sp)
sw $t1 20($sp)
sw $t2 24($sp)
sw $t3 28($sp)
sw $t4 32($sp)
sw $t5 36($sp)
#corps
jal cell_voisines
move $t5 $v0
li $v1 0
li $a0 5
jal st_creer
move $t3 $v0
li $t2 4
li $t4 0
li $t0 0
boucle_cell_voisines_non_visitees:
beq $t4 $t2 fin_boucle_cell_voisines_non_visitees
move $t0 $t4
mul $t0 $t0 4
add $t0 $t0 $t5
lw $t1 0($t0)
addi $t4 $t4 1
beq $t1 -1 boucle_cell_voisines_non_visitees
lw $a1 8($sp)
mul $a1 $a1 $a1
bge $t1 $a1 boucle_cell_voisines_non_visitees
lw $a1 8($sp)
move $a0 $a2
move $a1 $t1
jal valeur_cell
move $a0 $v0
jal cell_deja_visite
beq $v0 1 boucle_cell_voisines_non_visitees
addi $v1 $v1 1
move $a0 $t3
move $a1 $t1
jal st_empiler
j boucle_cell_voisines_non_visitees
fin_boucle_cell_voisines_non_visitees:
move $v0 $t3
#epilogue
lw $t5 36($sp)
lw $t4 32($sp)
lw $t3 28($sp)
lw $t2 24($sp)
lw $t1 20($sp)
lw $t0 16($sp)
lw $a2 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 40
jr $ra

deplacement_dans_laby:
#preconditions:
#l'indice est retrouvable dans le labyrinthe
#$a2 = 1, 2, 3 ou 4
#arguments:
#$a0: la taille du labyrinthe
#$a1: l'indice de la cellule
#$a2: le deplacement 1 = haut, 2 = bas, 3 = gauche, 4 = droite
#retour:
#$v0 contient l'indice de la cellule de destination (ne verifie pas si cette cellule est dans le labyrinthe)
#prologue
addi $sp $sp -16
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $a2 12($sp)
#corps
beq $a2 1 si_haut
beq $a2 2 si_bas
beq $a2 3 si_gauche
beq $a2 4 si_droite
si_haut:
sub $v0 $a1 $a0
j fin_deplacement_dans_laby
si_bas:
add $v0 $a1 $a0
j fin_deplacement_dans_laby
si_gauche:
addi $v0 $a1 -1
j fin_deplacement_dans_laby
si_droite:
addi $v0 $a1 1
#epilogue
fin_deplacement_dans_laby:
lw $a2 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 16
jr $ra

voisin_alea:
#precondition:
#l'indice est retrouvable dans le labyrinthe
#arguments:
#$a0: l'indice de la cellule
#$a1: la taille du labyrinthe
#$a2: l'adresse du labyrinthe
#retour:
#$v0 contient l'indice de la cellule voisine choisie
#prologue
addi $sp $sp -24
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $a2 12($sp)
sw $t0 16($sp)
sw $t1 20($sp)
#corps
jal cell_voisines_non_visitees
move $t1 $v0
li $t0 4
li $a0 0
move $a1 $v1
li $v0 42
syscall
mul $a0 $a0 $t0
add $a0 $a0 $t1
lw $v0 0($a0)
#epilogue
lw $t1 20($sp)
lw $t0 16($sp)
lw $a2 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 24
jr $ra

marquer_cell_visite:
#precondition:
#l'indice est retrouvable dans le labyrinthe
#arguments:
#$a0: l'adresse du labyrinthe
#$a1: l'indice i de la cellule
#retour:

#prologue
addi $sp $sp -16
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
#corps
jal valeur_cell
move $a0 $v0
li $a1 6
jal cell_mettre_bit_a1
move $t0 $v0
lw $a0 4($sp)
lw $a1 8($sp)
move $a2 $t0
jal changer_valeur_cell
#epilogue
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 12
jr $ra

marquer_cell_debut:
#precondition:
#l'indice est retrouvable dans le labyrinthe
#arguments:
#$a0: l'adresse du labyrinthe
#$a1: l'indice i de la cellule
#retour:

#prologue
addi $sp $sp -16
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
#corps
jal valeur_cell
move $a0 $v0
li $a1 4
jal cell_mettre_bit_a1
move $t0 $v0
lw $a0 4($sp)
lw $a1 8($sp)
move $a2 $t0
jal changer_valeur_cell
#epilogue
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 12
jr $ra

marquer_cell_fin:
#precondition:
#l'indice est retrouvable dans le labyrinthe
#arguments:
#$a0: l'adresse du labyrinthe
#$a1: l'indice i de la cellule
#retour:

#prologue
addi $sp $sp -16
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $t0 12($sp)
#corps
jal valeur_cell
move $a0 $v0
li $a1 5
jal cell_mettre_bit_a1
move $t0 $v0
lw $a0 4($sp)
lw $a1 8($sp)
move $a2 $t0
jal changer_valeur_cell
#epilogue
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 12
jr $ra

casser_mur_entre_cell:
#precondition:
#l'indice est retrouvable dans le labyrinthe
#arguments:
#$a0: l'indice de la cellule 1
#$a1: l'indice de la cellule 2
#$a2: la taille du labyrinthe
#$a3: l'adresse du labyrinthe
#retour:

#prologue
addi $sp $sp -40
sw $ra 0($sp)
sw $a0 4($sp)
sw $a1 8($sp)
sw $a2 12($sp)
sw $a3 16($sp)
sw $t0 20($sp)
sw $t1 24($sp)
sw $t2 28($sp)
sw $t3 32($sp)
sw $t4 36($sp)
#corps
sub $t0 $a0 $a1
move $t1 $a2 #$t1 = N
move $t2 $a2
mul $t2 $t2 -1 #$t2 = -N
beq $t0 1 si_gauche_2 #on determine la position relative des deux cellules pour savoir quel mur casser
beq $t0 -1 si_droite_2
beq $t0 $t1 si_haut_2
beq $t0 $t2 si_bas_2
si_gauche_2:
li $t3 3
li $t4 1
j fin_casser_mur_entre_cell
si_droite_2:
li $t3 1
li $t4 3
j fin_casser_mur_entre_cell
si_haut_2:
li $t3 0
li $t4 2
j fin_casser_mur_entre_cell
si_bas_2:
li $t3 2
li $t4 0
fin_casser_mur_entre_cell:
move $a0 $a3 #on casse le mur de $a0
lw $a1 4($sp)
jal valeur_cell
move $a0 $v0
move $a1 $t3
jal cell_mettre_bit_a0
lw $a0 16($sp)
lw $a1 4($sp)
move $a2 $v0
jal changer_valeur_cell
move $a0 $a3  #on casse le mur de $a1
lw $a1 8($sp)
jal valeur_cell
move $a0 $v0
move $a1 $t4
jal cell_mettre_bit_a0
lw $a0 16($sp)
lw $a1 8($sp)
move $a2 $v0
jal changer_valeur_cell
#epilogue
lw $t4 36($sp)
lw $t3 32($sp)
lw $t2 28($sp)
lw $t1 24($sp)
lw $t0 20($sp)
lw $a3 16($sp)
lw $a2 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 40
jr $ra

longueur_str:
#parametres:
#$a0: l'adresse d'une null-terminated string
#retour: 
#$v0 contient la longueur de la chaine (sans le caractere null)

#prologue
addi $sp $sp -20
sw $ra 0($sp)
sw $a0 4($sp)
sw $t0 8($sp)
sw $t1 12($sp)
sw $t2 16($sp)
#corps
li $t0 0
boucle_longueur_str:
move $t1 $t0
add $t1 $t1 $a0
lb $t2 0($t1)
beqz $t2 fin_boucle_longueur_str
addi $t0 $t0 1
j boucle_longueur_str
fin_boucle_longueur_str:
move $v0 $t0
#epilogue
lw $t2 16($sp)
lw $t1 12($sp)
lw $t0 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 20
jr $ra

convert_str_int:
#parametres:
#$a0: l'adresse d'une null-terminated string
#retour: 
#$v0 contient la valeur en int de la chaine

#prologue
addi $sp $sp -24
sw $ra 0($sp)
sw $a0 4($sp)
sw $t0 8($sp)
sw $t1 12($sp)
sw $t2 16($sp)
sw $t3 20($sp)
#corps
li $t0 0
li $t1 1
jal longueur_str
move $t2 $v0
add $a0 $a0 $t2
boucle_convert_str_int:
beqz $t2 fin_boucle_convert_str_int
addi $a0 $a0 -1
lb $t3 0($a0)
addi $t3 $t3 -48 #48 est le code ascii de '0'
mul $t3 $t3 $t1
mul $t1 $t1 10
addi $t2 $t2 -1
add $t0 $t0 $t3
j boucle_convert_str_int
fin_boucle_convert_str_int:
move $v0 $t0
#epilogue
lw $t3 20($sp)
lw $t2 16($sp)
lw $t1 12($sp)
lw $t0 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addi $sp $sp 24
jr $ra

exit:
li $v0 10
syscall

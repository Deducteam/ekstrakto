// Calculus of Construction embedded into Lambda-Pi Modulo

constant symbol uT : TYPE
symbol eT : uT → TYPE

constant symbol Pi : Π (X : uT), ((eT X) → uT) → uT
constant symbol PiT : (uT → uT) → uT

rule eT (Pi $X $Y) ↪ Π (x : (eT $X)), eT ($Y x)
rule eT (PiT $Y)   ↪ Π (x : uT), eT ($Y x)

symbol Arrow : uT → uT → uT
rule Arrow $t1 $t2 ↪ Pi $t1 (λ (x : eT $t1), $t2)
#Множество оборудования
set L;
#Множество деталей
set I;
#Оптимизируемый функционал
var Y;
#Множество мест в цеху
set J;
#Расстояние от склада до j-ого места
param c_j{j in J};
#Количество операций, нужное для обработки iой детали
param M_i{I};
set M_I{i in I} := if M_i[i]>0 then {1 .. M_i[i]} else {}; 
#1, если kая деталь с lым номером операции обраб на iом станке
param r_ikl{i in I,k in M_I[i],l in L}, default 0;
#Переменная размещения оборудования
var x_lj{l in L,j in J}, binary;

minimize target: Y;
s.t.Optim:
	Y = sum{i in I,k in M_I[i], l in L, j in J}2*r_ikl[i,k,l]*x_lj[l,j]*c_j[j];
    
s.t.qqq {l in L}:
	sum{j in J}x_lj[l,j]=1;
    
s.t.aaa{j in J}:
	sum{l in L}x_lj[l,j]=1;

solve;

display Y;

printf '' > 'rasstanovka.txt';

for {j in J, l in L:x_lj[l,j]>0}
{
printf '%s', j >> 'rasstanovka.txt';
printf "\t" >> 'rasstanovka.txt';
printf '%s', l >> 'rasstanovka.txt';
printf "\n" >> 'rasstanovka.txt';
}
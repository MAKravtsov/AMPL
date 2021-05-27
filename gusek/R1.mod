#��������� ������������
set L;
#��������� �������
set I;
#�������������� ����������
var Y;
#��������� ���� � ����
set J;
#���������� �� ������ �� j-��� �����
param c_j{j in J};
#���������� ��������, ������ ��� ��������� i�� ������
param M_i{I};
set M_I{i in I} := if M_i[i]>0 then {1 .. M_i[i]} else {}; 
#1, ���� k�� ������ � l�� ������� �������� ����� �� i�� ������
param r_ikl{i in I,k in M_I[i],l in L}, default 0;
#���������� ���������� ������������
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
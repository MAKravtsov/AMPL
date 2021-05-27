#��������� �������������� �������
set I;
#��������� ����� �������
set J;
#���������� = ��������������� �����������
var Y; #,>=0;

#���������� ����� ������� ������� ����
param M_j{J};
set M_J{j in J} := if M_j[j]>0 then {1 .. M_j[j]} else {};

#����� ��������� �� ������� ����� ���� ���������� ������
param K_i{I};
set K_I{i in I} := if K_i[i]>0 then {0..K_i[i]-1} else  {};

#��������� ������� �������������� �� ������������ �������
set I_j{J}, dimen 1;

set K_j_i{j in J,i in I_j[j]}, dimen 1;

#����������-��������� ������������ ������ �� ������������� �����������
var th_ik{i in I, k in K_I[i]},binary;

#���� �� ����� ������ ������ �������������� ������ �� ������������� ����������� �� ������������ ������
var th_tilda_jilk{j in J,i in I_j[j],l in M_J[j], k in K_j_i[j,i]} >=0,<=1;

#����� ������� � ������
param n_i{I};

#����� �������� ��������� ������� �� ������ ������������� ����
param t_jik{j in J, i in I_j[j],k in K_j_i[j,i]};

#����������-��������� ������������ ������ �� ������������� ����������� �� ������������ ������
var th_hat_jilk{j in J,i in I_j[j],l in M_J[j], k in K_j_i[j,i]}, binary;

#����� ����������� ������������
param tau_jik{j in J, i in I_j[j],k in K_j_i[j,i]};

#���������� ���������-���������� ������
var Y_jl{j in J, l in M_J[j]}, binary;

#������ ������� ������ j-�� ����
param V_j{J};

#������������ ����������� �������� ������ j-�� ����
param mu_j{J};

#��������� ���� ������
param  c_i{i in I};

#������������� ������������ ������ �� k-�� ��������
param c_ik{i in I, k in K_I[i]};

#����������� �������� ��������
param C_0;
#�������� ���������� �� ������� ������������
param D;

param d_j{J};

#��������� ��������� ��������������� ��������
param b_jik{j in J, i in I_j[j],k in K_j_i[j,i]},default 0;



param a1, default 1.0;
param a2, default 1.0;
param a3, default 1.0;

#��������� ������������ ������ �� ��������� ������ �������
param b_j{J};

#��� �������������
maximize target: Y;

#�������������� ����������
s.t. funct: Y = 
a1*sum{i in I, k in K_I[i]} n_i[i]*th_ik[i,k]*(c_i[i]-c_ik[i,k])

-a2*sum{j in J, l in M_J[j]} (b_j[j]*Y_jl[j,l])

-a3*sum{j in J, i in I_j[j],l in M_J[j],k in K_j_i[j,i]} (b_jik[j,i,k]*th_hat_jilk[j,i,l,k]);

#����������� �� ������� ������
s.t. TimeLimit 
{j in J, l in M_J[j]}:

sum{i in I_j[j],k in K_j_i[j,i]}(th_tilda_jilk[j,i,l,k]*n_i[i]*t_jik[j,i,k]+th_hat_jilk[j,i,l,k]*tau_jik[j,i,k])
	<=Y_jl[j,l]*V_j[j]*mu_j[j];

s.t. OneRoute{j in J, i in I_j[j], k in K_j_i[j,i]}:

sum{l in M_J[j]}th_tilda_jilk[j,i,l,k]=th_ik[i,k];

#��� ������ �������� �������������, ��������� ������ ������
# necessary detail condition
s.t. ndc{i in I}:

sum{k in K_I[i]}th_ik[i,k]=1;

# ���� ����������� ������������
s.t. retuning{j in J, l in M_J[j], i in I_j[j], k in K_j_i[j,i]}:
			th_hat_jilk[j,i,l,k]-th_tilda_jilk[j,i,l,k]>=0;

#����������� �� �������
s.t. income: 

			sum{i in I, k in K_I[i]}n_i[i]*th_ik[i,k]*(c_i[i]-c_ik[i,k])>=C_0;
			
#����������� �� ��������� ������������
s.t. cost: 
			sum{j in J, l in M_J[j]}
			(
					d_j[j]*Y_jl[j,l]
					+sum{i in I_j[j],k in K_j_i[j,i]}b_jik[j,i,k]*th_hat_jilk[j,i,l,k]
			)
				<=D;
solve;


#����� ����������� ������������� � ����

display Y;

#множество обрабатываемых деталей
set I;
#множество типов станков
set J;
#переменная = оптимизируемому функционалу
var Y; #,>=0;

#допустимое число станков каждого типа
param M_j{J};
set M_J{j in J} := if M_j[j]>0 then {1 .. M_j[j]} else {};

#число маршрутов по которым может быть обработана деталь
param K_i{I};
set K_I{i in I} := if K_i[i]>0 then {0..K_i[i]-1} else  {};

#множество деталей обрабатываемых на определенных станках
set I_j{J}, dimen 1;

set K_j_i{j in J,i in I_j[j]}, dimen 1;

#переменная-индикатор производства детали по определенному техмаршруту
var th_ik{i in I, k in K_I[i]},binary;

#доля от общей партии детали обрабатываемой детали по определенному техмаршруту на определенном станке
var th_tilda_jilk{j in J,i in I_j[j],l in M_J[j], k in K_j_i[j,i]} >=0,<=1;

#число деталей в партии
param n_i{I};

#время операций обработки деталей на станке определенного типа
param t_jik{j in J, i in I_j[j],k in K_j_i[j,i]};

#переменная-индикатор производства детали по определенному техмаршруту на определенном станке
var th_hat_jilk{j in J,i in I_j[j],l in M_J[j], k in K_j_i[j,i]}, binary;

#время переналадки оборудования
param tau_jik{j in J, i in I_j[j],k in K_j_i[j,i]};

#переменная включения-исключения станка
var Y_jl{j in J, l in M_J[j]}, binary;

#ресурс времени станка j-го типа
param V_j{J};

#максимальный коэффициент загрузки станка j-го типа
param mu_j{J};

#отпускная цена детали
param  c_i{i in I};

#себестоимость производства детали по k-му маршруту
param c_ik{i in I, k in K_I[i]};

#минимальное значение желаемой
param C_0;
#средства выделенные на закупку оборудования
param D;

param d_j{J};

#Стоимость комплекта технологической оснастки
param b_jik{j in J, i in I_j[j],k in K_j_i[j,i]},default 0;



param a1, default 1.0;
param a2, default 1.0;
param a3, default 1.0;

#стоимость обслуживания станка за выбранный период времени
param b_j{J};

#что максимизируем
maximize target: Y;

#оптимизируемый функционал
s.t. funct: Y = 
a1*sum{i in I, k in K_I[i]} n_i[i]*th_ik[i,k]*(c_i[i]-c_ik[i,k])

-a2*sum{j in J, l in M_J[j]} (b_j[j]*Y_jl[j,l])

-a3*sum{j in J, i in I_j[j],l in M_J[j],k in K_j_i[j,i]} (b_jik[j,i,k]*th_hat_jilk[j,i,l,k]);

#ограничение по времени работы
s.t. TimeLimit 
{j in J, l in M_J[j]}:

sum{i in I_j[j],k in K_j_i[j,i]}(th_tilda_jilk[j,i,l,k]*n_i[i]*t_jik[j,i,k]+th_hat_jilk[j,i,l,k]*tau_jik[j,i,k])
	<=Y_jl[j,l]*V_j[j]*mu_j[j];

s.t. OneRoute{j in J, i in I_j[j], k in K_j_i[j,i]}:

sum{l in M_J[j]}th_tilda_jilk[j,i,l,k]=th_ik[i,k];

#все детали являются обязательными, исключать детали нельзя
# necessary detail condition
s.t. ndc{i in I}:

sum{k in K_I[i]}th_ik[i,k]=1;

# учет переналадок оборудования
s.t. retuning{j in J, l in M_J[j], i in I_j[j], k in K_j_i[j,i]}:
			th_hat_jilk[j,i,l,k]-th_tilda_jilk[j,i,l,k]>=0;

#ограничение на прибыль
s.t. income: 

			sum{i in I, k in K_I[i]}n_i[i]*th_ik[i,k]*(c_i[i]-c_ik[i,k])>=C_0;
			
#ограничение на стоимость оборудования
s.t. cost: 
			sum{j in J, l in M_J[j]}
			(
					d_j[j]*Y_jl[j,l]
					+sum{i in I_j[j],k in K_j_i[j,i]}b_jik[j,i,k]*th_hat_jilk[j,i,l,k]
			)
				<=D;
solve;


#вывод результатов моделирования в файл

display Y;

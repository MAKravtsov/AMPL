#множество обрабатываемых деталей
set I;
#множество старых типов станков
set J_old;
#множество новых типов станков
set J_new;
#множество всех типов станков
set J_all;
#переменная = оптимизируемому функционалу
var Y; #,>=0;

#допустимое число старых станков каждого типа
param M_j_old{J_old};
set M_J_old{j in J_old} := if M_j_old[j]>0 then {1 .. M_j_old[j]} else {};

#допустимое число новых станков каждого типа
param M_j_all{J_all};
set M_J_all{j in J_all} := if M_j_all[j]>0 then {1 .. M_j_all[j]} else {};

#допустимое число новых станков каждого типа
param M_j_new{J_old};
set M_J_new{j in J_old} := if M_j_new[j]>0 then {1 .. M_j_new[j]} else {};


#число маршрутов по которым может быть обработана деталь
param K_i{I};
set K_I{i in I} := if K_i[i]>0 then {0..K_i[i]-1} else  {};

#множество деталей обрабатываемых на определенных станках
set I_j{J_all}, dimen 1;

#технологические маршруты деталей
set K_j_i{j in J_all,i in I_j[j]}, dimen 1;

#переменная-индикатор производства детали по определенному техмаршруту
var th_ik{i in I, k in K_I[i]},binary;

#доля от общей партии детали обрабатываемой детали по определенному техмаршруту на определенном станке
var th_tilda_jilk{j in J_all,i in I_j[j],l in M_J_all[j], k in K_j_i[j,i]} >=0,<=1;

#число деталей в партии
param n_i{I};

#время операций обработки деталей на станке определенного типа
param t_jik{j in J_all, i in I_j[j],k in K_j_i[j,i]};

#переменная-индикатор производства детали по определенному техмаршруту на определенном станке
var th_hat_jilk{j in J_all,i in I_j[j],l in M_J_all[j], k in K_j_i[j,i]}, binary;

#время переналадки оборудования
param tau_jik{j in J_all, i in I_j[j],k in K_j_i[j,i]};

#переменная включения-исключения станка
var Y_jl{j in J_all, l in M_J_all[j]}, binary;

#ресурс времени станка j-го типа
param V_j{J_all};

#максимальный коэффициент загрузки станка j-го типа
param mu_j{J_all};

#отпускная цена детали
param  c_i{i in I};

#себестоимость производства детали по k-му маршруту
param c_ik{i in I, k in K_I[i]};

#минимальное значение желаемой
param C_0;

#средства выделенные на закупку оборудования
param D;

#Стоимость покупки оборудования
param d_j{J_all};

#Стоимость продажи оборудования
param s_j{J_all};

#Стоимость комплекта технологической оснастки
param b_jik{j in J_all, i in I_j[j],k in K_j_i[j,i]},default 0;

#стоимость обслуживания станка за выбранный период времени
param b_j{J_all};

#Коэффициенты уравнения
param a1, default 1.0;
param a2, default 1.0;
param a3, default 1.0;

#что максимизируем
maximize target: Y;

#оптимизируемый функционал
subject to funct: Y = 
	a1*sum{i in I, k in K_I[i]} n_i[i]*th_ik[i,k]*(c_i[i]-c_ik[i,k])
	-a2*sum{j in J_all, l in M_J_all[j]} (b_j[j]*Y_jl[j,l])
	-a3*sum{j in J_all, i in I_j[j],l in M_J_all[j],k in K_j_i[j,i]} (b_jik[j,i,k]*th_hat_jilk[j,i,l,k]);

#ограничение по времени работы
subject to TimeLimit {j in J_all, l in M_J_all[j]}:
	sum{i in I_j[j],k in K_j_i[j,i]}(th_tilda_jilk[j,i,l,k]*n_i[i]*t_jik[j,i,k]+th_hat_jilk[j,i,l,k]*tau_jik[j,i,k])
		<=Y_jl[j,l]*V_j[j]*mu_j[j];

#Ограничение по маршруту
subject to OneRoute {j in J_all, i in I_j[j], k in K_j_i[j,i]}:
	sum{l in M_J_all[j]}th_tilda_jilk[j,i,l,k]=th_ik[i,k];

#все детали являются обязательными, исключать детали нельзя
# necessary detail condition
subject to ndc{i in I}:
	sum{k in K_I[i]}th_ik[i,k]=1;

# учет переналадок оборудования
subject to retuning{j in J_all, l in M_J_all[j], i in I_j[j], k in K_j_i[j,i]}:
	th_hat_jilk[j,i,l,k]-th_tilda_jilk[j,i,l,k]>=0;

#ограничение на прибыль
subject to income: 
	sum{i in I, k in K_I[i]}n_i[i]*th_ik[i,k]*(c_i[i]-c_ik[i,k])>=C_0;
			
#ограничение на стоимость оборудования
subject to cost: 
	sum{j in J_old, l in M_J_old[j]} (
		d_j[j]*Y_jl[j,l]
		- s_j[j] * ( 1 - Y_jl[j,l] )
	) + 
	sum{j in J_old, l in M_J_new[j]} (
		d_j[j]*Y_jl[j,l]
		+sum{i in I_j[j],k in K_j_i[j,i]}b_jik[j,i,k]*th_hat_jilk[j,i,l,k]
	) + 
	sum{j in J_new, l in M_J_all[j]} (
		d_j[j]*Y_jl[j,l]
		+sum{i in I_j[j],k in K_j_i[j,i]}b_jik[j,i,k]*th_hat_jilk[j,i,l,k]
	) <=D; 

solve;


#вывод результатов моделирования в файл
display Y;

printf '' > 'out.txt';

printf 'Новых станков: '>> 'out.txt';
printf "\n"  >> 'out.txt';
for{j in J_old,i in I_j[j],l in M_J_new[j], k in K_j_i[j,i]:th_tilda_jilk[j,i,l,k]>0}
{
   printf '%s;', j >> 'out.txt';
   printf '%s;', i	 >> 'out.txt';
   printf '%d;', k >> 'out.txt';
   printf '%f;', th_tilda_jilk[j,i,l,k]>> 'out.txt';
   printf '%d', l >> 'out.txt';
   printf "\n"  >> 'out.txt';
}
for{j in J_new,i in I_j[j],l in M_J_all[j], k in K_j_i[j,i]:th_tilda_jilk[j,i,l,k]>0}
{
   printf '%s;', j >> 'out.txt';
   printf '%s;', i	 >> 'out.txt';
   printf '%d;', k >> 'out.txt';
   printf '%f;', th_tilda_jilk[j,i,l,k]>> 'out.txt';
   printf '%d', l >> 'out.txt';
   printf "\n"  >> 'out.txt';
}
printf "\n"  >> 'out.txt';

printf 'Всего станков: '>> 'out.txt';
printf "\n"  >> 'out.txt';
for{j in J_all,i in I_j[j],l in M_J_all[j], k in K_j_i[j,i]:th_tilda_jilk[j,i,l,k]>0}
{
   printf '%s;', j >> 'out.txt';
   printf '%s;', i	 >> 'out.txt';
   printf '%d;', k >> 'out.txt';
   printf '%f;', th_tilda_jilk[j,i,l,k]>> 'out.txt';
   printf '%d', l >> 'out.txt';
   printf "\n"  >> 'out.txt';
}
printf "\n"  >> 'out.txt';

printf 'Сколько мы потратили? %d',sum{j in J_all, l in M_J_all[j]}
			(
					d_j[j]*Y_jl[j,l]
					+sum{i in I_j[j],k in K_j_i[j,i]}b_jik[j,i,k]*th_hat_jilk[j,i,l,k]
			)>> 'out.txt';
printf "\n"  >> 'out.txt';
printf 'Прибыль = %d',sum{i in I, k in K_I[i]}n_i[i]*th_ik[i,k]*(c_i[i]-c_ik[i,k])>> 'out.txt';

data;
#Множество станков и деталей
set J_old:= "Расточный" "Фрезерный" "Моечный" "Зуборезной" "Вертикально-сверлильный" "Радиально-сверлильный" "Токарно-винторезный" "Строгальный" "Продольно-фрезерный" "Станок с ЧПУ" ;
set J_new:= "Хонинговальный" "Долбежный" "Лазерный";
set J_all:= "Расточный" "Фрезерный" "Моечный" "Зуборезной" "Вертикально-сверлильный" "Радиально-сверлильный" "Токарно-винторезный" "Строгальный" "Продольно-фрезерный" "Станок с ЧПУ" "Хонинговальный" "Долбежный" "Лазерный";
set I:= "Вал" "Корпус" "Втулка" "Ступица" "Стакан" "Колесо" "Рычаг" "Штуцер" "Клапан" "Крышка" "Гильза" "Опора" "Блок" "Прокладка" ;
#Деньги
param C_0:=0;
param D:=1000000000000;
#Параметры станка
param b_j:=
"Расточный" 100000
"Фрезерный" 80000
"Моечный" 50000
"Зуборезной" 90000
"Вертикально-сверлильный" 130000
"Радиально-сверлильный" 145000
"Токарно-винторезный" 130000
"Строгальный" 30000
"Продольно-фрезерный" 130000
"Станок с ЧПУ" 200000
"Хонинговальный" 150000
"Долбежный" 100000
"Лазерный" 180000
;
param d_j:=
"Расточный" 1000000
"Фрезерный" 3000000
"Моечный" 500000
"Зуборезной" 3000000
"Вертикально-сверлильный" 2000000
"Радиально-сверлильный" 1800000
"Токарно-винторезный" 2500000
"Строгальный" 700000
"Продольно-фрезерный" 3000000
"Станок с ЧПУ" 5000000
"Хонинговальный" 2500000
"Долбежный" 2000000
"Лазерный" 4000000
;
param s_j:=
"Расточный" 500000
"Фрезерный" 1500000
"Моечный" 250000
"Зуборезной" 1500000
"Вертикально-сверлильный" 1000000
"Радиально-сверлильный" 900000
"Токарно-винторезный" 1250000
"Строгальный" 350000
"Продольно-фрезерный" 1500000
"Станок с ЧПУ" 2500000
"Хонинговальный" 1250000
"Долбежный" 1000000
"Лазерный" 2000000
;
param V_j:=
"Расточный" 10000
"Фрезерный" 15000
"Моечный" 20000
"Зуборезной" 15000
"Вертикально-сверлильный" 13000
"Радиально-сверлильный" 15000
"Токарно-винторезный" 11000
"Строгальный" 16000
"Продольно-фрезерный" 15000
"Станок с ЧПУ" 25000
"Хонинговальный" 23000
"Долбежный" 22000
"Лазерный" 24000
;
param mu_j:=
"Расточный" 0.85
"Фрезерный" 0.85
"Моечный" 0.85
"Зуборезной" 0.85
"Вертикально-сверлильный" 0.85
"Радиально-сверлильный" 0.85
"Токарно-винторезный" 0.85
"Строгальный" 0.85
"Продольно-фрезерный" 0.85
"Станок с ЧПУ" 0.85
"Хонинговальный" 0.85
"Долбежный" 0.85
"Лазерный" 0.85
;
param M_j_old:=
"Расточный" 3
"Фрезерный" 2
"Моечный" 1
"Зуборезной" 2
"Вертикально-сверлильный" 1
"Радиально-сверлильный" 1
"Токарно-винторезный" 2
"Строгальный" 1
"Продольно-фрезерный" 1
"Станок с ЧПУ" 1
;
param M_j_new:=
"Расточный" 2
"Фрезерный" 3
"Моечный" 4
"Зуборезной" 3
"Вертикально-сверлильный" 4
"Радиально-сверлильный" 4
"Токарно-винторезный" 3
"Строгальный" 4
"Продольно-фрезерный" 4
"Станок с ЧПУ" 4
;
param M_j_all:=
"Расточный" 5
"Фрезерный" 5
"Моечный" 5
"Зуборезной" 5
"Вертикально-сверлильный" 5
"Радиально-сверлильный" 5
"Токарно-винторезный" 5
"Строгальный" 5
"Продольно-фрезерный" 5
"Станок с ЧПУ" 5
"Хонинговальный" 5
"Долбежный" 5
"Лазерный" 5
;
#Параметры деталей
param K_i:=
"Вал" 1
"Корпус" 1
"Втулка" 1
"Ступица" 1
"Стакан" 1
"Колесо" 1
"Рычаг" 1
"Штуцер" 1
"Клапан" 1
"Крышка" 1
"Гильза" 2
"Опора" 3
"Блок" 2
"Прокладка" 2
;
param c_i:=
"Вал" 10000
"Корпус" 20000
"Втулка" 500
"Ступица" 10000
"Стакан" 1500
"Колесо" 2000
"Рычаг" 8000
"Штуцер" 300
"Клапан" 700
"Крышка" 15000
"Гильза" 2000
"Опора" 5000
"Блок" 4000
"Прокладка" 200
;
param n_i:=
"Вал" 50
"Корпус" 30
"Втулка" 500
"Ступица" 40
"Стакан" 200
"Колесо" 100
"Рычаг" 60
"Штуцер" 600
"Клапан" 250
"Крышка" 35
"Гильза" 300
"Опора" 100
"Блок" 200
"Прокладка" 250
;
#Какие детали, на каких станках обрабатываются
set I_j["Расточный"]:= "Втулка" "Стакан" "Колесо" "Рычаг" "Клапан" "Гильза" "Опора" "Блок" "Прокладка" ;
set I_j["Фрезерный"]:= "Ступица" "Крышка" ;
set I_j["Моечный"]:= "Вал" "Корпус" "Стакан" "Колесо" "Крышка" "Гильза" "Опора" "Блок" ;
set I_j["Зуборезной"]:= "Колесо" ;
set I_j["Вертикально-сверлильный"]:= "Стакан" "Рычаг" "Опора" "Блок" ;
set I_j["Радиально-сверлильный"]:= "Корпус" "Клапан" "Гильза" "Опора" ;
set I_j["Токарно-винторезный"]:= "Втулка" "Гильза" "Опора" ;
set I_j["Строгальный"]:= "Колесо" "Рычаг" "Клапан" "Крышка" "Опора" "Блок" "Прокладка" ;
set I_j["Продольно-фрезерный"]:= "Корпус" "Ступица" "Рычаг" "Блок" ;
set I_j["Станок с ЧПУ"]:= "Вал" "Ступица" "Штуцер" "Гильза" "Опора" "Блок" "Прокладка" ;
set I_j["Хонинговальный"]:= "Блок" ;
set I_j["Долбежный"]:= "Опора" "Блок" ;
set I_j["Лазерный"]:= "Гильза" "Опора" "Блок" "Прокладка" ;
#Маршруты деталей
set K_j_i["Моечный","Вал"]:= 0 ;
set K_j_i["Станок с ЧПУ","Вал"]:= 0 ;
set K_j_i["Моечный","Корпус"]:= 0 ;
set K_j_i["Радиально-сверлильный","Корпус"]:= 0 ;
set K_j_i["Продольно-фрезерный","Корпус"]:= 0 ;
set K_j_i["Расточный","Втулка"]:= 0 ;
set K_j_i["Токарно-винторезный","Втулка"]:= 0 ;
set K_j_i["Фрезерный","Ступица"]:= 0 ;
set K_j_i["Продольно-фрезерный","Ступица"]:= 0 ;
set K_j_i["Станок с ЧПУ","Ступица"]:= 0 ;
set K_j_i["Расточный","Стакан"]:= 0 ;
set K_j_i["Моечный","Стакан"]:= 0 ;
set K_j_i["Вертикально-сверлильный","Стакан"]:= 0 ;
set K_j_i["Расточный","Колесо"]:= 0 ;
set K_j_i["Моечный","Колесо"]:= 0 ;
set K_j_i["Зуборезной","Колесо"]:= 0 ;
set K_j_i["Строгальный","Колесо"]:= 0 ;
set K_j_i["Расточный","Рычаг"]:= 0 ;
set K_j_i["Вертикально-сверлильный","Рычаг"]:= 0 ;
set K_j_i["Строгальный","Рычаг"]:= 0 ;
set K_j_i["Продольно-фрезерный","Рычаг"]:= 0 ;
set K_j_i["Станок с ЧПУ","Штуцер"]:= 0 ;
set K_j_i["Расточный","Клапан"]:= 0 ;
set K_j_i["Радиально-сверлильный","Клапан"]:= 0 ;
set K_j_i["Строгальный","Клапан"]:= 0 ;
set K_j_i["Фрезерный","Крышка"]:= 0 ;
set K_j_i["Моечный","Крышка"]:= 0 ;
set K_j_i["Строгальный","Крышка"]:= 0 ;
set K_j_i["Расточный","Гильза"]:= 0 ;
set K_j_i["Моечный","Гильза"]:= 0 1 ;
set K_j_i["Радиально-сверлильный","Гильза"]:= 1 ;
set K_j_i["Токарно-винторезный","Гильза"]:= 0 ;
set K_j_i["Станок с ЧПУ","Гильза"]:= 1 ;
set K_j_i["Лазерный","Гильза"]:= 0 1 ;
set K_j_i["Расточный","Опора"]:= 1 ;
set K_j_i["Моечный","Опора"]:= 0 1 ;
set K_j_i["Вертикально-сверлильный","Опора"]:= 1 ;
set K_j_i["Радиально-сверлильный","Опора"]:= 2 ;
set K_j_i["Токарно-винторезный","Опора"]:= 1 ;
set K_j_i["Строгальный","Опора"]:= 0 ;
set K_j_i["Станок с ЧПУ","Опора"]:= 0 2 ;
set K_j_i["Долбежный","Опора"]:= 0 2 ;
set K_j_i["Лазерный","Опора"]:= 0 1 ;
set K_j_i["Расточный","Блок"]:= 0 1 ;
set K_j_i["Моечный","Блок"]:= 0 ;
set K_j_i["Вертикально-сверлильный","Блок"]:= 0 ;
set K_j_i["Строгальный","Блок"]:= 1 ;
set K_j_i["Продольно-фрезерный","Блок"]:= 1 ;
set K_j_i["Станок с ЧПУ","Блок"]:= 0 ;
set K_j_i["Хонинговальный","Блок"]:= 0 1 ;
set K_j_i["Долбежный","Блок"]:= 1 ;
set K_j_i["Лазерный","Блок"]:= 0 ;
set K_j_i["Расточный","Прокладка"]:= 1 ;
set K_j_i["Строгальный","Прокладка"]:= 0 ;
set K_j_i["Станок с ЧПУ","Прокладка"]:= 0 ;
set K_j_i["Лазерный","Прокладка"]:= 0 1 ;
#Время обработки
param t_jik
["Моечный","Вал",0]:= 45
["Станок с ЧПУ","Вал",0]:= 150
["Моечный","Корпус",0]:= 30
["Радиально-сверлильный","Корпус",0]:= 45
["Продольно-фрезерный","Корпус",0]:= 150
["Расточный","Втулка",0]:= 5
["Токарно-винторезный","Втулка",0]:= 20
["Фрезерный","Ступица",0]:= 120
["Продольно-фрезерный","Ступица",0]:= 45
["Станок с ЧПУ","Ступица",0]:= 150
["Расточный","Стакан",0]:= 30
["Моечный","Стакан",0]:= 35
["Вертикально-сверлильный","Стакан",0]:= 40
["Расточный","Колесо",0]:= 40
["Моечный","Колесо",0]:= 20
["Зуборезной","Колесо",0]:= 180
["Строгальный","Колесо",0]:= 25
["Расточный","Рычаг",0]:= 30
["Вертикально-сверлильный","Рычаг",0]:= 35
["Строгальный","Рычаг",0]:= 40
["Продольно-фрезерный","Рычаг",0]:= 45
["Станок с ЧПУ","Штуцер",0]:= 12
["Расточный","Клапан",0]:= 11
["Радиально-сверлильный","Клапан",0]:= 15
["Строгальный","Клапан",0]:= 9
["Фрезерный","Крышка",0]:= 240
["Моечный","Крышка",0]:= 60
["Строгальный","Крышка",0]:= 30
["Расточный","Гильза",0]:= 10
["Моечный","Гильза",0]:= 3
["Моечный","Гильза",1]:= 3
["Радиально-сверлильный","Гильза",1]:= 10
["Токарно-винторезный","Гильза",0]:= 20
["Станок с ЧПУ","Гильза",1]:= 12
["Лазерный","Гильза",0]:= 1
["Лазерный","Гильза",1]:= 1
["Расточный","Опора",1]:= 15
["Моечный","Опора",0]:= 4
["Моечный","Опора",1]:= 5
["Вертикально-сверлильный","Опора",1]:= 20
["Радиально-сверлильный","Опора",2]:= 10
["Токарно-винторезный","Опора",1]:= 60
["Строгальный","Опора",0]:= 15
["Станок с ЧПУ","Опора",0]:= 10
["Станок с ЧПУ","Опора",2]:= 10
["Долбежный","Опора",0]:= 20
["Долбежный","Опора",2]:= 20
["Лазерный","Опора",0]:= 4
["Лазерный","Опора",1]:= 4
["Расточный","Блок",0]:= 30
["Расточный","Блок",1]:= 30
["Моечный","Блок",0]:= 15
["Вертикально-сверлильный","Блок",0]:= 20
["Строгальный","Блок",1]:= 40
["Продольно-фрезерный","Блок",1]:= 45
["Станок с ЧПУ","Блок",0]:= 50
["Хонинговальный","Блок",0]:= 40
["Хонинговальный","Блок",1]:= 40
["Долбежный","Блок",1]:= 20
["Лазерный","Блок",0]:= 7
["Расточный","Прокладка",1]:= 5
["Строгальный","Прокладка",0]:= 1
["Станок с ЧПУ","Прокладка",0]:= 3
["Лазерный","Прокладка",0]:= 2
["Лазерный","Прокладка",1]:= 2
;
#Время переналадки
param tau_jik
["Моечный","Вал",0]:= 7
["Станок с ЧПУ","Вал",0]:= 7
["Моечный","Корпус",0]:= 5
["Радиально-сверлильный","Корпус",0]:= 10
["Продольно-фрезерный","Корпус",0]:= 5
["Расточный","Втулка",0]:= 7
["Токарно-винторезный","Втулка",0]:= 5
["Фрезерный","Ступица",0]:= 10
["Продольно-фрезерный","Ступица",0]:= 10
["Станок с ЧПУ","Ступица",0]:= 15
["Расточный","Стакан",0]:= 9
["Моечный","Стакан",0]:= 7
["Вертикально-сверлильный","Стакан",0]:= 7
["Расточный","Колесо",0]:= 10
["Моечный","Колесо",0]:= 5
["Зуборезной","Колесо",0]:= 20
["Строгальный","Колесо",0]:= 15
["Расточный","Рычаг",0]:= 10
["Вертикально-сверлильный","Рычаг",0]:= 7
["Строгальный","Рычаг",0]:= 7
["Продольно-фрезерный","Рычаг",0]:= 7
["Станок с ЧПУ","Штуцер",0]:= 5
["Расточный","Клапан",0]:= 7
["Радиально-сверлильный","Клапан",0]:= 7
["Строгальный","Клапан",0]:= 7
["Фрезерный","Крышка",0]:= 15
["Моечный","Крышка",0]:= 5
["Строгальный","Крышка",0]:= 10
["Расточный","Гильза",0]:= 4
["Моечный","Гильза",0]:= 2
["Моечный","Гильза",1]:= 2
["Радиально-сверлильный","Гильза",1]:= 4
["Токарно-винторезный","Гильза",0]:= 7
["Станок с ЧПУ","Гильза",1]:= 2
["Лазерный","Гильза",0]:= 0
["Лазерный","Гильза",1]:= 0
["Расточный","Опора",1]:= 5
["Моечный","Опора",0]:= 2
["Моечный","Опора",1]:= 2
["Вертикально-сверлильный","Опора",1]:= 5
["Радиально-сверлильный","Опора",2]:= 5
["Токарно-винторезный","Опора",1]:= 20
["Строгальный","Опора",0]:= 5
["Станок с ЧПУ","Опора",0]:= 3
["Станок с ЧПУ","Опора",2]:= 3
["Долбежный","Опора",0]:= 5
["Долбежный","Опора",2]:= 7
["Лазерный","Опора",0]:= 1
["Лазерный","Опора",1]:= 1
["Расточный","Блок",0]:= 7
["Расточный","Блок",1]:= 7
["Моечный","Блок",0]:= 5
["Вертикально-сверлильный","Блок",0]:= 5
["Строгальный","Блок",1]:= 10
["Продольно-фрезерный","Блок",1]:= 7
["Станок с ЧПУ","Блок",0]:= 10
["Хонинговальный","Блок",0]:= 10
["Хонинговальный","Блок",1]:= 10
["Долбежный","Блок",1]:= 7
["Лазерный","Блок",0]:= 2
["Расточный","Прокладка",1]:= 2
["Строгальный","Прокладка",0]:= 1
["Станок с ЧПУ","Прокладка",0]:= 1
["Лазерный","Прокладка",0]:= 0
["Лазерный","Прокладка",1]:= 0
;
#Себестоимость деталей
param c_ik
["Вал",0]:= 6000
["Корпус",0]:= 7750
["Втулка",0]:= 100
["Ступица",0]:= 3500
["Стакан",0]:= 400
["Колесо",0]:= 650
["Рычаг",0]:= 1200
["Штуцер",0]:= 80
["Клапан",0]:= 125
["Крышка",0]:= 8000
["Гильза",0]:= 250
["Гильза",1]:= 300
["Опора",0]:= 1000
["Опора",1]:= 1200
["Опора",2]:= 950
["Блок",0]:= 600
["Блок",1]:= 500
["Прокладка",0]:= 100
["Прокладка",1]:= 80
;

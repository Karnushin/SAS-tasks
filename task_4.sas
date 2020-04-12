/* Макрос для изображения 6 графиков с группировкой*/
%macro drawDotsWithGroup(data_=, group_name=);
/*PetalWidth, PetalLength, SepalWidth, SepalLength*/

proc sgplot data=&data_;
	scatter x=PetalWidth y=PetalLength / group=&group_name markerchar=&group_name;
run;

proc sgplot data=&data_;
	scatter x=PetalWidth y=SepalWidth / group=&group_name markerchar=&group_name;
run;

proc sgplot data=&data_;
	scatter x=PetalWidth y=SepalLength / group=&group_name markerchar=&group_name;
run;

proc sgplot data=&data_;
	scatter x=PetalLength y=SepalWidth / group=&group_name markerchar=&group_name;
run;

proc sgplot data=&data_;
	scatter x=PetalLength y=SepalLength / group=&group_name markerchar=&group_name;
run;

proc sgplot data=&data_;
	scatter x=SepalWidth y=SepalLength / group=&group_name markerchar=&group_name;
run;

%mend;

/*Графики зависимостей параметров*/
%drawDotsWithGroup(data_=sashelp.iris, group_name=Species);
/*Исходя из вида графиков, попробуем разделить кластеры по переменным
PetalWidth, PetalLength для большей точности*/

data iris;
	set sashelp.iris;
	retain Number 0;
	if (PetalWidth > 17) then PetalWidth = PetalWidth + 10;
	if (PetalLength > 48) then PetalLength = PetalLength + 10;
	Number = Number + 1;
run;

/*Удаление избыточных переменных*/
proc varclus data=iris minclusters=3;
	var PetalWidth PetalLength SepalWidth SepalLength;
run;

/*Графики главных компонент*/
proc princomp data=iris plots=matrix;
	var PetalWidth PetalLength SepalWidth SepalLength;
run;

/*Масштабирование переменных*/
proc stdize data=iris out=iris_scaled method=agk(3);
	var PetalWidth PetalLength SepalWidth SepalLength;
run;

/*Трансформация переменных*/
proc aceclus data=iris_scaled percent=75 out=iris_new;
	var PetalWidth PetalLength SepalWidth SepalLength;
run;

proc varclus data=iris_new minclusters=3;
	var PetalWidth PetalLength SepalWidth SepalLength Can1 Can2 Can3 Can4; 
run;

/*Графики зависимостей с группами*/
%drawDotsWithGroup(data_=iris_new, group_name=Species);
/*-----------------------------------------------------------------------------*/
proc distance data=iris_new out=dist method=euclid;
	var ratio (PetalWidth PetalLength SepalWidth SepalLength Can1 Can2 Can3 Can4);
run;

/*Проекции групп*/
proc mds data=dist plots=(all);
run;

/*k-means*/
proc fastclus data=iris_new out=fastclus maxclusters=3;
	var PetalWidth SepalWidth PetalLength SepalLength; 
run;

%drawDotsWithGroup(data_=fastclus, group_name=cluster);

data test_1;
	set fastclus;
	if (Species = 'Virginica') then Type = 1;
	if (Species = 'Setosa') then Type = 2;
	if (Species = 'Versicolor') then Type = 3;		
run;

/*Подсчет числа ошибок для k-means*/
proc sql;
	create table count_errors_1 as
	select count(1) from test_1
	where Type ne cluster;
quit;
/*5 ошибок*/

/*Иерархическая кластеризация*/
proc cluster data=iris_new method=average outtree=tree_1;
	var PetalWidth SepalWidth PetalLength SepalLength;
	id Number;
run;

proc tree data=tree_1 n=3 out=tree_2;
	id Number;
run;

/*Пересечение переменных с кластерами*/
proc sql;
	create table tree_cluster as
	select tree_1.Number, cluster, PetalWidth, PetalLength, SepalWidth, SepalLength
	from tree_1 
	inner join tree_2 on tree_1.Number = tree_2.Number;
quit;

%drawDotsWithGroup(data_=tree_cluster, group_name=cluster);

proc sql;
	create table joined_table as
	select cluster, Species from tree_cluster
	inner join iris on tree_cluster.Number = iris.Number;
quit;

data test_2;
	set joined_table;
	if (Species = 'Virginica') then Type = 1;
	if (Species = 'Setosa') then Type = 2;
	if (Species = 'Versicolor') then Type = 3;	
run;

/*Подсчет числа ошибок для иерарх. кластер.*/
proc sql;
	create table count_errors_2 as
	select count(1)
	from test_2
	where Type ne cluster;
quit;
/*7 ошибок*/

/*При данной настройке параметров получается, что метод fastclus показывает лучшие
результаты, а именно 5 ошибок против 7 у иерархической кластеризации, но в обоих
случаях число ошибок меньше 10, которые требуются в задаче, а значит оба метода
удовлетворяют условию */

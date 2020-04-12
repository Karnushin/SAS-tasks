/*Origin влияет на horsepower, так как p-value < 0.01*/
proc glm data=sashelp.cars;
	class Origin;
	model HorsePower=Origin;
	lsmeans Origin / adjust=t alpha=0.01 pdiff=all;
	/*RMSE: 67.60494*/
run;
/*-----------------------------------------------------------------------------------------*/
/*Бонусное задание*/
proc template;
	edit stat.GLM.Pdiff;
		cellstyle _val_ > 0.01 as {color=#FF3333};
	end;
run;
/*-----------------------------------------------------------------------------------------*/
/*t-test'ы для origin*/
proc ttest data=sashelp.cars;
	where Origin in ("USA", "Asia");
	class Origin;
	var HorsePower;
run;

proc ttest data=sashelp.cars;
	where Origin in ("USA", "Europe");
	class Origin;
	var HorsePower;
run;

proc ttest data=sashelp.cars;
	where Origin in ("Europe", "Asia");
	class Origin;
	var HorsePower;
run;
/*Вывод:"неразличимых" групп нет => объединять нечего*/
/*-----------------------------------------------------------------------------------------*/
proc glm data=sashelp.cars;
	class Origin Type;
	model HorsePower = Origin|Type;
	/*RMSE: 61.38518*/
	/*p-value origin*type: 0.0763 > 0.01 => данный предиктор не нужен*/
run;

/*В итоге получается финальная модель следующего вида:*/
proc glm data=sashelp.cars;
	class Origin Type;
	model HorsePower = Origin Type;
	/*RMSE: 61.81883*/
run;

/*Для pdf отчета*/
ods document name=work.part_1(write);
proc glm data=sashelp.cars;
	class Origin;
	model HorsePower = Origin;
	lsmeans Origin / adjust=t alpha=0.01 pdiff=all;
	ods select glm.lsmeans.Origin.HorsePower.diff;
run;
ods document close;
ods document name=work.part_2(write);
proc glm DATA=sashelp.cars;
	class Origin Type;
	model HorsePower = Origin Type;
	ods select select glm.anova.HorsePower.overallanova;
	ods select glm.anova.HorsePower.fitstatistics;
run;
ods document close;

/*Создание pdf и формирование отчета*/
ods pdf file='/folders/myfolders/task2/task_2.pdf';
proc document name=work.part_1;
	replay;
run;

proc document name=work.part_2;
	replay;
run;
ods pdf close;

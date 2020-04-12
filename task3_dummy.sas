%let TARGET_VAR = MPG_highway;/*MPG_city; /*MPG_highway;*/
%macro prepare_data(rowdata=sashelp.cars, traindata=train_cars, testdata=test_cars);

proc rank data=&rowdata out=cars_d groups=10;
where (type ne "Hybrid");
var &TARGET_VAR;
ranks R_&TARGET_VAR;
run;

proc sort data = cars_d;
by R_&TARGET_VAR;
run;

proc surveyselect data=cars_d out=&traindata n=30;
strata R_&TARGET_VAR;
run;

proc sql;
create table &testdata as select * from &rowdata
where not model in (select model from &traindata) and (type ne "Hybrid");
quit;

data &testdata;
set &testdata;
/*add here necessary variables generation*/
if (Cylinders eq .) then Cylinders=4;
run;

data &traindata;
set &traindata;
/*add here necessary input variables generation*/
if (Cylinders eq .) then Cylinders=4;
run;

%mend;

%macro calc_mape(dataset=test_cars);
data _null_;
retain MAPE 0;
set &dataset end=last;
MAPE=(MAPE*(_N_-1)+abs(&TARGET_VAR-Result)/&TARGET_VAR)/_N_;
if (last) then put "MAPE=" MAPE;
run;
%mend;

%prepare_data();
/*add your model here instead of simple GLM*/
proc glm data=train_cars plots=all;
class origin type;
model &TARGET_VAR= origin type Invoice Weight Length Wheelbase Cylinders HorsePower EngineSize;
store mmodel;
run;

proc plm source=mmodel plots=all;
score data=test_cars out=test_cars_res pred=Result;
run;

%calc_mape(dataset=test_cars_res);

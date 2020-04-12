proc format;
	picture rub
	low-high='0000000.00RUB';
run;

proc sql;
	create table CarsInfo as
    select distinct Make, Origin, Cylinders as C, count(*) as Quantity, avg(invoice) as AvgInvoice
    from sashelp.cars
    group by Make, C;
quit;

proc fcmp outlib=work.res.res;
	function USDRUB(num);
		return(num * 65);
	endsub;
	
	function RUBUSD(num);
		return(num / 65);
	endsub;
run;
options cmplib=work.res;

data _null_;	
	set work.CarsInfo;
	length quantities $200;
	length avgCosts $200;
	length result $500;
	length helper $100;
	retain quantities;
	retain avgCosts;	
	file '/folders/myfolders/task1/task_1.txt';
	
	by Make;	
	
	helper = cats('C', C, '=', Quantity);
    quantities = catx(" ", quantities, helper);
    
    helper = cats('C',C, '=', put(USDRUB(AvgInvoice), rub.));
    avgCosts = catx(" ", avgCosts, helper);
    
	if last.Make=1 then do;
		length name $200;
		name = cats(Make,'(',Origin,')');
		put name;
		put quantities;
		put avgCosts;
		quantities = '';
		avgCosts = '';
	end;
run;
/*-------------------------------------------------------------------------------------*/

data Result (keep = Origin C CountCN AllMoney);	
	infile '/folders/myfolders/task1/task_1.txt' dlm='09'x end=done;
	length brandCountry $100;
	length cylinds $100;
	length cost $200;
	input  brandCountry $;
	input cylinds $;
	input cost $;
	
	length originKey $20 CNKey $20 valueMoney 8 CNcount 4;
	declare hash total(hashexp:10);	
	total.definekey('originKey', 'CNKey');
	total.definedata('valueMoney', 'CNcount', 'originKey', 'CNKey');
	total.definedone();
	
	originKey = scan(brandCountry, 2, '()');
	i = 1;
	length money_str $100 cn_str $100;
	cn_str = scan(cylinds, i, ' ');
	money_str = scan(cost, i, ' ');
	do while(money_str ne ' ');
		length money $30 k 4;
		CNKey = scan(money_str, 1, '=');
		money = scan(money_str, 2, '=');
		valueMoney = RUBUSD(input(scan(money, 1, 'RUB'), 7.));
		CNcount = input(scan(cn_str, 2, '='), 4.);
		/**/
		valueMoney = CNcount * valueMoney;
		/**/
		total.add();		
		i = i + 1;	
		money_str = scan(cost, i, ' ');
		cn_str = scan(cylinds, i, ' ');
	end;
	
	declare hiter iterator('total');
	flag = iterator.first();
	do while (flag = 0);
		Origin = originKey;
		C = CNKey;
		CountCN = CNcount;
		AllMoney = round(valueMoney, .01);		
		output;
		flag = iterator.next();
	end;
run;

proc sql;
   create table work.total as
   select Origin, C, sum(allmoney) / sum(countcn) as AvgMoney
   from work.result
   group by origin, C
   order by C;
quit;

proc transpose data = work.total out = work.final;
   by C;
   var AvgMoney;
   id Origin;
run;

proc sql;
   ALTER TABLE work.final DROP _NAME_;
quit;


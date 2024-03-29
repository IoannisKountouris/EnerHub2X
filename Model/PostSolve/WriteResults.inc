*Write Results

*Save on GDX and SQL
* Make output folder if it does not exist
$ifi not exist '..\output'
execute 'mkdir ..\output';

$ifi not exist '..\output\Excel'
execute 'mkdir ..\output\Excel';


*--------------------------------------------------------------------------------------------------------------------------------
*Write results without considering paymentes from reservation market and activation.

$ifi not %Operation_Reserve_market% == NO $goto MISS_DAY_AHEAD_market_write_results

* Results
ResultT('Operation',tech,energy ,time)$(carriermix(tech,'export',energy) or carriermix(tech,'import',energy)) = Generation.l(tech,energy,time)-Fueluse.l(tech,energy,time) + EPS;
*ResultT('Maximum fueluse_MW',in(tech,energy),time)=profile(tech,time)*techdata(tech,'Capacity')/techdata(tech,'Fe')*carriermix(tech,'import',energy);
*ResultT('Maximum generation_MW',out(tech,energy),time)=profile(tech,time)*techdata(tech,'Capacity')*carriermix(tech,'export',energy);
ResultT('Volume',out(tech,energy),time)$techdata(tech,'storageCap')=Volume.l(tech,time) + EPS;
* TODO: price from which area?
ResultT('Costs_EUR',tech,energy,time)$(carriermix(tech,'export',energy) or carriermix(tech,'import',energy))=
    + Fueluse.l(tech,energy,time)*sum(area,price(area,energy,'import',time))
    - Generation.l(tech,energy,time)*sum(area,price(area,energy,'export',time))+ EPS;
* Todo: how to devide startup cost?
ResultT('Startcost_EUR',tech,'system_cost',time)=Startcost.l(tech,time)+ EPS;
*ResultT('Startcost_EUR',+ sum((tech),techdata(tech,'FixedOmcost'))
ResultT('Variable_OM_cost_EUR',tech,'system_cost',time) = Fuelusetotal.l(tech,time)*techdata(tech,'VariableOmcost')+ EPS;


ResultF('Flow',flowset(areaOut,areaIn,energy),time)=Flow.l(areaOut,areaIn,energy,time)+ EPS;

ResultA('Buy',area,energy,time)$buyE(area,energy)=Buy.l(area,energy,time)+ EPS;
ResultA('Sale',area,energy,time)$saleE(area,energy)=Sale.l(area,energy,time)+ EPS;
ResultA('Demand',area,energy,time)$demand(area,energy,time)=demand(area,energy,time)+ EPS;
ResultA('Import_price_EUR',area,energy,time)$price(area,energy,'import',time)=price(area,energy,'import',time)+ EPS;
ResultA('Export_price_EUR',area,energy,time)$price(area,energy,'export',time)=price(area,energy,'export',time)+ EPS;
ResultA('Buy_EUR',area,energy,time)$buyE(area,energy)=Buy.l(area,energy,time)*price(area,energy,'import',time)+ EPS;
ResultA('Sale_EUR',area,energy,time)$saleE(area,energy)=Sale.l(area,energy,time)*price(area,energy,'export',time)+ EPS;

ResultTsum(Resultset,tech,energy) = sum(time,ResultT(Resultset,tech,energy,time));
ResultFsum(Resultset,flowset) = sum(time,ResultF(Resultset,flowset,time));
ResultAsum(Resultset,area,energy) = sum(time,ResultA(Resultset,area,energy,time));


ResultC('CapacityFactor',tech,time) = sum(energy$TechToEnergy(tech,energy),Generation.l(tech,energy,time))/itechdata(tech,'Capacity') + EPS ;
ResultCsum('CapacityFactor',tech) = sum((time,energy),Generation.l(tech,energy,time)$TechToEnergy(tech,energy))/(itechdata(tech,'Capacity') * card(time)) +EPS;
ResultCsum('FLH',tech) = ResultCsum('CapacityFactor',tech)* card(time) +EPS;

*Create GDX file
execute_unload '..\model\ResultAll\ResultsAll.gdx';
execute_unload '..\output\%CASEID%_ahead.gdx',
ResultT, ResultF, ResultA,ResultC,ResultCsum
ResultTsum, ResultFsum, ResultAsum,
itechdata;



$label MISS_DAY_AHEAD_market_write_results
*----------------------------------------------------------------------------------------------------------------------------------------------
*


*-------------------------------------------------------------------------------------------------------------------------------------------
*Save results all
$ifi not %Operation_Reserve_market% == YES $goto MISS_Reserve_market_write_results

Parameters
slack11
;

slack11= sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy_Up.l(area,energy,time)$sum(tech$(buyE(area,energy) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP'))));


Display slack11;


*Day ahead
ResultT('DayAhead','Operation',tech,energy,time)$(carriermix(tech,'export',energy) or carriermix(tech,'import',energy))= Generation.l(tech,energy,time)-Fueluse.l(tech,energy,time) + EPS;
ResultT('DayAhead','Volume',out(tech,energy),time)$techdata(tech,'storageCap')=Volume.l(tech,time) + EPS;

ResultT('DayAhead','Costs_EUR',tech,energy,time)$(carriermix(tech,'export',energy) or carriermix(tech,'import',energy))=
    + Fueluse.l(tech,energy,time)*sum(area,price(area,energy,'import',time))
    - Generation.l(tech,energy,time)*sum(area,price(area,energy,'export',time)) + EPS ;

ResultF('DayAhead','Flow',flowset(areaOut,areaIn,energy),time)=Flow.l(areaOut,areaIn,energy,time) + EPS;

ResultA('DayAhead','Buy',area,energy,time)$buyE(area,energy)=Buy.l(area,energy,time)+ EPS;
ResultA('DayAhead','Sale',area,energy,time)$saleE(area,energy)=Sale.l(area,energy,time)+ EPS;
ResultA('DayAhead','Demand',area,energy,time)$demand(area,energy,time)=demand(area,energy,time)+ EPS;
ResultA('DayAhead','Import_price_EUR',area,energy,time)$price(area,energy,'import',time)=price(area,energy,'import',time)+ EPS;
ResultA('DayAhead','Export_price_EUR',area,energy,time)$price(area,energy,'export',time)=price(area,energy,'export',time)+ EPS;
ResultA('DayAhead','Buy_EUR',area,energy,time)$buyE(area,energy)=Buy.l(area,energy,time)*price(area,energy,'import',time)+ EPS;
ResultA('DayAhead','Sale_EUR',area,energy,time)$saleE(area,energy)=Sale.l(area,energy,time)*price(area,energy,'export',time)+ EPS;


ResultTsum('DayAhead',Resultset,tech,energy) = sum(time,ResultT('DayAhead',Resultset,tech,energy,time));
ResultFsum('DayAhead',Resultset,flowset) = sum(time,ResultF('DayAhead',Resultset,flowset,time));
ResultAsum('DayAhead',Resultset,area,energy) = sum(time,ResultA('DayAhead',Resultset,area,energy,time)) ;



*Up Reserve
ResultT('Up','Operation',Reserve(tech),energy,time)$(carriermix(tech,'export',energy) or carriermix(tech,'import',energy))=Generation_Up.l(tech,energy,time)-Fueluse_Up.l(tech,energy,time) + EPS;
*ResultT_all('Up','Volume',out(tech,energy),time)$(techdata(tech,'storageCap') and (techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')))=Volume.l(tech,time);

ResultT('Up','Costs_EUR',Reserve(tech),energy,time)$(carriermix(tech,'export',energy) or carriermix(tech,'import',energy))=
    + Fueluse_Up.l(tech,energy,time)*sum(area,price(area,energy,'import',time))
    - Generation_Up.l(tech,energy,time)*sum(area,price(area,energy,'export',time)) + EPS;

ResultF('Up','Flow',flowset(areaOut,areaIn,energy),time)=Flow_Up.l(areaOut,areaIn,energy,time) + EPS;
ResultA('Up','Buy',area,energy,time)$buyE(area,energy)=Buy_Up.l(area,energy,time) + EPS;
ResultA('Up','Sale',area,energy,time)$saleE(area,energy)=Sale_Up.l(area,energy,time) + EPS;
ResultA('Up','Demand',area,energy,time)$demand(area,energy,time)=demand(area,energy,time) +EPS;
ResultA('Up','Import_price_EUR',area,energy,time)$price(area,energy,'import',time)=price(area,energy,'import',time) + EPS;
ResultA('Up','Export_price_EUR',area,energy,time)$price(area,energy,'export',time)=price(area,energy,'export',time) + EPS;
ResultA('Up','Buy_EUR',area,energy,time)$buyE(area,energy)=Buy_Up.l(area,energy,time)*price(area,energy,'import',time) +EPS;
ResultA('Up','Sale_EUR',area,energy,time)$saleE(area,energy)=Sale_Up.l(area,energy,time)*price(area,energy,'export',time) +EPS;


ResultTsum('Up',Resultset,Reserve(tech),energy) = sum(time,ResultT('Up',Resultset,tech,energy,time));
ResultFsum('Up',Resultset,flowset) = sum(time,ResultF('Up',Resultset,flowset,time));
ResultAsum('Up',Resultset,area,energy) = sum(time,ResultA('Up',Resultset,area,energy,time));


*Down reserve
ResultT('Down','Operation',Reserve(tech),energy,time)$(carriermix(tech,'export',energy) or carriermix(tech,'import',energy))=Generation_Down.l(tech,energy,time)-Fueluse_Down.l(tech,energy,time) + EPS;
*ResultT_all('Down','Volume',out(tech,energy),time)$(techdata(tech,'storageCap') and (techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')))=Volume.l(tech,time);

ResultT('Down','Costs_EUR',Reserve(tech),energy,time)$(carriermix(tech,'export',energy) or carriermix(tech,'import',energy))=
    + Fueluse_Down.l(tech,energy,time)*sum(area,price(area,energy,'import',time))
    - Generation_Down.l(tech,energy,time)*sum(area,price(area,energy,'export',time)) + EPS;

ResultF('Down','Flow',flowset(areaOut,areaIn,energy),time)=Flow_Down.l(areaOut,areaIn,energy,time) + EPS;
ResultA('Down','Buy',area,energy,time)$buyE(area,energy)=Buy_Down.l(area,energy,time) + EPS;
ResultA('Down','Sale',area,energy,time)$saleE(area,energy)=Sale_Down.l(area,energy,time) + EPS;
ResultA('Down','Demand',area,energy,time)$demand(area,energy,time)=demand(area,energy,time) +EPS;
ResultA('Down','Import_price_EUR',area,energy,time)$price(area,energy,'import',time)=price(area,energy,'import',time) + EPS;
ResultA('Down','Export_price_EUR',area,energy,time)$price(area,energy,'export',time)=price(area,energy,'export',time) + EPS;
ResultA('Down','Buy_EUR',area,energy,time)$buyE(area,energy)=Buy_Down.l(area,energy,time)*price(area,energy,'import',time) +EPS;
ResultA('Down','Sale_EUR',area,energy,time)$saleE(area,energy)=Sale_Down.l(area,energy,time)*price(area,energy,'export',time) +EPS;


ResultTsum('Down',Resultset,Reserve(tech),energy) = sum(time,ResultT('Down',Resultset,tech,energy,time));
ResultFsum('Down',Resultset,flowset) = sum(time,ResultF('Down',Resultset,flowset,time));
ResultAsum('Down',Resultset,area,energy) = sum(time,ResultA('Down',Resultset,area,energy,time));



*Save the capacities
*ResultC_all(service,*,tech,time)
*Results for technical aspects
ResultC('DayAhead','Capacity',tech,time)      = sum(energy$TechToEnergy(tech,energy),Generation.l(tech,energy,time)) + EPS;
*ResultC('Up','Capacity',Reserve(tech),time)   = sum(energy$TechToEnergy(tech,energy),Generation_Up.l(tech,energy,time)) + EPS;
*ResultC('Down','Capacity',Reserve(tech),time) = sum(energy$TechToEnergy(tech,energy),Generation_Down.l(tech,energy,time)) + EPS;

*Instead of capacity max based on gen, saves the electricity providing the service.
ResultC('Up','Capacity',Reserve(tech),time)  = + CapacityReserved_Up.l(tech,time)*carriermix(tech,'import','electricity')
                                               + CapacityReserved_Up.l(tech,time)*carriermix(tech,'export','electricity') +EPS;

ResultC('Down','Capacity',Reserve(tech),time)= + CapacityReserved_Down.l(tech,time)*carriermix(tech,'import','electricity')
                                               + CapacityReserved_Down.l(tech,time)*carriermix(tech,'export','electricity') +EPS;


ResultC('DayAhead','CapacityFactor',tech,time) = sum(energy$TechToEnergy(tech,energy),Generation.l(tech,energy,time))/itechdata(tech,'Capacity') + EPS ;
ResultCsum('DayAhead','CapacityFactor',tech) = sum((time,energy),Generation.l(tech,energy,time)$TechToEnergy(tech,energy))/(itechdata(tech,'Capacity') * card(time)) +EPS;
ResultCsum('DayAhead','FLH',tech) = ResultCsum('DayAhead','CapacityFactor',tech) * card(time) +EPS;

ResultC('Up','CapacityFactor',tech,time)$itechdata(tech,'CapacityUP') = sum(energy$TechToEnergy(tech,energy),Generation_UP.l(tech,energy,time))/(itechdata(tech,'Capacity') * itechdata(tech,'CapacityUP')) + EPS ;
ResultCsum('Up','CapacityFactor',tech)$itechdata(tech,'CapacityUP')   = sum((time,energy),Generation_UP.l(tech,energy,time)$TechToEnergy(tech,energy))/(itechdata(tech,'Capacity') * itechdata(tech,'CapacityUP') * card(time)) +EPS;
ResultCsum('Up','FLH',tech)$itechdata(tech,'CapacityUP') = ResultCsum('Up','CapacityFactor',tech) * card(time) +EPS;

ResultC('Down','CapacityFactor',tech,time)$itechdata(tech,'CapacityDown') = sum(energy$TechToEnergy(tech,energy),Generation_Down.l(tech,energy,time))/(itechdata(tech,'Capacity') * itechdata(tech,'CapacityDown')) + EPS ;
ResultCsum('Down','CapacityFactor',tech)$itechdata(tech,'CapacityDown')   = sum((time,energy),Generation_Down.l(tech,energy,time)$TechToEnergy(tech,energy))/(itechdata(tech,'Capacity') * itechdata(tech,'CapacityDown') * card(time)) +EPS;
ResultCsum('Down','FLH',tech)$itechdata(tech,'CapacityDown') = ResultCsum('Down','CapacityFactor',tech) * card(time) +EPS;


*$ontext
*Results economy
ResultEconomi('DayAhead','Total_Profit_EUR') =  - sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy.l(area,energy,time)) + sum((saleE(area,energy),time),price(area,energy,'export',time)*Sale.l(area,energy,time));
ResultEconomi('Up','Total_Profit_EUR')       =  - sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy_up.l(area,energy,time)) + sum((saleE(area,energy),time),price(area,energy,'export',time)*Sale_up.l(area,energy,time));
ResultEconomi('Down','Total_Profit_EUR')     =  + sum((BuyDownSet(area,energy),time),price(area,energy,'import',time)*Buy_Down.l(area,energy,time)) - sum((SellDownSet(area,energy),time),price(area,energy,'export',time)*Sale_Down.l(area,energy,time));



ResultEconomi('DayAhead','CapacityPayment_EUR') = 0;
ResultEconomi('Up','CapacityPayment_EUR')       = + sum((Reserve(tech),time),ReserveCapPrices('Up',time)*CapacityReserved_Up.l(tech,time)*carriermix(tech,'export','electricity'))
                                                  + sum((Reserve(tech),time),ReserveCapPrices('UP',time)*CapacityReserved_Up.l(tech,time)*carriermix(tech,'import','electricity'));

ResultEconomi('Down','CapacityPayment_EUR')     = + sum((Reserve(tech),time),ReserveCapPrices('Down',time)*CapacityReserved_Down.l(tech,time)*carriermix(tech,'export','electricity'))
                                                  + sum((Reserve(tech),time),ReserveCapPrices('Down',time)*CapacityReserved_Down.l(tech,time)*carriermix(tech,'import','electricity'));


#extended saving with the reserve market
execute_unload '..\model\ResultAll\ResultsAll.gdx';
execute_unload '..\output\%CASEID%_ahead_ancillary.gdx',
ResultT, ResultF, ResultA,ResultC,ResultCsum
ResultTsum, ResultFsum, ResultAsum,ResultEconomi
itechdata;

$label MISS_Reserve_market_write_results

*Write results to excel
$ifi not %WriteXLSX% == YES $goto MISS_write_results_XLSX

$IFtheni %Operation_Reserve_market%  == NO
EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead.gdx O=..\output\Excel\%CASEID%_ahead.xlsx  EpsOut=0 filter=1  par=ResultT      cdim=1   rng=ResultT!a1 '     ;
EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead.gdx O=..\output\Excel\%CASEID%_ahead.xlsx  EpsOut=0 filter=1  par=ResultF      cdim=1   rng=ResultF!a1 '     ;
EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead.gdx O=..\output\Excel\%CASEID%_ahead.xlsx  EpsOut=0 filter=1  par=ResultA      cdim=1   rng=ResultA!a1 '     ;
EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead.gdx O=..\output\Excel\%CASEID%_ahead.xlsx  EpsOut=0 filter=1  par=ResultFsum   cdim=1   rng=ResultFsum!a1 '  ;
EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead.gdx O=..\output\Excel\%CASEID%_ahead.xlsx  EpsOut=0 filter=1  par=ResultAsum   cdim=1   rng=ResultAsum!a1 '  ;
EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead.gdx O=..\output\Excel\%CASEID%_ahead.xlsx  EpsOut=0 filter=1  par=itechdata    cdim=1   rng=techdata!a1 '    ;
EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead.gdx O=..\output\Excel\%CASEID%_ahead.xlsx  EpsOut=0 filter=1  par=ResultC      cdim=1   rng=ResultC!a1 '     ;
EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead.gdx O=..\output\Excel\%CASEID%_ahead.xlsx  EpsOut=0 filter=1  par=ResultCsum   cdim=1   rng=ResultCsum!a1 '  ;
$ENDIF

$IFI %Operation_Reserve_market%  == YES EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead_ancillary.gdx O=..\output\Excel\%CASEID%_ahead_ancillary.xlsx  EpsOut=0 filter=1  par=ResultT     cdim=1   rng=ResultT!a1 '     ;
$IFI %Operation_Reserve_market%  == YES EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead_ancillary.gdx O=..\output\Excel\%CASEID%_ahead_ancillary.xlsx  EpsOut=0 filter=1  par=ResultF     cdim=1   rng=ResultF!a1 '     ;
$IFI %Operation_Reserve_market%  == YES EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead_ancillary.gdx O=..\output\Excel\%CASEID%_ahead_ancillary.xlsx  EpsOut=0 filter=1  par=ResultA     cdim=1   rng=ResultA!a1 '     ;
$IFI %Operation_Reserve_market%  == YES EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead_ancillary.gdx O=..\output\Excel\%CASEID%_ahead_ancillary.xlsx  EpsOut=0 filter=1  par=ResultFsum  cdim=1   rng=ResultFsum!a1 '  ;
$IFI %Operation_Reserve_market%  == YES EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead_ancillary.gdx O=..\output\Excel\%CASEID%_ahead_ancillary.xlsx  EpsOut=0 filter=1  par=ResultAsum  cdim=1   rng=ResultAsum!a1 '  ;
$IFI %Operation_Reserve_market%  == YES EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead_ancillary.gdx O=..\output\Excel\%CASEID%_ahead_ancillary.xlsx  EpsOut=0 filter=1  par=itechdata   cdim=1   rng=techdata!a1 '    ;
$IFI %Operation_Reserve_market%  == YES EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead_ancillary.gdx O=..\output\Excel\%CASEID%_ahead_ancillary.xlsx  EpsOut=0 filter=1  par=ResultC     cdim=1   rng=ResultC!a1 '     ;
$IFI %Operation_Reserve_market%  == YES EXECUTE 'gdxxrw.exe ..\output\%CASEID%_ahead_ancillary.gdx O=..\output\Excel\%CASEID%_ahead_ancillary.xlsx  EpsOut=0 filter=1  par=ResultCsum  cdim=1   rng=ResultCsum!a1 '  ;


$label MISS_write_results_XLSX



*Finish Writing results

*-----------------------------------------------------------------------------------------------------------------------------------


$ontext

execute_unload 'ResultsAll.gdx';
execute_unload '..\output\%CASEID%.gdx',
ResultT, ResultF, ResultA,
ResultTsum, ResultFsum, ResultAsum,
techdata;
$ifi %MAKESQL%==yes execute '"C:\GAMS\win64\GreenLabP2X\Balmorel2SQL" ..\output\%CASEID%.gdx %PROJECTID%';

#extended saving with the reserve market
execute_unload '..\output\%CASEID%_all.gdx',
ResultT_all, ResultF_all, ResultA_all,ResultC_all
ResultTsum_all, ResultFsum_all, ResultAsum_all,ResultEconomi_all
techdata;

$ifi %MAKESQL%==yes execute '"C:\GAMS\win64\GreenLabP2X\Balmorel2SQL" ..\output\%CASEID%_all.gdx %PROJECTID%';

$offtext

*-----------------------------------------------------------------------------------------------------------------------------------
*Save on GDX and SQL
* Make output folde if it does not exist

$ontext

$ifi %MAKESQL%==yes execute '"C:\GAMS\win64\GreenLabP2X\Balmorel2SQL" ..\output\%CASEID%.gdx %PROJECTID%';
$ifi %MAKESQL%==yes execute '"C:\GAMS\win64\GreenLabP2X\Balmorel2SQL" ..\output\%CASEID%_all.gdx %PROJECTID%';

* Graphics
File batfile   /'temp.bat'/;
File graphfile /'network.txt'/;

Loop(time,
*$batinclude graphviz.inc time
);

* Error checking

$offtext








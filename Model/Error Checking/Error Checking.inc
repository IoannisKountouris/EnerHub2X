File errorlog /'../Error/errorlog.txt'/;
put errorlog;
Put 'Input data errors:' / / ;

loop((tech,dir,energy)$(carriermix(tech,dir,energy)<0),
    Put 'Carrier should not be negative, change import/export: ',energy.tl,' for ',tech.tl /;
    Errors=Errors+1;
);

loop(tech$(not techdata(tech,'Fe')),
    Put 'Fuel efficientcy must be defined for: ',tech.tl /;
    Errors=Errors+1;
);

loop(tech$techdata(tech,'StorageCap'),
    if(sum(energy$out(tech,energy),1)>1,
        Put 'Storage can only have one energy output: ',tech.tl /;
        Errors=Errors+1;
    );
);

Loop(tech$(smax(time,profile(tech,time))>1),
    Put 'Profile should at maximum be 100%: ',tech.tl /;
    Errors=Errors+1;
);

* Test for efficientcy curve
loop(tech$sum(step,curve(tech,step)),

    if(techdata(tech,'storageCap'),
        Put 'Storages can not have an efficientcy curve: ', tech.tl /;
        Errors=Errors+1;
    );

    if(smax(step,efficientcyCurve(tech,'export',step)) <> techdata(tech,'Capacity'),
        Put 'Last point on efficientcy curve must match capacity: ', tech.tl /;
        Errors=Errors+1;
    );

    if(sum(step$(ord(step)=smax(step1$curve(tech,step1),ord(step1))),efficientcyCurve(tech,'export',step)/efficientcyCurve(tech,'import',step)) <> techdata(tech,'Fe'),
        Put 'Last point on efficientcy curve must match total efficientcy: ', tech.tl /;
        Errors=Errors+1;
    );

    loop((dir,step)$(efficientcyCurve(tech,dir,step)>efficientcyCurve(tech,dir,step+1) and efficientcyCurve(tech,dir,step+1)),
        Put 'Point on efficientcy curve must be increasing: ', tech.tl,',',dir.tl /;
        Errors=Errors+1;
    );

* First point may be {0,0}
    loop(step$(ord(step)>1 and sum(dir,efficientcyCurve(tech,dir,step))=1),
        Put 'Both point on efficientcy curve must be defined: ', tech.tl,',',step.tl /;
        Errors=Errors+1;
    );
);

* Todo: Check import price lower than export price
* Circles of fun?

* Check flows possible/relevant

* Todo    flowset(area,area,energy)
Loop((area,out(tech,energy))$(location(area,tech)                               # Located in this area
  and not saleE(area,energy)                                                    # But no sale
  and not sum(tech1,in(tech1,energy))                                           # No tech use
  and not sum(areaIn,flowset(area,areaIn,energy))),                             # No out flow
    Put 'Technology missing energy outlet of ', area.tl,', ',tech.tl,', ',energy.tl /;
    Errors=Errors+1;
);
Loop((area,in(tech,energy))$(location(area,tech)                                # Located in this area
  and not buyE(area,energy)                                                     # But no retailer
  and not sum(tech1,out(tech1,energy))                                          # No tech produser
  and not sum(areaOut,flowset(areaOut,area,energy))),                           # No in flow
    Put 'Technology missing energy source of ', area.tl,', ',tech.tl,',',energy.tl /;
    Errors=Errors+1;
);
Loop(buyE(area,energy)$(not sum(tech$location(area,tech),in(tech,energy)) and not sum(areaIn,flowset(area,areaIn,energy))),
    Put 'Buying not relevant in this area of ', area.tl,',',energy.tl /;
    Errors=Errors+1;
);
Loop(saleE(area,energy)$(not sum(tech$location(area,tech),out(tech,energy)) and not sum(areaOut,flowset(areaOut,area,energy))),
    Put 'Sale not possible in this area of ', area.tl,',',energy.tl /;
    Errors=Errors+1;
);





if(Errors,
    Put /;
    Put Errors:0:0 ' input errors!';
else
    Put 'Not input errors.';
);


*----------------------------------------------------------------------------------------------------------------------------------------------
*END
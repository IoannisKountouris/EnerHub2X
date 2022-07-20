* GHH model
* Developed by Ea Energy Analysis
*Ioannis Kountouris

* Notes IK:
* - Adapt the ramp rates for the technologies given reservation capacities
* - Add eeficiency curves? 
* - check what is the probability of activation currently is 0.3 of the capacity reserved

* ------------------------------------------------------------------------------
* Options

* Sets # as comment sign
$EOLCOM #

* Limit on printing in lst-file of equations and variables for debuging
option limrow=10000;
option limcol=10000;

*relative gap in case of MIP the compute time is heavily increased do not use that if running a whole year
option optcr=0.001, reslim=1200;

*Set number of decimals to print out
*Option DECIMALS=3;

* Run options
$setglobal MAKESQL     YES                       # Save run in database [yes/no]
$setglobal PROJECTID   GHH                       # Name of project in database
$setglobal CASEID      IK_Reserve_try          # Name of case in database

* ------------------------------------------------------------------------------

* Definitions of sets
Sets
    resultset   'Elements for result printing'
    area        'Areas for grouping of technologies into demand and price areas'
    tech        'Technologies'
    dir         'Direction of flow [import/export]'
    energy      'Types of energy'
    step        'Steps in efficientcy curve'
    color       'Color of energies for plot'
    time        'Time steps'
    scenario    'Name of scenarios'
    Service     'can be day ahead up, down'
    dataset
    location(area,tech)
    flowset(area,area,energy)
    out(tech,energy)
    in(tech,energy)
    buyE(area,energy)
    saleE(area,energy)
    ecolor(energy,color)
    curve(tech,step)
    UC(tech)    'Unit commitment'
    resultset
    pricingType
    units       'Different fysical units forms'
    LinesInterconnectors(area)
    Reserve(tech)
;
alias(area,areaIn,AreaOut);
alias(tech,tech1);
alias(step,step1);
alias(time,time1);
alias(energy,energy1);

Parameters
    profile(tech,time)
    techdata(tech,dataset)
    carriermix(tech,dir,energy)
    demand(area,energy,time)
    price(area,energy,dir,time)
    pricing(tech,energy,pricingType)
    efficientcyCurve(tech,dir,step)
    standardUnit(energy,units)       'Which units are relevant for this energy. Standard form must be one'
    InterconnectorCapacity(area,energy,time)
*Reserve market parameters
    ActivationProbability
    ReserveCapPrices(Service,time)
* Results
    ResultT(resultset,tech,energy,time)
    ResultF(resultset,area,area,energy,time)
    ResultA(resultset,area,energy,time)
    ResultTsum(resultset,tech,energy)
    ResultFsum(resultset,area,area,energy)
    ResultAsum(resultset,area,energy)
;

Scalar
    Errors  /0/
    penalty /100000/
;

*Manual Parameters
ActivationProbability = 0.3;


* ------------------------------------------------------------------------------
* Load data
$batinclude loadGDX.inc resultset
$batinclude loadGDX.inc area
$batinclude loadGDX.inc tech
$batinclude loadGDX.inc dir
$batinclude loadGDX.inc step
$batinclude loadGDX.inc energy
$batinclude loadGDX.inc color
$batinclude loadGDX.inc time
$batinclude loadGDX.inc scenario
$batinclude loadGDX.inc dataset
$batinclude loadGDX.inc location
$batinclude loadGDX.inc flowset
$batinclude loadGDX.inc ecolor
$batinclude loadGDX.inc pricingType


$batinclude loadGDX.inc profile
$batinclude loadGDX.inc techdata
$batinclude loadGDX.inc carriermix
$batinclude loadGDX.inc demand
$batinclude loadGDX.inc price
$batinclude loadGDX.inc efficientcyCurve
$batinclude loadGDX.inc InterconnectorCapacity

*Reserve market addon
$batinclude loadGDX.inc Service
$batinclude loadGDX.inc ReserveCapPrices


* test todo remove
efficientcyCurve(tech,dir,step)=0;


*--------------------------------------------------------------------------------
*test parameters
*price('DK1-reserve','Electricity','import',time) = 80;
*ReserveCapPrices('Up',time)=3000;

* ------------------------------------------------------------------------------
* Assigning sets

* Input and output energy types of technologies
in(tech,energy)$carriermix(tech,'import',energy)=yes;
out(tech,energy)$carriermix(tech,'export',energy)=yes;

* Fuel efficientcy
techdata(tech,'Fe')=sum(energy,carriermix(tech,'export',energy))/sum(energy,carriermix(tech,'import',energy));
carriermix(tech,'export',energy)=carriermix(tech,'export',energy)/sum(energy1,carriermix(tech,'export',energy1));
carriermix(tech,'import',energy)=carriermix(tech,'import',energy)/sum(energy1,carriermix(tech,'import',energy1));

buyE(area,energy)$sum(time,price(area,energy,'import',time))=yes;
saleE(area,energy)$(sum(time,price(area,energy,'export',time)) or sum(time,demand(area,energy,time)) )=yes;

* Unit commitment
UC(tech)$techdata(tech,'Minimum')=yes;

*Technologies that provide reserves
Reserve(tech)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown'))=yes;

* Test for efficientcy curve (first step can be {0,0})
curve(tech,step)$sum(dir,efficientcyCurve(tech,dir,step))=yes;
curve(tech,'step1')$sum(step,curve(tech,step))=yes;

*Lines of interconnectors and areas
LinesInterconnectors(area)$sum((energy,time),InterconnectorCapacity(area,energy,time))=YES;


Display saleE,buyE,LinesInterconnectors,ReserveCapPrices,Reserve;


Parameter
Slack(area,energy)
;

slack(area,energy)=sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP')));

Display Slack;
*$exit


* ------------------------------------------------------------------------------
* Error checking

File errorlog /'errorlog.txt'/;
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


* ------------------------------------------------------------------------------


Variables
    Cost
;

Positive Variables
    Fueluse(tech,energy,time)
    Fuelusetotal(tech,time)
    Generation(tech,energy,time)
    Volume(tech,time)
    Flow(area,area,energy,time)
    Buy(area,energy,time)
    Sale(area,energy,time)
    Startcost(tech,time)
    Ramping(tech,time)
    Profit(tech,energy,time)
* Strafvariable
    SlackDemand(area,energy,time,dir)

*Variables Reserve
    Fuelusetotal_Up(tech,time)
    Fuelusetotal_Down(tech,time)
    CapacityReserved_Up(tech,time)
    CapacityReserved_Down(tech,time)
    Generation_Up(tech,energy,time)
    Generation_Down(tech,energy,time)
    Fueluse_Up(tech,energy,time)
    Fueluse_Down(tech,energy,time)
    Buy_Up(area,energy,time)
    Buy_Down(area,energy,time)
    Sale_Up(area,energy,time)
    Sale_Down(area,energy,time)
    Flow_Up(area,area,energy,time)
    Flow_Down(area,area,energy,time)

;

Binary Variables
    Online(tech,time)
*charge - discharge storages
    Charge(tech,time)
    Discharge(tech,time)
*Participation in up/down
    UpCap(tech,time)
    DownCap(tech,time)
;

SOS2 Variables
    Load(tech,step,time)
;

Equations
    Objective
    Fuelmix(tech,energy,time)           'Total fuel use consis of a fuel mix'
* Different forms of production
    Production(tech,energy,time)        'Linear production curve (not storage)'
    ProductionStorage(tech,time)        'Production with storage option'
    ProductionCurve(tech,energy,time)   'Production curve with special order set'
    FuelCurve(tech,energy,time)         'Total fuel use curve with special order set'
* Technical limits
    Balance(area,energy,time)
    ChargingStorageMax(tech,time)
    ChargingStorageMin(tech,time)
    DisChargingStorageMax(tech,time)
    DisChargingStorageMin(tech,time)
    StatusStorageOp(tech,time)
    RampUp(tech,time)
    RampDown(tech,time)
    Capacity(tech,time)
    Minimumload(tech,time)
    Startupcost(tech,time)
    MaxBuy(energy,time)
    MaxSale(energy,time)
    FuelusetotalLimProfiles(tech,time)
    FuelusetotalLim(tech,time)
*Reserve market formulation
    FuelmixUp(tech,energy,time)
    ProductionUp(tech,energy,time)
    FuelmixDown(tech,energy,time)
    ProductionDown(tech,energy,time)
    ReatTimeUpDeploymentUp(tech,time)
    ReatTimeUpDeploymentDown(tech,time)
    CapReservedUpMax(tech,time)
    CapReservedDownMax(tech,time)
    ComplementarityUpDownReservedCapacities(tech,time)
    FuelusetotalDayAheadMax(tech,time)
    FuelusetotalDayAheadMin(tech,time)
    BalanceUp(area,energy,time)
    BalanceDown(area,energy,time)
    MaxBuyUp(area,energy,time)
    MaxBuyDown(area,energy,time)
    MaxSaleUp(area,energy,time)
    MaxSaleDown(area,energy,time)
* Demand
    eqFLH(tech)
    DemandTime(area,energy,time)
* Pricing
;

Objective ..
    Cost =E=
* Fuelcost
    sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy(area,energy,time))

  + sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy_Up(area,energy,time)$sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP'))))

  - sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy_Down(area,energy,time)$sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityDown'))))

* Sales
  - sum((saleE(area,energy),time),price(area,energy,'export',time)*Sale(area,energy,time))

  - sum((saleE(area,energy),time),price(area,energy,'export',time)*Sale_Up(area,energy,time)$sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP'))))

  + sum((saleE(area,energy),time),price(area,energy,'export',time)*Sale_Down(area,energy,time)$sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityDown'))))
* O&M
*  + sum((tech),techdata(tech,'FixedOmcost'))
  + sum((tech,time),Fuelusetotal(tech,time)*techdata(tech,'VariableOmcost'))
* Startup cost
  + sum((tech,time),Startcost(tech,time))
* Regulating cost
*  + sum((tech,time),Ramping(tech,time)*techdata(tech,'RegulatingCost'))
* Penalty for infeasable solution
  + penalty*sum((area,energy,time,dir),SlackDemand(area,energy,time,dir))
*Profit from reserving capacities
  - sum((tech,time),ReserveCapPrices('Up',time)*CapacityReserved_Up(tech,time)$techdata(tech,'CapacityUP'))
  - sum((tech,time),ReserveCapPrices('Down',time)*CapacityReserved_Down(tech,time)$techdata(tech,'CapacityDown'))
;

Fuelmix(in(tech,energy),time)$(techdata(tech,'Capacity'))..
    carriermix(tech,'import',energy)*Fuelusetotal(tech,time)
    =E=
    Fueluse(tech,energy,time)
;

Production(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
*    and sum(step,curve(tech,step))
) ..
    carriermix(tech,'export',energy)*Fuelusetotal(tech,time)*techdata(tech,'Fe')
    =E=
    Generation(tech,energy,time)
;
*$ontext
ProductionCurve(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
    and sum(step,curve(tech,step)) ) ..
    carriermix(tech,'export',energy)*techdata(tech,'Fe')*
    sum(step,Load(tech,step,time)*efficientcyCurve(tech,'export',step))
    =E=
    Generation(tech,energy,time)
;
*$offtext

FuelCurve(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
    and sum(step,curve(tech,step)) ) ..
    sum(step,Load(tech,step,time)*efficientcyCurve(tech,'import',step))
    =E=
    Fuelusetotal(tech,time)
;

*-------------------------------------------------------------------------------------------------------------------------


FuelmixUp(in(tech,energy),time)$(techdata(tech,'Capacity') and (techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) )..
    carriermix(tech,'import',energy)*Fuelusetotal_Up(tech,time)
    =E=
    Fueluse_Up(tech,energy,time)
;

ProductionUp(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap') and (techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown'))
*    and sum(step,curve(tech,step))
) ..
    carriermix(tech,'export',energy)*Fuelusetotal_Up(tech,time)*techdata(tech,'Fe')
    =E=
    Generation_Up(tech,energy,time)
;

FuelmixDown(in(tech,energy),time)$(techdata(tech,'Capacity') and (techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')))..
    carriermix(tech,'import',energy)*Fuelusetotal_Down(tech,time)
    =E=
    Fueluse_Down(tech,energy,time)
;

ProductionDown(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap') and (techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown'))
*    and sum(step,curve(tech,step))
) ..
    carriermix(tech,'export',energy)*Fuelusetotal_Down(tech,time)*techdata(tech,'Fe')
    =E=
    Generation_Down(tech,energy,time)
;

*Activation Up
ReatTimeUpDeploymentUp(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    Fuelusetotal_Up(tech,time)
    =E=
    ActivationProbability * CapacityReserved_Up(tech,time)
;

*Activation Down
ReatTimeUpDeploymentDown(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    Fuelusetotal_Down(tech,time)
    =E=
    ActivationProbability * CapacityReserved_Down(tech,time)
;

*Limits on capacity able to be reserved
CapReservedUpMax(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    CapacityReserved_Up(tech,time)
    =L=
    techdata(tech,'CapacityUp')*UpCap(tech,time)*profile(tech,time)/techdata(tech,'Fe')
;


CapReservedDownMax(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    CapacityReserved_Down(tech,time)
    =L=
    techdata(tech,'CapacityUp')*DownCap(tech,time)*profile(tech,time)*profile(tech,time)/techdata(tech,'Fe')
;

*Can not be reserved both for up and down
ComplementarityUpDownReservedCapacities(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    UpCap(tech,time) + DownCap(tech,time)
    =L=
    1
;

*Limit max on day ahead Fuelusetototal due to reservations
FuelusetotalDayAheadMax(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    Fuelusetotal(tech,time)
    =L=
    techdata(tech,'Capacity')*profile(tech,time)/techdata(tech,'Fe') - CapacityReserved_Up(tech,time)
;


*Limit min on day ahead Fuelusetototal due to reservations
FuelusetotalDayAheadMin(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    Fuelusetotal(tech,time)
    =G=
    CapacityReserved_Down(tech,time)
;



$ontext
ProductionStorage(tech,time)$(techdata(tech,'storageCap')) ..                               #They do not provide the same results
   Volume(tech,time)
    =E=
  techdata(tech,'InitialVolume')$(ord(time)=1)+ Volume(tech,time--1)$(ord(time)>1)
  + Fuelusetotal(tech,time)*techdata(tech,'Fe') - sum(energy$out(tech,energy),Generation(tech,energy,time)*carriermix(tech,'export',energy))
;
$offtext


*Take into account the balancing flows for storage plus up and down 
ProductionStorage(tech,time)$(techdata(tech,'storageCap')) ..
   Volume(tech,time)
    =E=
  techdata(tech,'InitialVolume')$(ord(time)=1)+ Volume(tech,time--1)$(ord(time)>1)

  + Fuelusetotal(tech,time)*techdata(tech,'Fe')

  + (Fuelusetotal_Up(tech,time)$Reserve(tech))*techdata(tech,'Fe')

  - (Fuelusetotal_Down(tech,time)$Reserve(tech))*techdata(tech,'Fe')

  - sum(energy$out(tech,energy),(Generation(tech,energy,time)$Reserve(tech))*carriermix(tech,'export',energy))

  - sum(energy$out(tech,energy),(Generation_UP(tech,energy,time)$Reserve(tech))*carriermix(tech,'export',energy))

  + sum(energy$out(tech,energy),(Generation_Down(tech,energy,time)$Reserve(tech))*carriermix(tech,'export',energy))
;


*Storage can not charge and discharge the same time
* Limit on charging Max Storage
ChargingStorageMax(tech,time)$(techdata(tech,'storageCap')) ..
    Fuelusetotal(tech,time)*techdata(tech,'Fe')
    =L=
    techdata(tech,'Capacity')*Charge(tech,time)
;

* Limit on charging Min Storage
ChargingStorageMin(tech,time)$(techdata(tech,'storageCap') and techdata(tech,'minimum')) ..
    techdata(tech,'minimum')*Charge(tech,time)
    =L=
    Fuelusetotal(tech,time)*techdata(tech,'Fe')
;

* Limit on discharging Max Storage
DisChargingStorageMax(tech,time)$(techdata(tech,'storageCap')) ..
    sum(energy$out(tech,energy),Generation(tech,energy,time)*carriermix(tech,'export',energy))
    =L=
    techdata(tech,'Capacity')*Discharge(tech,time)
;

* Limit on discharging Min Storage
DisChargingStorageMin(tech,time)$(techdata(tech,'storageCap') and techdata(tech,'minimum')) ..
    techdata(tech,'minimum')*Discharge(tech,time)
    =L=
    sum(energy$out(tech,energy),Generation(tech,energy,time)*carriermix(tech,'export',energy))
;

*Can not charge - discharge at the same time
StatusStorageOp(tech,time)$(techdata(tech,'storageCap')) ..
    Charge(tech,time) + Discharge(tech,time)
    =L=
    1
;


* Must have capacity or oppertunity to buy or sell
BalanceDown(area,energy,time)$(buyE(area,energy) or saleE(area,energy)
or sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),techdata(tech,'Capacity'))
)..

  + Buy_Down(area,energy,time)$buyE(area,energy)
  + Sum(areaIn$flowset(areaIn,area,energy),Flow_Down(areaIn,area,energy,time))
  + sum(tech$(location(area,tech) and out(tech,energy)),Generation_Down(tech,energy,time))
    =E=
  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse_Down(tech,energy,time))
  + Sale_down(area,energy,time)$saleE(area,energy)
  + Sum(areaOut$flowset(area,areaOut,energy),Flow_Down(area,areaOut,energy,time))

;

* Must have capacity or oppertunity to buy or sell
BalanceUP(area,energy,time)$((buyE(area,energy) or saleE(area,energy))
or sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),techdata(tech,'Capacity'))
)..

  + Buy_Up(area,energy,time)$buyE(area,energy)
  + Sum(areaIn$flowset(areaIn,area,energy),Flow_UP(areaIn,area,energy,time))
  + sum(tech$(location(area,tech) and out(tech,energy)),Generation_Up(tech,energy,time))
    =E=
  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse_Up(tech,energy,time))
  + Sale_Up(area,energy,time)$saleE(area,energy)
  + Sum(areaOut$flowset(area,areaOut,energy),Flow_UP(area,areaOut,energy,time))

;



* Must have capacity or oppertunity to buy or sell
Balance(area,energy,time)$((buyE(area,energy) or saleE(area,energy))
or sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),techdata(tech,'Capacity'))
)..
    Buy(area,energy,time)$buyE(area,energy)
  + Sum(areaIn$flowset(areaIn,area,energy),Flow(areaIn,area,energy,time))
  + sum(tech$(location(area,tech) and out(tech,energy)),Generation(tech,energy,time))
    =E=
  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse(tech,energy,time))
  + Sale(area,energy,time)$saleE(area,energy)
  + Sum(areaOut$flowset(area,areaOut,energy),Flow(area,areaOut,energy,time))

;


$ontext
* Must have capacity or oppertunity to buy or sell
Balance(area,energy,time)$((buyE(area,energy) or saleE(area,energy))
or sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),techdata(tech,'Capacity'))
)..
  + Buy(area,energy,time)$buyE(area,energy)

  + Buy_Up(area,energy,time)$(buyE(area,energy) and sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP'))))

  - Buy_Down(area,energy,time)$(buyE(area,energy) and sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP'))))

  + Sum(areaIn$flowset(areaIn,area,energy),Flow(areaIn,area,energy,time))

  + Sum(areaIn$flowset(areaIn,area,energy),Flow_up(areaIn,area,energy,time))

  - Sum(areaIn$flowset(areaIn,area,energy),Flow_Down(areaIn,area,energy,time))

  + sum(tech$(location(area,tech) and out(tech,energy)),Generation(tech,energy,time))

  + sum(tech$(location(area,tech) and out(tech,energy)),Generation_UP(tech,energy,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')))

  - sum(tech$(location(area,tech) and out(tech,energy)),Generation_Down(tech,energy,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')))

    =E=

  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse(tech,energy,time))

  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse_Up(tech,energy,time))

  - sum(tech$(location(area,tech) and in(tech,energy)),Fueluse_Down(tech,energy,time))

  + Sale(area,energy,time)$saleE(area,energy)

  + Sum(areaOut$flowset(area,areaOut,energy),Flow(area,areaOut,energy,time))

;
$offtext



DemandTime(area,energy,time)$sum(time1,demand(area,energy,time1)) ..
    Sale(area,energy,time) + SlackDemand(area,energy,time,'import') - SlackDemand(area,energy,time,'export')
    =G=
    demand(area,energy,time)
;

*Max Buy or sale regarding capacity of pipes or interconnector
MaxBuy(energy,time)$(sum(area,InterconnectorCapacity(area,energy,time))) ..
    sum(area,Buy(area,energy,time)$buyE(area,energy))
   + sum(area,Buy_Up(area,energy,time)$(buyE(area,energy) and sum(tech,techdata(tech,'CapacityUP'))))
   - sum(area,Buy_Down(area,energy,time)$(buyE(area,energy) and sum(tech,techdata(tech,'CapacityDown'))))
    =L=
    sum(area,InterconnectorCapacity(area,energy,time))/card(LinesInterconnectors)
;

MaxSale(energy,time)$(sum(area,InterconnectorCapacity(area,energy,time))) ..
    sum(area,Sale(area,energy,time)$buyE(area,energy))
  + sum(area,Sale_Up(area,energy,time)$(buyE(area,energy) and sum(tech,techdata(tech,'CapacityUP'))))
  - sum(area,Sale_down(area,energy,time)$(buyE(area,energy) and sum(tech,techdata(tech,'CapacityDown'))))
    =L=
    sum(area,InterconnectorCapacity(area,energy,time))/card(LinesInterconnectors)
;


MaxBuyUp(area,energy,time)$(buyE(area,energy) and sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP'))))..
   Buy_Up(area,energy,time)
   =L=
   sum(tech,Fueluse_Up(tech,energy,time))
;

MaxBuyDown(area,energy,time)$(buyE(area,energy) and sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityDown'))))..
   Buy_Down(area,energy,time)
   =L=
   sum(tech,Fueluse_Down(tech,energy,time))
;

MaxSaleUp(area,energy,time)$(buyE(area,energy) and sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP'))))..
   Buy_Up(area,energy,time)
   =L=
   sum(tech,Generation_Up(tech,energy,time))
;

MaxSaleDown(area,energy,time)$(buyE(area,energy) and sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityDown'))))..
   Buy_Up(area,energy,time)
   =L=
   sum(tech,Generation_Down(tech,energy,time))
;



RampUp(tech,time)$techdata(tech,'ramprate') ..
    techdata(tech,'ramprate')$(not UC(tech))
  + (techdata(tech,'ramprate')*Online(tech,time--1) + techdata(tech,'Minimum')*(1-Online(tech,time--1)))$UC(tech)
    =G=
    sum(energy$out(tech,energy), Generation(tech,energy,time)-Generation(tech,energy,time--1))
;

RampDown(tech,time)$techdata(tech,'ramprate') ..
    techdata(tech,'ramprate')$(not UC(tech))
  + (techdata(tech,'ramprate')*Online(tech,time) + techdata(tech,'Minimum')*(1-Online(tech,time)))$UC(tech)             #devide by  techdata(tech,'Minimum')/techdata(tech,'Fe')?
    =G=
    sum(energy$out(tech,energy), Generation(tech,energy,time--1)-Generation(tech,energy,time))
;

* Capacity defined as constraint if binary needed
Capacity(UC(tech),time) ..
    (techdata(tech,'Capacity')/techdata(tech,'Fe'))*Online(tech,time)
    =G=
    Fuelusetotal(tech,time)
;

Minimumload(UC(tech),time)$techdata(tech,'minimum') ..
    Fuelusetotal(tech,time)
    =G=
    (techdata(tech,'Minimum')/techdata(tech,'Fe'))*Online(tech,time)
;

Startupcost(UC(tech),time)$techdata(tech,'Startupcost') ..
    Startcost(tech,time)
    =G=
    techdata(tech,'Startupcost')*(Online(tech,time)-Online(tech,time--1))
;


FuelusetotalLimProfiles(tech,time)$sum(time1,profile(tech,time1) and not (techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')))..
    Fuelusetotal(tech,time)$sum(time1,profile(tech,time1))
    =L=
    techdata(tech,'Capacity')*profile(tech,time)/techdata(tech,'Fe')
;

FuelusetotalLim(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    Fuelusetotal(tech,time) =L=
    techdata(tech,'Capacity')/techdata(tech,'Fe')
;


* Pricing
*FixPrice(tech,energy,time) ..
*    Profit(tech,energy,time)


* Capacity
*Fuelusetotal.up(tech,time)=techdata(tech,'Capacity')/techdata(tech,'Fe');
*Fuelusetotal.up(tech,time)$sum(time1,profile(tech,time1))=techdata(tech,'Capacity')*profile(tech,time)/techdata(tech,'Fe');


* Storage volume
Volume.up(tech,time)=techdata(tech,'StorageCap');
Volume.fx(tech,time)$(techdata(tech,'StorageCap') and ord(time)=card(time)) = techdata(tech,'InitialVolume');


* Test
*Fuelusetotal.lo('Battery',time)$(ord(time)=1)=2;
*sale.fx('DK1','Methanol',time)=0;
*sale.fx('DK1','Biometan',time)=0;
*Flow.fx('Skive','DK1','Hydrogen',time)=5;
*Generation.fx('Electrolysis','Hydrogen',time)=5;
*Fuelusetotal.fx('Electrolysis',time)=5/0.8684/.76;
*Generation('Skive','DK1','Hydrogen',time)=18;
*Generation.fx('Komprimering','HydrogenCom','Hour-1 01/01/19 00:00')=3;
*Fuelusetotal.fx('Komprimering','Hour-1 01/01/19 00:00')=3/1.0219155093422;




* ------------------------------------------------------------------------------
* Model and solve

Model P2Xmodel /
    Objective
    Fuelmix
*    FuelCurve
*    ProductionCurve
    Production
    ProductionStorage
    ChargingStorageMax
    ChargingStorageMin
    DisChargingStorageMax
    DisChargingStorageMin
    StatusStorageOp
    Balance
    MaxBuy
    MaxSale
    RampUp
    RampDown
    Capacity
    Minimumload
    Startupcost
    DemandTime
    FuelusetotalLimProfiles
    FuelusetotalLim
*Reserve market Equations
    FuelmixUp
    ProductionUp
    FuelmixDown
    ProductionDown
    ReatTimeUpDeploymentUp
    ReatTimeUpDeploymentDown
    CapReservedUpMax
    CapReservedDownMax
    ComplementarityUpDownReservedCapacities
    FuelusetotalDayAheadMax
    FuelusetotalDayAheadMin
    BalanceUp
    BalanceDown
*    MaxBuyUp
*    MaxBuyDown
*    MaxSaleUp
*    MaxSaleDown
/;

Solve P2Xmodel minimizing cost using mip;

Display Fueluse.l, Fuelusetotal.l, generation.l, volume.l,buy.l,sale.l,SlackDemand.l,online.l,flow.l,Balance.m,charge.l,
discharge.l,Startcost.l,CapacityReserved_Up.l,CapacityReserved_Down.l,UpCap.l,DownCap.l,Buy_Up.l,Buy_Down.l,Sale_Up.l,Sale_Down.l,Fuelusetotal_Up.l,Fuelusetotal_Down.l
Fueluse_Up.l,generation_Up.l,Fueluse_Down.l,generation_Down.l,Flow_Down.l,Flow_UP.l;
*Fuelusetotal_Up.l,Fuelusetotal_Down.l;

* Results
ResultT('Operation (MW)',tech,energy ,time)=Generation.l(tech,energy,time)-Fueluse.l(tech,energy,time);
*ResultT('Maximum fueluse (MW)',in(tech,energy),time)=profile(tech,time)*techdata(tech,'Capacity')/techdata(tech,'Fe')*carriermix(tech,'import',energy);
*ResultT('Maximum generation (MW)',out(tech,energy),time)=profile(tech,time)*techdata(tech,'Capacity')*carriermix(tech,'export',energy);
ResultT('Volume (MWh)',out(tech,energy),time)=Volume.l(tech,time);
* TODO: price from which area?
ResultT('Costs (kr)',tech,energy,time)=
    + Fueluse.l(tech,energy,time)*sum(area,price(area,energy,'import',time))
    - Generation.l(tech,energy,time)*sum(area,price(area,energy,'export',time));
* Todo: how to devide startup cost?
ResultT('Startcost (kr)',tech,'System',time)=Startcost.l(tech,time);
*ResultT('Startcost (kr)',+ sum((tech),techdata(tech,'FixedOmcost'))
ResultT('Variable O&M cost (kr)',tech,'System',time) = Fuelusetotal.l(tech,time)*techdata(tech,'VariableOmcost');


ResultF('Flow (MW)',flowset(areaOut,areaIn,energy),time)=Flow.l(areaOut,areaIn,energy,time);

ResultA('Buy (MW)',area,energy,time)=Buy.l(area,energy,time);
ResultA('Sale (MW)',area,energy,time)=Sale.l(area,energy,time);
ResultA('Demand (kr)',area,energy,time)=demand(area,energy,time);
ResultA('Import price (kr)',area,energy,time)=price(area,energy,'import',time);
ResultA('Export price (kr)',area,energy,time)=price(area,energy,'export',time);
ResultA('Buy (kr)',area,energy,time)=Buy.l(area,energy,time)*price(area,energy,'import',time);
ResultA('Sale (kr)',area,energy,time)=Sale.l(area,energy,time)*price(area,energy,'export',time);

ResultTsum(Resultset,tech,energy) = sum(time,ResultT(Resultset,tech,energy,time));
ResultFsum(Resultset,flowset) = sum(time,ResultF(Resultset,flowset,time));
ResultAsum(Resultset,area,energy) = sum(time,ResultA(Resultset,area,energy,time));
ResultTsum('Fixed O&M cost (kr)',tech,'System') = 1000000*techdata(tech,'FixedOmcost')*techdata(tech,'Capacity');
ResultTsum('Investment cost (kr)',tech,'System') = 1000000*techdata(tech,'InvestmentCost')*techdata(tech,'Capacity');


* Make output folde if it does not exist
$ifi not exist '..\output'
execute 'mkdir ..\output'



execute_unload 'ResultsAll.gdx';
execute_unload '..\output\%CASEID%.gdx',
ResultT, ResultF, ResultA,
ResultTsum, ResultFsum, ResultAsum,
techdata;
$ifi %MAKESQL%==yes execute '"C:\GAMS\win64\GreenLabP2X\Balmorel2SQL" ..\output\%CASEID%.gdx %PROJECTID%';

* ------------------------------------------------------------------------------
* Model and solve




* Graphics
File batfile   /'temp.bat'/;
File graphfile /'network.txt'/;

Loop(time,
*$batinclude graphviz.inc time
);

* Error checking

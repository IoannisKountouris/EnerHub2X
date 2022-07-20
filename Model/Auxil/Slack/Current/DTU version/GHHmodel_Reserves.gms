* GHH model
* Developed by Ea Energy Analysis and DTU management
*Ioannis Kountouris

* Notes IK 18/10/2021:
* - Adapt the ramp rates for the technologies given reservation capacities
* - Add eeficiency curves?
* - check what is the probability of activation currently is 0.3 of the capacity reserved
* - Do the capacities reserved need to be devided by FE?
* - Capacity paymenet should be related with electricity fueluse or generation
* - efficient curves on activation and regulation

*Open questions
*- Can the virtual power plant provides up and down real time activation in the same hour?. Optim in 1 hour intervals while 15mins resolution may needed.

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
$setglobal MAKESQL     YES                                 # Save run in database [yes/no]
$setglobal PROJECTID   GHH                                 # Name of project in database
$setglobal CASEID      IK_Reserve_24h_validate_IK          # Name of case in database

* Options for operation details
$setglobal Operation_Reserve_market             YES
$setglobal Operation_Efficiency_curves          NO
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
    profile(time,tech)
    techdata(tech,dataset)
    carriermix(tech,dir,energy)
    demand(time,area,energy)
    price(time,area,energy,dir)
    pricing(tech,energy,pricingType)
    efficientcyCurve(tech,dir,step)
    standardUnit(energy,units)       'Which units are relevant for this energy. Standard form must be one'
    InterconnectorCapacity(time,area,energy)

*Reserve market parameters
    ActivationProbability
    ReserveCapPrices(time,service)

* Results Day ahead
    ResultT(resultset,tech,energy,time)
    ResultF(resultset,area,area,energy,time)
    ResultA(resultset,area,energy,time)
    ResultTsum(resultset,tech,energy)
    ResultFsum(resultset,area,area,energy)
    ResultAsum(resultset,area,energy)

* Results from Up/down reserve plus activation
    ResultT_all(service,resultset,tech,energy,time)
    ResultF_all(service,resultset,area,area,energy,time)
    ResultA_all(service,resultset,area,energy,time)
    ResultTsum_all(service,resultset,tech,energy)
    ResultFsum_all(service,resultset,area,area,energy)
    ResultAsum_all(service,resultset,area,energy)
    ResultC_all(service,resultset,tech,time)  #save the capacities reserved
    ResultEconomi_all(service,resultset)      #Save numbers
;

Scalar
    Errors  /0/
    penalty /100000/
;

*Manual Parameters, prob to be activated to provide real time regulation
ActivationProbability = 0.3;


* ------------------------------------------------------------------------------


* Load data
$batinclude loadinc.inc resultset
$batinclude loadinc.inc area
$batinclude loadinc.inc tech
$batinclude loadinc.inc dir
$batinclude loadinc.inc step
$batinclude loadinc.inc energy
$batinclude loadinc.inc color
$batinclude loadinc.inc time
$batinclude loadinc.inc scenario
$batinclude loadinc.inc dataset
$batinclude loadinc.inc location
$batinclude loadinc.inc flowset
$batinclude loadinc.inc profile
$batinclude loadinc.inc carriermix
$batinclude loadinc.inc techdata
$batinclude loadinc.inc demand
$batinclude loadinc.inc price
$batinclude loadinc.inc efficientcyCurve
$batinclude loadinc.inc InterconnectorCapacity

*Reserve market addon
$batinclude loadinc.inc Service
$batinclude loadinc.inc ReserveCapPrices

Display  time, flowset, profile, carriermix, techdata, demand,price, efficientcyCurve,
InterconnectorCapacity, Service, ReserveCapPrices;

*$exit


* test todo remove
*efficientcyCurve(tech,dir,step)=0;


*--------------------------------------------------------------------------------
*Define options

$IFtheni  %Operation_Reserve_market%    ==    NO

techdata(tech,'CapacityDown')=0;
techdata(tech,'CapacityUP')=0;


Display techdata;

$ENDIF


* ------------------------------------------------------------------------------
* Assigning sets

* Input and output energy types of technologies
in(tech,energy)$carriermix(tech,'import',energy)=yes;
out(tech,energy)$carriermix(tech,'export',energy)=yes;

* Fuel efficientcy
techdata(tech,'Fe')=sum(energy,carriermix(tech,'export',energy))/sum(energy,carriermix(tech,'import',energy));
carriermix(tech,'export',energy)=carriermix(tech,'export',energy)/sum(energy1,carriermix(tech,'export',energy1));
carriermix(tech,'import',energy)=carriermix(tech,'import',energy)/sum(energy1,carriermix(tech,'import',energy1));

buyE(area,energy)$sum(time,price(time,area,energy,'import'))=yes;
saleE(area,energy)$(sum(time,price(time,area,energy,'export')) or sum(time,demand(time,area,energy)))=yes;

* Unit commitment
UC(tech)$techdata(tech,'Minimum')=yes;

*Technologies that provide reserves
Reserve(tech)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown'))=yes;

* Test for efficientcy curve (first step can be {0,0})
curve(tech,step)$sum(dir,efficientcyCurve(tech,dir,step))=yes;
curve(tech,'step1')$sum(step,curve(tech,step))=yes;

*Lines of interconnectors and areas
LinesInterconnectors(area)$sum((time,energy),InterconnectorCapacity(time,area,energy))=YES;


Display saleE,buyE,LinesInterconnectors,ReserveCapPrices,Reserve, curve;


Parameter
Slack1(area,energy)
;

slack1(area,energy)=sum(tech$(buyE(area,energy) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP')));



SET
BuyUpSet(area,energy)
BuyDownSet(area,energy)
SellUpSet(area,energy)
SellDownSet(area,energy)
;

BuyUpSet(area,energy)$sum(tech,(buyE(area,energy) and techdata(tech,'CapacityUP')))=yes;
BuyDownSet(area,energy)$sum(tech,(buyE(area,energy) and techdata(tech,'CapacityDown')))=yes;
SellUpSet(area,energy)$sum(tech,(saleE(area,energy) and techdata(tech,'CapacityUP')))=yes;
SellDownSet(area,energy)$sum(tech,(saleE(area,energy) and techdata(tech,'CapacityDown')))=yes;

Display Slack1,SellUpSet,SellDownSet,BuyUpSet,BuyDownSet;
*$exit

*--------------------------------------------------------------------------------
*test parameters
*price('DK1-reserve','Electricity','import',time) = 80;
*ReserveCapPrices(time,'Up')=3000;
*techdata(tech,'CapacityDown')=0;
*techdata(tech,'CapacityUP')=0;
*demand(time,area,'hydrogenCom')=220;


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

Loop(tech$(smax(time,profile(time,tech))>1),
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

*$exit
* ------------------------------------------------------------------------------


Variables
    Cost
;

Positive Variables
    Fueluse(time,tech,energy)
    Fuelusetotal(time,tech)
    Generation(time,tech,energy)
    Volume(time,tech)
    Flow(area,area,energy,time)
    Buy(area,energy,time)
    Sale(area,energy,time)
    Startcost(tech,time)
    Ramping(tech,time)
*    Profit(tech,energy,time)

* SlackVariables
    SlackDemand(area,energy,time,dir)

*Variables Reserve and actication for up/down
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
    Load(tech,time,step)
;

Equations
    Objective
* Different forms of production
    Fuelmix(tech,energy,time)           'Total fuel use consis of a fuel mix'
    Production(tech,energy,time)        'Linear production curve (not storage)'
    ProductionStorage(tech,time)        'Production with storage option'
    ProductionCurve(tech,energy,time)   'Production curve with special order set'
    FuelCurve(tech,energy,time)         'Total fuel use curve with special order set'
*Efficiency curves
    ProductionFuelCurve(tech,energy,time)       'Production curve with special order set'
    ImportFuelCurve(tech,time)                  'Total fuel use curve with special order set'
    Weights(tech,time)
    LinkWeights(tech,time,step)
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
*    eqFLH(tech)
    DemandTime(area,energy,time)
* Pricing
;

$ontext
Objective ..
    Cost =E=
* Fuelcost
    sum((buyE(area,energy),time),price(time,area,energy,'import')*Buy(area,energy,time))

  + sum((buyE(area,energy),time),price(time,area,energy,'import')*Buy_Up(area,energy,time)$sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP'))))

  - sum((buyE(area,energy),time),price(time,area,energy,'import')*Buy_Down(area,energy,time)$sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityDown'))))

* Sales
  - sum((saleE(area,energy),time),price(time,area,energy,'export')*Sale(area,energy,time))

  - sum((saleE(area,energy),time),price(time,area,energy,'export')*Sale_Up(area,energy,time)$sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP'))))

  + sum((saleE(area,energy),time),price(time,area,energy,'export')*Sale_Down(area,energy,time)$sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityDown'))))
* O&M
*  + sum((tech),techdata(tech,'FixedOmcost'))
  + sum((tech,time),Fuelusetotal(time,tech)*techdata(tech,'VariableOmcost'))
* Startup cost
  + sum((tech,time),Startcost(tech,time))
* Regulating cost
*  + sum((tech,time),Ramping(tech,time)*techdata(tech,'RegulatingCost'))
* Penalty for infeasable solution
  + penalty*sum((area,energy,time,dir),SlackDemand(area,energy,time,dir))
*Profit from reserving capacities
  - sum((tech,time),ReserveCapPrices(time,'Up')*CapacityReserved_Up(tech,time)$techdata(tech,'CapacityUP')*techdata(tech,'Fe'))
  - sum((tech,time),ReserveCapPrices(time,'Down')*CapacityReserved_Down(tech,time)$techdata(tech,'CapacityDown')*techdata(tech,'Fe'))
;
$offtext


Objective ..
    Cost =E=
* Fuelcost
   - sum((buyE(area,energy),time),price(time,area,energy,'import')*Buy(area,energy,time))

  - sum((BuyUpSet(area,energy),time),price(time,area,energy,'import')*Buy_Up(area,energy,time))

  + sum((BuyDownSet(area,energy),time),price(time,area,energy,'import')*Buy_Down(area,energy,time))

* Sales
  + sum((saleE(area,energy),time),price(time,area,energy,'export')*Sale(area,energy,time))

  + sum((SellUpSet(area,energy),time),price(time,area,energy,'export')*Sale_Up(area,energy,time))

  - sum((SellDownSet(area,energy),time),price(time,area,energy,'export')*Sale_Down(area,energy,time))
* O&M
*  + sum((tech),techdata(tech,'FixedOmcost'))
  - sum((tech,time),Fuelusetotal(time,tech)*techdata(tech,'VariableOmcost'))
* Startup cost
  - sum((tech,time),Startcost(tech,time))
* Regulating cost
*  + sum((tech,time),Ramping(tech,time)*techdata(tech,'RegulatingCost'))
* Penalty for infeasable solution
  - penalty*sum((area,energy,time,dir),SlackDemand(area,energy,time,dir))
*Profit from reserving capacities
  + sum((Reserve(tech),time),ReserveCapPrices(time,'Up')*CapacityReserved_Up(tech,time)*techdata(tech,'Fe'))
  + sum((Reserve(tech),time),ReserveCapPrices(time,'Down')*CapacityReserved_Down(tech,time)*techdata(tech,'Fe'))
;


#Flows imported to technologies
Fuelmix(in(tech,energy),time)$(techdata(tech,'Capacity'))..
    carriermix(tech,'import',energy)*Fuelusetotal(time,tech)
    =E=
    Fueluse(time,tech,energy)
;

#flows exported from technologies if they have load dependacy should go to other equations
Production(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
$IFI %Operation_Efficiency_curves% == YES and not sum(step,curve(tech,step))
) ..
    carriermix(tech,'export',energy)*Fuelusetotal(time,tech)*techdata(tech,'Fe')
    =E=
    Generation(time,tech,energy)
;

*$ontext
*develp a way to be have the capacity and not definied a curve from excel
*$ontext
ImportFuelCurve(tech,time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
    and sum(step,curve(tech,step))) ..
    techdata(tech,'Capacity')*sum(step,Load(tech,time,step)*efficientcyCurve(tech,'import',step))
    =E=
    Fuelusetotal(time,tech)
;
* No need to multiply by *techdata(tech,'Fe'), due to SO2 variables.
ProductionFuelCurve(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
    and sum(step,curve(tech,step)))..
   carriermix(tech,'export',energy)* techdata(tech,'Capacity')*sum(step,Load(tech,time,step)*efficientcyCurve(tech,'export',step)*efficientcyCurve(tech,'import',step))
    =E=
    Generation(time,tech,energy)
;

*be careful !! equal to the online status do not forget we have unit commitement. If you put equal to 1 for convexity end up infeasible !! took couple of hours to understand!
Weights(tech,time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
    and sum(step,curve(tech,step)))..
    sum(step,Load(tech,time,step)) =E= Online(tech,time)
;

*Constraint Indicating that no more than two consecutive elements can be non-zero, perhaps the MIP solver containts this constraint when using sos2. Even without same results.
LinkWeights(tech,time,step)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
    and sum(step1,curve(tech,step)))..
Load(tech,time,step) + Load(tech,time,step-1) =G= 0
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
    techdata(tech,'CapacityUp')*UpCap(tech,time)*profile(time,tech)/techdata(tech,'Fe')
;


CapReservedDownMax(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    CapacityReserved_Down(tech,time)
    =L=
    techdata(tech,'CapacityDown')*DownCap(tech,time)*profile(time,tech)/techdata(tech,'Fe')
;

*Can not be reserved both for up and down
ComplementarityUpDownReservedCapacities(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    UpCap(tech,time) + DownCap(tech,time)
    =L=
    1
;

*Limit max on day ahead Fuelusetototal due to reservations
FuelusetotalDayAheadMax(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    Fuelusetotal(time,tech)
    =L=
    techdata(tech,'Capacity')*profile(time,tech)/techdata(tech,'Fe') - CapacityReserved_Up(tech,time)
;


*Limit min on day ahead Fuelusetototal due to reservations
FuelusetotalDayAheadMin(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    Fuelusetotal(time,tech)
    =G=
    CapacityReserved_Down(tech,time)
;



$ontext
ProductionStorage(tech,time)$(techdata(tech,'storageCap')) ..                               #They do not provide the same results
   Volume(time,tech)
    =E=
  techdata(tech,'InitialVolume')$(ord(time)=1)+ Volume(tech,time--1)$(ord(time)>1)
  + Fuelusetotal(time,tech)*techdata(tech,'Fe') - sum(energy$out(tech,energy),Generation(time,tech,energy)*carriermix(tech,'export',energy))
;
$offtext


*Take into account the balancing flows for storage plus up and down
ProductionStorage(tech,time)$(techdata(tech,'storageCap')) ..
   Volume(time,tech)
    =E=
  techdata(tech,'InitialVolume')$(ord(time)=1)+ Volume(time--1,tech)$(ord(time)>1)

  + Fuelusetotal(time,tech)*techdata(tech,'Fe')

  + (Fuelusetotal_Up(tech,time)$Reserve(tech))*techdata(tech,'Fe')

  - (Fuelusetotal_Down(tech,time)$Reserve(tech))*techdata(tech,'Fe')

  - sum(energy$out(tech,energy),(Generation(time,tech,energy))*carriermix(tech,'export',energy))

  - sum(energy$out(tech,energy),(Generation_UP(tech,energy,time)$Reserve(tech))*carriermix(tech,'export',energy))

  + sum(energy$out(tech,energy),(Generation_Down(tech,energy,time)$Reserve(tech))*carriermix(tech,'export',energy))
;


*Storage can not charge and discharge the same time
* Limit on charging Max Storage
ChargingStorageMax(tech,time)$(techdata(tech,'storageCap')) ..
    Fuelusetotal(time,tech)*techdata(tech,'Fe')
    =L=
    techdata(tech,'Capacity')*Charge(tech,time)
;

* Limit on charging Min Storage
ChargingStorageMin(tech,time)$(techdata(tech,'storageCap') and techdata(tech,'minimum')) ..
    techdata(tech,'minimum')*Charge(tech,time)
    =L=
    Fuelusetotal(time,tech)*techdata(tech,'Fe')
;

* Limit on discharging Max Storage
DisChargingStorageMax(tech,time)$(techdata(tech,'storageCap')) ..
    sum(energy$out(tech,energy),Generation(time,tech,energy)*carriermix(tech,'export',energy))
    =L=
    techdata(tech,'Capacity')*Discharge(tech,time)
;

* Limit on discharging Min Storage
DisChargingStorageMin(tech,time)$(techdata(tech,'storageCap') and techdata(tech,'minimum')) ..
    techdata(tech,'minimum')*Discharge(tech,time)
    =L=
    sum(energy$out(tech,energy),Generation(time,tech,energy)*carriermix(tech,'export',energy))
;

*Can not charge - discharge at the same time
StatusStorageOp(tech,time)$(techdata(tech,'storageCap')) ..
    Charge(tech,time) + Discharge(tech,time)
    =L=
    1
;


* Must have capacity or oppertunity to buy or sell for down reserve activation during real time
BalanceDown(area,energy,time)$(buyE(area,energy) or saleE(area,energy)
or sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),techdata(tech,'Capacity'))
)..

  + Buy_Down(area,energy,time)$buyE(area,energy)
  + Sum(areaIn$flowset(areaIn,area,energy),Flow_Down(areaIn,area,energy,time))
  + sum(tech$(location(area,tech) and out(tech,energy)),Generation_Down(tech,energy,time)$Reserve(tech))
    =E=
  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse_Down(tech,energy,time)$Reserve(tech))
  + Sale_down(area,energy,time)$saleE(area,energy)
  + Sum(areaOut$flowset(area,areaOut,energy),Flow_Down(area,areaOut,energy,time))

;

* Must have capacity or oppertunity to buy or sell for up reserve activation during real time
BalanceUP(area,energy,time)$((buyE(area,energy) or saleE(area,energy))
or sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),techdata(tech,'Capacity'))
)..

  + Buy_Up(area,energy,time)$buyE(area,energy)
  + Sum(areaIn$flowset(areaIn,area,energy),Flow_UP(areaIn,area,energy,time))
  + sum(tech$(location(area,tech) and out(tech,energy)),Generation_Up(tech,energy,time)$Reserve(tech))
    =E=
  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse_Up(tech,energy,time)$Reserve(tech))
  + Sale_Up(area,energy,time)$saleE(area,energy)
  + Sum(areaOut$flowset(area,areaOut,energy),Flow_UP(area,areaOut,energy,time))

;


* Must have capacity or oppertunity to buy or sell on the day ahead
Balance(area,energy,time)$(buyE(area,energy) or saleE(area,energy)
or sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),techdata(tech,'Capacity'))
)..
    Buy(area,energy,time)$buyE(area,energy)
  + Sum(areaIn$flowset(areaIn,area,energy),Flow(areaIn,area,energy,time))
  + sum(tech$(location(area,tech) and out(tech,energy)),Generation(time,tech,energy))
    =E=
  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse(time,tech,energy))
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

  + sum(tech$(location(area,tech) and out(tech,energy)),Generation(time,tech,energy))

  + sum(tech$(location(area,tech) and out(tech,energy)),Generation_UP(tech,energy,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')))

  - sum(tech$(location(area,tech) and out(tech,energy)),Generation_Down(tech,energy,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')))

    =E=

  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse(time,tech,energy))

  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse_Up(tech,energy,time))

  - sum(tech$(location(area,tech) and in(tech,energy)),Fueluse_Down(tech,energy,time))

  + Sale(area,energy,time)$saleE(area,energy)

  + Sum(areaOut$flowset(area,areaOut,energy),Flow(area,areaOut,energy,time))

;
$offtext



DemandTime(area,energy,time)$sum(time1,demand(time1,area,energy)) ..
    Sale(area,energy,time)
    + Sale_Up(area,energy,time)$(saleE(area,energy) and sum(tech,techdata(tech,'CapacityUP')))
    + SlackDemand(area,energy,time,'import') - SlackDemand(area,energy,time,'export')
    =G=
    demand(time,area,energy)
;

*Max Buy or sale regarding capacity of pipes or interconnector,
* Comment check if the interconnector will gain more capacity. Perhaps Buy_down needs to be removed same for the sale_down needs an investigation what is going wrong with extra buy!
MaxBuy(energy,time)$(sum(area,InterconnectorCapacity(time,area,energy))) ..
    sum(area,Buy(area,energy,time)$buyE(area,energy))
   + sum(area,Buy_Up(area,energy,time)$(buyE(area,energy) and sum(tech,techdata(tech,'CapacityUP'))))
   - sum(area,Buy_Down(area,energy,time)$(buyE(area,energy) and sum(tech,techdata(tech,'CapacityDown'))))
    =L=
    sum(area,InterconnectorCapacity(time,area,energy))/card(LinesInterconnectors)
;

MaxSale(energy,time)$(sum(area,InterconnectorCapacity(time,area,energy))) ..
    sum(area,Sale(area,energy,time)$saleE(area,energy))
  + sum(area,Sale_Up(area,energy,time)$(saleE(area,energy) and sum(tech,techdata(tech,'CapacityUP'))))
  - sum(area,Sale_down(area,energy,time)$(saleE(area,energy) and sum(tech,techdata(tech,'CapacityDown'))))
    =L=
    sum(area,InterconnectorCapacity(time,area,energy))/card(LinesInterconnectors)
;

*Limitis on how much you can buy and sale on activation
MaxBuyUp(area,energy,time)$(BuyUpSet(area,energy))..
   Buy_Up(area,energy,time)
   =L=
   sum(tech$(in(tech,energy)),Fueluse_Up(tech,energy,time))
;

MaxBuyDown(area,energy,time)$(BuyDownSet(area,energy) or buyE(area,energy))..
   Buy_Down(area,energy,time)
   =L=
   Buy(area,energy,time)
;


MaxSaleUp(area,energy,time)$(SellUpSet(area,energy))..
   Sale_Up(area,energy,time)
   =E=
   sum(tech$(out(tech,energy)),Generation_Up(tech,energy,time))
;

MaxSaleDown(area,energy,time)$(SellDownSet(area,energy) or saleE(area,energy))..
   Sale_Down(area,energy,time)
   =L=
   sale(area,energy,time)
;

*------------------------------------------------------------------------------------------------------------------

*-Todo
*Ramp constraints need to be adjusted regarding the reserves up/down to be accurate

RampUp(tech,time)$techdata(tech,'ramprate') ..
    techdata(tech,'ramprate')$(not UC(tech))
  + (techdata(tech,'ramprate')*Online(tech,time--1) + techdata(tech,'Minimum')*(1-Online(tech,time--1)))$UC(tech)
    =G=
    sum(energy$out(tech,energy), Generation(time,tech,energy)-Generation(time--1,tech,energy))
;

RampDown(tech,time)$techdata(tech,'ramprate') ..
    techdata(tech,'ramprate')$(not UC(tech))
  + (techdata(tech,'ramprate')*Online(tech,time) + techdata(tech,'Minimum')*(1-Online(tech,time)))$UC(tech)             #devide by  techdata(tech,'Minimum')/techdata(tech,'Fe')?
    =G=
    sum(energy$out(tech,energy), Generation(time--1,tech,energy)-Generation(time,tech,energy))
;

* Capacity defined as constraint if binary needed
Capacity(UC(tech),time) ..
    (techdata(tech,'Capacity')/techdata(tech,'Fe'))*Online(tech,time)
    =G=
    Fuelusetotal(time,tech)
;

Minimumload(UC(tech),time)$techdata(tech,'minimum') ..
    Fuelusetotal(time,tech)
    =G=
    (techdata(tech,'Minimum')/techdata(tech,'Fe'))*Online(tech,time)
;

Startupcost(UC(tech),time)$techdata(tech,'Startupcost') ..
    Startcost(tech,time)
    =G=
    techdata(tech,'Startupcost')*(Online(tech,time)-Online(tech,time--1))
;


FuelusetotalLimProfiles(tech,time)$sum(time1,profile(time1,tech) and not (techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')))..
    Fuelusetotal(time,tech)$sum(time1,profile(time1,tech))
    =L=
    techdata(tech,'Capacity')*profile(time,tech)/techdata(tech,'Fe')
;

FuelusetotalLim(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    Fuelusetotal(time,tech) =L=
    techdata(tech,'Capacity')/techdata(tech,'Fe')
;



* Capacity
*Fuelusetotal.up(tech,time)=techdata(tech,'Capacity')/techdata(tech,'Fe');
*Fuelusetotal.up(tech,time)$sum(time1,profile(tech,time1))=techdata(tech,'Capacity')*profile(tech,time)/techdata(tech,'Fe');


* Storage volume
Volume.up(time,tech)=techdata(tech,'StorageCap');
Volume.fx(time,tech)$(techdata(tech,'StorageCap') and ord(time)=card(time)) = techdata(tech,'InitialVolume');


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
*Sale.up('DK1',energy,time) = 100000;
*CapacityReserved_Up.up(tech,time) =100;
*CapacityReserved_Down.up(tech,time) =100;
*Buy_Down.up('DK1',energy,time) =10000;





* ------------------------------------------------------------------------------
* Model and solve

Model P2Xmodel /
    Objective
    Fuelmix
$IFI %Operation_Efficiency_curves%  == YES            ImportFuelCurve
$IFI %Operation_Efficiency_curves%  == YES            ProductionFuelCurve
$IFI %Operation_Efficiency_curves%  == YES            Weights
$IFI %Operation_Efficiency_curves%  == YES            LinkWeights   #Perhaps we do not need that, leave it in case that solver does not fully support sos2
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
    MaxBuyUp
    MaxBuyDown
    MaxSaleUp
    MaxSaleDown
/;

*option  mip = GAMSCHK
option  mip = CPLEX
Solve P2Xmodel maximizing cost using mip;

Display Fueluse.l, Fuelusetotal.l, generation.l, volume.l,buy.l,sale.l,SlackDemand.l,online.l,flow.l,Balance.m,charge.l,
discharge.l,Startcost.l,CapacityReserved_Up.l,CapacityReserved_Down.l,UpCap.l,DownCap.l,Buy_Up.l,Buy_Down.l,Sale_Up.l,Sale_Down.l,Fuelusetotal_Up.l,Fuelusetotal_Down.l
Fueluse_Up.l,generation_Up.l,Fueluse_Down.l,generation_Down.l,Flow_Down.l,Flow_UP.l
$IFI %Operation_Efficiency_curves% == YES ,Load.l;



*----------------------------------------------------------------------------------------------------------------------------------------------
*Write Results
Parameters
slack11
;

slack11= sum((buyE(area,energy),time),price(time,area,energy,'import')*Buy_Up.l(area,energy,time)$sum(tech$(buyE(area,energy) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP'))));


Display slack11;

* Results
ResultT('Operation_MW',tech,energy ,time)=Generation.l(time,tech,energy)-Fueluse.l(time,tech,energy);
*ResultT('Maximum fueluse_MW',in(tech,energy),time)=profile(tech,time)*techdata(tech,'Capacity')/techdata(tech,'Fe')*carriermix(tech,'import',energy);
*ResultT('Maximum generation_MW',out(tech,energy),time)=profile(tech,time)*techdata(tech,'Capacity')*carriermix(tech,'export',energy);
ResultT('Volume_MWh',out(tech,energy),time)=Volume.l(time,tech);
* TODO: price from which area?
ResultT('Costs_kr',tech,energy,time)=
    + Fueluse.l(time,tech,energy)*sum(area,price(time,area,energy,'import'))
    - Generation.l(time,tech,energy)*sum(area,price(time,area,energy,'export'));
* Todo: how to devide startup cost?
ResultT('Startcost_kr',tech,'system_cost',time)=Startcost.l(tech,time);
*ResultT('Startcost_kr',+ sum((tech),techdata(tech,'FixedOmcost'))
ResultT('Variable_OM_cost_kr',tech,'system_cost',time) = Fuelusetotal.l(time,tech)*techdata(tech,'VariableOmcost');


ResultF('Flow_MW',flowset(areaOut,areaIn,energy),time)=Flow.l(areaOut,areaIn,energy,time);

ResultA('Buy_MW',area,energy,time)=Buy.l(area,energy,time);
ResultA('Sale_MW',area,energy,time)=Sale.l(area,energy,time);
ResultA('Demand_kr',area,energy,time)=demand(time,area,energy);
ResultA('Import_price_kr',area,energy,time)=price(time,area,energy,'import');
ResultA('Export_price_kr',area,energy,time)=price(time,area,energy,'export');
ResultA('Buy_kr',area,energy,time)=Buy.l(area,energy,time)*price(time,area,energy,'import');
ResultA('Sale_kr',area,energy,time)=Sale.l(area,energy,time)*price(time,area,energy,'export');

ResultTsum(Resultset,tech,energy) = sum(time,ResultT(Resultset,tech,energy,time));
ResultFsum(Resultset,flowset) = sum(time,ResultF(Resultset,flowset,time));
ResultAsum(Resultset,area,energy) = sum(time,ResultA(Resultset,area,energy,time));
ResultTsum('Fixed_OM_cost_kr',tech,'System_cost') = 1000000*techdata(tech,'FixedOmcost')*techdata(tech,'Capacity');
ResultTsum('Investment_cost_kr',tech,'System_cost') = 1000000*techdata(tech,'InvestmentCost')*techdata(tech,'Capacity');

*-------------------------------------------------------------------------------------------------------------------------------------------
*Save results all


*Day ahead
ResultT_all('DayAhead','Operation_MW',tech,energy,time)=Generation.l(time,tech,energy)-Fueluse.l(time,tech,energy);
ResultT_all('DayAhead','Volume_MWh',out(tech,energy),time)=Volume.l(time,tech);

ResultT_all('DayAhead','Costs_kr',tech,energy,time)=
    + Fueluse.l(time,tech,energy)*sum(area,price(time,area,energy,'import'))
    - Generation.l(time,tech,energy)*sum(area,price(time,area,energy,'export'));

ResultF_all('DayAhead','Flow_MW',flowset(areaOut,areaIn,energy),time)=Flow.l(areaOut,areaIn,energy,time);

ResultA_all('DayAhead','Buy_MW',area,energy,time)=Buy.l(area,energy,time);
ResultA_all('DayAhead','Sale_MW',area,energy,time)=Sale.l(area,energy,time);
ResultA_all('DayAhead','Demand_kr',area,energy,time)=demand(time,area,energy);
ResultA_all('DayAhead','Import_price_kr',area,energy,time)=price(time,area,energy,'import');
ResultA_all('DayAhead','Export_price_kr',area,energy,time)=price(time,area,energy,'export');
ResultA_all('DayAhead','Buy_kr',area,energy,time)=Buy.l(area,energy,time)*price(time,area,energy,'import');
ResultA_all('DayAhead','Sale_kr',area,energy,time)=Sale.l(area,energy,time)*price(time,area,energy,'export');


ResultTsum_all('DayAhead',Resultset,tech,energy) = sum(time,ResultT_all('DayAhead',Resultset,tech,energy,time));
ResultFsum_all('DayAhead',Resultset,flowset) = sum(time,ResultF_all('DayAhead',Resultset,flowset,time));
ResultAsum_all('DayAhead',Resultset,area,energy) = sum(time,ResultA_all('DayAhead',Resultset,area,energy,time));
ResultTsum_all('DayAhead','Fixed_OM_cost_kr',tech,'system_cost') = 1000000*techdata(tech,'FixedOmcost')*techdata(tech,'Capacity');
ResultTsum_all('DayAhead','Investment_cost_kr',tech,'system_cost') = 1000000*techdata(tech,'InvestmentCost')*techdata(tech,'Capacity');



*Up Reserve
ResultT_all('Up','Operation_MW',tech,energy,time)=Generation_Up.l(tech,energy,time)-Fueluse_Up.l(tech,energy,time);
ResultT_all('Up','Volume_MWh',out(tech,energy),time)=Volume.l(time,tech);

ResultT_all('Up','Costs_kr',tech,energy,time)=
    + Fueluse_Up.l(tech,energy,time)*sum(area,price(time,area,energy,'import'))
    - Generation_Up.l(tech,energy,time)*sum(area,price(time,area,energy,'export'));

ResultF_all('Up','Flow_MW',flowset(areaOut,areaIn,energy),time)=Flow_Up.l(areaOut,areaIn,energy,time);
ResultA_all('Up','Buy_MW',area,energy,time)=Buy_Up.l(area,energy,time);
ResultA_all('Up','Sale_MW',area,energy,time)=Sale_Up.l(area,energy,time);
ResultA_all('Up','Demand_kr',area,energy,time)=demand(time,area,energy);
ResultA_all('Up','Import_price_kr',area,energy,time)=price(time,area,energy,'import');
ResultA_all('Up','Export_price_kr',area,energy,time)=price(time,area,energy,'export');
ResultA_all('Up','Buy_kr',area,energy,time)=Buy_Up.l(area,energy,time)*price(time,area,energy,'import');
ResultA_all('Up','Sale_kr',area,energy,time)=Sale_Up.l(area,energy,time)*price(time,area,energy,'export');


ResultTsum_all('Up',Resultset,tech,energy) = sum(time,ResultT_all('Up',Resultset,tech,energy,time));
ResultFsum_all('Up',Resultset,flowset) = sum(time,ResultF_all('Up',Resultset,flowset,time));
ResultAsum_all('Up',Resultset,area,energy) = sum(time,ResultA_all('Up',Resultset,area,energy,time));
ResultTsum_all('Up','Fixed_OM_cost_kr',tech,'system_cost') = 1000000*techdata(tech,'FixedOmcost')*techdata(tech,'Capacity');
ResultTsum_all('Up','Investment_cost_kr',tech,'system_cost') = 1000000*techdata(tech,'InvestmentCost')*techdata(tech,'Capacity');


*Down reserve
ResultT_all('Down','Operation_MW',tech,energy,time)=Generation_Down.l(tech,energy,time)-Fueluse_Down.l(tech,energy,time);
ResultT_all('Down','Volume_MWh',out(tech,energy),time)=Volume.l(time,tech);

ResultT_all('Down','Costs_kr',tech,energy,time)=
    + Fueluse_Down.l(tech,energy,time)*sum(area,price(time,area,energy,'import'))
    - Generation_Down.l(tech,energy,time)*sum(area,price(time,area,energy,'export'));

ResultF_all('Down','Flow_MW',flowset(areaOut,areaIn,energy),time)=Flow_Down.l(areaOut,areaIn,energy,time);
ResultA_all('Down','Buy_MW',area,energy,time)=Buy_Down.l(area,energy,time);
ResultA_all('Down','Sale_MW',area,energy,time)=Sale_Down.l(area,energy,time);
ResultA_all('Down','Demand_kr',area,energy,time)=demand(time,area,energy);
ResultA_all('Down','Import_price_kr',area,energy,time)=price(time,area,energy,'import');
ResultA_all('Down','Export_price_kr',area,energy,time)=price(time,area,energy,'export');
ResultA_all('Down','Buy_kr',area,energy,time)=Buy_Down.l(area,energy,time)*price(time,area,energy,'import');
ResultA_all('Down','Sale_kr',area,energy,time)=Sale_Down.l(area,energy,time)*price(time,area,energy,'export');

ResultTsum_all('Down',Resultset,tech,energy) = sum(time,ResultT_all('Down',Resultset,tech,energy,time));
ResultFsum_all('Down',Resultset,flowset) = sum(time,ResultF_all('Down',Resultset,flowset,time));
ResultAsum_all('Down',Resultset,area,energy) = sum(time,ResultA_all('Down',Resultset,area,energy,time));
ResultTsum_all('Down','Fixed_OM_cost_kr',tech,'system_cost') = 1000000*techdata(tech,'FixedOmcost')*techdata(tech,'Capacity');
ResultTsum_all('Down','Investment_cost_kr',tech,'system_cost') = 1000000*techdata(tech,'InvestmentCost')*techdata(tech,'Capacity');

*Save the capacities
*ResultC_all(service,*,tech,time)

ResultC_all('DayAhead','Capacity_MW',tech,time) = Fuelusetotal.l(time,tech)*techdata(tech,'Fe');
ResultC_all('Up','Capacity_MW',tech,time) = CapacityReserved_Up.l(tech,time)*techdata(tech,'Fe');
ResultC_all('Down','Capacity_MW',tech,time) =-CapacityReserved_Down.l(tech,time)*techdata(tech,'Fe');

*$ontext
*Results economy
ResultEconomi_all('DayAhead','Total_Profit_kr') =  - sum((buyE(area,energy),time),price(time,area,energy,'import')*Buy.l(area,energy,time)) + sum((saleE(area,energy),time),price(time,area,energy,'export')*Sale.l(area,energy,time));
ResultEconomi_all('Up','Total_Profit_kr') =  - sum((buyE(area,energy),time),price(time,area,energy,'import')*Buy_up.l(area,energy,time)) + sum((saleE(area,energy),time),price(time,area,energy,'export')*Sale_up.l(area,energy,time));
ResultEconomi_all('Down','Total_Profit_kr') =   + sum((BuyDownSet(area,energy),time),price(time,area,energy,'import')*Buy_Down.l(area,energy,time)) - sum((SellDownSet(area,energy),time),price(time,area,energy,'export')*Sale_Down.l(area,energy,time));
ResultEconomi_all('DayAhead','CapacityPayment_kr') = 0;
ResultEconomi_all('Up','CapacityPayment_kr') = + sum((Reserve(tech),time),ReserveCapPrices(time,'Up')*CapacityReserved_Up.l(tech,time)*techdata(tech,'Fe'));
ResultEconomi_all('Down','CapacityPayment_kr') = + sum((Reserve(tech),time),ReserveCapPrices(time,'Down')*CapacityReserved_Down.l(tech,time)*techdata(tech,'Fe'));


*$offtext

*-----------------------------------------------------------------------------------------------------------------------------------
*Save on GDX and SQL
* Make output folde if it does not exist
$ifi not exist '..\output'
execute 'mkdir ..\output'



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



* GHH model
* Developed by Ea Energy Analysis
*Ioannis Kountouris

* Notes IK 18/10/2021:
* - Adapt the ramp rates for the technologies given reservation capacities
* - Add eeficiency curves?
* - check what is the probability of activation currently is 0.3 of the capacity reserved
* - Do the capacities reserved need to be devided by FE?
*- Capacity paymenet should be related with electricity fueluse or generation

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
$setglobal MAKESQL     NO                        # Save run in database [yes/no]
$setglobal PROJECTID   GHH                       # Name of project in database
$setglobal CASEID      IK_skive_test               # Name of case in database

*Write excel results (works only for microsoft not ios)
$setglobal WriteXLSX                           NO

* Options for operation details
$setglobal Operation_Reserve_market            NO

*FutureTechnologies to add in the model (based on the set Future set, look at the data xlsx)
$setglobal FutureTech                          NO


*To do fix the code and implementation
$setglobal Operation_Efficiency_curves         NO

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
    FutureTech

*Sets for the reservation addon
    BuyUpSet(area,energy)
    BuyDownSet(area,energy)
    SellUpSet(area,energy)
    SellDownSet(area,energy)
    Reserve(tech)                 'technologies that can provide reserve'
;

set
itech(tech)
IA(tech)
;


alias(area,areaIn,AreaOut);
alias(tech,tech1);
alias(itech,itech1);
alias(step,step1);
alias(time,time1);
alias(energy,energy1);

Parameters
    Profile(tech,time)
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
$batinclude loadinc.inc FutureTech

*Reserve market addon
$batinclude loadinc.inc Service
$batinclude loadinc.inc ReserveCapPrices

Display  time, flowset, profile, carriermix, techdata, demand,price, efficientcyCurve,
InterconnectorCapacity, Service, ReserveCapPrices,FutureTech;

*$exit


* test todo remove
*efficientcyCurve(tech,dir,step)=0;



*--------------------------------------------------------------------------------
*test parameters
*price('DK1-reserve','Electricity','import',time) = 80;
*ReserveCapPrices('Up',time)=3000;
*techdata(tech,'CapacityDown')=0;
*techdata(tech,'CapacityUP')=0;

*--------------------------------------------------------------------------------
*Define options

$IFtheni  %Operation_Reserve_market%    ==    NO

techdata(tech,'CapacityDown')=0;
techdata(tech,'CapacityUP')=0;


Display techdata;

$ENDIF

$ifi not %FutureTech% == NO $goto MISS_new_technologies


IA(tech) = YES;
itech(tech) = IA(tech) - FutureTech(tech);


$label MISS_new_technologies

Display itech,tech;





*techdata('OnshoreWind','CapacityDown')=10;
*techdata('OnshoreWind','CapacityUP')=10;
*techdata('SolarPV','CapacityDown')=10;
*techdata('SolarPV','CapacityUP')=10;
*techdata('El-Generator','CapacityDown')=0;
*techdata('El-Generator','CapacityUP')=0;

* ------------------------------------------------------------------------------
* Assigning sets

* Input and output energy types of technologies
in(itech,energy)$carriermix(itech,'import',energy)=yes;
out(itech,energy)$carriermix(itech,'export',energy)=yes;

Display in, out;

*$exit

* Fuel efficientcy
techdata(itech,'Fe')=sum(energy,carriermix(itech,'export',energy))/sum(energy,carriermix(itech,'import',energy));
carriermix(itech,'export',energy)=carriermix(itech,'export',energy)/sum(energy1,carriermix(itech,'export',energy1));
carriermix(itech,'import',energy)=carriermix(itech,'import',energy)/sum(energy1,carriermix(itech,'import',energy1));

buyE(area,energy)$sum(time,price(area,energy,'import',time))=yes;
saleE(area,energy)$(sum(time,price(area,energy,'export',time)) or sum(time,demand(area,energy,time)) )=yes;

* Unit commitment
UC(itech)$techdata(itech,'Minimum')=yes;

* Test for efficientcy curve (first step can be {0,0})
curve(itech,step)$sum(dir,efficientcyCurve(itech,dir,step))=yes;
curve(itech,'step1')$sum(step,curve(itech,step))=yes;

*Lines of interconnectors and areas
LinesInterconnectors(area)$sum((energy,time),InterconnectorCapacity(area,energy,time))=YES;


Display saleE,buyE,LinesInterconnectors,ReserveCapPrices,carriermix ;


Parameter
Slack(area,energy)
;

slack(area,energy)=sum(itech$(buyE(area,energy) and (in(itech,energy) or out(itech,energy))),(techdata(itech,'CapacityUP')));

*Technologies that provide reserves
Reserve(itech)$(techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown'))=yes;

*Available flows to satisfy the activation demand
BuyUpSet(area,energy)$sum(itech,(buyE(area,energy) and techdata(itech,'CapacityUP')))=yes;
BuyDownSet(area,energy)$sum(itech,(buyE(area,energy) and techdata(itech,'CapacityDown')))=yes;
SellUpSet(area,energy)$sum(itech,(saleE(area,energy) and techdata(itech,'CapacityUP')))=yes;
SellDownSet(area,energy)$sum(itech,(saleE(area,energy) and techdata(itech,'CapacityDown')))=yes;

Display Slack,SellUpSet,SellDownSet,BuyUpSet,BuyDownSet, Reserve;
*$exit


* ------------------------------------------------------------------------------
* Error checking

File errorlog /'../Error/errorlog.txt'/;
put errorlog;
Put 'Input data errors:' / / ;

loop((itech,dir,energy)$(carriermix(itech,dir,energy)<0),
    Put 'Carrier should not be negative, change import/export: ',energy.tl,' for ',itech.tl /;
    Errors=Errors+1;
);

loop(itech$(not techdata(itech,'Fe')),
    Put 'Fuel efficientcy must be defined for: ',itech.tl /;
    Errors=Errors+1;
);

loop(itech$techdata(itech,'StorageCap'),
    if(sum(energy$out(itech,energy),1)>1,
        Put 'Storage can only have one energy output: ',itech.tl /;
        Errors=Errors+1;
    );
);

Loop(itech$(smax(time,profile(itech,time))>1),
    Put 'Profile should at maximum be 100%: ',itech.tl /;
    Errors=Errors+1;
);

* Test for efficientcy curve
loop(itech$sum(step,curve(itech,step)),

    if(techdata(itech,'storageCap'),
        Put 'Storages can not have an efficientcy curve: ', itech.tl /;
        Errors=Errors+1;
    );

    if(smax(step,efficientcyCurve(itech,'export',step)) <> techdata(itech,'Capacity'),
        Put 'Last point on efficientcy curve must match capacity: ', itech.tl /;
        Errors=Errors+1;
    );

    if(sum(step$(ord(step)=smax(step1$curve(itech,step1),ord(step1))),efficientcyCurve(itech,'export',step)/efficientcyCurve(itech,'import',step)) <> techdata(itech,'Fe'),
        Put 'Last point on efficientcy curve must match total efficientcy: ', itech.tl /;
        Errors=Errors+1;
    );

    loop((dir,step)$(efficientcyCurve(itech,dir,step)>efficientcyCurve(itech,dir,step+1) and efficientcyCurve(itech,dir,step+1)),
        Put 'Point on efficientcy curve must be increasing: ', itech.tl,',',dir.tl /;
        Errors=Errors+1;
    );

* First point may be {0,0}
    loop(step$(ord(step)>1 and sum(dir,efficientcyCurve(itech,dir,step))=1),
        Put 'Both point on efficientcy curve must be defined: ', itech.tl,',',step.tl /;
        Errors=Errors+1;
    );
);

* Todo: Check import price lower than export price
* Circles of fun?

* Check flows possible/relevant

* Todo    flowset(area,area,energy)
Loop((area,out(itech,energy))$(location(area,itech)                               # Located in this area
  and not saleE(area,energy)                                                    # But no sale
  and not sum(itech1,in(itech1,energy))                                           # No tech use
  and not sum(areaIn,flowset(area,areaIn,energy))),                             # No out flow
    Put 'Technology missing energy outlet of ', area.tl,', ',itech.tl,', ',energy.tl /;
    Errors=Errors+1;
);
Loop((area,in(itech,energy))$(location(area,itech)                                # Located in this area
  and not buyE(area,energy)                                                     # But no retailer
  and not sum(itech1,out(itech1,energy))                                          # No tech produser
  and not sum(areaOut,flowset(areaOut,area,energy))),                           # No in flow
    Put 'Technology missing energy source of ', area.tl,', ',itech.tl,',',energy.tl /;
    Errors=Errors+1;
);
Loop(buyE(area,energy)$(not sum(itech$location(area,itech),in(itech,energy)) and not sum(areaIn,flowset(area,areaIn,energy))),
    Put 'Buying not relevant in this area of ', area.tl,',',energy.tl /;
    Errors=Errors+1;
);
Loop(saleE(area,energy)$(not sum(itech$location(area,itech),out(itech,energy)) and not sum(areaOut,flowset(areaOut,area,energy))),
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
*    Profit(tech,energy,time)
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
    Load(tech,time,step)
;

Equations
    Objective
    Fuelmix(tech,energy,time)           'Total fuel use consis of a fuel mix'
* Different forms of production
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
    sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy(area,energy,time))

  + sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy_Up(area,energy,time)$sum(itech$(location(area,tech) and (in(itech,energy) or out(itech,energy))),(techdata(itech,'CapacityUP'))))

  - sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy_Down(area,energy,time)$sum(itech$(location(area,tech) and (in(itech,energy) or out(itech,energy))),(techdata(itech,'CapacityDown'))))

* Sales
  - sum((saleE(area,energy),time),price(area,energy,'export',time)*Sale(area,energy,time))

  - sum((saleE(area,energy),time),price(area,energy,'export',time)*Sale_Up(area,energy,time)$sum(itech$(location(area,tech) and (in(itech,energy) or out(itech,energy))),(techdata(itech,'CapacityUP'))))

  + sum((saleE(area,energy),time),price(area,energy,'export',time)*Sale_Down(area,energy,time)$sum(itech$(location(area,tech) and (in(itech,energy) or out(itech,energy))),(techdata(itech,'CapacityDown'))))
* O&M
*  + sum((itech),techdata(itech,'FixedOmcost'))
  + sum((itech,time),Fuelusetotal(itech,time)*techdata(itech,'VariableOmcost'))
* Startup cost
  + sum((itech,time),Startcost(itech,time))
* Regulating cost
*  + sum((itech,time),Ramping(itech,time)*techdata(itech,'RegulatingCost'))
* Penalty for infeasable solution
  + penalty*sum((area,energy,time,dir),SlackDemand(area,energy,time,dir))
*Profit from reserving capacities
  - sum((itech,time),ReserveCapPrices('Up',time)*CapacityReserved_Up(itech,time)$techdata(itech,'CapacityUP')*techdata(itech,'Fe'))
  - sum((itech,time),ReserveCapPrices('Down',time)*CapacityReserved_Down(itech,time)$techdata(itech,'CapacityDown')*techdata(itech,'Fe'))
;
$offtext


Objective ..
    Cost =E=
* Fuelcost
   - sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy(area,energy,time))

  - sum((BuyUpSet(area,energy),time),price(area,energy,'import',time)*Buy_Up(area,energy,time))

  + sum((BuyDownSet(area,energy),time),price(area,energy,'import',time)*Buy_Down(area,energy,time))

* Sales
  + sum((saleE(area,energy),time),price(area,energy,'export',time)*Sale(area,energy,time))

  + sum((SellUpSet(area,energy),time),price(area,energy,'export',time)*Sale_Up(area,energy,time))

  - sum((SellDownSet(area,energy),time),price(area,energy,'export',time)*Sale_Down(area,energy,time))
* O&M
*  + sum((itech),techdata(itech,'FixedOmcost'))
  - sum((itech,time),Fuelusetotal(itech,time)*techdata(itech,'VariableOmcost'))
* Startup cost
  - sum((itech,time),Startcost(itech,time))
* Regulating cost
*  + sum((itech,time),Ramping(itech,time)*techdata(itech,'RegulatingCost'))
* Penalty for infeasable solution
  - penalty*sum((area,energy,time,dir),SlackDemand(area,energy,time,dir))
*Profit from reserving capacities
  + sum((Reserve(itech),time),ReserveCapPrices('Up',time)*CapacityReserved_Up(itech,time)*techdata(itech,'Fe'))
  + sum((Reserve(itech),time),ReserveCapPrices('Down',time)*CapacityReserved_Down(itech,time)*techdata(itech,'Fe'))
;


#Flows imported to technologies
Fuelmix(in(itech,energy),time)$(techdata(itech,'Capacity'))..
    carriermix(itech,'import',energy)*Fuelusetotal(itech,time)
    =E=
    Fueluse(itech,energy,time)
;

#flows exported from technologies
Production(out(itech,energy),time)$(techdata(itech,'Capacity') and not techdata(itech,'storageCap')
$IFI %Operation_Efficiency_curves% == YES and not sum(step,curve(itech,step))
) ..
    carriermix(itech,'export',energy)*Fuelusetotal(itech,time)*techdata(itech,'Fe')
    =E=
    Generation(itech,energy,time)
;

*-------------------------Load dependency curves-----------------------------------------------------------------------
*$ontext
*develp a way to be have the capacity and not definied a curve from excel
*$ontext
ImportFuelCurve(itech,time)$(techdata(itech,'Capacity') and not techdata(itech,'storageCap')
    and sum(step,curve(itech,step))) ..
    techdata(itech,'Capacity')*sum(step,Load(itech,time,step)*efficientcyCurve(itech,'import',step))
    =E=
    Fuelusetotal(itech,time)
;
* No need to multiply by *techdata(itech,'Fe'), due to SO2 variables.
ProductionFuelCurve(out(itech,energy),time)$(techdata(itech,'Capacity') and not techdata(itech,'storageCap')
    and sum(step,curve(itech,step)))..
   carriermix(itech,'export',energy)* techdata(itech,'Capacity')*sum(step,Load(itech,time,step)*efficientcyCurve(itech,'export',step)*efficientcyCurve(itech,'import',step))
    =E=
    Generation(itech,energy,time)
;

*be careful !! equal to the online status do not forget we have unit commitement. If you put equal to 1 for convexity end up infeasible !! took couple of hours to understand!
Weights(itech,time)$(techdata(itech,'Capacity') and not techdata(itech,'storageCap')
    and sum(step,curve(itech,step)))..
    sum(step,Load(itech,time,step)) =E= Online(itech,time)
;

*Constraint Indicating that no more than two consecutive elements can be non-zero, perhaps the MIP solver containts this constraint when using sos2. Even without same results.
LinkWeights(itech,time,step)$(techdata(itech,'Capacity') and not techdata(itech,'storageCap')
    and sum(step1,curve(itech,step)))..
Load(itech,time,step) + Load(itech,time,step-1) =G= 0
;
*-------------------------------------------------------------------------------------------------------------------------


FuelmixUp(in(itech,energy),time)$(techdata(itech,'Capacity') and (techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')) )..
    carriermix(itech,'import',energy)*Fuelusetotal_Up(itech,time)
    =E=
    Fueluse_Up(itech,energy,time)
;

ProductionUp(out(itech,energy),time)$(techdata(itech,'Capacity') and not techdata(itech,'storageCap') and (techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown'))
*    and sum(step,curve(itech,step))
) ..
    carriermix(itech,'export',energy)*Fuelusetotal_Up(itech,time)*techdata(itech,'Fe')
    =E=
    Generation_Up(itech,energy,time)
;

FuelmixDown(in(itech,energy),time)$(techdata(itech,'Capacity') and (techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')))..
    carriermix(itech,'import',energy)*Fuelusetotal_Down(itech,time)
    =E=
    Fueluse_Down(itech,energy,time)
;

ProductionDown(out(itech,energy),time)$(techdata(itech,'Capacity') and not techdata(itech,'storageCap') and (techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown'))
*    and sum(step,curve(itech,step))
) ..
    carriermix(itech,'export',energy)*Fuelusetotal_Down(itech,time)*techdata(itech,'Fe')
    =E=
    Generation_Down(itech,energy,time)
;

*Activation Up
ReatTimeUpDeploymentUp(itech,time)$(techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')) ..
    Fuelusetotal_Up(itech,time)
    =E=
    ActivationProbability * CapacityReserved_Up(itech,time)
;

*Activation Down
ReatTimeUpDeploymentDown(itech,time)$(techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')) ..
    Fuelusetotal_Down(itech,time)
    =E=
    ActivationProbability * CapacityReserved_Down(itech,time)
;

*Limits on capacity able to be reserved
CapReservedUpMax(itech,time)$(techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')) ..
    CapacityReserved_Up(itech,time)
    =L=
    techdata(itech,'CapacityUp')*UpCap(itech,time)*profile(itech,time)/techdata(itech,'Fe')
;


CapReservedDownMax(itech,time)$(techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')) ..
    CapacityReserved_Down(itech,time)
    =L=
    techdata(itech,'CapacityDown')*DownCap(itech,time)*profile(itech,time)/techdata(itech,'Fe')
;

*Can not be reserved both for up and down
ComplementarityUpDownReservedCapacities(itech,time)$(techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')) ..
    UpCap(itech,time) + DownCap(itech,time)
    =L=
    1
;

*Limit max on day ahead Fuelusetototal due to reservations
FuelusetotalDayAheadMax(itech,time)$(techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')) ..
    Fuelusetotal(itech,time)
    =L=
    techdata(itech,'Capacity')*profile(itech,time)/techdata(itech,'Fe') - CapacityReserved_Up(itech,time)
;


*Limit min on day ahead Fuelusetototal due to reservations
FuelusetotalDayAheadMin(itech,time)$(techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')) ..
    Fuelusetotal(itech,time)
    =G=
    CapacityReserved_Down(itech,time)
;



$ontext
ProductionStorage(itech,time)$(techdata(itech,'storageCap')) ..                               #They do not provide the same results
   Volume(itech,time)
    =E=
  techdata(itech,'InitialVolume')$(ord(time)=1)+ Volume(itech,time--1)$(ord(time)>1)
  + Fuelusetotal(itech,time)*techdata(itech,'Fe') - sum(energy$out(itech,energy),Generation(itech,energy,time)*carriermix(itech,'export',energy))
;
$offtext


*Take into account the balancing flows for storage plus up and down
ProductionStorage(itech,time)$(techdata(itech,'storageCap')) ..
   Volume(itech,time)
    =E=
  techdata(itech,'InitialVolume')$(ord(time)=1)+ Volume(itech,time--1)$(ord(time)>1)

  + Fuelusetotal(itech,time)*techdata(itech,'Fe')

  + (Fuelusetotal_Up(itech,time)$Reserve(itech))*techdata(itech,'Fe')

  - (Fuelusetotal_Down(itech,time)$Reserve(itech))*techdata(itech,'Fe')

  - sum(energy$out(itech,energy),(Generation(itech,energy,time))*carriermix(itech,'export',energy))

  - sum(energy$out(itech,energy),(Generation_UP(itech,energy,time)$Reserve(itech))*carriermix(itech,'export',energy))

  + sum(energy$out(itech,energy),(Generation_Down(itech,energy,time)$Reserve(itech))*carriermix(itech,'export',energy))
;


*Storage can not charge and discharge the same time
* Limit on charging Max Storage
ChargingStorageMax(itech,time)$(techdata(itech,'storageCap')) ..
    Fuelusetotal(itech,time)*techdata(itech,'Fe')
    =L=
    techdata(itech,'Capacity')*Charge(itech,time)
;

* Limit on charging Min Storage
ChargingStorageMin(itech,time)$(techdata(itech,'storageCap') and techdata(itech,'minimum')) ..
    techdata(itech,'minimum')*Charge(itech,time)
    =L=
    Fuelusetotal(itech,time)*techdata(itech,'Fe')
;

* Limit on discharging Max Storage
DisChargingStorageMax(itech,time)$(techdata(itech,'storageCap')) ..
    sum(energy$out(itech,energy),Generation(itech,energy,time)*carriermix(itech,'export',energy))
    =L=
    techdata(itech,'Capacity')*Discharge(itech,time)
;

* Limit on discharging Min Storage
DisChargingStorageMin(itech,time)$(techdata(itech,'storageCap') and techdata(itech,'minimum')) ..
    techdata(itech,'minimum')*Discharge(itech,time)
    =L=
    sum(energy$out(itech,energy),Generation(itech,energy,time)*carriermix(itech,'export',energy))
;

*Can not charge - discharge at the same time
StatusStorageOp(itech,time)$(techdata(itech,'storageCap')) ..
    Charge(itech,time) + Discharge(itech,time)
    =L=
    1
;


* Must have capacity or opportunity to buy or sell on the day ahead
Balance(area,energy,time)$(buyE(area,energy) or saleE(area,energy)
or sum(itech$(location(area,itech) and (in(itech,energy) or out(itech,energy))),techdata(itech,'Capacity'))
)..
    Buy(area,energy,time)$buyE(area,energy)
  + Sum(areaIn$flowset(areaIn,area,energy),Flow(areaIn,area,energy,time))
  + sum(itech$(location(area,itech) and out(itech,energy)),Generation(itech,energy,time))
    =E=
  + sum(itech$(location(area,itech) and in(itech,energy)),Fueluse(itech,energy,time))
  + Sale(area,energy,time)$saleE(area,energy)
  + Sum(areaOut$flowset(area,areaOut,energy),Flow(area,areaOut,energy,time))

;


* Must have capacity or opportunity to buy or sell for down reserve activation during real time
BalanceDown(area,energy,time)$(buyE(area,energy) or saleE(area,energy)
or sum(itech$(location(area,itech) and (in(itech,energy) or out(itech,energy))),techdata(itech,'Capacity'))
)..

  + Buy_Down(area,energy,time)$buyE(area,energy)
  + Sum(areaIn$flowset(areaIn,area,energy),Flow_Down(areaIn,area,energy,time))
  + sum(itech$(location(area,itech) and out(itech,energy)),Generation_Down(itech,energy,time)$Reserve(itech))
    =E=
  + sum(itech$(location(area,itech) and in(itech,energy)),Fueluse_Down(itech,energy,time)$Reserve(itech))
  + Sale_down(area,energy,time)$saleE(area,energy)
  + Sum(areaOut$flowset(area,areaOut,energy),Flow_Down(area,areaOut,energy,time))

;

* Must have capacity or opportunity to buy or sell for up reserve activation during real time
BalanceUP(area,energy,time)$((buyE(area,energy) or saleE(area,energy))
or sum(itech$(location(area,itech) and (in(itech,energy) or out(itech,energy))),techdata(itech,'Capacity'))
)..

  + Buy_Up(area,energy,time)$buyE(area,energy)
  + Sum(areaIn$flowset(areaIn,area,energy),Flow_UP(areaIn,area,energy,time))
  + sum(itech$(location(area,itech) and out(itech,energy)),Generation_Up(itech,energy,time)$Reserve(itech))
    =E=
  + sum(itech$(location(area,itech) and in(itech,energy)),Fueluse_Up(itech,energy,time)$Reserve(itech))
  + Sale_Up(area,energy,time)$saleE(area,energy)
  + Sum(areaOut$flowset(area,areaOut,energy),Flow_UP(area,areaOut,energy,time))

;


$ontext
* Must have capacity or oppertunity to buy or sell
Balance(area,energy,time)$((buyE(area,energy) or saleE(area,energy))
or sum(itech$(location(area,tech) and (in(itech,energy) or out(itech,energy))),techdata(itech,'Capacity'))
)..
  + Buy(area,energy,time)$buyE(area,energy)

  + Buy_Up(area,energy,time)$(buyE(area,energy) and sum(itech$(location(area,tech) and (in(itech,energy) or out(itech,energy))),(techdata(itech,'CapacityUP'))))

  - Buy_Down(area,energy,time)$(buyE(area,energy) and sum(itech$(location(area,tech) and (in(itech,energy) or out(itech,energy))),(techdata(itech,'CapacityUP'))))

  + Sum(areaIn$flowset(areaIn,area,energy),Flow(areaIn,area,energy,time))

  + Sum(areaIn$flowset(areaIn,area,energy),Flow_up(areaIn,area,energy,time))

  - Sum(areaIn$flowset(areaIn,area,energy),Flow_Down(areaIn,area,energy,time))

  + sum(itech$(location(area,tech) and out(itech,energy)),Generation(itech,energy,time))

  + sum(itech$(location(area,tech) and out(itech,energy)),Generation_UP(itech,energy,time)$(techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')))

  - sum(itech$(location(area,tech) and out(itech,energy)),Generation_Down(itech,energy,time)$(techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')))

    =E=

  + sum(itech$(location(area,tech) and in(itech,energy)),Fueluse(itech,energy,time))

  + sum(itech$(location(area,tech) and in(itech,energy)),Fueluse_Up(itech,energy,time))

  - sum(itech$(location(area,tech) and in(itech,energy)),Fueluse_Down(itech,energy,time))

  + Sale(area,energy,time)$saleE(area,energy)

  + Sum(areaOut$flowset(area,areaOut,energy),Flow(area,areaOut,energy,time))

;
$offtext



DemandTime(area,energy,time)$sum(time1,demand(area,energy,time1)) ..
    Sale(area,energy,time) + SlackDemand(area,energy,time,'import') - SlackDemand(area,energy,time,'export')
    =G=
    demand(area,energy,time)
;

*Max Buy or sale regarding capacity of pipes or interconnector,
* Comment check if the interconnector will gain more capacity. Perhaps Buy_down needs to be removed same for the sale_down
MaxBuy(energy,time)$(sum(area,InterconnectorCapacity(area,energy,time))) ..
    sum(area,Buy(area,energy,time)$buyE(area,energy))
   + sum(area,Buy_Up(area,energy,time)$(buyE(area,energy) and sum(itech,techdata(itech,'CapacityUP'))))
   - sum(area,Buy_Down(area,energy,time)$(buyE(area,energy) and sum(itech,techdata(itech,'CapacityDown'))))
    =L=
    sum(area,InterconnectorCapacity(area,energy,time))/card(LinesInterconnectors)
;

MaxSale(energy,time)$(sum(area,InterconnectorCapacity(area,energy,time))) ..
    sum(area,Sale(area,energy,time)$saleE(area,energy))
  + sum(area,Sale_Up(area,energy,time)$(saleE(area,energy) and sum(itech,techdata(itech,'CapacityUP'))))
  - sum(area,Sale_down(area,energy,time)$(saleE(area,energy) and sum(itech,techdata(itech,'CapacityDown'))))
    =L=
    sum(area,InterconnectorCapacity(area,energy,time))/card(LinesInterconnectors)
;

*Limitis on how much you can buy and sale on activation
MaxBuyUp(area,energy,time)$(BuyUpSet(area,energy))..
   Buy_Up(area,energy,time)
   =L=
   sum(itech$(in(itech,energy)),Fueluse_Up(itech,energy,time))
;

MaxBuyDown(area,energy,time)$(BuyDownSet(area,energy) or buyE(area,energy))..
   Buy_Down(area,energy,time)
   =L=
   Buy(area,energy,time)
;


MaxSaleUp(area,energy,time)$(SellUpSet(area,energy))..
   Sale_Up(area,energy,time)
   =E=
   sum(itech$(out(itech,energy)),Generation_Up(itech,energy,time))
;

MaxSaleDown(area,energy,time)$(SellDownSet(area,energy) or saleE(area,energy))..
   Sale_Down(area,energy,time)
   =L=
   sale(area,energy,time)
;

*------------------------------------------------------------------------------------------------------------------

*-Todo
*Ramp constraints need to be adjusted regarding the reserves up/down to be accurate

RampUp(itech,time)$techdata(itech,'ramprate') ..
    techdata(itech,'ramprate')$(not UC(itech))
  + (techdata(itech,'ramprate')*Online(itech,time--1) + techdata(itech,'Minimum')*(1-Online(itech,time--1)))$UC(itech)
    =G=
    sum(energy$out(itech,energy), Generation(itech,energy,time)-Generation(itech,energy,time--1))
;

RampDown(itech,time)$techdata(itech,'ramprate') ..
    techdata(itech,'ramprate')$(not UC(itech))
  + (techdata(itech,'ramprate')*Online(itech,time) + techdata(itech,'Minimum')*(1-Online(itech,time)))$UC(itech)             #devide by  techdata(itech,'Minimum')/techdata(itech,'Fe')?
    =G=
    sum(energy$out(itech,energy), Generation(itech,energy,time--1)-Generation(itech,energy,time))
;

* Capacity defined as constraint if binary needed
Capacity(UC(itech),time) ..
    (techdata(itech,'Capacity')/techdata(itech,'Fe'))*Online(itech,time)
    =G=
    Fuelusetotal(itech,time)
;

Minimumload(UC(itech),time)$techdata(itech,'minimum') ..
    Fuelusetotal(itech,time)
    =G=
    (techdata(itech,'Minimum')/techdata(itech,'Fe'))*Online(itech,time)
;

Startupcost(UC(itech),time)$techdata(itech,'Startupcost') ..
    Startcost(itech,time)
    =G=
    techdata(itech,'Startupcost')*(Online(itech,time)-Online(itech,time--1))
;


FuelusetotalLimProfiles(itech,time)$sum(time1,profile(itech,time1) or techdata(itech,'Capacity'))..
    Fuelusetotal(itech,time)$sum(time1,profile(itech,time1))
    =L=
    techdata(itech,'Capacity')*profile(itech,time)/techdata(itech,'Fe')
;

FuelusetotalLim(itech,time)$(techdata(itech,'Capacity') or  techdata(itech,'CapacityUP') or techdata(itech,'CapacityDown')) ..
    Fuelusetotal(itech,time) =L=
    techdata(itech,'Capacity')/techdata(itech,'Fe')
;

*Variable limit

* Storage volume circle
Volume.up(itech,time)=techdata(itech,'StorageCap');
Volume.fx(itech,time)$(techdata(itech,'StorageCap') and ord(time)=card(time)) = techdata(itech,'InitialVolume');


* Capacity
*Fuelusetotal.up(itech,time)=techdata(itech,'Capacity')/techdata(itech,'Fe');
*Fuelusetotal.up(itech,time)$sum(time1,profile(itech,time1))=techdata(itech,'Capacity')*profile(itech,time)/techdata(itech,'Fe');




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
*CapacityReserved_Up.up(itech,time) =100;
*CapacityReserved_Down.up(itech,time) =100;
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

*Write results
$INCLUDE '../model/WriteResults/WriteResults.inc';



*Define Equations
Equations
    Objective
    Fuelmix(tech,energy,time)                   'Total fuel use consisist of a fuel mix'
* Different forms of production
    Production(tech,energy,time)                'Linear production curve (not storage)'
    ProductionStorage(tech,time)                'Production with storage option'
    ProductionCurve(tech,energy,time)           'Production curve with special order set'
    FuelCurve(tech,energy,time)                 'Total fuel use curve with special order set'
*Efficiency curves
    ProductionFuelCurve(tech,energy,time)       'Production curve with special order set'
    ImportFuelCurve(tech,time)                  'Total fuel use curve with special order set'
    Weights(tech,time)
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
    RealTimeBalance(area,energy,time)
    MaxBuyUp(area,energy,time)
    MaxBuyDown(area,energy,time)
    MaxSaleUp(area,energy,time)
    MaxSaleDown(area,energy,time)
* Demand
*    eqFLH(tech)
    DemandTime(area,energy,time)
*Mandate
    ElectricityPermission(energy)
* Pricing
;


*----------------------------------------------------------------------------------------------------------------------------------------------------
*Objective function
*----------------------------------------------------------------------------------------------------------------------------------------------------

Objective ..
    Cost =E=
* Fuelcost
   - sum((buyE(area,energy),time),price(area,energy,'import',time)*Buy(area,energy,time))
* Sales
  + sum((saleE(area,energy),time),price(area,energy,'export',time)*Sale(area,energy,time))
* O&M
*  - sum((tech),techdata(tech,'FixedOmcost'))
  - sum((TechToEnergy(tech,energy),time),Generation(tech,energy,time)*techdata(tech,'VariableOmcost'))
* Startup cost
  - sum((tech,time),Startcost(tech,time))
* Penalty for infeasable solution
  - penalty*sum((area,energy,time,dir),SlackDemand(area,energy,time,dir))
*Resrvation and activation revenues and costs
*Assets that consumes electricity, reservation payment
$IFI %Operation_Reserve_market%  == YES  + sum((Reserve(tech),time),ReserveCapPrices('Up',time)*CapacityReserved_Up(tech,time)*carriermix(tech,'import','electricity'))
$IFI %Operation_Reserve_market%  == YES  + sum((Reserve(tech),time),ReserveCapPrices('Down',time)*CapacityReserved_Down(tech,time)*carriermix(tech,'import','electricity'))
*Assets that generate electricity, reservation payment
$IFI %Operation_Reserve_market%  == YES  + sum((Reserve(tech),time),ReserveCapPrices('Up',time)*CapacityReserved_Up(tech,time)*carriermix(tech,'export','electricity'))
$IFI %Operation_Reserve_market%  == YES  + sum((Reserve(tech),time),ReserveCapPrices('Down',time)*CapacityReserved_Down(tech,time)*carriermix(tech,'export','electricity'))
*Fuel Cost when being activated
$IFI %Operation_Reserve_market%  == YES  - sum((BuyUpSet(area,energy),time),price(area,energy,'import',time)*Buy_Up(area,energy,time))
$IFI %Operation_Reserve_market%  == YES  + sum((BuyDownSet(area,energy),time),price(area,energy,'import',time)*Buy_Down(area,energy,time))
*Sales when being activated
$IFI %Operation_Reserve_market%  == YES  + sum((SellUpSet(area,energy),time),price(area,energy,'export',time)*Sale_Up(area,energy,time))
$IFI %Operation_Reserve_market%  == YES  - sum((SellDownSet(area,energy),time),price(area,energy,'export',time)*Sale_Down(area,energy,time))
*Cost of producing (check if works general and perhaps when participating those markets you have different costs)
$IFI %Operation_Reserve_market%  == YES  - sum((TechToEnergy(Reserve(tech),energy),time),Generation_UP(tech,energy,time)*techdata(tech,'VariableOmcost'))
$IFI %Operation_Reserve_market%  == YES  + sum((TechToEnergy(Reserve(tech),energy),time),Generation_Down(tech,energy,time)*techdata(tech,'VariableOmcost'))
;


*-------------------------------------------------------------------------------------------------------------------------
*Basic Fuel Conversion equations
*-------------------------------------------------------------------------------------------------------------------------
#Flows imported to technologies
Fuelmix(in(tech,energy),time)$(techdata(tech,'Capacity'))..
    carriermix(tech,'import',energy)*Fuelusetotal(tech,time)
    =E=
    Fueluse(tech,energy,time)
;

#flows exported from technologies, not for technologies with a storage and not for load dependency technologies
Production(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
$IFI %Operation_Efficiency_curves% == YES and not sum(step,curve(tech,step))
) ..
    carriermix(tech,'export',energy)*Fuelusetotal(tech,time)*techdata(tech,'Fe')
    =E=
    Generation(tech,energy,time)
;

*-------------------------------------------------------------------------------------------------------------------------
*-------------------------Load dependency curves-----------------------------------------------------------------------
*-------------------------------------------------------------------------------------------------------------------------
*TODO 06052022
*develp a way to be have the capacity and not definied a curve from excel


ImportFuelCurve(tech,time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
    and sum(step,curve(tech,step))) ..
    techdata(tech,'Capacity')*sum(step,Load(tech,time,step)*efficientcyCurve(tech,'import',step))
    =E=
    Fuelusetotal(tech,time)
;
* No need to multiply by *techdata(tech,'Fe'), due to SO2 variables.
ProductionFuelCurve(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
    and sum(step,curve(tech,step)))..
   carriermix(tech,'export',energy)* techdata(tech,'Capacity')*sum(step,Load(tech,time,step)*efficientcyCurve(tech,'export',step)*efficientcyCurve(tech,'import',step))
    =E=
    Generation(tech,energy,time)
;

*be careful !! equal to the online status do not forget we have unit commitement. If you put equal to 1 for convexity end up infeasible !! took couple of hours to understand!
Weights(tech,time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap')
    and sum(step,curve(tech,step)))..
    sum(step,Load(tech,time,step)) =E= Online(tech,time)
;


*-------------------------------------------------------------------------------------------------------------------------
*Reservation and activation market participation
*-------------------------------------------------------------------------------------------------------------------------

*For Up regulation activation fuel needed
FuelmixUp(in(tech,energy),time)$(techdata(tech,'Capacity') and (techdata(tech,'CapacityUP')))..
    carriermix(tech,'import',energy)*Fuelusetotal_Up(tech,time)
    =E=
    Fueluse_Up(tech,energy,time)
;

*For Up regulation generated fuel
ProductionUp(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap') and (techdata(tech,'CapacityUP'))
*    and sum(step,curve(tech,step))
) ..
    carriermix(tech,'export',energy)*Fuelusetotal_Up(tech,time)*techdata(tech,'Fe')
    =E=
    Generation_Up(tech,energy,time)
;

*For Down regulation activation fuel needed
FuelmixDown(in(tech,energy),time)$(techdata(tech,'Capacity') and techdata(tech,'CapacityDown'))..
    carriermix(tech,'import',energy)*Fuelusetotal_Down(tech,time)
    =E=
    Fueluse_Down(tech,energy,time)
;

*For Down regulation generated fuel
ProductionDown(out(tech,energy),time)$(techdata(tech,'Capacity') and not techdata(tech,'storageCap') and techdata(tech,'CapacityDown')
*    and sum(step,curve(tech,step))
) ..
    carriermix(tech,'export',energy)*Fuelusetotal_Down(tech,time)*techdata(tech,'Fe')
    =E=
    Generation_Down(tech,energy,time)
;


*Total level of acitivity, in case of Up activation
ReatTimeUpDeploymentUp(tech,time)$(techdata(tech,'Capacity') and techdata(tech,'CapacityUp')) ..
    Fuelusetotal_Up(tech,time)
    =E=
    ActivationProbability(time) * CapacityReserved_Up(tech,time)
;

*Total level of acitivity, in case of Down activation
ReatTimeUpDeploymentDown(tech,time)$(techdata(tech,'Capacity') and techdata(tech,'CapacityDown')) ..
    Fuelusetotal_Down(tech,time)
    =E=
    ActivationProbability(time) * CapacityReserved_Down(tech,time)
;

*Limit of total level of activity for Up max based on parameter definied in techdata
CapReservedUpMax(tech,time)$(techdata(tech,'Capacity') and techdata(tech,'CapacityUP')) ..
    CapacityReserved_Up(tech,time)
    =L=
    techdata(tech,'CapacityUp')*ReserveCap(tech,time)*profile(tech,time)
;

*Limit of total level of activity for Down max based on parameter definied in techdata
CapReservedDownMax(tech,time)$(techdata(tech,'Capacity') and techdata(tech,'CapacityDown')) ..
    CapacityReserved_Down(tech,time)
    =L=
    techdata(tech,'CapacityDown')*(1-ReserveCap(tech,time))*profile(tech,time)
;

$ontext
*Can not be reserved both for up and down
ComplementarityUpDownReservedCapacities(tech,time)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    UpCap(tech,time) + DownCap(tech,time)
    =L=
    1
;
$offtext

*Limit max on day ahead Fuelusetototal due to reservations, total capacity is splitted to reservation and day ahead
FuelusetotalDayAheadMax(tech,time)$(techdata(tech,'Capacity') and techdata(tech,'CapacityUP')) ..
    Fuelusetotal(tech,time)
    =L=
    techdata(tech,'Capacity')*profile(tech,time) - CapacityReserved_Up(tech,time)
;


*Limit min on day ahead Fuelusetototal due to reservations, if you are reserved for down regulation you should have at least the same activity level on the day ahead
FuelusetotalDayAheadMin(tech,time)$(techdata(tech,'Capacity') and techdata(tech,'CapacityDown')) ..
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



*------------------------------------------------------------------------------------------------------------------------------------
*Limitation on charging and discarging. (At the end more constraints for storages check!)
*------------------------------------------------------------------------------------------------------------------------------------


*The storage flows need to account for flows like (day ahead, down activation and up activation)
ProductionStorage(tech,time)$(techdata(tech,'storageCap')) ..
   Volume(tech,time)
    =E=
  techdata(tech,'InitialVolume')$(ord(time)=1) + Volume(tech,time--1)$(ord(time)>1)

  + Fuelusetotal(tech,time)*techdata(tech,'Fe')

  - sum(energy$out(tech,energy),(Generation(tech,energy,time))*carriermix(tech,'export',energy))

$IFI %Operation_Reserve_market%  == YES  + (Fuelusetotal_Up(tech,time)$Reserve(tech))*techdata(tech,'Fe')

$IFI %Operation_Reserve_market%  == YES  - (Fuelusetotal_Down(tech,time)$Reserve(tech))*techdata(tech,'Fe')

$IFI %Operation_Reserve_market%  == YES - sum(energy$out(tech,energy),(Generation_UP(tech,energy,time)$Reserve(tech))*carriermix(tech,'export',energy))

$IFI %Operation_Reserve_market%  == YES + sum(energy$out(tech,energy),(Generation_Down(tech,energy,time)$Reserve(tech))*carriermix(tech,'export',energy))
;

*Storage can not charge and discharge the same time, same applies with real time for the activation, the decision should have the same direction as the day ahead!
* Limit on charging Max Storage
ChargingStorageMax(tech,time)$(techdata(tech,'storageCap')) ..
    Fuelusetotal(tech,time)
$IFI %Operation_Reserve_market%  == YES + CapacityReserved_Up(tech,time)$Reserve(tech)
$IFI %Operation_Reserve_market%  == YES - CapacityReserved_Down(tech,time)$Reserve(tech)
    =L=
    techdata(tech,'Capacity')*Charge(tech,time)
;

* Limit on charging Min Storage
ChargingStorageMin(tech,time)$(techdata(tech,'storageCap') and techdata(tech,'minimum')) ..
    techdata(tech,'minimum')*Charge(tech,time)
    =L=
    Fuelusetotal(tech,time)
$IFI %Operation_Reserve_market%  == YES + CapacityReserved_Up(tech,time)$Reserve(tech)
$IFI %Operation_Reserve_market%  == YES - CapacityReserved_Down(tech,time)$Reserve(tech)
;

* Limit on discharging Max Storage
DisChargingStorageMax(tech,time)$(techdata(tech,'storageCap')) ..
    sum(energy$out(tech,energy),Generation(tech,energy,time)*carriermix(tech,'export',energy))
$IFI %Operation_Reserve_market%  == YES + sum(energy$out(tech,energy),Generation_UP(tech,energy,time)*carriermix(tech,'export',energy)$Reserve(tech))
$IFI %Operation_Reserve_market%  == YES - sum(energy$out(tech,energy),Generation_Down(tech,energy,time)*carriermix(tech,'export',energy)$Reserve(tech))
    =L=
    techdata(tech,'Capacity')*(1-Charge(tech,time))
;

* Limit on discharging Min Storage
DisChargingStorageMin(tech,time)$(techdata(tech,'storageCap') and techdata(tech,'minimum')) ..
    techdata(tech,'minimum')*(1-charge(tech,time))
    =L=
    sum(energy$out(tech,energy),Generation(tech,energy,time)*carriermix(tech,'export',energy))
$IFI %Operation_Reserve_market%  == YES + sum(energy$out(tech,energy),Generation_UP(tech,energy,time)*carriermix(tech,'export',energy)$Reserve(tech))
$IFI %Operation_Reserve_market%  == YES - sum(energy$out(tech,energy),Generation_Down(tech,energy,time)*carriermix(tech,'export',energy)$Reserve(tech))
;

$ontext
*In case a storage like 'caes' has 3 states of operation, you need to add another binary and acivate this constraint
*To do 06052022 you can discrease binaries to 1, and perhasp you do not need binaries at all.
*Can not charge - discharge at the same time
StatusStorageOp(tech,time)$(techdata(tech,'storageCap')) ..
    Charge(tech,time) + Discharge(tech,time)
    =L=
    1
;

$offtext


*------------------------------------------------------------------------------------------------------------------------------------
*Balance equations and Demand, connections among areas
*------------------------------------------------------------------------------------------------------------------------------------

* Must have capacity or opportunity to buy or sell on the day ahead
Balance(area,energy,time)$(buyE(area,energy) or saleE(area,energy)
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



* Must have capacity or opportunity to buy or sell for down reserve activation during real time
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

* Must have capacity or opportunity to buy or sell for up reserve activation during real time
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



$ontext

RealTimeBalance(area,energy,time)$((buyE(area,energy) or saleE(area,energy))
or sum(tech$(location(area,tech) and (in(tech,energy) or out(tech,energy))),techdata(tech,'Capacity'))
)..

  + Buy_Up(area,energy,time)$buyE(area,energy)
  - Buy_Down(area,energy,time)$buyE(area,energy)
  + Sum(areaIn$flowset(areaIn,area,energy),Flow_UP(areaIn,area,energy,time))
  - Sum(areaIn$flowset(areaIn,area,energy),Flow_Down(areaIn,area,energy,time))
  + sum(tech$(location(area,tech) and out(tech,energy)),Generation_Up(tech,energy,time)$Reserve(tech))
  - sum(tech$(location(area,tech) and out(tech,energy)),Generation_Down(tech,energy,time)$Reserve(tech))
    =E=
  + sum(tech$(location(area,tech) and in(tech,energy)),Fueluse_Up(tech,energy,time)$Reserve(tech))
  - sum(tech$(location(area,tech) and in(tech,energy)),Fueluse_Up(tech,energy,time)$Reserve(tech))
  + Sale_Up(area,energy,time)$saleE(area,energy)
  - Sale_down(area,energy,time)$saleE(area,energy)
  + Sum(areaOut$flowset(area,areaOut,energy),Flow_UP(area,areaOut,energy,time))
  - Sum(areaOut$flowset(area,areaOut,energy),Flow_Down(area,areaOut,energy,time))

;

$offtext



*Demand needs to be satisfied
DemandTime(area,energy,time)$sum(time1,demand(area,energy,time1)) ..
    Sale(area,energy,time) + SlackDemand(area,energy,time,'import') - SlackDemand(area,energy,time,'export')
$IFI %Operation_Reserve_market%  == YES + Sale_Up(area,energy,time)$saleE(area,energy)
$IFI %Operation_Reserve_market%  == YES - Sale_Down(area,energy,time)$saleE(area,energy)
    =G=
    demand(area,energy,time)
;

*Max Buy or sale regarding capacity of pipes or interconnector,
*TODO 06052022 Comment check if the interconnector will gain more capacity. Perhaps Buy_down needs to be removed same for the sale_down
MaxBuy(energy,time)$(sum(area,InterconnectorCapacity(area,energy,time))) ..
    sum(area,Buy(area,energy,time)$buyE(area,energy))
$IFI %Operation_Reserve_market%  == YES   + sum(area,Buy_Up(area,energy,time)$(buyE(area,energy) and sum(tech,techdata(tech,'CapacityUP'))))
$IFI %Operation_Reserve_market%  == YES   - sum(area,Buy_Down(area,energy,time)$(buyE(area,energy) and sum(tech,techdata(tech,'CapacityDown'))))
    =L=
    sum(area,InterconnectorCapacity(area,energy,time))/card(LinesInterconnectors)
;

MaxSale(energy,time)$(sum(area,InterconnectorCapacity(area,energy,time))) ..
    sum(area,Sale(area,energy,time)$saleE(area,energy))
$IFI %Operation_Reserve_market%  == YES  + sum(area,Sale_Up(area,energy,time)$(saleE(area,energy) and sum(tech,techdata(tech,'CapacityUP'))))
$IFI %Operation_Reserve_market%  == YES  - sum(area,Sale_down(area,energy,time)$(saleE(area,energy) and sum(tech,techdata(tech,'CapacityDown'))))
    =L=
    sum(area,InterconnectorCapacity(area,energy,time))/card(LinesInterconnectors)
;

*Limits on how much you can buy and sale on activation
MaxBuyUp(area,energy,time)$(BuyUpSet(area,energy))..
   Buy_Up(area,energy,time)
   =L=
   sum(tech$(in(tech,energy)),Fueluse_Up(tech,energy,time)$Reserve(tech))
;

MaxBuyDown(area,energy,time)$(BuyDownSet(area,energy) or buyE(area,energy))..
   Buy_Down(area,energy,time)
   =L=
   Buy(area,energy,time)
;


MaxSaleUp(area,energy,time)$(SellUpSet(area,energy))..
   Sale_Up(area,energy,time)
   =E=
   sum(tech$(out(tech,energy)),Generation_Up(tech,energy,time)$Reserve(tech))
;

MaxSaleDown(area,energy,time)$(SellDownSet(area,energy) or saleE(area,energy))..
   Sale_Down(area,energy,time)
   =L=
   sale(area,energy,time)
;

*------------------------------------------------------------------------------------------------------------------
*Technical constraints regarding unit commitment and ramp up rates and max prod
*------------------------------------------------------------------------------------------------------------------

*-Todo Check if the constraints work correctly insteda of capacity generationup? overestimate?
*Ramp constraints need to be adjusted regarding the reserves up/down to be accurate

RampUp(tech,time)$techdata(tech,'ramprate') ..
    techdata(tech,'ramprate')$(not UC(tech))
  + (techdata(tech,'ramprate')*Online(tech,time--1) + techdata(tech,'Minimum')*(1-Online(tech,time--1)))$UC(tech)
    =G=
    sum(energy$out(tech,energy), (Generation(tech,energy,time) - Generation(tech,energy,time--1))/techdata(tech,'FE')

*In case of UP activation
$IFI %Operation_Reserve_market%  == YES + CapacityReserved_Up(tech,time)$Reserve(tech)
        )
;

RampDown(tech,time)$techdata(tech,'ramprate') ..
    techdata(tech,'ramprate')$(not UC(tech))
  + (techdata(tech,'ramprate')*Online(tech,time) + techdata(tech,'Minimum')*(1-Online(tech,time)))$UC(tech)             # Changed from generation to total level, think ?devide by  techdata(tech,'Minimum')/techdata(tech,'Fe')?
    =G=
    sum(energy$out(tech,energy), (Generation(tech,energy,time--1) - Generation(tech,energy,time))/techdata(tech,'FE')

*In case of Down activation
$IFI %Operation_Reserve_market%  == YES - CapacityReserved_Down(tech,time)$Reserve(tech)
        )

;


* Capacity defined as constraint if binary needed
Capacity(UC(tech),time) ..
    (techdata(tech,'Capacity'))*Online(tech,time)
    =G=
    Fuelusetotal(tech,time)
*In case to schedule for up can not excited the capacity
$IFI %Operation_Reserve_market%  == YES + CapacityReserved_Up(tech,time)$Reserve(tech)
;

Minimumload(UC(tech),time)$techdata(tech,'minimum') ..
    Fuelusetotal(tech,time)
*In case is shut down and will operate only to provide up
$IFI %Operation_Reserve_market%  == YES + CapacityReserved_Up(tech,time)$Reserve(tech)
    =G=
    (techdata(tech,'Minimum'))*Online(tech,time)

;

Startupcost(UC(tech),time)$techdata(tech,'Startupcost') ..
    Startcost(tech,time)
    =G=
    techdata(tech,'Startupcost')*(Online(tech,time)-Online(tech,time--1))
;

*In case reserve add on is activates the following two constraints are redunant
FuelusetotalLimProfiles(tech,time)$sum(time1,profile(tech,time1) or techdata(tech,'Capacity'))..
    Fuelusetotal(tech,time)$sum(time1,profile(tech,time1))
    =L=
    techdata(tech,'Capacity')*profile(tech,time)
;

FuelusetotalLim(tech,time)$(techdata(tech,'Capacity') or  techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown')) ..
    Fuelusetotal(tech,time) =L=
    techdata(tech,'Capacity')
;

*----------------------------------------------------------------------------------------------------------------------------------------------
*Mandate
*----------------------------------------------------------------------------------------------------------------------------------------------

ElectricityPermission('electricity').. 

sum(time,sum((area)$buyE(area,'electricity'), Buy(area,'Electricity',time))) =L= ElectricityMandate * sum(time,sum((tech,area)$(location(area,tech) and in(tech,'electricity')),Fueluse(tech,'Electricity',time)));

*----------------------------------------------------------------------------------------------------------------------------------------------
*Variables limit so to avoid extra equations
*----------------------------------------------------------------------------------------------------------------------------------------------
* Storage volume circle
Volume.up(tech,time)=techdata(tech,'StorageCap');
Volume.fx(tech,time)$(techdata(tech,'StorageCap') and ord(time)=card(time)) = techdata(tech,'InitialVolume');

*hard constraints to push  storage discharge only as a day ahead decision
*Generation_Up.fx(tech,energy,time)$(techdata(tech,'storageCap'))   =0;
*Generation_Down.fx(tech,energy,time)$(techdata(tech,'storageCap')) =0;


*Buy only up regulation
$IFI %Only_UP_Regulation_Activation% == YES Buy_Down.fx('DK1','Electricity',time)=0;
*Only rene energy to electrolysis, 100% green
$IFI %Only_Green_Hydrogen% == YES Buy.fx('DK1','Electricity',time)=0;

*----------------------------------------------------------------------------------------------------------------------------------------------
*END

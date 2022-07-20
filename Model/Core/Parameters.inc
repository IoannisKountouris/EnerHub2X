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
     ReserveCapPrices(Service,time)
     ActivationProbability(time)
* Results Day ahead
$IFI %Operation_Reserve_market%  == NO    ResultT(resultset,tech,energy,time)
$IFI %Operation_Reserve_market%  == NO    ResultF(resultset,area,area,energy,time)
$IFI %Operation_Reserve_market%  == NO    ResultA(resultset,area,energy,time)
$IFI %Operation_Reserve_market%  == NO    ResultTsum(resultset,tech,energy)
$IFI %Operation_Reserve_market%  == NO    ResultFsum(resultset,area,area,energy)
$IFI %Operation_Reserve_market%  == NO    ResultAsum(resultset,area,energy)
$IFI %Operation_Reserve_market%  == NO    ResultC(resultset,tech,time)
$IFI %Operation_Reserve_market%  == NO    ResultCsum(resultset,tech)
* Results from Up/down reserve plus activation
$IFI %Operation_Reserve_market%  == YES     ResultT(service,resultset,tech,energy,time)
$IFI %Operation_Reserve_market%  == YES     ResultF(service,resultset,area,area,energy,time)
$IFI %Operation_Reserve_market%  == YES     ResultA(service,resultset,area,energy,time)
$IFI %Operation_Reserve_market%  == YES     ResultTsum(service,resultset,tech,energy)
$IFI %Operation_Reserve_market%  == YES     ResultFsum(service,resultset,area,area,energy)
$IFI %Operation_Reserve_market%  == YES     ResultAsum(service,resultset,area,energy)
$IFI %Operation_Reserve_market%  == YES     ResultC(service,resultset,tech,time)  #save the capacities reserved
$IFI %Operation_Reserve_market%  == YES     ResultCsum(service,resultset,tech)  #save the capacities reserved
$IFI %Operation_Reserve_market%  == YES     ResultEconomi(service,resultset)      #Save numbers
;

Scalar
    Errors  /0/
    penalty /100000/
    ElectricityMandate /0.10/
*Manual Parameters, prob to be activated to provide real time regulation

;

*Internal parameters used in the model
Parameters
itechdata(tech,dataset)
;

*----------------------------------------------------------------------------------------------------------------------------------------------
*END
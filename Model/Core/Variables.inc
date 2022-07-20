
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
*    Ramping(tech,time)
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
*    Discharge(tech,time)
*Participation in up/down
    ReserveCap(tech,time)
*    UpCap(tech,time)
*    DownCap(tech,time)
;

SOS2 Variables
    Load(tech,time,step)
;

*----------------------------------------------------------------------------------------------------------------------------------------------
*END
* Capacity
*Fuelusetotal.up(tech,time)=techdata(tech,'Capacity')/techdata(tech,'Fe');
*Fuelusetotal.up(tech,time)$sum(time1,profile(tech,time1))=techdata(tech,'Capacity')*profile(tech,time)/techdata(tech,'Fe');


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

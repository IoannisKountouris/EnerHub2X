* OP2X model 23/05/2022
* Developed by DTU management and Ea Energy Analysis
*Ioannis Kountouris and Lissy Langer

*--------------------------------------------------------------------------------------------------------------------
*TO DO


*--------------------------------------------------------------------------------------------------------------------
*Open questions


*--------------------------------------------------------------------------------------------------------------------
* Options for solver
*Gurobi license
*GRB_LICENSE_FILE=C:\Users\iokoun\Desktop\Local SuperP2G\Model\y\gurobi.lic

* Sets # as comment sign
$EOLCOM #

* Limit on printing in lst-file of equations and variables for debuging
option limrow=10000;
option limcol=10000;

*relative gap in case of MIP the compute time is heavily increased do not use that if running a whole year
option optcr=0.0015, reslim=2500;

*Solver selection
*option  mip = GAMSCHK

*Options for CPLEX
option  mip = CPLEX

*Option to use gurobo only if you have the license
*option  mip = GUROBI
*--------------------------------------------------------------------------------------------------------------------
*Set number of decimals to print out
*Option DECIMALS=3;

* Run options
$setglobal MAKESQL     NO                       # Save run in database [yes/no]
$setglobal PROJECTID   GLS                      # Name of project in database
$setglobal CASEID      IK_testmandate               # Name of case in database
*--------------------------------------------------------------------------------------------------------------------
*Write excel results (works only for microsoft not ios)
$setglobal WriteXLSX                           NO

*--------------------------------------------------------------------------------------------------------------------
*Technical constraints options
*--------------------------------------------------------------------------------------------------------------------
*unit commitment activated (YES/NO)
$setglobal Unit_Commitment                     YES

*Assume all assets have zero constraints on ramping rates, activate ramp rates (YES/NO)
$setglobal Ramp_rates                          YES

*To do fix the code and implementation to include activation quantities (YES/NO)
$setglobal Operation_Efficiency_curves         NO

*--------------------------------------------------------------------------------------------------------------------
*Reservation and activation market options
*--------------------------------------------------------------------------------------------------------------------
*Activate Reservation market capacities with activation (YES/NO)
$setglobal Operation_Reserve_market            NO

*Activation probability based on random probabilities or a scalar (YES if random/NO if scalar, insert exogenous as parameter)
$setglobal Random_probability_of_activation    NO

*In case of DK1 provide only up regulation will be activatied.
$setglobal Only_UP_Regulation_Activation       NO

*--------------------------------------------------------------------------------------------------------------------
*General options
*--------------------------------------------------------------------------------------------------------------------
*FutureTechnologies to add in the model (based on the set Future set, look at the data xlsx) (YES/NO)
$setglobal FutureTech                          NO

*Green Electricity, skive does not buy from the grid even if the prices are zero
$setglobal Only_Green_Hydrogen                 NO

*Set a limit of 10% buying from the grid even when the price is cheap, go to parameter change the value of scalar
$setglobal ElectricityMandate                  NO 

*End of options

*--------------------------------------------------------------------------------------------------------------------
*Load the parameters of the model
*--------------------------------------------------------------------------------------------------------------------
$INCLUDE '../model/Core/Sets.inc';
*--------------------------------------------------------------------------------------------------------------------

*--------------------------------------------------------------------------------------------------------------------
*Load the parameters of the model
*--------------------------------------------------------------------------------------------------------------------
$INCLUDE '../model/Core/Parameters.inc';
*--------------------------------------------------------------------------------------------------------------------

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

*--------------------------------------------------------------------------------------------------------------------
*Define options and decisions
*--------------------------------------------------------------------------------------------------------------------

*If unit commitment is off then no minimum restrictions
$IFtheni  %Unit_Commitment%    ==    NO
techdata(tech,'Minimum') = 0;
$ENDIF
*--------------------------------------------------------------------------------------------------------------------
*If Ramp rates are not biniding then ramp rates will go to zero
$IFtheni  %Ramp_rates%    ==    NO
techdata(tech,'RampRate') = 0;
$ENDIF

Display techdata ;

*--------------------------------------------------------------------------------------------------------------------
*If not interested for participating in reservation activation market, you have no available capacity
$IFtheni  %Operation_Reserve_market%    ==    NO
techdata(tech,'CapacityDown')=0;
techdata(tech,'CapacityUP')=0;


Display techdata;

$ENDIF
*--------------------------------------------------------------------------------------------------------------------
*If you want to run a scenario without new technologies shut down their operation.
$ifi not %FutureTech% == NO $goto MISS_new_technologies
profile(FutureTech(tech),time)=EPS;
$label MISS_new_technologies

Display tech,profile;

*$exit


*--------------------------------------------------------------------------------------------------------------------
*Sensitivity analysis

*techdata('OnshoreWind','CapacityDown')=10;
*techdata('OnshoreWind','CapacityUP')=10;
*techdata('SolarPV','CapacityDown')=10;
*techdata('SolarPV','CapacityUP')=10;
*Update the cap of electrolysis
techdata('Electrolysis','Capacity')=techdata('Electrolysis','Capacity')*100/12;

*techdata('Electrolysis','VariableOmcost')= -20; 
*--------------------------------------------------------------------------------------------------------------------
*test parameters

techdata('HydrogenStorage','InitialVolume')=0;
techdata('ElectricStorage','InitialVolume')=0;

*--------------------------------------------------------------------------------------------------------------------
* Assigning sets and parameter manipulation (important for the user to understand the following lines of code)
*--------------------------------------------------------------------------------------------------------------------

*Save the techdata before changes or adjustments
itechdata(tech,dataset) = techdata(tech,dataset);

* Input and output energy types of technologies
in(tech,energy)$carriermix(tech,'import',energy)=yes;
out(tech,energy)$carriermix(tech,'export',energy)=yes;

* Unit commitment technologies
UC(tech)$techdata(tech,'Minimum') = YES;

*Scale up the minimum level to activity level, the minimum level is percentage % of the capacity, only for the UC technologies
techdata(UC,'Minimum') = sum(energy,carriermix(UC,'import',energy)) * techdata(UC,'capacity')* techdata(UC,'Minimum') ;

*Technologies that have a ramp rate limitation
RR(tech)$techdata(tech,'RampRate') = YES;

*Scale up the ramp rate of every technology, linkking two total activity levels
techdata(RR,'RampRate') = sum(energy,carriermix(RR,'import',energy)) * techdata(RR,'capacity')* techdata(RR,'RampRate') ;

*Technologies that cab provide reserve services
Reserve(tech)$(techdata(tech,'CapacityUP') or techdata(tech,'CapacityDown'))= YES;


*Scale up the capacity allocated for reservation (UP/Down). The capacity is assigned as a percentage of the total capacity of the technology
techdata(Reserve,'CapacityUP')   = sum(energy,carriermix(Reserve,'import',energy)) * techdata(Reserve,'capacity')*techdata(Reserve,'CapacityUP');
techdata(Reserve,'CapacityDown') = sum(energy,carriermix(Reserve,'import',energy)) * techdata(Reserve,'capacity')*techdata(Reserve,'CapacityDown');


*Scalling up the capacity to the maximum available activity level. Do not change the orderd of equations, techdata is changing as a parameter after that point!
techdata(tech,'capacity') = sum(energy,carriermix(tech,'import',energy))*techdata(tech,'capacity');

*Lik technologies with the x energy flow that were designed (i.e., normalized flows to 1)
TechToEnergy(tech,energy) = YES$(carriermix(tech,'export',energy) = 1);

Display UC, RR,techdata,TechToEnergy;


*$exit

* Efficiency connecting total imported fuels to export fuels
techdata(tech,'Fe')=sum(energy,carriermix(tech,'export',energy))/sum(energy,carriermix(tech,'import',energy));

*Estimating the share of flows (be careful the carriermix calculation change the parameter!)
carriermix(tech,'export',energy)=carriermix(tech,'export',energy)/sum(energy1,carriermix(tech,'export',energy1));
carriermix(tech,'import',energy)=carriermix(tech,'import',energy)/sum(energy1,carriermix(tech,'import',energy1));

buyE(area,energy)$sum(time,price(area,energy,'import',time))= YES;
saleE(area,energy)$(sum(time,price(area,energy,'export',time)) or sum(time,demand(area,energy,time)) ) = YES;

* Test for efficientcy curve (first step can be {0,0})
curve(tech,step)$sum(dir,efficientcyCurve(tech,dir,step))= YES;
curve(tech,'step1')$sum(step,curve(tech,step))= YES;

*Lines of interconnectors and areas
LinesInterconnectors(area)$sum((energy,time),InterconnectorCapacity(area,energy,time))= YES;


Display saleE,buyE,LinesInterconnectors,ReserveCapPrices,carriermix ;


Parameter
Slack(area,energy)
;

slack(area,energy)=sum(tech$(buyE(area,energy) and (in(tech,energy) or out(tech,energy))),(techdata(tech,'CapacityUP')));


*Available flows to satisfy the activation demand
BuyUpSet(area,energy)$sum(tech,(buyE(area,energy) and techdata(tech,'CapacityUP')))=yes;
BuyDownSet(area,energy)$sum(tech,(buyE(area,energy) and techdata(tech,'CapacityDown')))=yes;
SellUpSet(area,energy)$sum(tech,(saleE(area,energy) and techdata(tech,'CapacityUP')))=yes;
SellDownSet(area,energy)$sum(tech,(saleE(area,energy) and techdata(tech,'CapacityDown')))=yes;

Display Slack,SellUpSet,SellDownSet,BuyUpSet,BuyDownSet, Reserve;

*Actiavation probabilities, sampling from uniform dist or not (for consistent results use the single value)
$IFI %Random_probability_of_activation% == YES ActivationProbability(time) = uniform(0,0.3);
$IFI %Random_probability_of_activation% == NO  ActivationProbability(time) = 0.3;



Display ActivationProbability;
*$exit


*--------------------------------------------------------------------------------------------------------------------
* Error checking
*--------------------------------------------------------------------------------------------------------------------
*Load the error checking code of the model
$INCLUDE '../model/Error Checking/Error Checking.inc';
*--------------------------------------------------------------------------------------------------------------------


*--------------------------------------------------------------------------------------------------------------------
*Load the variables of the model
*--------------------------------------------------------------------------------------------------------------------
$INCLUDE '../model/Core/variables.inc';
*--------------------------------------------------------------------------------------------------------------------


*--------------------------------------------------------------------------------------------------------------------
*Load equations of the model
*--------------------------------------------------------------------------------------------------------------------
$INCLUDE '../model/Core/Equations.inc';
*--------------------------------------------------------------------------------------------------------------------


*--------------------------------------------------------------------------------------------------------------------
* Model and solve
*--------------------------------------------------------------------------------------------------------------------
$INCLUDE '../model/Core/ModelDefinition.inc';

*Optfile
*P2Xmodel.optfile=1;

*Solve statement
Solve P2Xmodel maximizing cost using mip;


*$onecho > cplex.opt
*option  datacheck=2
*$offecho

*--------------------------------------------------------------------------------------------------------------------
Display Fueluse.l, Fuelusetotal.l, generation.l, volume.l,buy.l,sale.l,SlackDemand.l,online.l,flow.l,Balance.m,charge.l,Startcost.l,fuelmix.m;
$IFI %Operation_Efficiency_curves% == YES  Display Load.l;

$IFtheni  %Operation_Reserve_market%    ==    YES
Display CapacityReserved_Up.l,CapacityReserved_Down.l,ReserveCap.l,Buy_Up.l,Buy_Down.l,Sale_Up.l,Sale_Down.l,Fuelusetotal_Up.l,Fuelusetotal_Down.l
Fueluse_Up.l,generation_Up.l,Fueluse_Down.l,generation_Down.l,Flow_Down.l,Flow_UP.l ;
$ENDIF


*--------------------------------------------------------------------------------------------------------------------


*----------------------------------------------------------------------------------------------------------------------------------------------
*Write results
$INCLUDE '../model/PostSolve/WriteResults.inc';
*----------------------------------------------------------------------------------------------------------------------------------------------
*END

Parameter
test(tech,time)
;

test(tech,time) = sum(energy$out(tech,energy), (Generation.l(tech,energy,time) - Generation.l(tech,energy,time--1))/techdata(tech,'FE'));

Display test ;

$ontext
set
itech(tech)
IA(tech)
;

IA(tech) = YES;
itech(tech) = IA(tech) - FutureTech(tech);
$offtext

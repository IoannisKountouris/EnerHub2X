*model definition

Model P2Xmodel /
                                                      Objective
                                                      Fuelmix
$IFI %Operation_Efficiency_curves%  == YES            ImportFuelCurve
$IFI %Operation_Efficiency_curves%  == YES            ProductionFuelCurve
$IFI %Operation_Efficiency_curves%  == YES            Weights
                                                      Production
                                                      ProductionStorage
                                                      ChargingStorageMax
                                                      ChargingStorageMin
                                                      DisChargingStorageMax
                                                      DisChargingStorageMin
*                                                     StatusStorageOp                                 #activate only when you have 3 states storages
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
$IFI %ElectricityMandate%  == YES                     ElectricityPermission
*Reserve market Equations
$IFI %Operation_Reserve_market%  == YES               FuelmixUp
$IFI %Operation_Reserve_market%  == YES               ProductionUp
$IFI %Operation_Reserve_market%  == YES               FuelmixDown
$IFI %Operation_Reserve_market%  == YES               ProductionDown
$IFI %Operation_Reserve_market%  == YES               ReatTimeUpDeploymentUp
$IFI %Operation_Reserve_market%  == YES               ReatTimeUpDeploymentDown
$IFI %Operation_Reserve_market%  == YES               CapReservedUpMax
$IFI %Operation_Reserve_market%  == YES               CapReservedDownMax
$IFI %Operation_Reserve_market%  == YES               FuelusetotalDayAheadMax
$IFI %Operation_Reserve_market%  == YES               FuelusetotalDayAheadMin
$IFI %Operation_Reserve_market%  == YES               BalanceUp
$IFI %Operation_Reserve_market%  == YES               BalanceDown
$IFI %Operation_Reserve_market%  == YES               MaxBuyUp
$IFI %Operation_Reserve_market%  == YES               MaxBuyDown
$IFI %Operation_Reserve_market%  == YES               MaxSaleUp
$IFI %Operation_Reserve_market%  == YES               MaxSaleDown
/;


*----------------------------------------------------------------------------------------------------------------------------------------------
*END
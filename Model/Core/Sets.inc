Sets
    resultset                                   'Elements for result printing'
    area                                        'Areas for grouping of technologies into demand and price areas'
    tech                                        'Technologies'
    dir                                         'Direction of flow [import/export]'
    energy                                      'Types of energy'
    step                                        'Steps in efficientcy curve'
    color                                       'Color of energies for plot'
    time                                        'Time steps'
    scenario                                    'Name of scenarios'
    Service                                     'can be day ahead up, down'
    dataset
    location(area,tech)                         'Mapping set of technologies to areas'
    flowset(area,area,energy)                   'Mapping set of flows between areas'
    out(tech,energy)                            'Maping set  of output flows per technology'
    in(tech,energy)                             'Mapping set of input flows per technology'
    buyE(area,energy)                           
    saleE(area,energy)
    ecolor(energy,color)
    curve(tech,step)
    UC(tech)                                     'Unit commitment technologies'
    RR(tech)                                     'Ramp rate technologies'
    resultset
    pricingType
    units                                         'Different fysical units forms'
    LinesInterconnectors(area)
    FutureTech(tech)
    TechToEnergy(tech,energy)                     'Link the technology with the fuel/energy which was designed and constraint e.g., electrolyzer to hydrogen, Methanol plant to methanol etc'

*Sets for the reservation addon
    BuyUpSet(area,energy)
    BuyDownSet(area,energy)
    SellUpSet(area,energy)
    SellDownSet(area,energy)
    Reserve(tech)                                   'technologies that can provide reserve'
;
alias(area,areaIn,AreaOut);
alias(tech,tech1);
alias(step,step1);
alias(time,time1);
alias(energy,energy1);

*----------------------------------------------------------------------------------------------------------------------------------------------
*END
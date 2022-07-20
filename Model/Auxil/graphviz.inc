put graphfile;
Put 'digraph {' / / ;

Put 'Import;' /;
Loop(ecolor(energy,color)$sum(area,buyE(area,energy)),
    if(sum(area,Buy.l(area,energy,time)),
        Put 'Import -> ' energy.tl '[color=' color.tl ',label=' sum(area,Buy.l(area,energy,time)) '];' /;
    else
        Put 'Import -> ' energy.tl '[color=' color.tl ',style=dashed];' /;
    );
);

loop(tech,
    put '  ' tech.tl '[shape=box';
    if(Volume.l(tech,time),
        Put ',label="' tech.tl:0:0 ' \n ' Volume.l(tech,time):0:2'"';
    );
    Put '];' /;
);

Loop(ecolor(energy,color),
    put energy.tl '[style=filled, color=' color.tl '];'/;
);

Loop((in(tech,energy),color)$ecolor(energy,color),
    if(fueluse.l(tech,energy,time),
        put energy.tl '->' tech.tl '[color=' color.tl ',label=' fueluse.l(tech,energy,time) '];' /;
    else
        put energy.tl '->' tech.tl '[color=' color.tl ',style=dashed];' /;
    )
);

Loop((out(tech,energy),color)$ecolor(energy,color),
    if(generation.l(tech,energy,time),
        put tech.tl '->' energy.tl '[color=' color.tl ',label=' generation.l(tech,energy,time) '];' /;
    else
        put tech.tl '->' energy.tl '[color=' color.tl ',style=dashed];' /;
    );
);

Put 'Export;' /;
Loop(ecolor(energy,color)$sum(area,saleE(area,energy)),
    if(sum(area,Sale.l(area,energy,time)),
        Put energy.tl ' -> Export [color=' color.tl ',label=' sum(area,Sale.l(area,energy,time)) '];' /;
    else
        Put energy.tl ' -> Export [color=' color.tl ',style=dashed];' /;
    );
);
Put 'labelloc="t";' /;
Put 'label="' time.tl:0:0 '";' /;
Put '}';
putclose;

Putclose batfile 'dot network.txt -Tpng -o "network-'time.tl:0:0'.png"';
execute 'temp.bat';

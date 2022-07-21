$ifthen EXIST '../data/%1.inc'
$INCLUDE      '../data/%1.inc'
$else
$abort 'Missing data %1'
$endif

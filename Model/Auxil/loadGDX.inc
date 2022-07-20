$ifthen EXIST '../data/%1.gdx'
$GDXin ../data/%1.gdx
$loaddc %1
$GDXin
$else
$abort 'Missing data %1'
$endif
File errorlog /'../Error/errorlog.txt'/;
put errorlog;
Put 'Input data errors:' / / ;





if(Errors,
    Put /;
    Put Errors:0:0 ' input errors!';
else
    Put 'Not input errors.';
);


*----------------------------------------------------------------------------------------------------------------------------------------------
*END

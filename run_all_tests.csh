#!/bin/csh -f

set i=1
set max_test_nr=37
set score=(4 4 3 3 3 3 4 2 4 4 4 4 4 4 2 2 10 4 2 5 3 1 1 1 1 4 3 1 2 1 1 1 1 1 1 1 1)

while (${i} <= ${max_test_nr} )
    ./test/test.csh $i
    if ($status != 0) then
       echo "Test ${i}: 0 / $score[$i]"
    else
       echo "Test ${i}: $score[$i] / $score[$i]"
    endif
    set i=`expr ${i} + 1`
end

#!/bin/csh -f

set values=(4 4 3 3 3 3 4 2 4 4 4 4 4 4 2 2 10 4 2 5 3 1 1 1 1 4 3 1 2 1 1 1 1 1 1 1 1)
set failing_tests=()
set score=0

foreach i (1 2 3 4 5 7 9 10 11 13 15 17 19 23 25 31 33 35 37)
    ./test/test.csh $i
    if ($status != 0) then
       echo "Test ${i}: 0 / $values[$i]"
       set failing_tests=($failing_tests $i)
    else
       set score=`expr ${score} + $values[$i]`
    endif
    set i=`expr ${i} + 1`
end

if (${#failing_tests} != 0) then
  printf '\nFailing Tests:'
  printf '\n=================\n'
  foreach test (${failing_tests})
    echo -n "${test} "
  end
  printf '\n'
endif

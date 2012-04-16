#!/bin/csh -f

set failing_tests=()

foreach i (1 2 3 4 5 7 9 10 11 13 15 17 19 23 25 31 33 35 37)
    ./test/test.csh $i
    if ($status != 0) then
       set failing_tests=($failing_tests $i)
    else
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

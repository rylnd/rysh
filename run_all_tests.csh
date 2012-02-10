#!/bin/csh -f

set i=1
set max_test_nr=37
set values=(4 4 3 3 3 3 4 2 4 4 4 4 4 4 2 2 10 4 2 5 3 1 1 1 1 4 3 1 2 1 1 1 1 1 1 1 1)
set failing_tests=()
set score=0

while (${i} <= ${max_test_nr} )
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
endif

printf '\n\n=================\n'
echo -n "Total : ${score} /  100"
printf '\n=================\n\n'

#!/bin/csh -f

set i=1
set max_test_nr=37
set total=0
set max_total=0
set grade_file=grade.txt
set score=(4 4 3 3 3 3 4 2 4 4 4 4 4 4 2 2 10 4 2 5 3 1 1 1 1 4 3 1 2 1 1 1 1 1 1 1 1)

if (-e ${grade_file}) then
    rm -f ${grade_file}
endif
echo "" > ${grade_file}
echo "**************" >> ${grade_file}
echo " Score for P2" >> ${grade_file}
echo "**************" >> ${grade_file}
echo "" >> ${grade_file}
echo "" >> ${grade_file}

cp -f /afs/cs.wisc.edu/p/course/cs537-remzi/ta/p2/myprog .

while (${i} <= ${max_test_nr} )
  
    ./test.csh $i
    if ($status != 0) then
       echo "Test ${i}: 0 / $score[$i]" >> ${grade_file}
    else
       echo "Test ${i}: $score[$i] / $score[$i]" >> ${grade_file}
       set total=`expr ${total} + $score[$i]`
    endif
    set max_total=`expr ${max_total} + $score[$i]`
    set i=`expr ${i} + 1`
end

rm -f myprog

echo "" >> ${grade_file}
echo "" >> ${grade_file}
echo "------------------" >> ${grade_file}
echo "Total  : ${total} / ${max_total} " >> ${grade_file}
echo "------------------" >> ${grade_file}

#!/bin/csh -f

if ($#argv != 1) then
    echo "Usage: ./test.csh <test_nr>"
    exit 1
endif

set test_nr=$1
set test_input_dir="./test/data/"
set test_out_dir="./test/output/"

switch($test_nr)
case 1:
    if (-f makefile || -f Makefile || -f MAKEFILE) then
        if (-f README* || -f Readme* || -f readme*) then
           goto pass
        else
           echo "ERROR: README file not present"
           goto fail
        endif
    else
        echo "ERROR: makefile not present"
        goto fail
    endif
breaksw
case 2:
    rm -f rysh
    make >& /dev/null
    if (! -f rysh) then
           echo "ERROR: not compilable using make"
           goto fail
    endif
breaksw
case 3:
    if(! -f rysh) then
       echo "Please compile rysh before running this Test"
       goto fail
    endif
    (./rysh test1 test2 > /dev/null) >& test${test_nr}.err
    if($status == 139) then
       goto fail
    endif
    diff test${test_nr}.err ${test_out_dir}err >& /dev/null
    if ($status != 0) then
       echo "ERROR: Does not check for the appropriate number of cmd-line arugments"
       goto fail
    endif
breaksw
case 4:
    if(! -f rysh) then
       echo "Please compile rysh before running this Test"
       goto fail
    endif
    (./rysh invalid_input_file_xyz > /dev/null) >& test${test_nr}.err
    if($status == 139) then
       goto fail
    endif
    diff test${test_nr}.err ${test_out_dir}err >& /dev/null
    if ($status != 0) then
        echo "ERROR: does not check whether input file is valid"
        goto fail
    endif
breaksw
case 23:
case 25:
case 31:
case 33:
case 35:
    if(! -f rysh) then
       echo "Please compile rysh before running this Test"
       goto fail
    endif
    (./rysh ${test_input_dir}test${test_nr} > /dev/null) >& test${test_nr}.err
    if($status == 139) then
       goto fail
    endif
    diff test${test_nr}.err ${test_out_dir}err >& /dev/null
    if ($status != 0) then
        goto fail
    endif
breaksw
case 12:
    if(! -f rysh) then
       echo "Please compile rysh before running this Test"
       goto fail
    endif
    (./rysh ${test_input_dir}test${test_nr} > test${test_nr}.out) >& test${test_nr}.err
    if($status == 139) then
       goto fail
    endif
    diff test${test_nr}.out ${test_out_dir}test${test_nr}.out >& /dev/null
    if ($status != 0) then
       goto fail
    endif
    diff test${test_nr}.err ${test_out_dir}err >& /dev/null
    if ($status != 0) then
        goto fail
    endif
breaksw

case 10:
    if(! -f rysh) then
       echo "Please compile rysh before running this Test"
       goto fail
    endif
    (./rysh ${test_input_dir}test${test_nr} > /dev/null) >& test${test_nr}.out
    if ($status != 0) then
        goto fail
    else
       set x=`more test${test_nr}.out | wc -l`
       if($x != 0) then
           goto fail
       endif
    endif
breaksw
case 5:
case 7:
case 9:
case 11:
case 13:
case 15:
case 17:
case 19:
    if(! -f rysh) then
       echo "Please compile rysh before running this Test"
       goto fail
    endif
    /bin/csh -f ${test_input_dir}test${test_nr}.csh >& test${test_nr}.csh.out
    ./rysh ${test_input_dir}test${test_nr} >& test${test_nr}.out
    if ($status != 0) then
       goto fail
    endif
    diff test${test_nr}.out test${test_nr}.csh.out >& /dev/null
    if ($status != 0) then
       goto fail
    endif
breaksw
case 21:
case 27:
    if(! -f rysh) then
       echo "Please compile rysh before running this Test"
       goto fail
    endif
    rm -f out1 out2 out3 out1.cshell out2.cshell out3.cshell
    /bin/csh -f ${test_input_dir}test${test_nr}.csh >& test${test_nr}.csh.out
    if(-f out1) then
        mv out1 out1.cshell
    endif
    if(-f out2) then
        mv out2 out2.cshell
    endif
    if(-f out3) then
        mv out3 out3.cshell
    endif
    ./rysh ${test_input_dir}test${test_nr} >& test${test_nr}.out
    if($status != 0) then
        goto fail
    endif
    diff test${test_nr}.out test${test_nr}.csh.out >& /dev/null
    if ($status != 0) then
       goto fail
    elif(-f out1.cshell) then
          diff out1.cshell out1 >& /dev/null
          if($status != 0) then
             goto fail
          elif(-f out2.cshell) then
                diff out2.cshell out2 >& /dev/null
                if($status != 0) then
                   goto fail
                elif(-f out3.cshell) then
                      diff out3.cshell out3 >& /dev/null
                      if($status !=0) then
                         goto fail
                      endif
                endif
          endif
    endif
breaksw
case 29:
    if(! -f rysh) then
       echo "Please compile rysh before running this Test"
       goto fail
    endif
    rm -f out1.gz
    /bin/csh -f ${test_input_dir}test${test_nr}.csh >& /dev/null
    mv out1.gz out1.cshell.gz
    ./rysh ${test_input_dir}test${test_nr} >& /dev/null
    if($status != 0) then
       goto fail
    endif

    gunzip out1.cshell.gz
    if($status != 0) then
       goto fail
    endif
    gunzip out1.gz
    if($status != 0) then
       goto fail
    endif
    diff out1.cshell out1 >& /dev/null
    if($status != 0) then
       goto fail
    endif
breaksw
case 37:
    if(! -f rysh) then
       echo "Please compile rysh before running this Test"
       goto fail
    endif
    rm -f out1.gz
    /bin/csh -f ${test_input_dir}test${test_nr}.csh >& /dev/null
    mv out1.gz out1.cshell.gz
    mv out2.gz out2.cshell.gz
    ./rysh ${test_input_dir}test${test_nr} >& /dev/null
    if($status != 0) then
       goto fail
    endif

    gunzip out1.cshell.gz
    if($status != 0) then
       goto fail
    endif
    gunzip out1.gz
    if($status != 0) then
       goto fail
    endif
    diff out1.cshell out1 >& /dev/null
    if($status != 0) then
       goto fail
    endif

    gunzip out2.cshell.gz
    if($status != 0) then
       goto fail
    endif
    gunzip out2.gz
    if($status != 0) then
       goto fail
    endif
    diff out2.cshell out2 >& /dev/null
    if($status != 0) then
       goto fail
    endif
breaksw
default:
   echo "Invalid <test_nr> option used"
   exit 1
breaksw
endsw

pass:
   if(-f test${test_nr}.err) then
          rm -f test${test_nr}.err
   endif
   if(-f test${test_nr}.out) then
          rm -f test${test_nr}.out
   endif
   if(-f test${test_nr}.csh.out) then
          rm -f test${test_nr}.csh.out
   endif
   if(-f out1.cshell) then
          rm -f out1.cshell
   endif
   if(-f out2.cshell) then
          rm -f out2.cshell
   endif
   if(-f out3.cshell) then
          rm -f out3.cshell
   endif
   if(-f out1) then
          rm -f out1
   endif
   if(-f out2) then
          rm -f out2
   endif
   if(-f out3) then
          rm -f out3
   endif
   rm -f out1.gz out2.gz out1.cshell.gz out2.cshell.gz
   echo "Test ${test_nr}: Pass"
   exit 0
fail:
   if(-f test${test_nr}.err) then
          rm -f test${test_nr}.err
   endif
   if(-f test${test_nr}.out) then
          rm -f test${test_nr}.out
   endif
   if(-f test${test_nr}.csh.out) then
          rm -f test${test_nr}.csh.out
   endif
   if(-f out1.cshell) then
          rm -f out1.cshell
   endif
   if(-f out2.cshell) then
          rm -f out2.cshell
   endif
   if(-f out3.cshell) then
          rm -f out3.cshell
   endif
   if(-f out1) then
          rm -f out1
   endif
   if(-f out2) then
          rm -f out2
   endif
   if(-f out3) then
          rm -f out3
   endif
   rm -f out1.gz out2.gz out1.cshell.gz out2.cshell.gz
   exit 1


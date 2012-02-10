echo "./test/testprog 234 123 : out1.gz ; cat test.csh : out2.gz"
./test/testprog 234 123 | `which gzip` > out1.gz ; cat test.csh | `which gzip` > out2.gz

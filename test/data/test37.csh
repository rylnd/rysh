echo "./test/testprog 234 123 : out1.gz ; cat test.csh : out2.gz"
./test/testprog 234 123 | /usr/bin/gzip > out1.gz ; cat test.csh | /usr/bin/gzip > out2.gz

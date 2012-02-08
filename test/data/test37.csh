echo "./myprog 234 123 : out1.gz ; cat test.csh : out2.gz"
./myprog 234 123 | /bin/gzip > out1.gz ; cat test.csh | /bin/gzip > out2.gz

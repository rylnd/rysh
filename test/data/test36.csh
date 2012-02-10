echo "cal : out1.gz ; pwd"
cal | `which gzip` > out1.gz ; pwd

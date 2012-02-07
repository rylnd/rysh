SRCS = rysh.c
OBJS = $(SRCS:.c=.o)
CC   = gcc
OPTS = -Wall -D_GNU_SOURCE

all: rysh

%.o: %.c
	gcc $(OPTS) -c $< -o $@

rysh: $(OBJS)
	gcc -o rysh $(OBJS) -Wall

clean:
	rm -f $(OBJS) main


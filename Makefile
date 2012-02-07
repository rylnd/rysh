SRCS = myshell.c
OBJS = $(SRCS:.c=.o)
CC   = gcc
OPTS = -Wall -D_GNU_SOURCE

all: myshell

%.o: %.c
	gcc $(OPTS) -c $< -o $@

myshell: $(OBJS)
	gcc -o myshell $(OBJS) -Wall

clean:
	rm -f $(OBJS) main


SDIR = src
ODIR = obj
TARGET = rysh
SRC = rysh.c
OBJ = rysh.o
OPTS = -Wall -D_GNU_SOURCE

all: $(TARGET)

$(TARGET) : $(ODIR)/$(OBJ)
	gcc -o $(TARGET) $< -Wall

$(ODIR)/%.o : $(SDIR)/%.c
	-mkdir -p $(ODIR)
	gcc $(OPTS) -c $< -o $@

clean:
	rm -rf $(TARGET) $(ODIR)

.PHONY: all clean

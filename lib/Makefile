
.PHONY: all clean

all: getlnenv.o

clean:
	rm getlnenv.o

%.o: %.s
	HAS060 -m 68000 -o $@ $<

# makefile for test example, including gtools
# makefile.  Generated from makefile.in by configure.

SHELL=/bin/bash
CC=/usr/bin/llvm-gcc-4.2 
CC=/usr/bin/clang
#CC=gcc
## tested on all three compilers for Max OS X; gcc is the most generic.

CFLAGS=-O3 `gsl-config --cflags`
LFLAGS=`gsl-config --libs`

OBJ = ising.o

all : main.c $(OBJ)
	${CC} $^ -o ising ${CFLAGS} ${LFLAGS}

ising.o: ising.c
	${CC} $^ ${CFLAGS} -c

clean:
	rm -f *.o
	rm -f ising

	

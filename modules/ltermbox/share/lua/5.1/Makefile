#########################
###     CHANGE ME!    ###

TERMBOX_PATH=../

###  or maybe not? ;) ###
#########################



########################################
### no need to change anything below ###
########################################
##for crux
LUA_LIB_PATH=/usr/lib
##for other, infer^H^H^H^H^Hnon-crux ;) distros, that put lua in /usr/local
LUA_LIB_PATH2=/usr/local/lib

#gcc stuff
INCLUDE=/usr/include
CFLAGS=-O2 -march=native -s
LDFLAGS=-Wl,-O1 -Wl,--as-needed
BUILD_PATH=./build
SRC=./
LIBS=-llua -ltermbox 
WARNINGS=-Wall #-Wconversion

GCC=gcc ${CFLAGS} ${LDFLAGS} ${WARNINGS} -I${INCLUDE} -I${TERMBOX_PATH} -L. -L./${BUILD_PATH} -L${LUA_LIB_PATH} -L${LUA_LIB_PATH2} -L${TERMBOX_PATH} 

run: all

all: compile

dirs:
	mkdir -p ${BUILD_PATH}

compile: dirs
	${GCC} ${SRC}/ltermbox.c ${SRC}/../termbox.c ${SRC}/../term.c ${SRC}/../input.c ${SRC}/../ringbuffer.c ${SRC}/../utf8.c -o ./${BUILD_PATH}/ltermbox.so -shared -fPIC ${LIBS}

clean:
	rm -fr ${BUILD_PATH}


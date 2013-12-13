PREFIX=/home/jbalint/lib

# my local copy is built from SVN on sourceforge
INDRI_HOME=/home/jbalint

#LUA_HOME=/usr

#CXXFLAGS += -Wall
CXXFLAGS += -I$(LUA_HOME)/include -DLUA_USE_APICHECK
CXXFLAGS += -I$(INDRI_HOME)/include
CXXFLAGS += -W

# not sure how they intend you to get this... indri/atomic.hpp should have it set at installation
CXXFLAGS += -DHAVE_EXT_ATOMICITY_H -DP_NEEDS_GNU_CXX_NAMESPACE

LDFLAGS += -L$(INDRI_HOME)/lib

libluaindri.so: indri.cpp
	$(CXX) $(CXXFLAGS) -c -fpic -ggdb3 -D_GNU_C_SOURCE -o indri.o indri.cpp
	$(CXX) $(LDFLAGS) -shared -Wl,-soname,libluaindri.so -o libluaindri.so indri.o -lindri -lz -lpthread -llua

install: libluaindri.so
	cp libluaindri.so $(PREFIX)/lib

clean:
	rm -f libluaindri.so indri.o

TOOL_DIR = tools

UNAME := $(shell uname | tr "A-Z" "a-z")

ifeq ($(UNAME), darwin)
	ONAME := $(shell uname -s | tr "A-Z" "a-z")
else
	ONAME := $(shell uname -o | tr "A-Z" "a-z")
endif


MNAME := $(shell uname -m | tr "A-Z" "a-z")

ifeq ($(UNAME), linux)
	ifeq ($(MNAME), i686)
        LIB := x86-linux/libminisatprover*
    endif
	ifeq ($(MNAME), x86_64)
        # amd64 is a nickname for x86_64
        LIB := amd64-linux/libminisatprover*
    endif
endif
ifeq ($(UNAME), windows)
	ifeq ($(MNAME), i686)
        LIB := x86-windows/minisatprover*
    endif
	ifeq ($(MNAME), x86_64)
        LIB := x86-windows/minisatprover*
    endif
endif
ifeq ($(ONAME), cygwin)
	ifeq ($(MNAME), i686)
        LIB := x86-windows/minisatprover*
    endif
	ifeq ($(MNAME), x86_64)
        LIB := x86-windows/minisatprover*
    endif
endif

ifeq ($(UNAME), darwin)
	ifeq ($(MNAME), i686)
        LIB := x86-mac/libminisatprover*
    endif
	ifeq ($(MNAME), x86_64)
        LIB := x86-mac/libminisatprover*
    endif
    WGET_COMMAND := curl -O
else
    WGET_COMMAND := wget
endif

# Calling `make` should only build
all: alloyIG.jar lib build

# Calling `make install to=<target directory>` should only install
install:
	mkdir -p $(to)
	mkdir -p $(to)/lib
	mkdir -p $(to)/tools
	cp -f lib/*minisatprover* $(to)/lib
	cp -f tools/alloy4.jar $(to)/tools
	cp -f alloyIG.jar $(to)
	cp -f README.md $(to)/claferIG-README.md
	cabal install --bindir=$(to)


# this takes the version from the .cabal file. Need to run install first to produce Paths_claferIG.hs 
newVersion:
	ghc -isrc src/dateVer.hs dist/build/autogen/Paths_claferIG.hs -outputdir dist/build --make -o dateVer
	./dateVer > src/Version.hs


# Build takes less time. For ease of development.
build: alloyIG.jar
	cabal install --only-dependencies
	cabal configure
	cabal build

alloyIG.jar: src/manifest src/org/clafer/ig/AlloyIG.java src/manifest src/org/clafer/ig/Util.java src/org/clafer/ig/AlloyIGException.java src/edu/mit/csail/sdg/alloy4compiler/parser/AlloyCompiler.java
	$(MAKE) -C $(TOOL_DIR)
	mkdir -p dist/javabuild
	javac -cp "tools/alloy4.jar" -d dist/javabuild src/org/clafer/ig/AlloyIG.java src/org/clafer/ig/Util.java src/org/clafer/ig/AlloyIGException.java src/edu/mit/csail/sdg/alloy4compiler/parser/AlloyCompiler.java
	jar cfm alloyIG.jar src/manifest -C dist/javabuild org/clafer/ig/ -C dist/javabuild edu

lib:
	@if test -z $(LIB); then \
		echo "[WARNING] Did not find a minisat prover binary suitable for your system. You may need to build the binary yourself."; \
	else \
		unzip tools/alloy4.jar $(LIB) -d lib; \
		chmod +x lib/$(LIB); \
		cp lib/$(LIB) lib; \
	fi
	
runTests:
    # Only test a subset of the suite. The other cases do not work yet.
	./claferIG --all=4 -s dist/run test/suite/backquoted.cfr
	./claferIG --all=4 -s dist/run test/suite/BobsTeam.cfr
	./claferIG --all=4 -s dist/run test/suite/inconsistent.cfr
	./claferIG --all=4 -s dist/run test/suite/PersonFingers.cfr
	./claferIG --all=4 -s dist/run test/suite/waitingLine.cfr
	./claferIG --all=4 -s dist/run test/suite/subclaferCardinality.cfr
	
clean:
	rm -rf dist
	rm -f alloyIG.jar
	rm -f claferIG
	rm -rf lib
	rm -f dateVer*

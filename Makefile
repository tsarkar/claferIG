all: alloyIG.jar lib install

install:
	cabal install --bindir=.

# this takes the version from the .cabal file. Need to run install first to produce Paths_claferIG.hs 
newVersion:
	ghc -isrc src/dateVer.hs dist/build/autogen/Paths_claferIG.hs -outputdir dist/build --make -o dateVer
	./dateVer > src/Version.hs

lib:
	unzip alloy4.jar x86-linux/* -d lib
	unzip alloy4.jar x86-windows/* -d lib
	unzip alloy4.jar x86-mac/* -d lib
	
# Build takes less time. For ease of development.
build: alloyIG.jar
	ghc -XDeriveDataTypeable -isrc src/Main.hs -outputdir dist/build --make -o claferIG

alloyIG.jar: src/manifest src/org/clafer/ig/AlloyIG.java src/manifest src/org/clafer/ig/AlloyIGException.java src/edu/mit/csail/sdg/alloy4compiler/parser/AlloyCompiler.java
	@if test ! -f "alloy4.jar"; then \
		echo "[ERROR] Missing alloy4.jar. Try copying the jar into the current directory."; false; \
	fi
	mkdir -p dist/javabuild
	javac -cp "alloy4.jar" -d dist/javabuild src/org/clafer/ig/AlloyIG.java src/org/clafer/ig/AlloyIGException.java src/edu/mit/csail/sdg/alloy4compiler/parser/AlloyCompiler.java
	jar cfm alloyIG.jar src/manifest -C dist/javabuild org/clafer/ig/ -C dist/javabuild edu
	
clean:
	rm -rf dist
	rm -f alloyIG.jar
	rm -f claferIG
	rm -rf lib

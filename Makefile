prefix = /usr/local
TIMEFORMAT = "\nTime elapsed: %E"
# Build stdlib/runtime/coasm objects into $TMPDIR, pack tulang.a, then wipe WD.
# Stub a.tu.s is dropped on purpose: gc.ms.entry belongs to each user main, not colib.
BUILD_LIBA = build_install_liba() {                              	\
    if [ ! -d $(prefix)/lib/colib ]; then                        	\
        mkdir -p $(prefix)/lib/colib;                            	\
    fi;                                                     	 	\
	rm -rf $(prefix)/lib/colib/*;									\
	WD=$$(mktemp -d "$${TMPDIR:-/tmp}/tu-build-liba-XXXXXX");		\
	echo "[build-liba] workdir=$$WD";								\
	printf '%s\n'													\
		'use fmt	use os	use string	use std'					\
		'use std.map	use std.atomic	use std.regex'				\
		'use runtime	use runtime.debug	use time'					\
		> "$$WD/a.tu";												\
	if ! tu -s "$$WD/a.tu" -std --workdir "$$WD"; then				\
		echo "[build-liba] tu -s failed; refusing incomplete colib" >&2; \
		rm -rf "$$WD";												\
		return 1;													\
	fi;																\
	rm -f "$$WD/a.tu" "$$WD/a.tu.s";								\
	cp $(prefix)/lib/coasm/*.s "$$WD"/;								\
	if ! tu -c "$$WD"; then											\
		echo "[build-liba] tu -c failed; refusing incomplete colib" >&2; \
		rm -rf "$$WD";												\
		return 1;													\
	fi;																\
	ar -rc release/tulang.a "$$WD"/*.o;								\
	cp "$$WD"/*.o $(prefix)/lib/colib/;								\
	rm -rf "$$WD";													\
}
CLEAN_ALL = clean_all() {											\
    if [ -d $(prefix)/lib/colib ]; then                        		\
        rm -rf $(prefix)/lib/colib;                            		\
    fi;                                                     	 	\
    if [ -d $(prefix)/lib/copkg ]; then                        		\
        rm -rf $(prefix)/lib/copkg;                            		\
    fi;                                                     	 	\
    if [ -d $(prefix)/lib/coasm ]; then                        		\
        rm -rf $(prefix)/lib/coasm;                            		\
    fi;                                                     	 	\
}
INSTALL_ALL = install_all() {                              			\
    if [ ! -d $(prefix)/lib/colib ]; then                        	\
        mkdir -p $(prefix)/lib/colib;                            	\
    fi;                                                     	 	\
    if [ ! -d $(prefix)/lib/copkg ]; then                        	\
        mkdir -p $(prefix)/lib/copkg;                            	\
    fi;                                                     	 	\
    if [ ! -d $(prefix)/lib/coasm ]; then                        	\
        mkdir -p $(prefix)/lib/coasm;                            	\
    fi;                                                     	 	\
	rm -rf $(prefix)/lib/colib/*;									\
	rm -rf $(prefix)/lib/copkg/*;									\
	rm -rf $(prefix)/lib/coasm/*;									\
	cp release/tu $(prefix)/bin/tu;									\
	cp -r runtime $(prefix)/lib/copkg/;								\
	cp -r library/* $(prefix)/lib/copkg/;							\
	cp -r packages/* $(prefix)/lib/copkg/;							\
	cp -r syscall/* $(prefix)/lib/coasm/;							\
	if [ -f release/tulang.a ]; then								\
		XD=$$(mktemp -d "$${TMPDIR:-/tmp}/tu-extract-liba-XXXXXX");	\
		(cd "$$XD" && ar -x "$(CURDIR)/release/tulang.a");			\
		mv "$$XD"/*.o $(prefix)/lib/colib/;							\
		rm -rf "$$XD";												\
	fi;																\
}
TEST_COMPILER = test_compiler() {									\
	sh compiler/test.sh;											\
	sh asmer/test.sh;												\
	sh linker/test.sh;												\
}

.PHONY: build-liba
build-liba:
	@$(BUILD_LIBA); build_install_liba
	@echo "install liba  to $(prefix)/lib/colib success"

.PHONEY: release
release: install build-liba install
	@echo "release tu liba success"
	@echo "release bin lib success"

# NOTICE: don't use this
.PHONEY: release
dev_release: install
	@ERR=$$(mktemp); \
	tuc run tulang.tu 2>$$ERR; \
	STATUS=$$?; \
	cat $$ERR; \
	WD=$$(sed -n 's/^\[tuc\] workdir: //p' $$ERR | tail -1); \
	rm -f $$ERR; \
	if [ $$STATUS -ne 0 ]; then exit $$STATUS; fi; \
	if [ -z "$$WD" ] || [ "$$WD" = "(cwd)" ]; then WD=.; fi; \
	mv $$WD/a.out release/tu; \
	cp release/tu $(prefix)/bin/tu

.PHONY: install
install: 
	@$(INSTALL_ALL); install_all
	@echo "tu env installed"

.PHONY: clean
clean:
	@$(CLEAN_ALL); clean_all
	@echo "clean all fininshed"
# unused
#test_memory:
#	sh tests_compiler.sh memory
#	sh tests_asmer.sh memory
#	sh tests_linker.sh memory

check: install test

test_dev:
	@$(TEST_COMPILER); test_compiler
	@echo "test compiler success"

# Directory-level suites. dirs with tests/<dir>/.make_tests only run allowlisted files.
cases = async mixed class common datastruct internalpkg memory native operator runtime statement asyncio

# make test -j9
tests_cases: $(cases)
	@echo "all test cases passed"
	@$(TEST_COMPILER); test_compiler
	@echo "compiler tests passed"
tests_start:
	@echo "tests start"
tests: tests_start
	@$(TIME) $(MAKE) tests_cases
	#Time elapsed: 2:16.05
%: ./tests/%
	@sh tests_all.sh $@ ;
TIME = /usr/bin/time -f $(TIMEFORMAT)

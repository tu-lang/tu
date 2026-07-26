prefix = /usr/local
TIMEFORMAT = "\nTime elapsed: %E"
BUILD_LIBA = build_install_liba() {                              	\
    if [ ! -d $(prefix)/lib/colib ]; then                        	\
        mkdir -p $(prefix)/lib/colib;                            	\
    fi;                                                     	 	\
    if [ ! -d _tmp ]; then                         					\
        mkdir -p _tmp;                             					\
    fi;                                                          	\
	rm -rf $(prefix)/lib/colib/*;									\
	rm -rf _tmp/*;													\
	cd _tmp;														\
	echo "															\
		use fmt	use os	use string	use std							\
		use std.map	use std.atomic	use std.regex					\
		use runtime	use runtime.debug	use time					\
	" > a.tu;														\
	tu -s a.tu -std --workdir-cwd;									\
	rm -f a.tu.s;													\
	tu -c . -c $(prefix)/lib/coasm;									\
	ar -rc tulang.a *.o $(prefix)/lib/coasm/*.o;					\
	mv tulang.a ../release/;										\
	mv *.o $(prefix)/lib/colib/;									\
	mv $(prefix)/lib/coasm/*.o $(prefix)/lib/colib/;				\
	cd ..;															\
	rm -rf _tmp;													\
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
	cd release;														\
	ar -x tulang.a;													\
	mv *.o $(prefix)/lib/colib/;									\
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

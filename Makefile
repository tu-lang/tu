prefix = /usr/local

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
		use runtime	use runtime.sys	use runtime.malloc				\
		use runtime.debug	use runtime.gc	use time				\
	" > a.tu;														\
	tuc -s a.tu;													\
	rm a.s;															\
	tu -c . -c $(prefix)/lib/coasm;									\
	ar -rc tulang.a *.o;											\
	mv tulang.a ../release/;										\
	mv *.o $(prefix)/lib/colib;										\
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
	cp -r syscall/* $(prefix)/lib/coasm/;							\
	cd release;														\
	ar -x tulang.a;													\
	mv *.o $(prefix)/lib/colib/;									\
}

.PHONY: build-liba
build-liba:
	@$(BUILD_LIBA); build_install_liba
	@echo "install liba  to $(prefix)/lib/colib success"

.PHONY: install
install: 
	@$(INSTALL_ALL); install_all
	@echo "tu env installed"

.PHONY: clean
clean:
	@$(CLEAN_ALL); clean_all
	@echo "clean all fininshed"

test_memory:
	sh tests_compiler.sh memory
	sh tests_asmer.sh memory
	sh tests_linker.sh memory

check: install test

test_compiler:
	sh asmer/test.sh
	sh linker/test.sh
	sh compiler/test.sh

cases = mixed class common datastruct internalpkg memory native operator runtime statement
#make test -j9
test-all: test_compiler $(cases)
	@echo "all test passed"
	
test: $(cases)
	@echo "test passed"

%: ./tests/%
	@sh tests_compiler.sh $@ ;
	@sh tests_linker.sh $@  ;
	@sh tests_asmer.sh $@  ;


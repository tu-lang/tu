prefix = /usr/local

BUILD_LIBA = build_install_liba() {                              	\
    if [ ! -d $(prefix)/lib/colib ]; then                        	\
        mkdir -p $(prefix)/lib/colib;                            	\
    fi;                                                     	 	\
    if [ ! -d _tmp ]; then                         			\
        mkdir -p _tmp;                             			\
    fi;                                                          	\
	rm -rf $(prefix)/lib/colib/*;					\
	rm -rf _tmp/*;							\
	cd _tmp;							\
	echo "								\
		use fmt	use os	use string	use std			\
		use std.map	use std.atomic	use std.regex		\
		use runtime	use runtime.sys	use runtime.malloc	\
		use runtime.debug	use runtime.gc	use time	\
	" > a.tu;							\
	tu -s a.tu;							\
	rm a.s;								\
	tua -p . -p $(prefix)/lib/coasm;					\
	ar -rc tulang.a *.o;						\
	mv tulang.a ../asmer/;						\
	mv *.o $(prefix)/lib/colib;					\
	cd ..;								\
	rm -rf _tmp;							\
}
.PHONY: build-liba
build-liba:
	@$(BUILD_LIBA); build_install_liba
	@echo "install liba  to $(prefix)/lib/colib success"

.PHONY: install
install: 
	@cp release/tu $(prefix)/bin/tu
	@echo "tu bin installed"
	@mkdir -p $(prefix)/lib/copkg
	@rm -rf $(prefix)/lib/copkg/*
	@cp -r runtime $(prefix)/lib/copkg/
	@cp -r library/* $(prefix)/lib/copkg/
	@mkdir -p $(prefix)/lib/coasm
	@rm -rf $(prefix)/lib/coasm/*
	@cp -r syscall/* $(prefix)/lib/coasm
	@echo "tu lib installed"

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


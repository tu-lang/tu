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
	ta -p . $(prefix)/lib/coasm;					\
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

.PHONY: install-bin
install-bin: 
	@cp compiler/bin/amd64_linux_tuc $(prefix)/bin/tuc
	@cp linker/bin/amd64_linux_tl2 $(prefix)/bin/tul
	@cp asmer/bin/amd64_linux_tua $(prefix)/bin/tua
	@echo "tu bin installed"
	
.PHONY: install
install: 
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

test_asmer:
	cd asmer;sh test.sh
test_linker:
	sh linker/test.sh
test_compiler:
	compiler/test.sh

cases = mixed class common datastruct internalpkg memory native operator runtime statement
#make test -j9
test-all: test_asmer test_compiler test_linker $(cases)
	@echo "all test passed"
	
test: $(cases)
	@echo "test passed"

%: ./tests/%
	@sh tests_compiler.sh $@ ;
	@sh tests_linker.sh $@  ;
	@sh tests_asmer.sh $@  ;


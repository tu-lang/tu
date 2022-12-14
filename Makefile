prefix = /usr/local

install:
	@mkdir -p $(prefix)/lib/copkg
	@rm -rf $(prefix)/lib/copkg/*
	@cp -r runtime $(prefix)/lib/copkg/
	@cp -r std/* $(prefix)/lib/copkg/
	@mkdir -p $(prefix)/lib/coasm
	@rm -rf $(prefix)/lib/coasm/*
	@cp -r syscall/* $(prefix)/lib/coasm
	@echo "installed"

test_memory:
	sh tests_compiler.sh memory
	sh tests_asmer.sh memory
	sh tests_linker.sh memory

check: install test

test_linker:
	cd linker;sh test.sh
test_compiler:
	cd compiler;sh test.sh

cases = mixed class common datastruct internalpkg memory native operator runtime statement
#make test -j9
test: test_compiler test_linker $(cases)
	@echo "all test passed"

%: ./tests/%
	@sh tests_compiler.sh $@ ;
	@sh tests_linker.sh $@  ;
	#@sh tests_linker.sh $@  ;


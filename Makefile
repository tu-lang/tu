prefix = /usr/local

install:
	@mkdir -p $(prefix)/lib/copkg
	@rm -rf $(prefix)/lib/copkg/*
	@cp -r runtime/pkg/* $(prefix)/lib/copkg/
	@mkdir -p $(prefix)/lib/coasm
	@rm -rf $(prefix)/lib/coasm/*
	@cp -r runtime/syscall/* $(prefix)/lib/coasm
	@echo "installed"

test_memory:
	sh tests_compiler.sh memory
	sh tests_asmer.sh memory
	sh tests_linker.sh memory

check: install test

test_linker:
	cd linker;sh tests_linker.sh

cases = mixed class common datastruct internalpkg memory native operator runtime statement
#make test -j9
test: install test_linker $(cases)
	@echo "all test passed"

%: ./tests/%
	@sh tests_compiler.sh $@ ;
	@sh tests_linker.sh $@  ;
	#@sh tests_linker.sh $@  ;


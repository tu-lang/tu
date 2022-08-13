prefix = /usr/local

install:
	rm -rf $(prefix)/lib/copkg/*
	cp -r runtime/pkg/* $(prefix)/lib/copkg/

	rm -rf $(prefix)/lib/coasm/*
	#cp -r runtime/internal/* $(prefix)/lib/coasm/
	cp -r runtime/syscall/* $(prefix)/lib/coasm

test_memory:
	sh tests_compiler.sh memory
	sh tests_asmer.sh memory
	sh tests_linker.sh memory

check: install test


cases = class common datastruct internalpkg memory native operator runtime statement
#make test -j9
test: install $(cases)
	@echo "all test passed"

%: ./tests/%
	@sh tests_compiler.sh $@ ;
	@sh tests_linker.sh $@  ;
	#@sh tests_linker.sh $@  ;


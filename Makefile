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
# TARGET=linux|darwin — selects syscall tree + runtime OS file.
# Default follows host OS (uname); override with TARGET=linux|darwin.
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
DEFAULT_TARGET := darwin
else
DEFAULT_TARGET := linux
endif
TARGET ?= $(DEFAULT_TARGET)

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
	cp release/tu $(prefix)/bin/tu 2>/dev/null || true;				\
	cp -r runtime $(prefix)/lib/copkg/;								\
	cp -r library/* $(prefix)/lib/copkg/;							\
	cp -r packages/* $(prefix)/lib/copkg/;							\
	if [ "$(TARGET)" = "darwin" ]; then								\
		rm -f $(prefix)/lib/copkg/runtime/linux.tu;					\
		cp platform/darwin/runtime_os.tu $(prefix)/lib/copkg/runtime/darwin.tu; \
		mkdir -p $(prefix)/lib/coasm-darwin;						\
		rm -f $(prefix)/lib/coasm-darwin/*;							\
		cp syscall/darwin/*.s $(prefix)/lib/coasm-darwin/;			\
		echo "[install] TARGET=darwin → coasm-darwin + runtime/darwin.tu"; \
	else															\
		rm -f $(prefix)/lib/copkg/runtime/darwin.tu;				\
		for f in syscall/*.s; do cp "$$f" $(prefix)/lib/coasm/; done; \
	fi;																\
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
ifeq ($(TARGET),darwin)
	@$(MAKE) install-darwin
else
	@$(INSTALL_ALL); install_all
	@echo "tu env installed"
endif

# Darwin runtime/coasm for mother tuc --target=darwin (no self-hosted tu binary).
# Also refreshes Linux coasm: shared runtime/ (e.g. segsegvrecv_pc) must stay in
# sync or default `tuc build` (target=linux) fails with undefined asm symbols.
# On macOS, plain `make install` routes here via TARGET default = darwin.
.PHONY: install-darwin
install-darwin:
	@mkdir -p $(prefix)/lib/copkg $(prefix)/lib/coasm $(prefix)/lib/coasm-darwin
	@rm -rf $(prefix)/lib/copkg/*
	@cp -R runtime $(prefix)/lib/copkg/
	@cp -R library/* $(prefix)/lib/copkg/
	@cp -R packages/* $(prefix)/lib/copkg/
	@rm -f $(prefix)/lib/copkg/runtime/linux.tu
	@cp platform/darwin/runtime_os.tu $(prefix)/lib/copkg/runtime/darwin.tu
	# Darwin signal numbers (SIGUSR1=30, …); keep Linux signal.tu in the tree.
	@cp platform/darwin/os_signal.tu $(prefix)/lib/copkg/os/signal.tu
	# Native kqueue Selector: overlay epoll/waker so consumers keep netio.sys names.
	@cp packages/netio/sys/kqueue.tu $(prefix)/lib/copkg/netio/sys/epoll.tu
	@rm -f $(prefix)/lib/copkg/netio/sys/kqueue.tu
	@cp packages/netio/sys/waker_kqueue.tu $(prefix)/lib/copkg/netio/sys/waker.tu
	@rm -f $(prefix)/lib/copkg/netio/sys/waker_kqueue.tu
	@cp platform/darwin/netio_platform.tu $(prefix)/lib/copkg/netio/sys/platform.tu
	@rm -f $(prefix)/lib/coasm-darwin/*
	@cp syscall/darwin/*.s $(prefix)/lib/coasm-darwin/
	@rm -f $(prefix)/lib/coasm/*
	@cp syscall/*.s $(prefix)/lib/coasm/
	@echo "install-darwin: copkg + coasm-darwin (+ coasm)"

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
# Toolchain self-tests (compiler/asmer/linker) run as peer targets so `make tests -j`
# overlaps them with tests/* instead of waiting until every suite finishes.
cases = async mixed class common datastruct internalpkg memory native operator runtime statement asyncio toolchain_compiler toolchain_asmer toolchain_linker examples

.PHONY: toolchain_compiler toolchain_asmer toolchain_linker examples
toolchain_compiler:
	@sh compiler/test.sh
	@echo "compiler tests passed"
toolchain_asmer:
	@sh asmer/test.sh
	@echo "asmer tests passed"
toolchain_linker:
	@sh linker/test.sh
	@echo "linker tests passed"
examples:
	@bash examples/test.sh
	@echo "examples tests passed"

# make test -j9
tests_cases: $(cases)
	@echo "all test cases passed"
tests_start:
	@echo "tests start"
tests: tests_start
	@$(TIME) $(MAKE) tests_cases
	#Time elapsed: 2:16.05
%: ./tests/%
	@sh tests_all.sh $@ ;
TIME = /usr/bin/time -f $(TIMEFORMAT)

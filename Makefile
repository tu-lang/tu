prefix = /usr/local
TIMEFORMAT = "\nTime elapsed: %E"
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

# Copkg sources for TARGET only. No tu binary, no coasm.
# Cross-bootstrap on Darwin must not copy the ELF tu.
.PHONY: overlay-copkg
overlay-copkg:
	@mkdir -p $(prefix)/lib/copkg
	@rm -rf $(prefix)/lib/copkg/*
	@cp -R runtime $(prefix)/lib/copkg/
	@cp -R library/* $(prefix)/lib/copkg/
	@cp -R packages/* $(prefix)/lib/copkg/
	# Keep platform/ so --stdlib=disk can resolve --target overlays without
	# flipping the host runtime/ tree (linux host → windows/darwin cross).
	@cp -R platform $(prefix)/lib/copkg/
	# Flat copkg: never leave a root tu.mod (would force runtime/packages static).
	@rm -f $(prefix)/lib/copkg/tu.mod
ifeq ($(TARGET),darwin)
	@rm -f $(prefix)/lib/copkg/runtime/linux.tu $(prefix)/lib/copkg/runtime/windows.tu
	@cp platform/darwin/runtime_os.tu $(prefix)/lib/copkg/runtime/darwin.tu
	@cp platform/darwin/os_signal.tu $(prefix)/lib/copkg/os/signal.tu
	@cp packages/netio/sys/kqueue.tu $(prefix)/lib/copkg/netio/sys/epoll.tu
	@cp packages/netio/sys/waker_kqueue.tu $(prefix)/lib/copkg/netio/sys/waker.tu
	@cp platform/darwin/netio_platform.tu $(prefix)/lib/copkg/netio/sys/platform.tu
	# Retain kqueue* names for target-aware listing (do not delete).
else ifeq ($(TARGET),windows)
	@rm -f $(prefix)/lib/copkg/runtime/linux.tu $(prefix)/lib/copkg/runtime/darwin.tu
	@cp platform/windows/runtime_os.tu $(prefix)/lib/copkg/runtime/windows.tu
	@cp platform/windows/wsa_errno.tu $(prefix)/lib/copkg/runtime/wsa_errno.tu
	@cp platform/windows/fd_table.tu $(prefix)/lib/copkg/runtime/fd_table.tu
	@cp platform/windows/epoll_soft.tu $(prefix)/lib/copkg/runtime/epoll_soft.tu
	@cp platform/windows/sock_flags.tu $(prefix)/lib/copkg/runtime/sock_flags.tu
	@cp platform/windows/pipe.tu $(prefix)/lib/copkg/runtime/pipe.tu
	@cp platform/windows/netio_platform.tu $(prefix)/lib/copkg/netio/sys/platform.tu
	# Retain kqueue* for cross listing; unused when --target=windows.
else
	@rm -f $(prefix)/lib/copkg/runtime/darwin.tu $(prefix)/lib/copkg/runtime/windows.tu
	@rm -f $(prefix)/lib/copkg/runtime/wsa_errno.tu $(prefix)/lib/copkg/runtime/fd_table.tu
	@rm -f $(prefix)/lib/copkg/runtime/epoll_soft.tu $(prefix)/lib/copkg/runtime/sock_flags.tu
	@rm -f $(prefix)/lib/copkg/runtime/pipe.tu
	# Keep netio kqueue* sources so disk+darwin cross can resolve without re-overlay.
endif
	# RFC-110: flat copkg drops library/packages ancestors; materialize nearest tu.mod
	@bash scripts/materialize_tu_mod.sh "$(CURDIR)" "$(prefix)/lib/copkg"
	@echo "overlay-copkg: TARGET=$(TARGET) (sources only + tu.mod materialize)"
TEST_COMPILER = test_compiler() {									\
	sh compiler/test.sh;											\
	sh asmer/test.sh;												\
	sh linker/test.sh;												\
}

# All-target asm/stub trees for --stdlib=disk. Embed mode uses syscall/ +
# platform/*/stub_*.s from the materialized stdroot (no prefix required).
.PHONY: install-coasm-all
install-coasm-all:
	@mkdir -p $(prefix)/lib/coasm $(prefix)/lib/coasm-darwin $(prefix)/lib/coasm-windows \
		$(prefix)/lib/costub-linux $(prefix)/lib/costub-darwin $(prefix)/lib/copeff
	@rm -f $(prefix)/lib/coasm/* $(prefix)/lib/coasm-darwin/* $(prefix)/lib/coasm-windows/*
	@for f in syscall/*.s; do cp "$$f" $(prefix)/lib/coasm/; done
	@cp syscall/darwin/*.s $(prefix)/lib/coasm-darwin/
	@cp syscall/windows/*.s $(prefix)/lib/coasm-windows/
	@cp platform/linux/stub_entry.s platform/linux/stub_runtime.s $(prefix)/lib/costub-linux/
	@cp platform/darwin/stub_entry.s platform/darwin/stub_runtime.s $(prefix)/lib/costub-darwin/
	@cp platform/windows/stub_entry.s platform/windows/stub_runtime.s $(prefix)/lib/copeff/
	@echo "install-coasm-all: coasm + coasm-darwin + coasm-windows + costub-linux + costub-darwin + copeff"

# Cross-publish self-hosted tu for linux + darwin + windows (embedded stdroot),
# then install this host binary. Windows PE is linked by the host tu (peff),
# not mother tul / lld-link. See scripts/dev_release.sh.
.PHONY: dev_release
dev_release:
	@prefix="$(prefix)" bash scripts/dev_release.sh

# Default install: host tu binary only. Stdlib / coasm / stubs come from the
# embedded stdroot inside the binary (RFC-107). Use install-full for disk.
.PHONY: install install-bin
install install-bin:
	@mkdir -p $(prefix)/bin
ifeq ($(TARGET),darwin)
	@if [ -f release/tu-darwin ]; then \
		cp release/tu-darwin $(prefix)/bin/tu; \
		echo "[install] $(prefix)/bin/tu ← release/tu-darwin (bin only)"; \
	else \
		echo "[install] skip: missing release/tu-darwin (run make dev_release)"; \
	fi
else ifeq ($(TARGET),windows)
	@if [ -f release/tu-windows ]; then \
		cp release/tu-windows $(prefix)/bin/tu.exe; \
		if [ -d $(prefix)/RelWithDebInfo ]; then cp release/tu-windows $(prefix)/RelWithDebInfo/tu.exe; fi; \
		echo "[install] $(prefix)/bin/tu.exe ← release/tu-windows (bin only)"; \
	else \
		echo "[install] skip: missing release/tu-windows (run make dev_release)"; \
	fi
else
	@if [ "$(UNAME_S)" != "Linux" ]; then \
		echo "[install] TARGET=linux binary install only on Linux host (have $(UNAME_S))"; \
	elif [ -f release/tu ]; then \
		cp release/tu $(prefix)/bin/tu; \
		echo "[install] $(prefix)/bin/tu ← release/tu (bin only)"; \
	else \
		echo "[install] skip: missing release/tu (run make dev_release)"; \
	fi
endif

# Full disk prefix: copkg overlay + coasm/stubs + binary.
# Required for --stdlib=disk / TU_STDLIB=disk and self-host disk consumers.
.PHONY: install-full
install-full:
ifeq ($(TARGET),darwin)
	@$(MAKE) install-darwin
else ifeq ($(TARGET),windows)
	@$(MAKE) install-windows
else
	@$(MAKE) overlay-copkg TARGET=linux
	@mkdir -p $(prefix)/bin
	@$(MAKE) install-coasm-all
	@$(MAKE) install TARGET=linux
	@echo "tu env installed (full: copkg + coasm + stubs + bin)"
endif

# Darwin: full disk tree + binary. Prefer `make install` (bin only) for embed.
.PHONY: install-darwin
install-darwin:
	@$(MAKE) overlay-copkg TARGET=darwin
	@$(MAKE) install-coasm-all
	@$(MAKE) install TARGET=darwin
	@echo "install-darwin: copkg overlay + all-target coasm + tu-darwin"

# Windows: full disk tree + binary. Prefer `make install` / install-windows.cmd (bin).
.PHONY: install-windows
install-windows:
	@$(MAKE) overlay-copkg TARGET=windows
	@$(MAKE) install-coasm-all
	@$(MAKE) install TARGET=windows
	@echo "install-windows: copkg overlay + all-target coasm + tu-windows"

# Windows: mother tuc → tu/release/tu-windows (never clobber Linux release/tu).
.PHONY: bootstrap-windows
bootstrap-windows:
	powershell -NoProfile -File ../co/windows/dev_release.ps1

# Rebuild tu-darwin with the just-installed self-hosted tu (B4 loop).
.PHONY: bootstrap-darwin
bootstrap-darwin: install-darwin
	@if [ ! -x release/tu-darwin ] && [ ! -x $(prefix)/bin/tu ]; then \
		echo "bootstrap-darwin: missing release/tu-darwin; run make dev_release first"; exit 1; \
	fi
	@mv runtime/linux.tu runtime/linux.tu.bak
	@cp platform/darwin/runtime_os.tu runtime/darwin.tu
	@cp library/os/signal.tu library/os/signal.tu.bak
	@cp platform/darwin/os_signal.tu library/os/signal.tu
	@ERR=$$(mktemp); \
	if [ -x release/tu-darwin ]; then TU_BIN=./release/tu-darwin; else TU_BIN=tu; fi; \
	$$TU_BIN build tulang.tu --workdir-cwd 2>$$ERR; \
	STATUS=$$?; \
	cat $$ERR; \
	rm -f runtime/darwin.tu; \
	mv runtime/linux.tu.bak runtime/linux.tu; \
	mv library/os/signal.tu.bak library/os/signal.tu; \
	rm -f $$ERR; \
	if [ $$STATUS -ne 0 ]; then exit $$STATUS; fi
	@if [ -f ./a.out ]; then mv ./a.out release/tu-darwin; \
	elif [ -f ./tulang ]; then mv ./tulang release/tu-darwin; \
	else echo "bootstrap-darwin: no a.out/tulang produced"; exit 1; fi
	@cp release/tu-darwin $(prefix)/bin/tu
	@echo "[bootstrap-darwin] tu → release/tu-darwin"

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

# Directory-level suites: every *.tu under tests/<dir> runs (no allowlist).
# Toolchain self-tests (compiler/asmer/linker) run as peer targets so `make tests -j`
# overlaps them with tests/* instead of waiting until every suite finishes.
# examples runs serially after parallel suites (avoids stdroot embed races under -j).
parallel_cases = async mixed class common datastruct internalpkg memory native operator runtime statement asyncio pkgmode pkgmode_negative pkgmode_default async_negative
toolchain_cases = toolchain_compiler toolchain_asmer toolchain_linker
cases = $(toolchain_cases) $(parallel_cases) examples

.PHONY: toolchain_compiler toolchain_asmer toolchain_linker examples pkgmode_negative pkgmode_default async_negative
toolchain_compiler:
	@sh compiler/test.sh
	@echo "compiler tests passed"
toolchain_asmer:
	@sh asmer/test.sh
	@bash asmer/darwin/cases/check_macho.sh
	@bash asmer/darwin/cases/check_rip_store.sh
	@echo "asmer tests passed"
toolchain_linker:
	@sh linker/test.sh
	@bash linker/darwin/cases/check_execute.sh
	@bash linker/darwin/cases/check_dyld_import.sh
	@bash linker/darwin/cases/check_pclntab.sh
	@bash linker/linux/cases/check_nostd.sh
	@echo "linker tests passed"
examples:
	@bash examples/test.sh
	@echo "examples tests passed"
pkgmode_negative:
	@bash tests/pkgmode/negative/run.sh
	@echo "pkgmode negative tests passed"
pkgmode_default:
	@bash tests/pkgmode/default/run.sh
	@echo "pkgmode default tests passed"
async_negative:
	@bash tests/async/negative/run.sh
	@echo "async negative tests passed"

# make test -j9
tests_cases: $(cases)
	@echo "all test cases passed"
tests_start:
	@echo "tests start"
tests: tests_start
	@$(TIME) $(MAKE) $(toolchain_cases)
	@$(TIME) $(MAKE) $(parallel_cases) -j$(nproc)
	@$(TIME) $(MAKE) examples
	@echo "all test cases passed"
%: ./tests/%
	@sh tests_all.sh $@ ;
# GNU time -f is Linux-only; BSD time on Darwin only has -p.
ifeq ($(UNAME_S),Darwin)
TIME = /usr/bin/time -p
else
TIME = /usr/bin/time -f $(TIMEFORMAT)
endif

all: build

.PHONY: clear
clear: clean

build:
	@ dune build @check
	@ dune build

.PHONY: dev-deps
dev-deps:
	@ opam install merlin utop ocp-indent --yes

.PHONY: deps
deps:
	@ opam install . --deps-only

.PHONY: pin
pin:
	@ opam pin add twostep . -n --yes

.PHONY: unpin
unpin:
	@ opam pin remove twostep --yes

.PHONY: utop
utop: build
	@ dune utop lib

.PHONY: cleanup-files
cleanup-files:
	@ rm -f *~
	@ rm -f bin/*~
	@ rm -f lib/*~
	@ rm -f test/*~
	@ rm -f .*.un~
	@ rm -f bin/.*.un~
	@ rm -f lib/.*.un~
	@ rm -f test/.*.un~

.PHONY: clean
clean: cleanup-files
	@ dune clean

.PHONY: lint
lint:
	@ opam lint

quick-test: build
	@ ALCOTEST_QUICK_TESTS=1 dune runtest

test: build
	@ dune runtest --no-buffer -f -j 1

install: build
	@ dune install

.PHONY: uninstall
uninstall:
	@ dune uninstall

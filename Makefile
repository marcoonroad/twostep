all: build

.PHONY: clear
clear: clean

build:
	@ dune build

.PHONY: dev-deps
dev-deps:
	@ opam install ocamlformat.0.15.1 odoc merlin utop ocp-indent --yes

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

.PHONY: lint-format
lint-format:
	@ opam install ocamlformat.0.15.1 --yes
	@ dune build @fmt

.PHONY: lint
lint:
	@ opam lint
	@ make lint-format

.PHONY: format
format:
	@ opam install ocamlformat.0.15.1 --yes
	@ dune build @fmt --auto-promote || echo "\nSource code rewritten by format.\n"

quick-test: build
	@ ALCOTEST_QUICK_TESTS=1 dune runtest

test: build
	@ dune runtest --no-buffer -f -j 1

.PHONY: docs-index
docs-index:
	@ cp README.md docs/index.md

.PHONY: docs
docs: build
	@ mkdir -p docs/
	@ rm -rf docs/apiref/
	@ mkdir -p docs/apiref/
	@ dune build @doc
	@ make docs-index
	@ mv ./_build/default/_doc/_html/* ./docs/apiref/

.PHONY: serve-docs
serve-docs: docs
	@ cd docs && bundle exec jekyll serve && cd .. || cd ..

install: build
	@ dune install

.PHONY: uninstall
uninstall:
	@ dune uninstall

.PHONY: local-site-setup
local-site-setup:
	@ cd docs && bundle install --path vendor/bundle && cd ..

.PHONY: local-site-start
local-site-start:
	@ cd docs && bundle exec jekyll serve && cd ..

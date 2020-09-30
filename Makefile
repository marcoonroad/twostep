.PHONY: clean dev-deps deps lint-format lint format docs uninstall

all: build

clear: clean

build:
	@ dune build

dev-deps:
	@ opam install ocamlformat odoc merlin utop ocp-indent --yes

deps:
	@ opam install . --deps-only

pin:
	@ opam pin add twostep . -n --yes

utop: build
	@ dune utop lib

cleanup-files:
	@ rm -f *~
	@ rm -f bin/*~
	@ rm -f lib/*~
	@ rm -f test/*~
	@ rm -f .*.un~
	@ rm -f bin/.*.un~
	@ rm -f lib/.*.un~
	@ rm -f test/.*.un~
	@ rm -f `find . -name 'bisect*.out'`
	@ rm -f `find . -name 'bisect*.coverage'`

clean: cleanup-files
	@ dune clean

lint-format:
	@ opam install ocamlformat --yes
	@ dune build @fmt

lint:
	@ opam lint
	@ make lint-format

format:
	@ opam install ocamlformat --yes
	@ dune build @fmt --auto-promote || echo "\nSource code rewritten by format.\n"

quick-test: build
	@ ALCOTEST_QUICK_TESTS=1 dune runtest

test: build
	@ dune runtest --no-buffer -f -j 1

# to run inside docker alpine context
binary: clear
	@ dune build --profile deploy
	@ cp `dune exec --profile deploy -- which twostep` ./twostep.exe
	@ chmod a+rx ./twostep.exe

docs-index:
	@ cp README.md docs/index.md

docs: build
	@ mkdir -p docs/
	@ rm -rf docs/apiref/
	@ mkdir -p docs/apiref/
	@ dune build @doc
	@ make docs-index
	@ mv ./_build/default/_doc/_html/* ./docs/apiref/

install: build
	@ dune install

uninstall:
	@ dune uninstall

coverage: clean
	@ mkdir -p docs/
	@ rm -rf docs/apicov/
	@ mkdir -p docs/apicov/
	@ BISECT_ENABLE=yes make build
	@ BISECT_ENABLE=yes make test
	@ bisect-ppx-report \
		-title twostep \
		-I _build/default/ \
		-tab-size 2 \
		-html coverage/ \
		`find . -name 'bisect*.out'`
	@ bisect-ppx-report \
		-I _build/default/ \
		-text - \
		`find . -name 'bisect*.out'`
	@ mv ./coverage/* ./docs/apicov/

report: coverage
	@ bisect-ppx-report send-to Coveralls

.PHONY: local-site-setup
local-site-setup:
	@ cd docs && bundle install --path vendor/bundle && cd ..

.PHONY: local-site-start
local-site-start:
	@ cd docs && bundle exec jekyll serve && cd ..

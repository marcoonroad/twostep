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
	@ rm -f `find . -name 'bisect*.out'`
	@ rm -f `find . -name 'bisect*.coverage'`

.PHONY: clean
clean: cleanup-files
	@ dune clean

.PHONY: lint-format
lint-format:
	@ opam install ocamlformat --yes
	@ dune build @fmt

.PHONY: lint
lint:
	@ opam lint
	@ make lint-format

.PHONY: format
format:
	@ opam install ocamlformat --yes
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

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

cleanup:
	@ rm -fv *~
	@ rm -fv lib/*~
	@ rm -fv test/*~
	@ rm -fv .*.un~
	@ rm -fv lib/.*.un~
	@ rm -fv test/.*.un~
	@ rm -f `find . -name 'bisect*.out'`

.PHONY: clean
clean: cleanup
	@ dune clean

lint-format: build
	@ dune build @fmt

format:
	@ dune build @fmt --auto-promote || echo "\nSource code rewritten by format.\n"

test: build
	@ opam lint
	@ dune runtest --no-buffer -f -j 1

docs-index:
	@ cp README.md docs/index.md

docs: build
	@ mkdir -p docs
	@ rm -rf docs/apiref
	@ mkdir -p docs/apiref
	@ dune build @doc
	@ make docs-index
	@ mv _build/default/_doc/_html/* docs/apiref/

install: build
	@ dune install

uninstall:
	@ dune uninstall

coverage: clean
	@ mkdir -p docs/
	@ rm -rf docs/apicov
	@ mkdir -p docs/apicov
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
	@ mv ./coverage/* ./docs/apicov

build:
	@ dune build

pin:
	@ opam pin add twostep . -n --yes

utop: build
	@ dune utop lib

cleanup:
	@ rm -fv *~
	@ rm -fv lib/*~
	@ rm -fv lib_test/*~
	@ rm -fv .*.un~
	@ rm -fv lib/.*.un~
	@ rm -fv lib_test/.*.un~
	@ rm -f `find . -name 'bisect*.out'`

.PHONY: clean
clean: cleanup
	@ dune clean

test: clean build
	@ dune runtest

install: build
	@ dune install

uninstall: build
	@ dune uninstall


BINDIR=$(dir $(shell which ocaml))
DEPS=$(wildcard src/*.ml src/*.mli src/*.mly src/*.mll)
all: spliter.native

spliter.native: $(DEPS)
	ocamlbuild src/$@

# (Un)Installation

install: spliter.native 
	@install -m 755 -d $(BINDIR)
	@install -m 755 -p spliter.native $(BINDIR)/ekstrakto
	@echo 'Installation completed'
	@echo 'Type `ekstrakto \path\to\your\trace\file`'
uninstall:
	@rm -f $(BINDIR)/ekstrakto

# Cleaning.

clean:
	ocamlbuild -clean

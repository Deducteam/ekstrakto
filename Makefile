BINDIR=$(dir $(shell which ocaml))
DEPS=$(wildcard src/*.ml src/*.mli src/*.mly src/*.mll)
all: spliter.native

spliter.native: $(DEPS)
	ocamlbuild src/$@ -lib str

# (Un)Installation

install: spliter.native
	@echo 'Installing binary'
	@install -m 755 -d $(BINDIR)
	@install -m 755 -p spliter.native $(BINDIR)/ekstrakto

	@echo 'Copy of logic files'
	@mkdir -p ~/.ekstrakto/logic
	@install -m 755 -p logic/*.lp ~/.ekstrakto/logic/

	@echo 'Installation completed'
	@echo 'Type `ekstrakto \path\to\your\trace\file`'
uninstall:
	@rm -f $(BINDIR)/ekstrakto

# Cleaning.

clean:
	ocamlbuild -clean

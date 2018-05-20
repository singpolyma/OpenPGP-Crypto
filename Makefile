GHCFLAGS=-Wall -XNoCPP -fno-warn-name-shadowing -fno-warn-tabs -XHaskell98
HLINTFLAGS=-XHaskell98 -XNoCPP -i 'Use camelCase' -i 'Use String' -i 'Use head' -i 'Use string literal' -i 'Use list comprehension' --utf8
VERSION=0.5

.PHONY: all clean doc install debian test

all: sign verify keygen test report.html doc dist/build/libHSopenpgp-Crypto-$(VERSION).a dist/openpgp-Crypto-$(VERSION).tar.gz

install: dist/build/libHSopenpgp-Crypto-$(VERSION).a
	cabal install

debian: debian/control

test: tests/suite
	tests/suite

sign: examples/sign.hs Data/OpenPGP/Crypto.hs
	ghc --make $(GHCFLAGS) -o $@ $^

verify: examples/verify.hs Data/OpenPGP/Crypto.hs
	ghc --make $(GHCFLAGS) -o $@ $^

keygen: examples/keygen.hs Data/OpenPGP/Crypto.hs
	ghc --make $(GHCFLAGS) -o $@ $^

tests/suite: tests/suite.hs Data/OpenPGP/Crypto.hs
	ghc --make $(GHCFLAGS) -o $@ $^

report.html: examples/*.hs Data/OpenPGP/Crypto.hs tests/suite.hs
	-hlint $(HLINTFLAGS) --report Data examples

doc: dist/doc/html/openpgp-Crypto/index.html README

README: openpgp-Crypto.cabal
	tail -n+$$(( `grep -n ^description: $^ | head -n1 | cut -d: -f1` + 1 )) $^ > .$@
	head -n+$$(( `grep -n ^$$ .$@ | head -n1 | cut -d: -f1` - 1 )) .$@ > $@
	-printf ',s/        //g\n,s/^.$$//g\nw\nq\n' | ed $@
	$(RM) .$@

dist/doc/html/openpgp-Crypto/index.html: dist/setup-config Data/OpenPGP/Crypto.hs
	cabal haddock --hyperlink-source

dist/setup-config: openpgp-Crypto.cabal
	cabal configure

clean:
	find -name '*.o' -o -name '*.hi' | xargs $(RM)
	$(RM) sign verify keygen tests/suite report.html
	$(RM) -r dist dist-ghc

debian/control: openpgp-Crypto.cabal
	cabal-debian --update-debianization

dist/build/libHSopenpgp-Crypto-$(VERSION).a: openpgp-Crypto.cabal dist/setup-config Data/OpenPGP/Crypto.hs
	cabal build --ghc-options="$(GHCFLAGS)"

dist/openpgp-Crypto-$(VERSION).tar.gz: openpgp-Crypto.cabal dist/setup-config Data/OpenPGP/Crypto.hs README
	cabal check
	cabal sdist

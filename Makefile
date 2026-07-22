.PHONY: test install install-hooks

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
PROGRAM ?= rename

test:
	@perl -MTest::More -e 1 >/dev/null 2>&1 || { echo "Test::More is required"; exit 127; }
	@command -v prove >/dev/null 2>&1 || { echo "prove is required"; exit 127; }
	@prove -v t

install:
	@mkdir -p "$(BINDIR)"
	@install -m 0755 "$(PROGRAM)" "$(BINDIR)/$(PROGRAM)"

install-hooks:
	@chmod +x .githooks/pre-commit script/update-version
	@git config core.hooksPath .githooks
	@echo "Configured git hooks to use .githooks"

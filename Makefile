all: test hooks

.PHONY: test hooks

HOOKS=$(foreach file, $(wildcard hooks/*), .git/$(file))

hooks: $(HOOKS)

.git/hooks/%: hooks/%
	ln -s ../../hooks/$* $@

test:
	mix test

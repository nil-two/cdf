.PHONY: all lint test

all:

lint:
	@bash script/lint.bash

test:
	@bats test

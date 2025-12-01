.PHONY: test
test:
	@nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"

.PHONY: test-file
test-file:
	@nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedFile $(FILE)"

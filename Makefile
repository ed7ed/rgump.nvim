.PHONY: test

test:
	nvim --headless -c "PlenaryBustedDirectory tests/" -c "q"

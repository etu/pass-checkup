shellcheck:
	shellcheck checkup.bash

yamllint:
	yamllint -s -f github .github/workflows/*

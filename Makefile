setup:
	which xcodegen || brew install xcodegen
	xcodegen generate

.PHONY: setup

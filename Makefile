NAME := omarchy-handheld-lock
VERSION := $(shell jq -er .version manifest.json)
ARCHIVE := $(NAME)-$(VERSION).tar.gz
FILES := manifest.json Service.qml LockView.qml FingerprintPrompt.qml TouchKey.qml TouchKeyboard.qml README.md LICENSE Makefile

.PHONY: dist check
.DELETE_ON_ERROR:

dist: check
	mkdir -p dist
	tar --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 --mode=644 --transform='s,^,$(NAME)-$(VERSION)/,' -czf dist/$(ARCHIVE) $(FILES)
	cd dist && sha256sum $(ARCHIVE) > $(ARCHIVE).sha256

check:
	omarchy plugin validate .

# File: Makefile
# Author: Matt Manzi
# Created: 2021-01-17
#
# Quick recipes to manage the repository.
# Inspiration from:
# 	https://github.com/thockin/go-build-template/blob/master/Makefile

# users should set GOOS and/or GOARCH env variables when using recipes
BUILD_TARGET_OS = $(if $(GOOS),$(GOOS),$(shell go env GOOS))
BUILD_TARGET_ARCH = $(if $(GOARCH),$(GOARCH),$(shell go env GOARCH))

CMD_DIR := ./cmd
BIN_DIR := ./bin
VERSION_DIR := ./internal/version

CMD := $(CMD_DIR)/$(shell ls ./cmd/)
BIN := $(CMD:$(CMD_DIR)%=$(BIN_DIR)%)
VERSION := $(VERSION_DIR)/version.go

VERSION_RE := ^(const[[:space:]]+VersionString[[:space:]]+=[[:space:]]+)"(([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+))"$$

# debugging the makefile
vars:
	@echo "CMD_DIR=$(CMD_DIR)"
	@echo "BIN_DIR=$(BIN_DIR)"
	@echo "VERSION_DIR=$(VERSION_DIR)"
	@echo "CMD=$(CMD)"
	@echo "BIN=$(BIN)"
	@echo "BUILD_TARGET_OS=$(BUILD_TARGET_OS)"
	@echo "BUILD_TARGET_ARCH=$(BUILD_TARGET_ARCH)"

# run cmds in order
# not perfect because if there were more you'd be stuck
# but I only have for now so ¯\_(ツ)_/¯
run:
	@go run $(CMD)/main.go

# run but with debug verbosity
debug:
	@MM_VERBOSITY=debug go run $(CMD)/main.go

# build binaries
build: $(BIN)

$(BIN):
	GOOS=$(BUILD_TARGET_OS) \
	GOARCH=$(BUILD_TARGET_ARCH) \
	go build -o $(BIN) $(CMD)/main.go

# run golang tests
test: every-test

every-test:
	@go test ./...

version: $(VERSION)
	@/bin/echo -n "Verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)

patch-version: $(VERSION)
	@/bin/echo -n "Current verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)
	@$(eval patchv := $(shell sed -nr 's/$(VERSION_RE)/\5/p' $(VERSION)))
	@$(eval newpatch := $(shell echo $(patchv)+1 | bc))
	@sed -i.prev -r 's/$(VERSION_RE)/\1"\3.\4.$(newpatch)"/' $(VERSION)
	@/bin/echo -n "New verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)
	@rm $(VERSION).prev

minor-version: $(VERSION)
	@/bin/echo -n "Current verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)
	@$(eval minorv := $(shell sed -nr 's/$(VERSION_RE)/\4/p' $(VERSION)))
	@$(eval newminor := $(shell echo $(minorv)+1 | bc))
	@sed -i.prev -r 's/$(VERSION_RE)/\1"\3.$(newminor).0"/' $(VERSION)
	@/bin/echo -n "New verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)
	@rm $(VERSION).prev

major-version: $(VERSION)
	@/bin/echo -n "Current verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)
	@$(eval majorv := $(shell sed -nr 's/$(VERSION_RE)/\3/p' $(VERSION)))
	@$(eval newmajor := $(shell echo $(majorv)+1 | bc))
	@sed -i.prev -r 's/$(VERSION_RE)/\1"$(newmajor).0.0"/' $(VERSION)
	@/bin/echo -n "New verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)
	@rm $(VERSION).prev

# clean up the repo and resources
clean: bin-clean test-clean

test-clean:
	go clean -testcache

bin-clean:
	rm -rf $(BIN_DIR)

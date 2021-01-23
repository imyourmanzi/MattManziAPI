# File: Makefile
# Author: Matt Manzi
# Created: 2021-01-17
#
# Quick recipes to manage the repository.
# Inspiration from:
# 	https://github.com/thockin/go-build-template/blob/master/Makefile

# users should set GOOS and/or GOARCH env variables when using recipes
BUILD_TARGET_OS ?= $(shell go env GOOS)
BUILD_TARGET_ARCH ?= $(shell go env GOARCH)

CMD_DIR := ./cmd
BIN_DIR := ./bin
VERSION_DIR := ./internal/version

CMD := $(CMD_DIR)/$(shell ls ./cmd/)
BIN := $(CMD:$(CMD_DIR)%=$(BIN_DIR)%)
VERSION := $(VERSION_DIR)/version.go

VERSION_RE := ^(const[[:space:]]+VersionString[[:space:]]+=[[:space:]]+)"(([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+))"$$

DOCKER_NAME := apidb

# debugging the makefile
.PHONY: vars
vars:
	@echo 'BUILD_TARGET_OS := $(BUILD_TARGET_OS)'
	@echo 'BUILD_TARGET_ARCH := $(BUILD_TARGET_ARCH)'
	
	@echo 'CMD_DIR := $(CMD_DIR)'
	@echo 'BIN_DIR := $(BIN_DIR)'
	@echo 'VERSION_DIR := $(VERSION_DIR)'
	
	@echo 'CMD := $(CMD)'
	@echo 'BIN := $(BIN)'
	@echo 'VERSION := $(VERSION)'

	@echo 'VERSION_RE := $(VERSION_RE)'

	@echo 'DOCKER_NAME := $(DOCKER_NAME)'

# run but with debug verbosity
.PHONY: debug
debug:
	@MM_VERBOSITY=debug $(MAKE) run

# locally run cmds in order
# \ not perfect because if there were more you'd be stuck
# \ but I only have for now so ¯\_(ツ)_/¯
.PHONY: run
run: start-db
	@runCleanup () { \
		$(MAKE) stop-db; \
	}; trap runCleanup EXIT; go run $(CMD)/main.go

.PHONY: start-db
start-db:
	@/bin/echo -n "Starting local database..."
	@docker run -dp 27017-27019:27017-27019 --name $(DOCKER_NAME) mongo:4.4 > /dev/null
	@echo "OK"

.PHONY: stop-db
stop-db:
	@/bin/echo -n "Cleaning up local database..."
	@docker stop $(DOCKER_NAME) > /dev/null
	@docker rm $(DOCKER_NAME) > /dev/null
	@echo "Done"

# build binaries
.PHONY: build
build: $(BIN)

$(BIN):
	GOOS=$(BUILD_TARGET_OS) \
	GOARCH=$(BUILD_TARGET_ARCH) \
	go build -o $(BIN) $(CMD)/main.go

# run golang tests
.PHONY: test
test: every-test

.PHONY: every-test
every-test:
	@go test ./...

.PHONY: version
version: $(VERSION)
	@/bin/echo -n "Verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)

.PHONY: patch-version
patch-version: $(VERSION)
	@/bin/echo -n "Current verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)
	@$(eval patchv := $(shell sed -nr 's/$(VERSION_RE)/\5/p' $(VERSION)))
	@$(eval newpatch := $(shell echo $(patchv)+1 | bc))
	@sed -i.prev -r 's/$(VERSION_RE)/\1"\3.\4.$(newpatch)"/' $(VERSION)
	@/bin/echo -n "New verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)
	@rm $(VERSION).prev

.PHONY: minor-version
minor-version: $(VERSION)
	@/bin/echo -n "Current verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)
	@$(eval minorv := $(shell sed -nr 's/$(VERSION_RE)/\4/p' $(VERSION)))
	@$(eval newminor := $(shell echo $(minorv)+1 | bc))
	@sed -i.prev -r 's/$(VERSION_RE)/\1"\3.$(newminor).0"/' $(VERSION)
	@/bin/echo -n "New verion:	"
	@sed -nr 's/$(VERSION_RE)/\2/p' $(VERSION)
	@rm $(VERSION).prev

.PHONY: major-version
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
.PHONY: clean
clean: bin-clean test-clean

.PHONY: test-clean
test-clean:
	go clean -testcache

.PHONY: bin-clean
bin-clean:
	rm -rf $(BIN_DIR)

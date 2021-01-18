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

CMD := $(CMD_DIR)/$(shell ls ./cmd/)
BIN := $(CMD:$(CMD_DIR)%=$(BIN_DIR)%)

# debugging the makefile
vars:
	@echo "CMD=$(CMD)"
	@echo "BIN=$(BIN)"
	@echo "BUILD_TARGET_OS=$(BUILD_TARGET_OS)"
	@echo "BUILD_TARGET_ARCH=$(BUILD_TARGET_ARCH)"

# run cmds in order
# not perfect because if there were more you'd be stuck
# but I only have for now so ¯\_(ツ)_/¯
run:
	-@go run $(CMD)/main.go

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

# clean up the repo and resources
clean: bin-clean test-clean

test-clean:
	go clean -testcache

bin-clean:
	-rm -rf $(BIN_DIR)

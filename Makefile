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
LOCAL_DIR := ./.local
CERT_DIR := $(LOCAL_DIR)/x509
MONGO_DIR := $(LOCAL_DIR)/mongo

CMD := $(CMD_DIR)/$(shell ls ./cmd/)
BIN := $(CMD:$(CMD_DIR)%=$(BIN_DIR)%)
VERSION := $(VERSION_DIR)/version.go

VERSION_RE := ^(const[[:space:]]+VersionString[[:space:]]+=[[:space:]]+)"(([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+))"$$

CA_CNF := $(CERT_DIR)/ca.conf
CA_KEY := $(CA_CNF:.conf=.key)
CA_PEM := $(CA_CNF:.conf=.pem)

CLIENT_CNF := $(CERT_DIR)/client.conf
CLIENT_KEY := $(CLIENT_CNF:.conf=.key)
CLIENT_CSR := $(CLIENT_CNF:.conf=.csr)
CLIENT_CRT := $(CLIENT_CNF:.conf=.crt)
CLIENT_PEM := $(CLIENT_CNF:.conf=.pem)

SERVER_CNF := $(CERT_DIR)/server.conf
SERVER_KEY := $(SERVER_CNF:.conf=.key)
SERVER_CSR := $(SERVER_CNF:.conf=.csr)
SERVER_CRT := $(SERVER_CNF:.conf=.crt)
SERVER_PEM := $(SERVER_CNF:.conf=.pem)

MONGO_CNF := $(MONGO_DIR)/mongo_conf.yml
MONGO_USER_SCRIPT := $(MONGO_DIR)/add_user.sh

DOCKER_IMAGE_NAME := apidb_image
DOCKER_CONTAINER_NAME := $(DOCKER_IMAGE_NAME:%_image=%)

# debugging the makefile
.PHONY: vars
vars:
	@echo 'BUILD_TARGET_OS := $(BUILD_TARGET_OS)'
	@echo 'BUILD_TARGET_ARCH := $(BUILD_TARGET_ARCH)'

	@echo
	@echo 'CMD_DIR := $(CMD_DIR)'
	@echo 'BIN_DIR := $(BIN_DIR)'
	@echo 'VERSION_DIR := $(VERSION_DIR)'
	@echo 'LOCAL_DIR := $(LOCAL_DIR)'
	@echo 'CERT_DIR := $(CERT_DIR)'

	@echo
	@echo 'CMD := $(CMD)'
	@echo 'BIN := $(BIN)'
	@echo 'VERSION := $(VERSION)'

	@echo
	@echo 'VERSION_RE := $(VERSION_RE)'

	@echo
	@echo 'CA_CNF := $(CA_CNF)'
	@echo 'CA_KEY := $(CA_KEY)'
	@echo 'CA_PEM := $(CA_PEM)'

	@echo
	@echo 'CLIENT_CNF := $(CLIENT_CNF)'
	@echo 'CLIENT_KEY := $(CLIENT_KEY)'
	@echo 'CLIENT_CSR := $(CLIENT_CSR)'
	@echo 'CLIENT_CRT := $(CLIENT_CRT)'
	@echo 'CLIENT_PEM := $(CLIENT_PEM)'

	@echo
	@echo 'SERVER_CNF := $(SERVER_CNF)'
	@echo 'SERVER_KEY := $(SERVER_KEY)'
	@echo 'SERVER_CSR := $(SERVER_CSR)'
	@echo 'SERVER_CRT := $(SERVER_CRT)'
	@echo 'SERVER_PEM := $(SERVER_PEM)'

	@echo
	@echo 'MONGO_CNF := $(MONGO_CNF)'
	@echo 'MONGO_USER_SCRIPT := $(MONGO_USER_SCRIPT)'

	@echo
	@echo 'DOCKER_IMAGE_NAME := $(DOCKER_IMAGE_NAME)'
	@echo 'DOCKER_CONTAINER_NAME := $(DOCKER_CONTAINER_NAME)'

# run but with debug verbosity
.PHONY: debug
debug:
	@MM_VERBOSITY=debug $(MAKE) run

# locally run cmds in order
# (not perfect because if there were more I'd be stuck but I only have for now)
.PHONY: run
run: start-db
	@runCleanup () { \
		$(MAKE) stop-db; \
	}; trap runCleanup EXIT; go run $(CMD)/main.go

.PHONY: ca
ca $(CA_KEY) $(CA_PEM): $(CA_CNF)
	@openssl req -x509 \
	-config $(CA_CNF) -nodes \
	-newkey rsa -keyout $(CA_KEY) \
	-out $(CA_PEM) -outform PEM > /dev/null

.PHONY: server-cert
server-cert $(SERVER_KEY) $(SERVER_CSR) $(SERVER_CRT) $(SERVER_PEM): $(SERVER_CNF) $(SERVER_CNF) $(CA_KEY) $(CA_PEM)
	@openssl req \
	-config $(SERVER_CNF) -nodes \
	-newkey rsa -keyout $(SERVER_KEY) \
	-out $(SERVER_CSR) > /dev/null
	@openssl x509 -req -in $(SERVER_CSR) \
	-CA $(CA_PEM) -CAkey $(CA_KEY) -CAcreateserial \
	-out $(SERVER_CRT) > /dev/null
	@cat $(SERVER_CRT) $(SERVER_KEY) > $(SERVER_PEM)

.PHONY: client-cert
client-cert $(CLIENT_KEY) $(CLIENT_CSR) $(CLIENT_CRT) $(CLIENT_PEM): $(CLIENT_CNF) $(CLIENT_CNF) $(CA_KEY) $(CA_PEM)
	@openssl req \
	-config $(CLIENT_CNF) -nodes \
	-newkey rsa -keyout $(CLIENT_KEY) \
	-out $(CLIENT_CSR) > /dev/null
	@openssl x509 -req -in $(CLIENT_CSR) \
	-CA $(CA_PEM) -CAkey $(CA_KEY) -CAcreateserial \
	-out $(CLIENT_CRT) > /dev/null
	@cat $(CLIENT_CRT) $(CLIENT_KEY) > $(CLIENT_PEM)

.PHONY: rm-certs
rm-certs:
	cd $(CERT_DIR) && rm -f $(shell ls -1 $(CERT_DIR) | grep -v .conf)
	rm -f .srl

.PHONY: new-db
new-db: rm-db $(MONGO_CNF) $(MONGO_USER_SCRIPT) $(CA_PEM) $(SERVER_PEM) $(CLIENT_PEM) Dockerfile
	@docker build -t $(DOCKER_IMAGE_NAME) .
	@docker create -p 27017:27017/tcp --name $(DOCKER_CONTAINER_NAME) $(DOCKER_IMAGE_NAME) > /dev/null

.PHONY: start-db
start-db: new-db
	@/bin/echo -n "Starting local database..."
	@docker start $(DOCKER_CONTAINER_NAME) > /dev/null
	@echo "OK"
# manually connecting to the database as the api user
# from in container: mongo --tls --tlsCertificateKeyFile tls/client.pem --tlsCAFile tls/ca.pem --authenticationDatabase '$external' --authenticationMechanism MONGODB-X509 --host localhost:27017 mattmanzi_com
# from host machine: mongo --tls --tlsCertificateKeyFile ./.local/x509/client.pem --tlsCAFile ./.local/x509/ca.pem --authenticationDatabase '$external' --authenticationMechanism MONGODB-X509 --host localhost:27017 mattmanzi_com

.PHONY: stop-db
stop-db:
	@/bin/echo -n "Stopping local database..."
	-@docker stop $(DOCKER_CONTAINER_NAME) > /dev/null
	@echo "done"

.PHONY: rm-db
rm-db: stop-db
	docker rm -f $(DOCKER_CONTAINER_NAME)
	docker rmi -f $(DOCKER_IMAGE_NAME)

# build binaries
.PHONY: build
build: $(BIN)

$(BIN):
	GOOS=$(BUILD_TARGET_OS) \
	GOARCH=$(BUILD_TARGET_ARCH) \
	go build -o $(BIN) $(CMD)/main.go

.PHONY: rm-bin
rm-bin:
	rm -rf $(BIN_DIR)

# run golang tests
.PHONY: test unit-tests
test unit-tests:
	@go test -v ./...

%_test.go: %.go
	@go test -v $@

.PHONY: test-clean
test-clean:
	go clean -testcache

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
clean: rm-bin test-clean rm-db rm-certs

.PHONY: build setup test docker-build \
				run-testnet run-testnet-offline run-mainnet run-mainnet-offline \
				check-testnet-data check-testnet-construction check-mainnet-data

PROJECT             ?= avalanche-rosetta
GIT_COMMIT          ?= $(shell git rev-parse HEAD)
GO_VERSION          ?= $(shell go version | awk {'print $$3'})
WORKDIR             ?= $(shell pwd)
DOCKER_ORG          ?= avaplatform
DOCKER_IMAGE        ?= ${DOCKER_ORG}/${PROJECT}
DOCKER_LABEL        ?= latest
DOCKER_TAG          ?= ${DOCKER_IMAGE}:${DOCKER_LABEL}
AVALANCHE_VERSION   ?= v1.4.7
ROSETTA_CLI_VERSION ?= 0.6.7

build:
	go build -o ./rosetta-server ./cmd/server
	go build -o ./rosetta-runner ./cmd/runner

setup:
	go mod download

test:
	go test -v -cover -race ./...

docker-build:
	docker build \
		--build-arg AVALANCHE_VERSION=${AVALANCHE_VERSION} \
		--build-arg ROSETTA_VERSION=${GIT_COMMIT} \
		--build-arg ROSETTA_CLI_VERSION=${ROSETTA_CLI_VERSION} \
		-t ${DOCKER_TAG} \
		-f Dockerfile \
		.

docker-build-standalone:
	docker build \
		--build-arg ROSETTA_VERSION=${GIT_COMMIT} \
		-t ${DOCKER_ORG}/${PROJECT}-server:${DOCKER_LABEL} \
		-f Dockerfile.rosetta \
		.

# Start the Testnet in ONLINE mode
run-testnet:
	docker run \
		--rm \
		-d \
		-v ${WORKDIR}/.avalanchego:/root/.avalanchego \
		-e AVALANCHE_NETWORK=Fuji \
		-e AVALANCHE_CHAIN=43113 \
		-e AVALANCHE_MODE=online \
		--name avalanche-testnet \
		-p 8080:8080 \
		-p 9650:9650 \
		-p 9651:9651 \
		-it \
		${DOCKER_TAG}

# Start the Testnet in OFFLINE mode
run-testnet-offline:
	docker run \
		--rm \
		-d \
		-e AVALANCHE_NETWORK=Fuji \
		-e AVALANCHE_CHAIN=43113 \
		-e AVALANCHE_MODE=offline \
		--name avalanche-testnet-offline \
		-p 8080:8080 \
		-p 9650:9650 \
		-it \
		${DOCKER_TAG}

# Start the Mainnet in ONLINE mode
run-mainnet:
	docker run \
		--rm \
		-d \
		-v ${WORKDIR}/.avalanchego:/root/.avalanchego \
		-e AVALANCHE_NETWORK=Mainnet \
		-e AVALANCHE_CHAIN=43114 \
		-e AVALANCHE_MODE=online \
		--name avalanche-mainnet \
		-p 8080:8080 \
		-p 9650:9650 \
		-p 9651:9651 \
		-it \
		${DOCKER_TAG}

# Start the Mainnet in ONLINE mode
run-mainnet-offline:
	docker run \
		--rm \
		-d \
		-e AVALANCHE_NETWORK=Mainnet \
		-e AVALANCHE_CHAIN=43114 \
		-e AVALANCHE_MODE=offline \
		--name avalanche-mainnet-offline \
		-p 8080:8080 \
		-p 9650:9650 \
		-it \
		${DOCKER_TAG}

# Perform the Testnet data check
check-testnet-data:
	rosetta-cli check:data --configuration-file=/app/rosetta-cli-conf/testnet/config.json

# Perform the Testnet construction check
check-testnet-construction:
	rosetta-cli check:construction --configuration-file=/app/rosetta-cli-conf/testnet/config.json

# Perform the Mainnet data check
check-mainnet-data:
	rosetta-cli check:data --configuration-file=/app/rosetta-cli-conf/mainnet/config.json

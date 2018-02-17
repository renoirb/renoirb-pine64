SHELL := /bin/bash

ELASTICSEARCH_VERSION := 6.2.1
ELASTICSEARCH_TARBALL_SHA1 := 12ad78a5ef0a5de487f264f4efdfc4735155462e525a9a75343f4678f84daa0021ad1e5637e754eb55672bfa63f5c34ff6252de36b09539f08735cdd26499ab4
HTTP_PREFIX := https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch
ELASTICSEARCH_TARBALL := $(HTTP_PREFIX)-$(ELASTICSEARCH_VERSION).tar.gz
#ELASTICSEARCH_TARBALL_SHA512 := $(HTTP_PREFIX)-$(ELASTICSEARCH_VERSION).tar.gz.sha512
#ELASTICSEARCH_TARBALL_ASC := $(HTTP_PREFIX)-$(ELASTICSEARCH_VERSION).tar.gz.asc

# Get the part after : in Id string, e.g. from:
# sha256:c9e89cbdc3f7625ac36e840c75a76fd74a7fa2081847e47601459cb01f365f38
# So we can get:
# c9e89cbdc3f7625ac36e840c75a76fd74a7fa2081847e47601459cb01f365f38
IMAGE_ID := $(word 2, $(subst :, ,$(shell docker image inspect --format='{{.Id}}' arm64v8-elasticsearch)))
ES_ENV_NAME := SERVICE_NAME=local
ES_ENV_IP := SERVICE_IP=10.1.10.240

packages:
	mkdir -p packages

packages/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz: packages
	curl -sSL $(ELASTICSEARCH_TARBALL) -o packages/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz

.PHONY: build
build: packages/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz
	docker build -t arm64v8-elasticsearch --force-rm --rm=true .

.PHONY: publish
publish:
	$(info Tagging $(IMAGE_ID))
	docker tag $(IMAGE_ID) renoirb/arm64v8-elasticsearch:latest
	docker push renoirb/arm64v8-elasticsearch

.PHONY: stack
stack:
	docker stack deploy -c docker-compose.yaml es
	docker service logs -f es_elasticsearch

.PHONY: debug
debug:
	docker run -it --entrypoint=sh arm64v8-elasticsearch

.PHONY: run
run:
	docker run -it --rm -P --env "$(ES_ENV_IP)" --env "$(ES_ENV_NAME)" arm64v8-elasticsearch


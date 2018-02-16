SHELL := /bin/bash

ELASTICSEARCH_VERSION := 6.2.1
ELASTICSEARCH_TARBALL_SHA1 := 12ad78a5ef0a5de487f264f4efdfc4735155462e525a9a75343f4678f84daa0021ad1e5637e754eb55672bfa63f5c34ff6252de36b09539f08735cdd26499ab4
HTTP_PREFIX := https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch
ELASTICSEARCH_TARBALL := $(HTTP_PREFIX)-$(ELASTICSEARCH_VERSION).tar.gz
#ELASTICSEARCH_TARBALL_SHA512 := $(HTTP_PREFIX)-$(ELASTICSEARCH_VERSION).tar.gz.sha512
#ELASTICSEARCH_TARBALL_ASC := $(HTTP_PREFIX)-$(ELASTICSEARCH_VERSION).tar.gz.asc

IMAGE_ID := $(shell docker image inspect --format='{{.Id}}' arm64v8-elasticsearch)

packages:
	mkdir -p packages

packages/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz: packages
	curl -sSL $(ELASTICSEARCH_TARBALL) -o packages/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz

.PHONY: build
build: packages/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz
	docker build -t arm64v8-elasticsearch --force-rm --rm=true .


.PHONY: publish
publish:
	$(info IMAGE_ID)
	#docker push renoirb/arm64v8-elasticsearch

.PHONY: debug
debug:
	docker run -i -t --entrypoint=sh arm64v8-elasticsearch

.PHONY: run
run:
	docker run -i -P arm64v8-elasticsearch


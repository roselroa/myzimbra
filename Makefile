IMAGE=zimbra_centos

.PHONY: all build

all: build

build:
	docker build --rm -t $(IMAGE) .

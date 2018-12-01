.PHONY: all build

all: build

build: vendor/protobuf-3.6.1/src/protoc
	mkdir -p build
	cd build && \
		PATH="$$PWD/vendor/protobuf-3.6.1/src:$$PATH" \
		cmake .. -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=dist \
			-DPROTOBUF_SRC_ROOT_FOLDER="$$PWD/vendor/protobuf-3.6.1" \
	&& make && make install

PROTO_RELEASE = https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/protobuf-cpp-3.6.1.tar.gz
vendor/protobuf-3.6.1/src/protoc:
	mkdir -p vendor && cd vendor && \
		curl --location $(PROTO_RELEASE) | tar xzf -
	cd vendor/protobuf-3.6.1 && ./configure && make -j4

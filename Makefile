
REQUIRED_STRUCTURE=src/github.com/MQLLAB/MUKLA
TEST?=$$(go list ./... | grep -v /vendor/)
DEPS = $(shell go list -f '{{range .TestImports}}{{.}} {{end}}' ./...)
VETARGS=-asmdecl -atomic -bool -buildtags -copylocks -methods \
				-nilfunc -printf -rangeloops -shift -structtags -unsafeptr

VERSION:=$(shell date +"%Y%d%m-%H%M%S")

all: clean version build cover release

version:
		echo "${VERSION}" > VERSION

verify:
		echo "Verifying path of project conforms to expected setup and includes ${REQUIRED_STRUCTURE}"
		test -d $(GOPATH)/${REQUIRED_STRUCTURE}

fmt: verify
		mkdir -p tmp
		go fmt .

vet: fmt
		go tool vet ${VETARGS} $$(ls -d */ | grep -v vendor)

test: fmt
		go test -v -timeout=30s -parallel=4 $(TEST)

cover:
		contrib/coverage.sh

build: test vet
		GOOS=darwin GOARCH=amd64 go build -ldflags "-X main.version=${VERSION} -s -w" -o bin/mukla-darwin-amd64-${VERSION} main.go
		GOOS=linux GOARCH=amd64 go build -ldflags "-X main.version=${VERSION} -s -w" -o bin/mukla-linux-amd64-${VERSION} main.go
		GOOS=windows GOARCH=amd64 go build -ldflags "-X main.version=${VERSION} -s -w" -o bin/mukla-windows-amd64-${VERSION}.exe main.go
		rm -rf tmp

release: build
		chmod +x bin/mukla-darwin-amd64-${VERSION}
		chmod +x bin/mukla-linux-amd64-${VERSION}
		tar -czvf bin/mukla-darwin-amd64-${VERSION}.tar.gz -C bin mukla-darwin-amd64-${VERSION}
		tar -czvf bin/mukla-linux-amd64-${VERSION}.tar.gz -C bin mukla-linux-amd64-${VERSION}
		zip -j bin/mukla-windows-amd64-${VERSION}.zip bin/mukla-windows-amd64-${VERSION}.exe

clean:
		rm -rf bin
		rm -rf tmp
		rm -f coverage.txt
		rm -f VERSION

.PHONY: all deps vet test cover build fmt clean

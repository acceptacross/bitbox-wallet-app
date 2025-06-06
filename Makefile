# Copyright 2018 Shift Devices AG
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SHELL    := /bin/bash
WEBROOT  := frontends/web

catch:
	@echo "Choose a make target."
envinit:
	# Keep golangci-lint version in sync with what's in .github/workflows/ci.yml.
	curl -sfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(shell go env GOPATH)/bin v1.61.0
	go install github.com/vektra/mockery/v2@v2.46.0
	go install github.com/matryer/moq@v0.4.0
	go install golang.org/x/tools/cmd/goimports@latest
	$(MAKE) gomobileinit
gomobileinit:
	# TODO: replace with go install golang.org/x/mobile/cmd/gomobile@latest once https://github.com/golang/mobile/pull/105 is merged.
	git clone https://github.com/BitBoxSwiss/mobile.git /tmp/mobile && cd /tmp/mobile/cmd/gomobile && go install .
	gomobile init
servewallet:
	go run -mod=vendor ./cmd/servewallet
servewallet-mainnet:
	go run -mod=vendor ./cmd/servewallet -mainnet
servewallet-regtest:
	rm -f appfolder.dev/cache/headers-rbtc.bin && rm -rf appfolder.dev/cache/account-*rbtc* && go run -mod=vendor ./cmd/servewallet -regtest
servewallet-prodservers:
	go run -mod=vendor ./cmd/servewallet -devservers=false
servewallet-mainnet-prodservers:
	go run -mod=vendor ./cmd/servewallet -mainnet -devservers=false
buildweb:
	node --version
	npm --version
	rm -rf ${WEBROOT}/build
	cd ${WEBROOT} && npm ci
	cd ${WEBROOT} && npm run build
webdev:
	cd ${WEBROOT} && $(MAKE) dev
weblint:
	cd ${WEBROOT} && $(MAKE) lint
webfix:
	cd ${WEBROOT} && $(MAKE) fix
webtest:
	cd ${WEBROOT} && $(MAKE) jstest
webtestwatch:
	cd ${WEBROOT} && $(MAKE) jstest-watch
qt-linux: # run inside dockerdev
	$(MAKE) buildweb
	cd frontends/qt && $(MAKE) linux
qt-osx: # run on OSX.
	$(MAKE) buildweb
	cd frontends/qt && $(MAKE) osx
	$(MAKE) osx-sec-check
qt-windows:
	$(MAKE) buildweb
	cd frontends/qt && $(MAKE) windows
android:
	$(MAKE) buildweb
	cd frontends/android && ${MAKE} apk-debug
ios:
	cd frontends/ios && ${MAKE} build
osx-sec-check:
	@echo "Checking build output"
	./scripts/osx-build-check.sh
osx-create-dmg:
	@echo "Creating DMG installer"
	./scripts/osx-create-dmg.sh
ci:
	./scripts/ci.sh
clean:
	rm -rf ${WEBROOT}/build
	cd frontends/qt && $(MAKE) clean
	cd frontends/android && $(MAKE) clean
	cd backend/mobileserver && $(MAKE) clean

# The container image only supports amd64 bercause of "thyrlian/android-sdk"
# that downloads amd64 specific binaries
dockerinit:
	./scripts/container.sh build --platform linux/amd64 --pull -t shiftcrypto/bitbox-wallet-app:$(shell cat .containerversion) .
dockerdev:
	./scripts/dockerdev.sh
locize-push:
	cd ${WEBROOT}/src/locales && locize sync
locize-pull:
	cd ${WEBROOT}/src/locales && locize download
locize-fix:
	locize format ${WEBROOT}/src/locales --format json
go-vendor:
	go mod vendor

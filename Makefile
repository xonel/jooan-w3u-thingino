# Makefile — Firmware build, test, release targets

VERSION := $(shell cat VERSION)
TAG := v$(VERSION)

.PHONY: help version version-next version-major version-minor version-patch \
        build build-unique build-dual test release clean

help:
	@echo "Jooan W3-U Firmware Makefile"
	@echo ""
	@echo "Version: $(VERSION)"
	@echo ""
	@echo "Targets:"
	@echo "  version           Show current version"
	@echo "  version-next      Show next version options"
	@echo "  version-major     Bump major version (X.0.0)"
	@echo "  version-minor     Bump minor version (X.Y.0)"
	@echo "  version-patch     Bump patch version (X.Y.Z)"
	@echo "  build             Build both profiles (container)"
	@echo "  build-unique      Build unique profile only"
	@echo "  build-dual        Build dual profile only"
	@echo "  test              Run CI tests locally (QEMU)"
	@echo "  release           Create GitHub release (requires clean tree)"
	@echo "  clean             Clean build artifacts"

version:
	@echo $(VERSION)

version-next:
	@./scripts/version.sh next

version-major:
	./scripts/version.sh major

version-minor:
	./scripts/version.sh minor

version-patch:
	./scripts/version.sh patch

build: build-unique build-dual

build-unique:
	docker run --rm --userns=keep-id \
	  -v $(PWD):/workspace -v $(PWD)/overrides:/overrides \
	  -w /workspace -e BR2_DL_DIR=/dl \
	  ghcr.io/themactep/thingino-builder-image:latest \
	  bash -c "make CAMERA=jooan_w3u_t23n_sc2336p_unique_eth_atbm6132u defconfig build_fast pack"

build-dual:
	docker run --rm --userns=keep-id \
	  -v $(PWD):/workspace -v $(PWD)/overrides:/overrides \
	  -w /workspace -e BR2_DL_DIR=/dl \
	  ghcr.io/themactep/thingino-builder-image:latest \
	  bash -c "make CAMERA=jooan_w3u_t23n_sc2336p_dual_eth_atbm6132u defconfig build_fast pack"

test:
	@echo "Running validation checks..."
	@for bin in output/master/*/images/thingino-*.bin; do \
	  echo "Checking $$bin"; \
	  xxd -l 4 "$$bin" | grep -q "06050403" || { echo "FAIL: bad u-boot magic"; exit 1; }; \
	  xxd -s 0x70000 -l 4 "$$bin" | grep -q "27051956" || { echo "FAIL: bad kernel magic"; exit 1; }; \
	  xxd -s 0x200000 -l 4 "$$bin" | grep -q "68737173" || { echo "FAIL: bad rootfs magic"; exit 1; }; \
	  xxd -s 0x710000 -l 4 "$$bin" | grep -q "8519" || { echo "FAIL: bad data magic"; exit 1; }; \
	  echo "OK: $$bin"; \
	done
	@echo "All images valid!"

release:
	@if [ -z "$(VERSION_ARG)" ]; then \
	  echo "Usage: make release VERSION_ARG=x.y.z"; \
	  exit 1; \
	fi
	./scripts/release.sh $(VERSION_ARG)

clean:
	docker run --rm --userns=keep-id \
	  -v $(PWD):/workspace -v $(PWD)/overrides:/overrides \
	  -w /workspace -e BR2_DL_DIR=/dl \
	  ghcr.io/themactep/thingino-builder-image:latest \
	  bash -c "make CAMERA=jooan_w3u_t23n_sc2336p_unique_eth_atbm6132u clean && \
	           make CAMERA=jooan_w3u_t23n_sc2336p_dual_eth_atbm6132u clean"
	rm -rf output/
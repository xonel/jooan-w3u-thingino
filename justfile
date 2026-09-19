# justfile — Convenient commands for Jooan W3-U firmware development

# Version management
version:
	@cat VERSION

version-next:
	@./scripts/version.sh next

version-patch:
	./scripts/version.sh patch

version-minor:
	./scripts/version.sh minor

version-major:
	./scripts/version.sh major

# Build (requires Docker + thingino-builder-image)
build:
	@just build-unique && just build-dual

build-unique:
	docker run --rm --userns=keep-id \
	  -v {{pwd()}}:/workspace -v {{pwd()}}/overrides:/overrides \
	  -w /workspace -e BR2_DL_DIR=/dl \
	  ghcr.io/themactep/thingino-builder-image:latest \
	  bash -c "make CAMERA=jooan_w3u_t23n_sc2336p_unique_eth_atbm6132u defconfig build_fast pack"

build-dual:
	docker run --rm --userns=keep-id \
	  -v {{pwd()}}:/workspace -v {{pwd()}}/overrides:/overrides \
	  -w /workspace -e BR2_DL_DIR=/dl \
	  ghcr.io/themactep/thingino-builder-image:latest \
	  bash -c "make CAMERA=jooan_w3u_t23n_sc2336p_dual_eth_atbm6132u defconfig build_fast pack"

# Validation
test:
	@for bin in output/master/*/images/thingino-*.bin; do \
	  echo "Checking $$bin"; \
	  xxd -l 4 "$$bin" | grep -q "06050403" || { echo "FAIL: bad u-boot magic"; exit 1; }; \
	  xxd -s 0x70000 -l 4 "$$bin" | grep -q "27051956" || { echo "FAIL: bad kernel magic"; exit 1; }; \
	  xxd -s 0x200000 -l 4 "$$bin" | grep -q "68737173" || { echo "FAIL: bad rootfs magic"; exit 1; }; \
	  xxd -s 0x710000 -l 4 "$$bin" | grep -q "8519" || { echo "FAIL: bad data magic"; exit 1; }; \
	  echo "OK: $$bin"; \
	done
	@echo "All images valid!"

# Release
release version:
	@if [ -z "$$VERSION" ]; then \
	  echo "Usage: just release VERSION=x.y.z"; \
	  exit 1; \
	fi
	./scripts/release.sh "$$VERSION"

# Quick release with auto-patch bump
release-patch:
	@./scripts/version.sh patch
	@just release $(shell cat VERSION)

release-minor:
	@./scripts/version.sh minor
	@just release $(shell cat VERSION)

release-major:
	@./scripts/version.sh major
	@just release $(shell cat VERSION)

# Clean
clean:
	docker run --rm --userns=keep-id \
	  -v {{pwd()}}:/workspace -v {{pwd()}}/overrides:/overrides \
	  -w /workspace -e BR2_DL_DIR=/dl \
	  ghcr.io/themactep/thingino-builder-image:latest \
	  bash -c "make CAMERA=jooan_w3u_t23n_sc2336p_unique_eth_atbm6132u clean && \
	           make CAMERA=jooan_w3u_t23n_sc2336p_dual_eth_atbm6132u clean"
	rm -rf output/
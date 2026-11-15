# Makefile — Build, validate & package Jooan W3-U dual-sensor Thingino firmwares
# Uses official upstream https://github.com/themactep/thingino-firmware

VERSION := $(shell cat VERSION)
TAG := v$(VERSION)

CONTAINER_ENGINE ?= $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null)
BUILDER_IMAGE := ghcr.io/themactep/thingino-builder-image:latest
DL_IMAGE := ghcr.io/themactep/thingino-dl:latest
DL_CONTAINER := thingino-dl-cache

THINGINO_REPO := https://github.com/themactep/thingino-firmware.git
THINGINO_DIR ?= $(HOME)/.cache/thingino-w3u-build/thingino-firmware
CCACHE_DIR ?= $(HOME)/.buildroot-ccache

PROFILES := \
	jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u \
	jooan_w3u_t23n_cv2003_dual_eth+atbm6132u

ifeq ($(findstring podman,$(CONTAINER_ENGINE)),podman)
	CONTAINER_RUN := $(CONTAINER_ENGINE) run --rm --userns=keep-id
else
	CONTAINER_RUN := $(CONTAINER_ENGINE) run --rm --user $(shell id -u):$(shell id -g) --network=host
endif

.PHONY: help version prepare-thingino dl-cache build build-sc2336p build-cv2003 \
        collect validate release clean

help:
	@echo "Jooan W3-U Dual-Sensor Thingino Firmware (v$(VERSION))"
	@echo ""
	@echo "Targets:"
	@echo "  prepare-thingino  Clone/update official themactep/thingino-firmware & apply patches/profiles"
	@echo "  build             Build both dual-sensor firmwares (SC2336P + CV2003), validate & copy to firmware/"
	@echo "  build-sc2336p     Build Dual SC2336P profile only"
	@echo "  build-cv2003      Build Dual CV2003 profile only"
	@echo "  validate          Verify U-Boot 2013.07 SPL header + kernel/rootfs/data magics & SHA256SUMS"
	@echo "  clean             Remove build output directory"

version:
	@echo $(VERSION)

prepare-thingino:
	@mkdir -p "$(dir $(THINGINO_DIR))" "$(CCACHE_DIR)"
	@if [ ! -d "$(THINGINO_DIR)/.git" ]; then \
		git clone --depth 1 "$(THINGINO_REPO)" "$(THINGINO_DIR)"; \
	fi
	@git -C "$(THINGINO_DIR)" submodule update --init --depth 1
	@./scripts/apply-to-thingino.sh "$(THINGINO_DIR)"

dl-cache:
	@if ! $(CONTAINER_ENGINE) ps -a --format '{{.Names}}' | grep -q '^$(DL_CONTAINER)$$'; then \
		$(CONTAINER_ENGINE) pull $(DL_IMAGE) && \
		$(CONTAINER_ENGINE) create --name $(DL_CONTAINER) $(DL_IMAGE) /bin/true; \
	fi

build: prepare-thingino dl-cache
	@for cam in $(PROFILES); do \
		$(MAKE) build-one PROFILE="$$cam"; \
	done
	@$(MAKE) collect validate

build-sc2336p: prepare-thingino dl-cache
	@$(MAKE) build-one PROFILE="jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u"
	@$(MAKE) collect validate

build-cv2003: prepare-thingino dl-cache
	@$(MAKE) build-one PROFILE="jooan_w3u_t23n_cv2003_dual_eth+atbm6132u"
	@$(MAKE) collect validate

build-one:
	@echo "=== Building $(PROFILE) in $(BUILDER_IMAGE) ==="
	$(CONTAINER_RUN) \
		--volumes-from $(DL_CONTAINER) \
		-v "$(THINGINO_DIR)":/workspace \
		-v "$(THINGINO_DIR)/overrides":/overrides \
		-v "$(CCACHE_DIR)":/home/ubuntu/.buildroot-ccache \
		-w /workspace -e BR2_DL_DIR=/dl \
		$(BUILDER_IMAGE) \
		bash -c "sudo update-alternatives --install /usr/bin/install install /usr/bin/gnuinstall 100 2>/dev/null || true; WORKFLOW=1 PRISTINE=1 make CAMERA=$(PROFILE) defconfig build_fast pack"

collect:
	@mkdir -p firmware
	@for cam in $(PROFILES); do \
		img_dir="$(THINGINO_DIR)/output/master/$${cam}-3.10.14-uclibc/images"; \
		if [ -f "$$img_dir/thingino-$${cam}.bin" ]; then \
			cp -f "$$img_dir/thingino-$${cam}.bin" firmware/; \
			[ -f "$$img_dir/$${cam}.md" ] && cp -f "$$img_dir/$${cam}.md" firmware/ || true; \
		fi; \
	done
	@cd firmware && sha256sum thingino-jooan_w3u_t23n_*_dual_eth+atbm6132u.bin > SHA256SUMS.txt

validate:
	@echo "=== Validating firmware images ==="
	@for cam in $(PROFILES); do \
		bin="firmware/thingino-$${cam}.bin"; \
		[ -f "$$bin" ] || { echo "MISSING: $$bin"; exit 1; }; \
		size=$$(stat -c%s "$$bin"); \
		[ "$$size" -eq 8388608 ] || { echo "FAIL: $$bin size $$size != 8388608"; exit 1; }; \
		xxd -l 4 "$$bin" | grep -q "0605 0403" || { echo "FAIL: $$bin bad SPL magic"; exit 1; }; \
		xxd -s 12 -l 2 "$$bin" | grep -q "8037" || { echo "FAIL: $$bin not U-Boot 2013.07 (expected 0x80370000)"; exit 1; }; \
		dd if="$$bin" bs=1 count=327680 2>/dev/null | strings | grep -q "SPL 2013.07" || { echo "FAIL: $$bin missing SPL 2013.07 banner"; exit 1; }; \
		xxd -s 0x70000 -l 4 "$$bin" | grep -q "2705 1956" || { echo "FAIL: $$bin bad kernel uImage magic"; exit 1; }; \
		xxd -s 0x200000 -l 4 "$$bin" | grep -q "6873 7173" || { echo "FAIL: $$bin bad squashfs magic"; exit 1; }; \
		echo "OK: $$bin (8 MiB, U-Boot 2013.07, kernel+squashfs verified)"; \
	done
	@cd firmware && sha256sum -c SHA256SUMS.txt

clean:
	rm -rf "$(THINGINO_DIR)/output"

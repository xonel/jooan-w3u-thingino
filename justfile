# justfile — Jooan W3-U Dual-Sensor Thingino Firmware

version:
	@cat VERSION

prepare:
	@make prepare-thingino

build:
	@make build

build-sc2336p:
	@make build-sc2336p

build-cv2003:
	@make build-cv2003

validate:
	@make validate

clean:
	@make clean

# This refers to a submodule:
LUAC_CROSS=nodemcu-firmware/luac.cross

DEFAULT_PROJECT_FILES=*.lua includes/*.lua

.PHONY: upload format list restart

restart:
	nodemcu-tool reset

$(LUAC_CROSS):
	make -C nodemcu-firmware/app/lua/luac_cross

lfs.img: $(LUAC_CROSS) $(DEFAULT_PROJECT_FILES)
	$(LUAC_CROSS) -f -o lfs.img $(DEFAULT_PROJECT_FILES)

upload_lfs: lfs.img
	nodemcu-tool upload -c lfs.img
	@echo "---> lfs.img uploaded; now run node.flashreload(\"lfs.img\") on the device"

upload: upload_lfs init.lua
	nodemcu-tool upload init.lua

console:
	nodemcu-tool terminal



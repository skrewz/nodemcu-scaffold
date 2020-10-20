# This refers to a submodule:
LUAC_CROSS=nodemcu-firmware/luac.cross

DEFAULT_PROJECT_FILES=*.lua includes/*.lua

.PHONY: upload format list restart push_for_ota upload_lfs console terminal lfs_flash

restart:
	nodemcu-tool reset

$(LUAC_CROSS):
	make -C nodemcu-firmware/app/lua/luac_cross

lfs.img: $(LUAC_CROSS) $(DEFAULT_PROJECT_FILES) buildinfo.lua
	$(LUAC_CROSS) -f -o lfs.img $(DEFAULT_PROJECT_FILES)

upload_lfs: lfs.img
	nodemcu-tool upload -c lfs.img --remotename lfs_inc.img
	@echo "---> lfs.img uploaded; now run \`make lfs_flash\` on the device"

buildinfo.lua: .FORCE
	@echo "return {build_timestamp='$(shell date --utc +%Y-%m-%dT%H:%M:%SZ)'}" >  buildinfo.lua

upload: upload_lfs init.lua
	nodemcu-tool upload init.lua

push_for_ota: lfs.img device_ids.txt
	@# You'd put lines like 'c12345678 # some sensor' into device_ids.txt
	grep -o '^[^#]*' device_ids.txt | while read device_id; do \
	  rsync -v lfs.img 192.168.1.10:/var/www/imgs/$${device_id}.img || exit 1 ; \
	done

console:
	nodemcu-tool terminal

terminal:
	nodemcu-tool terminal

lfs_flash:
	# experimental stuff, for now (hard to catch the device while it's not busy)
	@echo "Flashing lfs_inc.img on device..."
	echo 'node.flashreload("lfs_inc.img")' | timeout 5 nodemcu-tool terminal 2>&1 || true | grep -q "LFS region updated."
	@echo "... seemed successful."

.FORCE:

# nodemcu-scaffold

A framework for deploying nodemcu Lua apps which tend to look very similar.

# An aside: submodules beware

This repo has submodules. You should thus **clone with git's `--recursive` flag**.

[nodemcu-libs](https://github.com/skrewz/nodemcu-libs) provides some of the functionality, and [nodemcu-firmware](https://github.com/nodemcu/nodemcu-firmware) is submoduled into here to facilitate [compiling `luac.cross`](https://nodemcu.readthedocs.io/en/master/lfs/#using-lfs) directly (cf. [Makefile](Makefile)).

# Why make this?

I noticed that my various nodemcu projects ended up containing a fair bit of boilerplate, repeated many times over. They essentially always needed to set up the same things, and only then differ in their "payload."

This framework encapsulates this, and makes efficient use of LFS to make fairly complex applications possible.


# Prerequisite: Building and flashing nodemcu-firmware

This framework uses the [Lua Flash Store](https://nodemcu.readthedocs.io/en/master/lfs/). To make use of this, you'll a [build](http://nodemcu-build.com/) an image with roughly these modules:

```
adc,bme280,bme680,file,gpio,i2c,mdns,mqtt,net,node,pwm,rtctime,sntp,spi,tmr,uart,wifi,tls
```

And crucially using a non-zero LFS size. I found 64KiB is sufficient, as these LFS images wind up around 30KiB in size.

Flash said firmware using e.g. [esptool.py](https://github.com/themadinventor/esptool):

```
$ ./esptool.py --port /dev/ttyUSB0 write_flash -fm qio 0x00000  nodemcu-master-*-modules-*.bin
esptool.py v2.2
Connecting....
Detecting chip type... ESP8266
Chip is ESP8266EX
Uploading stub...
Running stub...
Stub running...
Configuring flash size...
Auto-detected Flash size: 4MB
Flash params set to 0x0040
Compressed 475136 bytes to 309820...
Wrote 475136 bytes (309820 compressed) at 0x00000000 in 27.3 seconds (effective 139.2 kbit/s)...
Hash of data verified.

Leaving...
Hard resetting...
```

# Uploading

Two step process thus far. To build and upload a file named `lfs.img` to SPIFFS as well as `init.lua`:

```sh
make upload
```

At this point, you'll need to `make console` onto the serial terminal of the device and run `node.flashreload("lfs.img")` from there. It should print `LFS region updated.  Restarting.` in response (and then reboot). At this point, the firmware is operational and will attempt to connect to my MQTT broker.


# Adapting this

This is written for my purposes, but published in the hope that the approaches contained herewithin are useful to others. E.g. the mqtt broker hostname is only superficially configurable.

If you do find yourself adapting this pattern to your use case, drop me a line on [skrewz@skewz.net](mailto:skrewz@skrewz.net), or lodge an issue against the github project or somesuch.

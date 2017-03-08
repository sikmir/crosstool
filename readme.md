# Embox Crosstool
[![Build Status](https://travis-ci.org/embox/crosstool.svg?branch=master)](https://travis-ci.org/embox/crosstool)

Embox maintains a number of crosstools (binutils, gcc, gdb) that are most likely to work
for embox supported targets. This repo holds `crosstool.sh`, a script that builds crosstool
for:
* `i386`
* `microblaze`
* `mips`
* `msp430`
* `powerpc`
* `sparc`

For prebuild linux binary please refer to Release section.

The rest of README describes how to build crosstool by yourself.
In following text `ARCH` mean some architecture from  listed above.

### Prerequisites
> sudo apt-get install libisl-dev libcloog-isl-dev gcc-multilib g++-multilib libncurses5-dev texinfo bzip2 xz-utils make flex file

### Building
> ./crosstool.sh ARCH

It will download all necessary sources, unpack it, configure, compile and pack `ARCH-elf-toolchain.tar.bz2`

### Installing
Unpack ARCH-elf-toolchain.tar.bz2 and add /dest/ARCH-elf-toolchain/bin to $PATH. Or, just run
> ./install_crosstool.sh ARCH

### Using QEMU to run image

In some distros (e.g. Debian) default QEMU version doesn't support some features (e.g. overo ARM machine type), so we recommend to use Linaro QEMU as it's compatible with Embox auto_qemu.sh script.

Source could be obtained here:
> https://launchpad.net/qemu-linaro/trunk/2014.01/+download/qemu-linaro-1.7.0-2014.01.tar.gz

Before you start, make sure that you don't have QEMU installed from repos
> sudo apt-get remove qemu*

Then you will need some packages to build qemu from source
> sudo apt-get install zlib1g-dev libglib2.0-dev autoconf libtool libpixman-1-dev device-tree-compiler libfdt-dev

Finally, you can build and install it
> cd /path/to/source/qemu-linaro-1.7.0-2014.01/ && ./configure && make && sudo make install

# For Crosstool developers

Once you've updated crosstool.sh or target subscript, pushed you changes, and got OK status from travis,
you could tag you commit, then travis will rebuild the crosstools and publish build artifacts in Release section.
Workflow is like:
> git commit && git push # Suppose travis failed to build everything
> git commit && git push # Suppose travis went OK
> git tag -f current # Tag latest commit with `current` tag, overriding previous tag value
> git push origin current # Push tag, triggers travis to publish result under `current` release

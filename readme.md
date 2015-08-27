# Embox Crosstool
This toolkit will help you to build cross-compiler for various architectures. Supported:
* `i386`
* `microblaze`
* `mips`
* `msp430`
* `powerpc`
* `sparc`

In following text `ARCH` mean some architecture from  listed above.

### Prerequisites
> sudo apt-get install libisl-dev libcloog-isl-dev gcc-multilib g++-multilib libncurses5-dev texinfo

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

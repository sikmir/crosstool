#!/bin/bash

# Build a GNU/Linux cross-toolchain
# $Id$

set -e

print_msg() {
	echo -e $1 | tee -a $LOG_FILE
}

error_exit() {
	print_msg "$1"
	exit 1
}

print_help() {
	echo "USAGE: $0 [-j JOBS] ARCH"
	echo "ARCH is one of:"
	ls *.in | sed 's/\.in//; s/^/    /'
}

JOBS=$(nproc || echo 4)
while getopts j:h arg; do
	case $arg in
		h) print_help; exit 0 ;;
		j) JOBS="$OPTARG" ;;
		?) print_help; error_exit "Unknown argument";;
	esac
done
shift $(($OPTIND - 1))
CROSSTOOL_ARCH=$1

[ ! -z $CROSSTOOL_ARCH ] || error_exit "Provide ARCH name, refer to $0 -h"
[ -f $CROSSTOOL_ARCH.in ] || error_exit "This arch is not supported, refer to $0 -h"

. ./$CROSSTOOL_ARCH.in

# Create temp working dir
if [ ! -e build-$CROSSTOOL_ARCH ]; then 
	mkdir build-$CROSSTOOL_ARCH
fi

CUR_DIR=$(pwd)

BUILD_DIR=$CUR_DIR/build-$CROSSTOOL_ARCH

LOG_FILE=$BUILD_DIR/emtool.log

PATCHES_DIR=$CUR_DIR/patches

PATCHES="$(ls $PATCHES_DIR/*.patch 2>/dev/null || true) 
	$(ls $PATCHES_DIR/$CROSSTOOL_ARCH/*.patch 2>/dev/null || true)"

# Keys:
#  0 - binutils
#  1 - gcc
#  2 - gdb
GET_URL=( \
"https://sourceware.org/pub/binutils/releases/binutils-2.44.tar.bz2" \
"https://sourceware.org/pub/gcc/releases/gcc-14.3.0/gcc-14.3.0.tar.gz" \
"https://sourceware.org/pub/gdb/releases/gdb-15.2.tar.xz")

DOWNLOAD=../download

for i in $(seq 0 $((${#GET_URL[@]} - 1))); do
	TARBALL[$i]=$(basename ${GET_URL[$i]})
	NAME[$i]=${TARBALL[$i]%%.tar.*}
done

MAKE_FLAGS="${MAKE_FLAGS} -j$JOBS"

do_download() {
	local downloaded=".downloaded"
	print_msg "Download sources"
    if [ ! -e $downloaded ]; then
        for i in $(seq 0 $((${#GET_URL[@]} - 1))); do
        	print_msg "Downloading ${TARBALL[$i]}"
        	wget -c ${GET_URL[$i]} -P $DOWNLOAD
    	done
    fi
	print_msg "Download done"
	touch $downloaded
}

do_unpack() {
	local extracted=".extracted"
	local patched=".patched"
	print_msg "Extract sources"
	if [ ! -e $extracted ]; then
		for i in $(seq 0 $((${#GET_URL[@]} - 1))); do
			print_msg "Extracting ${TARBALL[$i]}"
			unzip_tar=$(echo ${TARBALL[$i]} | sed 's/.*\.gz/z/;s/.*.\.bz2/j/;s/.*\.xz/J/')
			[ -d ${NAME[$i]} ] || tar -${unzip_tar}xf $DOWNLOAD/${TARBALL[$i]}
			exit_code=$?
			[ $exit_code = 0 ] || exit $exit_code
		done

		print_msg "Download libraries required for gcc"
		pushd ${NAME[1]} > /dev/null
		./contrib/download_prerequisites
		popd > /dev/null
	fi
	print_msg "Extract done"
	touch $extracted

	print_msg "Apply patches"
	if [ ! -e $patched ]; then 
		for f in $PATCHES; do
			print_msg "Applying $f"
			patch -N -p0 < $f || print_msg "$f seems to be applied already"
		done
	fi
	print_msg "Patch done"
    touch $patched
}

do_binutils() {
	local source_dir="../${NAME[0]}"
	local build_dir="build-binutils"
	local install_dir="$BUILD_DIR/install-binutils"
	local binutils_done=".binutils_done"
	print_msg "Build binutils start"
	if [ ! -e $binutils_done ]; then
		if [ ! -d $build_dir ]; then
			mkdir $build_dir
		fi
		pushd $build_dir > /dev/null
		if [ ! -e Makefile ]; then
			$source_dir/configure \
				--prefix=$install_dir \
				--target=$TARGET \
				--with-float=soft \
				--enable-soft-float \
				--disable-werror \
				|| [ -e Makefile ] || error_exit "Configuration binutils failed"
		fi
		if ! make -q all; then
			make $MAKE_FLAGS all && make $MAKE_FLAGS install \
				|| error_exit "Building binutils failed"
		fi
		popd > /dev/null
	fi
	print_msg "Build binutils done"
	touch $binutils_done
}

do_gcc() {
	local source_dir="../${NAME[1]}"
	local build_dir="build-gcc"
	local install_dir="$BUILD_DIR/install-gcc"
	local binutils_dir="$BUILD_DIR/install-binutils"
	local path=$binutils_dir/bin:$PATH
	local gcc_done=".gcc_done"
	print_msg "Build gcc start"
	if [ ! -e $gcc_done ]; then
		if [ ! -d $build_dir ]; then
			mkdir $build_dir
		fi
		pushd $build_dir > /dev/null
		if [ ! -e Makefile ]; then
			PATH=$path $source_dir/configure \
				--prefix=$install_dir \
				--target=$TARGET \
				--disable-libssp \
				--disable-shared \
				--without-headers \
				--without-newlib \
				--with-gnu-as \
				--with-gnu-ld \
				--enable-languages=c,c++ \
				--enable-static \
				--enable-multilib \
				--enable-soft-float \
				"$TARGET_OPTIONS" \
				|| error_exit "Configuration gcc failed"
		fi
		if ! make -q all-gcc all-target-libgcc; then 
			PATH=$path make $MAKE_FLAGS all-gcc all-target-libgcc \
				&& PATH=$path make $MAKE_FLAGS install-gcc install-target-libgcc \
				|| error_exit "Building gcc failed"
		fi
		popd > /dev/null
	fi
	print_msg "Build gcc done"
	touch $gcc_done
}

do_gdb() {
	local source_dir="../${NAME[2]}"
	local build_dir="build-gdb"
	local install_dir="$BUILD_DIR/install-gdb"
	local gdb_done=".gdb_done"
	print_msg "Build gdb start"
	if [ ! -e $gdb_done ]; then
		if [ ! -d $build_dir ]; then
			mkdir $build_dir
		fi
		pushd $build_dir > /dev/null
		if [ ! -e Makefile ]; then
			$source_dir/configure \
				--prefix=$install_dir \
				--target=$TARGET \
				|| error_exit "Configuration gdb failed"
		fi
		if ! make -q all; then 
			make $MAKE_FLAGS all && make $MAKE_FLAGS install \
				|| error_exit "Building gdb failed"
		fi
		popd > /dev/null
	fi
	print_msg "Build gdb done"
	touch $gdb_done
}

makepkg() {
	local binutils_dir="install-binutils"
	local gcc_dir="install-gcc"
	local gdb_dir="install-gdb"
	local pkg_dir="$TARGET-toolchain"
	local pkg_done=".pkg_done"
	print_msg "Prepare package directory"
	if [ ! -e $pkg_done ]; then
		if [ -d $pkg_dir ]; then
			rm -rf $pkg_dir/*
		else
			mkdir $pkg_dir
		fi
		cp -r $binutils_dir/* $gcc_dir/* $gdb_dir/* $pkg_dir
		print_msg "Stripping..."
		find $pkg_dir | xargs file | grep -e "executable" -e "shared object" | grep ELF \
		  | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null
		print_msg "Make package"
		tar cf - $pkg_dir | bzip2 -f > ../${pkg_dir}.tar.bz2
	fi
	print_msg "Package done"
	touch $pkg_done
}

echo "" > $LOG_FILE

pushd $BUILD_DIR > /dev/null

print_msg "directory is $BUILD_DIR"

do_download && do_unpack && do_binutils && do_gcc && do_gdb && makepkg

popd > /dev/null

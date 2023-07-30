CPU ?= i386
ARCH ?= $(CPU)-linux-musl
CC = $(ARCH)-gcc
CFLAGS ?= -m32 -static -Os -Wall -Wextra
NASM ?= nasm
STRIP ?= $(ARCH)-strip
CORES ?= $(shell nproc)
LINUX ?= 5.8.9
BUSYBOX ?= 1.35.0
DOSLINUX = 0.0.2
DSL_ZIP = DSL$(subst .,,$(DOSLINUX))B.ZIP

HDD_BASE ?= hdd.base.img
LINUX_BZIMAGE = deps/linux-$(LINUX)/arch/x86/boot/bzImage
BUSYBOX_BIN = deps/busybox

LINUX_URL = https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$(LINUX).tar.gz
BUSYBOX_URL = https://www.busybox.net/downloads/binaries/$(BUSYBOX)-i686-linux-musl/busybox

SHELL := $(shell which bash)

.PHONY: all
all:		## Default target which builds a DSLxxxB.ZIP file with doslinux
all: dist

.PHONY: clean
clean:		## Remove any doslinux binaries, object files, ZIP file prep
clean:
	rm -rfv hdd.img doslinux.com init/init init/*.o deps/* \
$(DSL_ZIP) DOSLINUX/BZIMAGE DOSLINUX/INIT DOSLINUX/BUSYBOX \
DOSLINUX/DSL.COM DOSLINUX/ROOTFS/DOSLINUX.VER

ultraclean: clean
	sudo rm -v /usr/local/bin/$(ARCH)-*

$(HDD_BASE):
	dd if=/dev/zero of=$@ bs=1M count=500 status=progress

hdd.img:	## Old default target which requires an input HDD image $(HDD_BASE) and then modifies with mtools to include doslinux
hdd.img: $(HDD_BASE) doslinux.com init/init $(LINUX_BZIMAGE) $(BUSYBOX_BIN)
	cp -v $(HDD_BASE) hdd.img
	MTOOLSRC=mtoolsrc mmd C:/doslinux
	MTOOLSRC=mtoolsrc mcopy doslinux.com C:/doslinux/dsl.com
	MTOOLSRC=mtoolsrc mcopy init/init C:/doslinux/init
	MTOOLSRC=mtoolsrc mcopy $(LINUX_BZIMAGE) C:/doslinux/bzimage
	MTOOLSRC=mtoolsrc mcopy $(BUSYBOX_BIN) C:/doslinux/busybox
	MTOOLSRC=mtoolsrc mmd C:/doslinux/rootfs

doslinux.com: doslinux.asm
	$(NASM) -o $@ -f bin $<

init/init: init/init.o init/vm86.o init/panic.o init/kbd.o init/term.o
	$(CC) $(CFLAGS) -o $@ $^

init/%.o: init/%.c init/*.h /usr/local/bin/$(CC)
	$(CC) $(CFLAGS) -o $@ -c $<

deps/:
	mkdir -pv $@

deps/musl-cross-make/Makefile: deps/
	cd deps && \
	git clone --depth=1 https://github.com/richfelker/musl-cross-make.git

musl-cross-make-config-doslinux: Makefile
	echo "TARGET = $(ARCH)" > $@
	echo "OUTPUT = /usr/local" >> $@
# FIXME: This doesn't work the way musl-cross-make docs say it should
#	echo "COMMON_CONFIG += CC=\"$(ARCH)-linux-musl-gcc -static --static\"" >> $@
#	echo "COMMON_CONFIG += CXX=\"$(ARCH)-linux-musl-g++ -static --static\"" >> $@
	echo "COMMON_CONFIG += CFLAGS=\"-g0 -Os -static --static\"" >> $@
	echo "COMMON_CONFIG += CXXFLAGS=\"-g0 -Os -static --static\"" >> $@
	echo "COMMON_CONFIG += LDFLAGS=\"-s\"" >> $@

deps/musl-cross-make/config.mak: musl-cross-make-config-doslinux deps/musl-cross-make/Makefile
	cp -v musl-cross-make-config-doslinux $@

deps/musl-cross-make/build/local/$(ARCH)/obj_gcc/gcc/xgcc: deps/musl-cross-make/config.mak
	cd deps/musl-cross-make && \
	make -j$(CORES)

/usr/local/bin/$(CC): deps/musl-cross-make/build/local/$(ARCH)/obj_gcc/gcc/xgcc
	cd deps/musl-cross-make && \
	sudo make -j$(CORES) install

deps/linux-$(LINUX).tar.gz:
	wget -O $@ $(LINUX_URL)

deps/linux-$(LINUX)/Makefile: deps/linux-$(LINUX).tar.gz
	tar zxvf $< -C deps/
	touch deps/linux-$(LINUX)/Makefile

deps/linux-$(LINUX)/.config: deps/linux-$(LINUX)/Makefile linux-config-doslinux
	cp -v linux-config-doslinux $@

$(LINUX_BZIMAGE): deps/linux-$(LINUX)/.config
	cd deps/linux-$(LINUX) && \
	make -j$(CORES)

$(BUSYBOX_BIN):
	wget -O $@ $(BUSYBOX_URL)

.PHONY: dist
dist: $(DSL_ZIP)

DOSLINUX.VER: Makefile
	echo $(DOSLINUX) > $@

DOSLINUX/ROOTFS/DOSLINUX.VER: DOSLINUX.VER
	cp -v $< $@
DOSLINUX/DSL.COM: doslinux.com
	cp -v $< $@
DOSLINUX/INIT: init/init
	cp -v $< $@
DOSLINUX/BZIMAGE: $(LINUX_BZIMAGE)
	cp -v $< $@
DOSLINUX/BUSYBOX: $(BUSYBOX_BIN)
	cp -v $< $@

$(DSL_ZIP): DOSLINUX/ROOTFS/DOSLINUX.VER DOSLINUX/BZIMAGE
$(DSL_ZIP): DOSLINUX/INIT DOSLINUX/BUSYBOX DOSLINUX/DSL.COM
	zip -9vvr $@ DOSLINUX/

######################################################################

.PHONY: showconfig
showconfig:	## Shows the configuration variables for this Makefile and their current values
showconfig: p-DOSLINUX p-DSL_ZIP p-CORES p-CPU p-ARCH p-CC p-NASM
showconfig: p-STRIP p-LINUX p-LINUX_BZIMAGE p-LINUX_URL p-BUSYBOX
showconfig: p-BUSYBOX_BIN p-BUSYBOX_URL p-HDD_BASE p-SHELL

.PHONY: gstat
gstat:
	git status

.PHONY: gpush
gpush:
	git commit
	git push

define newline # a literal \n


endef
# Makefile debugging trick:
# call print-VARIABLE to see the runtime value of any variable
# (hardened a bit against some special characters appearing in the output)
p-%:
	@echo '$*=$(subst ','\'',$(subst $(newline),\n,$($*)))'
.PHONY: p-*

.PHONY: help
help:		## This help target
#	@awk '/^[a-zA-Z0-9\-_+. ]*:[ ]*##/ { print; }' Makefile
#	@RE='^[a-zA-Z0-9 .-_+]*:[a-zA-Z0-9 .-_+]*##' ; while read line ; do [[ "$$line" =~ $$RE ]] && echo "$$line" ; done <Makefile ; RE=''
	@RE='^[a-zA-Z0-9 .-_+]*:.*##' ; while read line ; do [[ "$$line" =~ $$RE ]] && echo "$$line" ; done <Makefile ; RE=''

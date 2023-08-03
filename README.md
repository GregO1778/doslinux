# DOS Subsystem for Linux

A WSL alternative for users who prefer an MS-DOS environment. DOS Subsystem for Linux integrates a real Linux environment into MS-DOS systems, allowing users to make use of both DOS and Linux applications from the DOS command prompt.

![](https://user-images.githubusercontent.com/179065/178898715-7e30135c-7afd-4f37-83cc-cf49a4d46d79.gif)

## Builing
* Building doslinux will need about 5GB of disk space.

* doslinux depends on several packages.  In Fedora 38, run

`sudo dnf install wget git patch bzip2 gcc glibc glibc-static g++ libstdc++ libstdc++-static make binutils flex bison openssl-devel mtools nasm zip unzip bc`

In Ubuntu 22.04, run

`sudo apt install build-essential git gcc make nano flex bison libssl-dev mtools nasm zip unzip bc`

In a VM configured for 16 CPUs, 16GB RAM, hosted on a dual Intel Xeon E5-2680 v4 2.4GHz hypervisor (a 9 year old server in 2023), full builds take about 15 miniutes.

* The included `Makefile` will download `gcc`, `binutils`, `busybox` (1.35.0), and `https://github.com/richfelker/musl-cross-make` for you.

* The included `Makefile` will then build a `i386-linux-musl` cross-compiler and Linux 5.8.9 kernel for you.

* Adjust the variables at the top of `Makefile` if you would like to use a higher/lower `$(ARCH)` or different kernel. (NOTE: this is quite working correctly yet)

* Running `make` is an alias for `make dist` which will result in a `DSLxxxB.ZIP` file containing `doslinux`, `init`, a Linux `bzImage` kernel, and `busybox`.

* After the completion of building the cross-compiler, `sudo make -j$(CORES) install` is executed to put the cross-compiler toolchain in your `/usr/local/` path.

* You can unzip roughly 6.5MB `DSLxxxB.ZIP` zipfile onto a DOS system, like MS-DOS or FreeDOS, and then start doslinux by running a command like `C:\DSL\dsl` or `C:\DSL\dsl sh` (giving you a shell into the loaded Linux).

## Old Build Instructions

* You will need a cross toolchain targeting `i386-linux-musl` on `PATH`.

  https://github.com/richfelker/musl-cross-make is a tool that can build one for you with minimal hassle. Set `TARGET` to `i386-linux-musl`.

* Build the prequisites (Linux and Busybox) by running `J=xxx script/build-prereq`, replacing `xxx` with the desired build parallelism.

* You will need a hard drive image `hdd.base.img` with an installed copy of MS-DOS on the first partition.

* Run `make`

  This will produce a new hard drive image `hdd.img` with DOS Subsystem for Linux installed. Invoke `C:\doslinux\dsl <command>` to run Linux commands. `C:\doslinux` can also be placed on your DOS `PATH` for greater convenience.

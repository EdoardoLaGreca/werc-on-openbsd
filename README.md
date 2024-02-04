# werc-on-openbsd

Automate [Werc](http://werc.cat-v.org/) setup on [OpenBSD](https://www.openbsd.org/).

~~The `setup.sh` script has been successfully tested on OpenBSD 7.2. Prior or later version of OpenBSD may not work.~~

**The `setup.sh` script has not been tested since the last change. Proceed with caution.**

The `unsetup.sh` script has not been tested yet, but it is supposed to work.

To preserve the original config files that are going to be modified, the setup script makes a copy (backup) of them and adds `.bk` at the end of their name. For example, the original `/etc/httpd.conf` file is copied to `/etc/httpd.conf.bk`. To restore the original files, the unsetup script renames the backup files with their original name. For this reason, **before running `setup.sh`, make sure to NOT have `/etc/httpd.conf.bk` or `/etc/fstab.bk` in your filesystem.**

## How-To

### Setup

 1. download the setup script (`setup.sh`)
    ```sh
    ftp https://raw.githubusercontent.com/EdoardoLaGreca/werc-on-openbsd/main/setup.sh
    ```
 2. verify its checksum (see [Checksums](#checksums))
    ```sh
    sha256 -q setup.sh
    ```
 3. make it executable
    ```
    chmod 744 setup.sh
    ```
 4. change the `domain` variable (and `webdir` if necessary) in `setup.sh`
 5. start the script as root
    ```sh
    doas ./setup.sh
    ```

### Un-setup

 1. download the unsetup script (`unsetup.sh`)
    ```sh
    ftp https://raw.githubusercontent.com/EdoardoLaGreca/werc-on-openbsd/main/unsetup.sh
    ```
 2. verify its checksum (see [Checksums](#checksums))
    ```sh
    sha256 -q unsetup.sh
    ```
 3. make it executable
    ```
    chmod 744 setup.sh
    ```
 4. change the `domain` and `webdir` variables as they were in `setup.sh`
 5. start the script as root
    ```sh
    doas ./unsetup.sh
    ```

## Checksums

### `setup.sh`

SHA-256: `a5dd15229bca1e1eb5206116343af9dc2a9b54af09f66d5c7dbf2a9880316f2b`

### `unsetup.sh`

SHA-256: `adda9770c29947dc2c3af94e0913460884561a6ad15723d6bee38599b20a7d66`

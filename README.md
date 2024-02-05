# werc-on-openbsd

Automate [Werc](http://werc.cat-v.org/) setup on [OpenBSD](https://www.openbsd.org/).

Both the `setup.sh` and `unsetup.sh` scripts have been successfully tested on OpenBSD 7.4. Prior or later version of OpenBSD may not work.

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

SHA-256: `d273f93a62f7b5343b8aed1cf985e27fce1e1ba4b6249134114f8a09cac268e2`

### `unsetup.sh`

SHA-256: `e06b8082fb356a06d1dcde78488ba673edad14c0d754e54717f5b97116b4c49b`

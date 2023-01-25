# werc-on-openbsd

Automate [Werc](http://werc.cat-v.org/) setup on [OpenBSD](https://www.openbsd.org/).

The `setup.sh` script has been successfully tested on OpenBSD 7.2. Prior or later version of OpenBSD may not work.

## How-To

 1. download the setup script (`setup.sh`)
    ```sh
    ftp https://raw.githubusercontent.com/EdoardoLaGreca/werc-on-openbsd/main/setup.sh
    ```
 2. verify its checksum (see [Checksums](#checksums))
    ```sh
    sha256 -q setup.sh
    ```
 3. (optional) if you're a paranoid, you may want to check the script content before running it
 4. start the script as root
    ```sh
    doas ./setup.sh
    ```

## Checksums

### `setup.sh`

SHA-256: `38ea5ce4ee6cf74aad983dc6955d5dc0dca45306897817b5aee93d630ffe7734`

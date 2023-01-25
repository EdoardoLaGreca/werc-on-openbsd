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
 4. change the `domain` variable (and `webdir`, if necessary) in `setup.sh`
 5. start the script as root
    ```sh
    doas ./setup.sh
    ```

## Checksums

### `setup.sh`

SHA-256: `53950aa8076e52a5b3cbed754cfa9c1e0fb97e46c4f79d2511d6c51c4e8aeb9b`

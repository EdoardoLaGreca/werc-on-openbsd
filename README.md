werc-on-openbsd
===============

Automate [Werc](http://werc.cat-v.org/) setup on [OpenBSD](https://www.openbsd.org/).

## Useful info

Both the `setup.sh` and `unsetup.sh` scripts, in their latest available version ([v2.2](https://github.com/EdoardoLaGreca/werc-on-openbsd/releases/tag/v2.2)), have been successfully tested on the latest available OpenBSD stable release (7.7). Prior or later versions of OpenBSD may not work.

**Performing an OpenBSD release upgrade (e.g. by using [sysupgrade(8)](https://man.openbsd.org/sysupgrade.8)) may break the current Werc installation.** It is advised to always test your Werc installation after performing either a system upgrade, a Werc update, or a plan9port update. If it stops working, head to [Troubleshooting](#troubleshooting).

### Limitations

For now, the installation resulting from `setup.sh` has only been tested with `GET` requests, which it supports for sure. Other types of HTTP requests may or may not work (e.g. the "user login" feature). The URL-based rules in `/etc/httpd.conf` (`location ...`) may need a different configuration to support HTTP requests other than `GET`.

### Other info

A [tagged commit](https://git-scm.com/book/en/v2/Git-Basics-Tagging) with tag name of the form `vN.M` (where `N` and `M` are integers), is a commit whose working tree has the following characteristics:

1. It has a readable README which is carefully divided into sections and contains instructions about the usage of the two scripts. The README file may also contain checksums for the two scripts.
2. It has the two scripts, `setup.sh` and `unsetup.sh`, tested against the latest OpenBSD stable version (available at that point in time) with positive outcome and no known side effect on the system.

Since the testing process is manual I may overlook some edge cases, sometimes on purpose and sometimes not. I care about the quality of my software but testing every single line against all its possible edge cases is really time consuming and unsustainable.

## Rationale

See [doc/rat.md](doc/rat.md).

## Usage

See [doc/usage.md](doc/usage.md).

## Testing

See [doc/testing.md](doc/testing.md).

## Troubleshooting

### Werc stops working after upgrading OpenBSD

It may happen that, after upgrading OpenBSD, your website stops working and only shows "500 internal server error".

While the exact reason behind this behavior should be carefully analyzed and understood, you might try uninstalling and re-installing Werc and plan9port. The procedure is the same as if you were to update them.

```sh
doas ./unsetup.sh uninst rm9env
doas ./setup.sh inst mk9env
```

## Checksums

Look for files ending in ".sum".

## License

Everything in this repository is licensed under the [ISC license](https://en.wikipedia.org/wiki/ISC_license). See LICENSE file.


# werc-on-openbsd

Automate [Werc](http://werc.cat-v.org/) setup on [OpenBSD](https://www.openbsd.org/).

## Useful info

<!--
Both the `setup.sh` and `unsetup.sh` scripts, in their latest available version ([v1.3](https://github.com/EdoardoLaGreca/werc-on-openbsd/releases/tag/v1.3)), have been successfully tested on the latest available OpenBSD stable release (7.6). Prior or later versions of OpenBSD may not work.
-->

**Performing an OpenBSD release upgrade (e.g. by using [sysupgrade(8)](https://man.openbsd.org/sysupgrade.8)) or updating the `plan9port` package may break the current Werc installation.** It is advised to always test your Werc installation after performing either a system upgrade or a `plan9port` update. If it stops working, head to [Troubleshooting](#troubleshooting).

### Limitations

For now, the installation (resulting from `setup.sh`) has only been tested with `GET` requests, which it supports for sure. Other types of HTTP requests may or may not work. The URL-based rules in `/etc/httpd.conf` may need a different configuration to support other HTTP requests as well.

### Other info

A [tagged commit](https://git-scm.com/book/en/v2/Git-Basics-Tagging) with tag name of the form `vN.M` (where `N` and `M` are integers), is a commit whose working tree has the following characteristics:

1. It has a readable README which is carefully divided into sections and contains instructions about the usage of the two scripts. The README file may also contain checksums for the two scripts.
2. It has the two scripts, `setup.sh` and `unsetup.sh`, tested against the latest OpenBSD stable version (available at that point in time) with positive outcome and no known side effect on the system.

Since the testing process is manual I may overlook some edge cases, sometimes on purpose and sometimes not. I care about the quality of my software but testing every single line against all its possible edge cases is really time consuming and unsustainable.

## Rationale and Details

(Moved to [rat.md](rat.md).)

## Usage

### Pre-usage checklist

**Note**: To preserve the original config files that are going to be modified, the setup script backs them up by adding `.bk` to the end of their name. For example, the original content of `/etc/httpd.conf` is copied to `/etc/httpd.conf.bk`. To restore the original files, the unsetup script renames the backup files with their original name, replacing the changed version.

In the following list, `$webdir` and `$p9pdir` respectively refer to `httpd`'s web content directory, by default `/var/www`, and plan9port's installation directory with `$webdir` as root, by default `/plan9`.

- **Do the files `/etc/httpd.conf.bk` and `/etc/fstab.bk` already exist in your machine's file system?** If so, `setup.sh` will overwrite them, consider renaming or removing them.
- **Did you add or change files in `$webdir` which cannot be lost?** The setup script creates new files in `$webdir` which may overwrite existing ones while the unsetup script removes some directories which may delete those files. Consider moving important files out of `$webdir` or placing them in directories which will not be removed.
- **Did you make a backup of your machine?** The setup script may fail to complete, for example due to a network error. This leads to an incomplete installation and neither running `setup.sh` again, nor running `unsetup.sh`, is going to repair it. Depending on which command(s) failed and the type of error, you may be able to manually repair the installation by yourself. However, this is not always the case and it's an error-prone procedure, so it's discouraged.

### Actual usage

The following procedure downloads scripts using the latest release tag. The latest tag shown in the URL below is manually updated, please check that it matches the actual latest release before proceeding. It is not recommended (at all) to run scripts from the `main` branch.

The following procedure refers to the setup script (`setup.sh`). For the un-setup script (`unsetup.sh`), the procedure is the same except for the script name.

The procedure is as follows, written both in human-readable steps and as commands:

1. Download the script from the latest tag.
2. Verify the script's checksum (see [Checksums](#checksums)).
3. Change the `domain` variable (and `webdir`, if necessary) at will.
4. Set the execution permission bit of the script.
5. Start the script as root.

```sh
ftp https://raw.githubusercontent.com/EdoardoLaGreca/werc-on-openbsd/v1.2/setup.sh
sha256 -q setup.sh
vi setup.sh	# change domain and webdir
chmod 744 setup.sh
doas ./setup.sh
```

The `setup.sh` script does not automatically start `httpd` and `slowcgi`. It behaves like that for two reasons: firstly you might want to make some final changes to your website before displaying it publicly and secondly you may have to reboot your system before starting the webserver if `/etc/fstab` has been changed by the script. The script should display a log message if you need to reboot (and/or `/etc/fstab` has been changed). The absence of such message in the log means that rebooting is not necessary. This does not apply to `unsetup.sh`.

### Running parts

Instead of running the entire script, one might want to run just one or some parts to, for example, debug the script or run again a part which could not terminate successfully. To do so is as simple as passing the function names to the script as arguments. An example is shown below.

```sh
./setup.sh preinst inst
```

Although the example above uses `setup.sh`, `unsetup.sh` also behaves in this way.

## Troubleshooting

### Werc stops working after upgrading OpenBSD or updating plan9port

It may happen that, after upgrading OpenBSD or updating the `plan9port` package, your website stops working and only shows "500 internal server error".

I don't know the reason, if I'm being honest. However, I found out that removing all the contents of the `plan9port` package from the webserver's directory and then placing them there again solves the error. Uninstalling and re-installing everything would work, although this solution is a waste of time, especially on slower machines, and could potentially have some side effects (it is not guaranteed not to have them).

The proper way to solve this issue is by using the following commands.

```
doas ./unsetup.sh rm9env
doas ./setup.sh mk9env
```

## Checksums (v1.3)

`setup.sh` SHA-256: ``

`unsetup.sh` SHA-256: ``

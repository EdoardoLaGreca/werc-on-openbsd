# Usage

## Pre-usage checklist

**Note**: To preserve the original config files that are going to be modified, the setup script backs them up by adding `.bk` to the end of their name. For example, the original content of `/etc/httpd.conf` is copied to `/etc/httpd.conf.bk`. To restore the original files, the unsetup script renames the backup files with their original name, replacing the changed version.

In the following list, `$webdir` and `$p9pdir` respectively refer to `httpd`'s web content directory, by default `/var/www`, and plan9port's installation directory with `$webdir` as root, by default `/plan9`.

- **Do the files `/etc/httpd.conf.bk` and `/etc/fstab.bk` already exist in your machine's file system?** If so, `setup.sh` will probably overwrite them, consider renaming or removing them.
- **Did you add or change files in `$webdir` which cannot be lost?** The setup script creates new files in `$webdir` which may overwrite existing ones while the unsetup script removes some directories which may delete those files. Consider moving important files out of `$webdir`.
- **Did you make a backup of your machine?** The setup script may fail to complete, for example due to a network error. This leads to an incomplete installation and neither running `setup.sh` again, nor running `unsetup.sh`, is going to repair it. (If it did, you're just lucky.) Depending on which command(s) failed and the type of error, you may be able to manually repair the installation by yourself. However, this is not always the case and it's an error-prone procedure, so it is not advised at all.

## Actual usage

The following procedure downloads scripts using the latest release tag. The latest tag shown in the URL below is manually updated, please check that it matches the actual latest release before proceeding. It is not recommended (at all) to run scripts from the `main` branch.

The following procedure refers to the setup script (`setup.sh`). For the un-setup script (`unsetup.sh`), the procedure is the same except for the script name.

The procedure is as follows, written both in human-readable steps and as commands:

1. Download the script from the latest tag.
2. Verify the script's checksum (see [Checksums section](/README.md#checksums) in README.md).
3. Change the `domain` variable (and `webdir`, if necessary) at will.
4. Set the execution permission bit of the script.
5. Start the script as root.

```sh
ftp https://raw.githubusercontent.com/EdoardoLaGreca/werc-on-openbsd/v2.2/setup.sh
sha256 -q setup.sh
vi setup.sh	# change domain and webdir
chmod 744 setup.sh
doas ./setup.sh
```

The setup script does not automatically start `httpd` and `slowcgi`. It behaves like that for two reasons: firstly, you might want to make some final changes to your website before displaying it publicly; secondly, if `/etc/fstab` has been changed by the script, you need to reboot your system before starting the webserver. The script should display a log message if you need to reboot (and/or `/etc/fstab` has been changed). The absence of such message in the log means that rebooting is not necessary. All this does not apply to `unsetup.sh`.

### Running parts

Instead of running the entire script, one might want to run just one or some parts to, for example, debug the script or run again a part which could not terminate successfully. To do so is as simple as passing the part names to the script as arguments. An example is shown below.

```sh
./setup.sh preinst inst
```

Although the line above uses `setup.sh`, `unsetup.sh` also behaves in this way.

## Maintenance

It is good practice to keep software up to date, both to receive new features and to patch existing vulnerabilities.

When using Werc, 4 pieces of software need to be kept up to date:

- OpenBSD's own HTTP and SlowCGI daemons (a.k.a. `httpd` and `slowcgi`)
- Werc
- plan9port

Unless you're using OpenBSD's `-current` branch, `httpd` and `slowcgi` are usually updated on every system upgrade. They are pretty secure and minimalist so keeping them up to date is not essential. These programs are part of OpenBSD's source tree which contains the whole operating system, including its kernel, essential libraries, and all preinstalled utilities. All software in that source tree undergoes severe security audits, that's why they are so secure.

On the other hand, it's important to keep Werc and plan9port up to date. To do so, run the following lines in the shell. They remove the existing Werc and plan9port installations, download their updated version, and install them again.

```sh
doas ./unsetup.sh uninst rm9env
doas ./setup.sh inst mk9env
```


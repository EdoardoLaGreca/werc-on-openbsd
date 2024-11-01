# werc-on-openbsd

Automate [Werc](http://werc.cat-v.org/) setup on [OpenBSD](https://www.openbsd.org/).

## Useful info

Both the `setup.sh` and `unsetup.sh` scripts, in their latest available version, have been successfully tested on OpenBSD 7.5. Prior or later versions of OpenBSD may not work.

A [tagged commit](https://git-scm.com/book/en/v2/Git-Basics-Tagging), whose tag name is in the form `vN.M` with `N` and `M` integers, is a commit whose working tree has the following characteristics:

1. It has a readable README which is carefully divided into sections and contains instructions about the usage of the two scripts. The README file may also contain checksums for the two scripts.
2. It has the two scripts, `setup.sh` and `unsetup.sh`, tested against the latest OpenBSD stable version (available at that point in time) with positive outcome and no known side effect on the system.

Since the testing process is manual I may overlook some edge cases, sometimes on purpose and sometimes not. I care about the quality of my software but testing every single line against all its possible edge cases is really time consuming and unsustainable.

**Performing an OpenBSD release upgrade (e.g. by using [sysupgrade(8)](https://man.openbsd.org/sysupgrade.8)) or updating the `plan9port` package may break the current Werc installation.** It is advised to always test your Werc installation after performing either a system upgrade or a `plan9port` update.

To preserve the original config files that are going to be modified, the setup script backs them up by adding `.bk` to the end of their name. For example, the original `/etc/httpd.conf` file is copied to `/etc/httpd.conf.bk`. To restore the original files, the unsetup script renames the backup files with their original name. For this reason, **before running `setup.sh`, make sure to NOT have files named `/etc/httpd.conf.bk` or `/etc/fstab.bk` in your filesystem.**

## Rationale and Details

[Werc](http://werc.cat-v.org/), defined as a "sane web anti-framework", is a set of [CGI](https://en.wikipedia.org/wiki/Common_Gateway_Interface) scripts that take markdown files and HTML templates and spit out a complete HTML page. It is simple (highly functional core is 150 lines), easily extensible, and fast enough.

Werc is quite popular among the [Plan 9](https://en.wikipedia.org/wiki/Plan_9_from_Bell_Labs) (and [9front](https://9front.org/)) users. Two possible and logical reasons are that:

1. It was written using Plan 9's default shell, [Rc](https://p9f.org/sys/doc/rc.html).
2. Like I said before, it is simple, and Plan 9 folks like simplicity.

I didn't have much knowledge or experience with Plan 9 at the time. However, I did have knowledge and experience with Unix-like systems (a lot more, compared to Plan 9) and I knew about the existence of [plan9port](https://9fans.github.io/plan9port/), a port of the Plan 9 user space to Unix-like systems (thank you [Russ Cox](https://swtch.com/~rsc/)). A Unix-like operating system and plan9port were all I needed to make Werc work outside of Plan 9. On one hand, an operating system family that I was familiar with. On the other, the simplicity of Werc and the Plan 9 user space.

The choice I made regarding the specific operating system to use was backed by one main thought: *if it is exposed to the internet, it must be **secure***. I could have chosen Linux, but OpenBSD is much more closely related to Unix (Unix as it was intended by its creators), and it has way stricter policies regarding security.

Another thing I really cared about, back when I started writing this script, is that it had to have the least external dependencies possible. In other words, with the reasonable exception of plan9port, it only had to use things that were already available in the default OpenBSD install. I took this decision for two reasons: the first is that I hate when something installs a zillion dependencies and bloats your system, the second is that external dependencies may introduce security breaches.

In addition to all I said before, and this was by far the hardest goal to achieve, it had to comply with OpenBSD's [httpd](https://man.openbsd.org/httpd) way of doing things. That is, the hosted website had to be `chroot`'ed into `/var/www`, so that potential breaches would only be limited to that portion of the file system. At first, since [symlinks](https://en.wikipedia.org/wiki/Symbolic_link) cannot be accessed from a `chroot`'ed environment, I solved it the naïve way: I just copied all the Plan 9 utilities, together with their dependencies, into `/var/www`. That was not the best solution, not even close, but it worked for a while. With recent changes now everything is just [hard links](https://en.wikipedia.org/wiki/Hard_link), which consume way less data on disk. I'm happy with this new solution and I don't think I will change it any time soon.

## Usage

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

I don't know the reason, if I'm being honest. However, I found out that removing all the contents of the `plan9port` package from the webserver's directory and then placing them there again solves the error. Uninstalling and re-installing everything would work, although this solution is a waste of time, especially on slower machines, and could potentially have some side effects (in other words, it is not guaranteed not to have them).

The proper way to solve this issue is by using the following commands.

```
doas ./unsetup.sh rmweb
doas ./setup.sh mkweb
```

## Checksums

### `setup.sh`

SHA-256: ``

### `unsetup.sh`

SHA-256: ``

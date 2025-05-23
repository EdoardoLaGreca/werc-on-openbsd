Rationale and details
=====================

[Werc](http://werc.cat-v.org/), defined as a "sane web anti-framework", is a
set of [CGI](https://en.wikipedia.org/wiki/Common_Gateway_Interface) scripts
that take markdown files and HTML templates and spit out a complete HTML page.
It is simple (highly functional core is 150 lines), easily extensible, and fast
enough.

Werc is quite popular among [Plan
9](https://en.wikipedia.org/wiki/Plan_9_from_Bell_Labs) and
[9front](https://9front.org/) users. Two possible and logical reasons are that:

1. It was written using Plan 9's default shell,
[Rc](https://p9f.org/sys/doc/rc.html).
2. Like I said before, it is simple, and Plan 9 folks like simplicity.

I didn't have much knowledge or experience with Plan 9 at the time. However, I
did have knowledge and experience with Unix-like systems (a lot more, compared
to Plan 9) and I knew about the existence of
[plan9port](https://9fans.github.io/plan9port/), a port of the Plan 9 user
space to Unix-like systems (thank you [Russ Cox](https://swtch.com/~rsc/)). A
Unix-like operating system and plan9port were all I needed to make Werc work
outside of Plan 9. On one hand, an operating system family that I was familiar
with. On the other, the simplicity of Werc and the Plan 9 user space.

The choice I made regarding the specific operating system to use was backed by
one main thought: *if it is exposed to the internet, it must be **secure***. I
could have chosen Linux, but OpenBSD is much more closely related to Unix (Unix
as it was intended by its creators), and it has way stricter policies regarding
security.

Another thing I really cared about, back when I started writing this script, is
that it had to have the least external dependencies possible. In other words,
with the reasonable exception of plan9port, it only had to rely on things that
were already available in the default OpenBSD install, if possible. I took this
decision for two reasons: the first is that I hate when something installs a
gazillion dependencies and bloats your system, the second is that external
dependencies may introduce security breaches.

In addition to all I said before, and this was by far the hardest goal to
achieve, all this had to comply with OpenBSD's
[httpd](https://man.openbsd.org/httpd) way of doing things. That is, the hosted
website is served from a `chroot`'ed directory, `/var/www`. By doing so,
potential breaches are only limited to that portion of the file system. At
first, since [symlinks](https://en.wikipedia.org/wiki/Symbolic_link) cannot be
accessed from a `chroot`'ed environment, I solved it the naïve way: I just
copied all the Plan 9 utilities, together with their shared objects, into
`/var/www`. This was not the best solution, not even close, but it worked for a
while. Then, I switched to
[hard links](https://en.wikipedia.org/wiki/Hard_link). In theory, hard links
consume way less data on disk. In practice, most of the times they are not
possible because even OpenBSD's default installation splits the filesystem into
many partitions and hard links cannot be created from one disk/partition to the
other. At that time I wrote the setup script to only hard link files when
possible and to copy them otherwise. Given the probabilities of finding an
OpenBSD installation with all files on the same partition, this latter solution
was basically the same as the former, naïve solution.

The final solution, introduced in
[v2.0](https://github.com/EdoardoLaGreca/werc-on-openbsd/releases/tag/v2.0), is
to clone plan9port's git repository into the `chroot`'ed filesystem and install
it there, with its hard-coded paths adjusted through the `-r` option. Not only
this improves the system's security, since patches can be applied immedately,
but it also eliminates the need of work-arounds to make hard-coded paths work.

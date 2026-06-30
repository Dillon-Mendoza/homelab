# Week 4 — Reference & Links

### Primary Study Source
- **Book:** *How Linux Works* (3rd Edition) by Brian Ward
- **Core Section:** **Section 7.3: "Running Commands as root"**
- **Key Takeaway:** Brian explains that `sudo` is the preferred way to handle root tasks because it limits the time you spend with full system privileges and provides an audit trail.

### Key Man Pages
- `man sudo` — General usage and flags.
- `man sudoers` — This is a long one, but read the "EXAMPLES" section.
- `man visudo` — Understand why it's better than `vi /etc/sudoers`.

### Curated Resources
- [Sudoers Manual (Official)](https://www.sudo.ws/docs/man/sudoers.man/)
- [GTFOBins](https://gtfobins.github.io/) — **Job Ready Essential:** This site shows how common binaries (like `vi`, `find`, `awk`) can be used to bypass security restrictions if granted sudo access.

### Exam Objective Mapping
- **2.2**: Given a scenario, manage users and groups (Privilege escalation and sudo configuration).

### Things That Trip People Up
1. **The Password Cache:** By default, sudo remembers your password for 5–15 minutes. This can lead to a false sense of security where you think you don't need a password, or someone can jump on your terminal right after you walk away. Use `sudo -k` to clear the cache.
2. **`sudo su -` vs `sudo -i`**: Both give you a root shell, but `sudo -i` is generally preferred as it is a more "native" sudo command that correctly handles environment variables and logging.
3. **The Sudoers.d Directory:** People often forget that files in `/etc/sudoers.d/` must **not** contain a period `.` in the filename (on some distributions like Debian/Ubuntu), otherwise they are ignored.

### Job Ready: Professional Perspective
In a corporate environment, you will rarely have `ALL=(ALL) ALL`. You will be given access to specific command aliases (Cmnd_Alias). For example, a `NETWORKING` alias might include `ip`, `route`, and `tcpdump`. Understanding how to request and verify these specific permissions is a key part of working on a professional team. **Reputation is made in the details**—being the guy who asks for "just enough" permission rather than "all of it" shows you understand the risk.

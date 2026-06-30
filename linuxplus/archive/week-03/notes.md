# Week 3 — Reference & Links

### Primary Study Source
- **Book:** *How Linux Works* (3rd Edition) by Brian Ward
- **Core Chapters:** 
    - **Chapter 7: "Users and Groups"** (Read the whole thing. It covers everything from UID/GID to PAM).
    - **Section 7.2: "The ID of a Process"** (Crucial for understanding how Linux handles permissions behind the scenes).

### Key Man Pages
- `man 5 passwd` — Detailed structure of the user database.
- `man 5 shadow` — Detailed structure of the password shadow file.
- `man useradd` — Understand all the flags (`-D` to see defaults!).
- `man chage` — Essential for security policy enforcement.

### Curated Resources
- [Linux Handbook: User Management Commands](https://linuxhandbook.com/user-management-commands/)
- [LearnLinuxTV: Linux User Account Management](https://www.youtube.com/watch?v=S29E30mZ240)

### Exam Objective Mapping
- **2.2**: Given a scenario, manage users and groups.

### Things That Trip People Up
1. **The `usermod -G` vs `-aG` Trap:** If you forget `-a`, you **replace** all existing secondary groups with the one you just named. In a job, this can lock a user out of critical systems. **Always use `-aG`**.
2. **Deleting Users:** Using `userdel` without `-r` leaves the home directory on the disk. This creates "orphaned" files that have a numeric UID but no associated username.
3. **Primary GID:** Every user has exactly ONE primary GID (set in `/etc/passwd`). All others are secondary/supplementary (set in `/etc/group`).

### Job Ready: Professional Perspective
In a real Linux Admin role, you rarely use `useradd` manually. You'll likely use configuration management (Ansible, Puppet) or integrate with a central directory like Active Directory or LDAP. However, knowing the local files (`/etc/passwd`, `/etc/shadow`) is how you troubleshoot when the network identity provider fails. **Rooted in craft** means knowing what happens when the high-level tools break.

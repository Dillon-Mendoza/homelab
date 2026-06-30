# Week 3 — Phase 1: Foundation Revisit
## Topic: User & Group Management Pt 1

In a professional environment, you never work as root. Managing users and groups correctly is the foundation of the "Principle of Least Privilege."

---

### The Identity Files (The "Source of Truth")

*Ref: How Linux Works (3rd Ed), Chapter 7: "Users and Groups"*

1. **`/etc/passwd`**: Defines user accounts.
   - Format: `name:password:UID:GID:GECOS:directory:shell`
   - *Job Ready Tip:* Know the UID ranges. 0 is root. 1–999 are system users. 1000+ are human users. If you see a human with a UID of 150, something is wrong.

2. **`/etc/shadow`**: Stores encrypted passwords and aging info.
   - Format: `name:password:lastchanged:min:max:warn:inactive:expire:reserved`
   - *Security Note:* This file is readable only by root. If a user can read this, they can attempt to crack everyone's password.

3. **`/etc/group`**: Defines groups and their members.
   - Format: `group_name:password:GID:user_list`

---

### Essential Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `useradd` | Create a new user | `sudo useradd -m -s /bin/bash dillon` |
| `usermod` | Modify an existing user | `sudo usermod -aG wheel dillon` (Add to group) |
| `userdel` | Delete a user | `sudo userdel -r dillon` (Remove home dir too) |
| `groupadd` | Create a new group | `sudo groupadd devops` |
| `id` | Show UID/GID for a user | `id dillon` |
| `chage` | Manage password aging | `sudo chage -M 90 dillon` (Max age 90 days) |

---

### The "Thing Beneath the Thing"
*Ref: How Linux Works, Chapter 7.2: "The ID of a Process"*

Every process on Linux has an **Effective UID (EUID)** and a **Real UID (RUID)**. Usually they are the same. When you use `sudo`, the process keeps your RUID but changes the EUID to 0. Understanding this distinction is how you troubleshoot complex permission issues in production.

---

### Quick Recall
1. `/etc/passwd`: The primary user database.
2. `/etc/shadow`: Where the hashes actually live.
3. `/etc/group`: Defines group membership.
4. `UID 0`: Always root.
5. `useradd -m`: Create home directory during user creation.
6. `usermod -aG`: **A**ppend a user to a **G**roup (critical to use `-a`).
7. `userdel -r`: Delete user and their files.
8. `chage -l`: List a user's password expiration info.
9. `getent passwd`: Query the passwd database (handles LDAP/AD too).
10. `pwck`: Check the integrity of password files.
11. `grpck`: Check the integrity of group files.
12. `/etc/skel`: The template for new user home directories.
13. `system-users`: UIDs under 1000.
14. `GECOS`: The comment field (Full Name, Phone, etc.).
15. `passwd -S`: Check the status of a user's password (L=Locked, P=Usable).

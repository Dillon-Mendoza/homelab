# Week 4 — Phase 1: Foundation Revisit
## Topic: User & Group Management Pt 2 (Privilege Escalation)

In professional Linux administration, "Logging in as root" is a cardinal sin. We use `sudo` to perform administrative tasks while maintaining an audit trail and the principle of least privilege.

---

### Sudo vs. Su

*Ref: How Linux Works (3rd Ed), Section 7.3: "Running Commands as root"*

- **`su` (Substitute User)**:
    - `su -`: Switches to the root user completely. Requires the **root password**.
    - *Drawback:* You don't know *who* actually ran the command, only that they had the root password.
- **`sudo` (SuperUser Do)**:
    - Runs a command as root (or another user). Requires the **user's own password**.
    - *Benefit:* Every command is logged with the original username. You can restrict *what* commands a user can run.

---

### The `/etc/sudoers` File

**NEVER** edit this file directly with a standard editor. Always use `visudo`. It checks for syntax errors before saving, preventing you from locking everyone (including root) out of sudo access.

#### Syntax Breakdown:
`user  HOST=(USERS:GROUPS)  COMMANDS`

- **Example 1 (Full Access):**
  `dillon  ALL=(ALL:ALL)  ALL`
  *Dillon can run any command as any user/group on any host.*
- **Example 2 (Group Access):**
  `%wheel  ALL=(ALL)  ALL`
  *Any member of the 'wheel' group has full sudo rights.*
- **Example 3 (Restricted Access - Job Ready):**
  `webadmin  ALL=(root)  NOPASSWD: /usr/bin/systemctl restart httpd`
  *The webadmin can restart the web server without a password, but nothing else.*

---

### Essential Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `sudo -l` | List my current sudo privileges | `sudo -l` |
| `sudo -u [user]` | Run a command as a specific user | `sudo -u postgres psql` |
| `sudo -i` | Simulate a login shell as root | `sudo -i` |
| `sudo -k` | Kill the sudo timestamp (require password next time) | `sudo -k` |
| `visudo` | Safely edit the sudoers file | `sudo visudo` |

---

### Quick Recall
1. `visudo`: The only safe way to edit sudoers.
2. `%group`: The syntax for defining group rules in sudoers.
3. `NOPASSWD`: Allows running specific commands without a password prompt.
4. `sudo -l`: First thing to run on a new system to see what you can do.
5. `/var/log/secure` (or `auth.log`): Where sudo attempts are logged.
6. `Defaults env_reset`: A common sudoers setting to clear environment variables for safety.
7. `Alias`: Used in sudoers to group users, hosts, or commands (User_Alias, Cmnd_Alias).
8. `sudo !!`: Run the previous command again with sudo.
9. `secure_path`: Defines the PATH used for sudo commands.
10. `visudo -c`: Check the sudoers file for syntax errors without opening it.

# Week 4: sudo Configuration & Policies
**Date:** March 30, 2026
**Estimated Time:** 5-8 hours

## Objectives
- Understand the difference between `su` and `sudo`.
- Implement the Principle of Least Privilege using `sudo` policies.
- Master `/etc/sudoers` configuration and the `visudo` command.
- Configure logging and auditing for `sudo` commands.
- Manage identity and secure access across infrastructure (Exam Objective 2.5, 3.2).

## Key Concepts
- **`su` vs `sudo`**: `su` switches to another user (requires their password); `sudo` runs commands with elevated privileges (requires current user's password).
- **`visudo`**: The only safe way to edit `/etc/sudoers` (provides syntax checking).
- **Sudoers Format**: `user host=(runas) commands`.
- **Groups in Sudoers**: Use `%groupname` to apply rules to all members of a group.
- **NOPASSWD**: Allows running commands without a password prompt (use with extreme caution).
- **Logging**: `sudo` logs to the system journal or a custom log file.

## Resources
- [CompTIA Linux+ XK0-005 Objectives](https://partners.comptia.org/docs/defaultsource/resources/comptia-linux-xk0-005-exam-objectives-(3-0))
- Chapter 7: sudo configuration section
- Search: "sudo configuration", "Linux+ sudo"

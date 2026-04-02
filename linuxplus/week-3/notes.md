# Week 3: User & Group Management
**Date:** March 23, 2026
**Estimated Time:** 5-8 hours

## Objectives
- Understand the structure of `/etc/passwd`, `/etc/shadow`, and `/etc/group`.
- Manage user accounts, groups, and password policies.
- Implement identity management and user/group structures (Exam Objective 2.5, 3.2).
- Configure system and service accounts.

## Key Concepts
- **/etc/passwd**: Stores user account information (username:x:UID:GID:comment:home:shell).
- **/etc/shadow**: Stores encrypted password hashes and aging information.
- **/etc/group**: Defines group memberships.
- **UID/GID**:
  - `0`: root
  - `1-999`: System accounts
  - `1000+`: Regular users
- **User Commands**: `useradd`, `usermod`, `userdel`, `id`, `whoami`.
- **Group Commands**: `groupadd`, `groupmod`, `groups`.
- **Password Aging**: `chage`, `passwd`.

## Resources
- [CompTIA Linux+ XK0-005 Objectives](https://partners.comptia.org/docs/defaultsource/resources/comptia-linux-xk0-005-exam-objectives-(3-0))
- Chapter 7: System Configuration: Users and Groups
- Search: "User Management Linux", "Linux+ User Management"

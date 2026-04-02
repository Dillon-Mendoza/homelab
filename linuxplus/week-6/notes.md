# Week 6: SSH Hardening & Deployment
**Date:** April 13, 2026
**Estimated Time:** 5-8 hours

## Objectives
- Harden SSH server configuration (`sshd_config`).
- Disable password authentication and root login.
- Configure SSH client for easy management (`~/.ssh/config`).
- Implement and execute security best practices (Exam Objective 3.4).

## Key Concepts
- **sshd_config**: Server-side configuration for SSH.
- **Client Config**: Using `~/.ssh/config` for aliases and connection parameters.
- **SSH Hardening**:
  - `PasswordAuthentication no`
  - `PermitRootLogin no`
  - `AllowUsers` / `AllowGroups`
  - Changing default port (optional).

## Resources
- [CompTIA Linux+ XK0-005 Objectives](https://partners.comptia.org/docs/defaultsource/resources/comptia-linux-xk0-005-exam-objectives-(3-0))
- Chapter 10: SSH hardening and security
- Search: "SSH Hardening Security", "SSH Security"

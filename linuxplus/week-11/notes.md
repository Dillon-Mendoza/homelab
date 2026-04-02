# Week 11: Centralized Logging (rsyslog & journald)
**Date:** May 18, 2026
**Estimated Time:** 5-8 hours

## Objectives
- Begin building your centralized logging infrastructure.
- Understand syslog severity levels and facilities.
- Configure rsyslog for remote logging (TCP/UDP).
- Analyze and troubleshoot system properties using logs (Exam Objective 2.1).

## Key Concepts
- **syslog Components**: Facility (auth, cron, kern, etc.) and Level (emerg to debug).
- **rsyslog**: A powerful syslog daemon supporting remote logging.
- **journald**: systemd's binary logging system, managed with `journalctl`.
- **Remote Logging**: Forwarding logs to a central server (Fedora) on port 514.
- **Protocols**: `@` for UDP, `@@` for TCP (more reliable).

## Resources
- [CompTIA Linux+ XK0-005 Objectives](https://partners.comptia.org/docs/defaultsource/resources/comptia-linux-xk0-005-exam-objectives-(3-0))
- Chapter 7: System Logging
- Search: "Centralized Logging", "Syslog", "rsyslog vs journald"

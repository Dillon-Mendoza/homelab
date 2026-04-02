# Week 8: Custom Systemd Services
**Date:** April 27, 2026
**Estimated Time:** 5-8 hours

## Objectives
- Create and manage custom systemd service unit files.
- Understand unit file sections: `[Unit]`, `[Service]`, and `[Install]`.
- Implement automatic restart and service dependencies.
- Configure and verify service parameters (Exam Objective 1.3).

## Key Concepts
- **Unit File Location**: Custom units are stored in `/etc/systemd/system/`.
- **Unit Sections**:
  - `[Unit]`: Metadata and dependencies (`Description`, `After`).
  - `[Service]`: Execution logic (`ExecStart`, `User`, `Restart`).
  - `[Install]`: Boot-time configuration (`WantedBy`).
- **daemon-reload**: Required to notify systemd of new or changed unit files.

## Resources
- [CompTIA Linux+ XK0-005 Objectives](https://partners.comptia.org/docs/default-source/resources/comptia-linux-xk0-005-examobjectives-(3-0))
- Chapter 6 (systemd unit files)
- Search: "Create Systemd Service", "Systemd Unit Files"

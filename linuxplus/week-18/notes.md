# Week 18: SELinux Basics
**Date:** July 6, 2026
**Estimated Time:** 5-8 hours

## Objectives
- Understand SELinux basics and troubleshoot common issues.
- Master SELinux modes: Enforcing, Permissive, and Disabled.
- Learn security contexts and labels (user:role:type:level).
- Manage SELinux booleans and file contexts.

## Key Concepts
- **MAC vs DAC**: Mandatory Access Control vs Discretionary Access Control.
- **SELinux Modes**: `getenforce` and `setenforce` usage.
- **Contexts**: Everything in SELinux has a label (e.g., `httpd_sys_content_t`).
- **Booleans**: On/off switches for specific permissions.
- **Troubleshooting**: Using `ausearch`, `audit2why`, and `sealert`.

## Resources
- [CompTIA Linux+ XK0-005 Objectives](https://partners.comptia.org/docs/default-source/resources/comptia-linux-xk0-005-exam-objectives-(3-0))
- Chapter 17: Security Best Practices (SELinux section)
- Search: "SELinux Tutorial", "SELinux troubleshooting commands"

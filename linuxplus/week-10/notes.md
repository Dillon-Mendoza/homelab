# Week 10: Linux Firewalls (iptables & UFW)
**Date:** May 11, 2026
**Estimated Time:** 5-8 hours

## Objectives
- Implement custom firewall rules enforcing tier hierarchy.
- Understand iptables chains (INPUT, OUTPUT, FORWARD) and default policies.
- Configure and verify Linux firewalls (Exam Objective 3.3).
- Implement security best practices (Exam Objective 3.4).

## Key Concepts
- **Chains**: INPUT (to this machine), FORWARD (through this machine), OUTPUT (from this machine).
- **Policies**: ACCEPT vs DROP. Rule matching order is top to bottom.
- **Connection Tracking**: ESTABLISHED, RELATED states (allowing responses).
- **Tools**: iptables, UFW (Ubuntu), firewalld (Fedora/RHEL), nftables.
- **Tier Hierarchy**: Blocking traffic "up" the hierarchy (Tier 4 cannot reach Tier 2).

## Resources
- [CompTIA Linux+ XK0-005 Objectives](https://partners.comptia.org/docs/defaultsource/resources/comptia-linux-xk0-005-exam-objectives-(3-0))
- Chapter 9: Firewalls section
- Search: "iptables Tutorial", "Linux+ Firewall"

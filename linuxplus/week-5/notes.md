# Week 5: SSH Key Authentication
**Date:** April 6, 2026
**Estimated Time:** 5-8 hours

## Objectives
- Enable SSH key authentication between systems.
- Understand public vs private key cryptography (asymmetric encryption).
- Manage SSH keys and the `authorized_keys` file.
- Implement identity management (Exam Objective 3.2).

## Key Concepts
- **Asymmetric Encryption**: Using a public key for encryption and a private key for decryption.
- **Key Files**:
  - `id_ed25519`: Private key (NEVER share).
  - `id_ed25519.pub`: Public key (safe to share).
  - `authorized_keys`: List of authorized public keys on the server.
  - `known_hosts`: Fingerprints of trusted servers.
- **ssh-agent**: Tool for managing passphrases for private keys.

## Resources
- [CompTIA Linux+ XK0-005 Objectives](https://partners.comptia.org/docs/defaultsource/resources/comptia-linux-xk0-005-exam-objectives-(3-0))
- Chapter 10: Network Applications and Services (SSH section)
- Search: "SSH Key Authentication", "SSH Keys"

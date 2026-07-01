

# Technical Documentation: Cloud Engineering Baseline Audit

System Owner: Gloria

Environment: Ubuntu Linux (WSL2) / Windows 11 PC

Repository: `~/cloud-learning`

Status: Successfully Audited & Hardened


## 1. Operating System & Package Management (Linux)

The local workstation runs an Ubuntu Linux subsystem via WSL2.

### Key Concepts Revived:

* The Package Manager (`apt`): `sudo apt update`: Synchronizes local package index files with the remote repositories (fetches the latest "menu" of software versions).
* `sudo apt upgrade`: Installs the actual software updates based on the updated index.


* File Permissions (`chmod`):
* Permissions are broken down into three tiers: Owner, Group, and Others.
* `chmod 755`: Grants full control (Read, Write, Execute) to the owner, while limiting groups and others to Read and Execute only.
* `chmod +x`: Explicitly flags a script file as executable.



## 2. Version Control & Tooling Architecture

All local configurations are validated as up-to-date and securely isolated from production clouds using local emulation boundaries.

### Local Tool Versions:

* Git Engine: `v2.43.0`
* Docker Engine: `v29.1.3`
* AWS CLI: `v2.34.24` (Configured for custom endpoint overrides)

### Core Workflow Mechanisms:

* Git Tracking (`git log`): Command utilized to view sequential commit history.
* *Note: When logs exceed the screen window, Linux pipes the output into a pager (`less`). The `q` key must be pressed to exit the pager and restore terminal control.


* Docker Lifecycles: Docker Image: A static, read-only template/recipe containing system configurations.
* Docker Container: A live, running instance of an image (the baked cake executing in memory).


* LocalStack Isolation: To prevent unexpected AWS cloud charges, standard CLI commands must include an explicit `--endpoint-url` flag targeting local ports:

bash
aws s3 ls --endpoint-url=http://localhost:4566



## 3. Network Security Control

The local machine is guarded by an active host-level firewall enforcement layer adhering to the Principle of Least Privilege (restricting technical entities strictly to the permissions required to perform their jobs).

### Firewall Profile (`sudo ufw status`):

* Status: `Active`
* Inbound Rules:
* Port 80 (HTTP): `ALLOW` from Anywhere (Configured to accept standard inbound web container traffic).
* Port 443 (HTTPS): Reserved for secure, encrypted traffic.
* Port 22 (SSH): Secured for remote cryptographic terminal access.




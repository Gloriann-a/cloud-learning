# 🚀 Cloud Engineering: User to Operator Journey

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E94333?style=for-the-badge&logo=ubuntu&logoColor=white)
![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white)
![VS Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white)
![Bash](https://img.shields.io/badge/bash-%234EAA25.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

---
## The Mission
Documenting my transition from Cloud User to **Cloud Operator**. Currently mastering the Linux terminal (Ubuntu/WSL2), Git version control, and secure file systems.


### Project Goal
 To document my hands-on mastery of Cloud Infrastructure, starting from the local terminal and moving toward automated cloud deployments. This repo serves as my "Proof of Work" as I transition into a Cloud Engineering role.

 ## 📈 Progress Log

| Date       | Phase   | Task             | Key Takeaway                                     |
| :---       | :---    | :---             | :---                                             |
| 2026-01-15 | Phase 1 | Initial Setup    | Successfully installed WSL2 & Ubuntu. |
| 2026-01-16 | Phase 1 | Git Fundamentals | Resolved credential errors & pushed first repo. |
| 2026-01-20 | Phase 1 | Portfolio Update | Optimized README with badges and progress log. |
| 2026-04-05 | Phase 1 | Foundation       | Nginx Setup,Installed & verified web server on Ubuntu.|
| 2026-04-05 | Phase 1 | Foundation       |AWS CLI Install,Ready for Cloud interaction via terminal.|
| 2026-04-07 | Phase 1 | Observability    |Log Analysis,Decoded HTTP 200/304 codes via tail -f.|
|2026-04-07  | Phase 1 | Observability    |Network Audit,Verified port 80 status using ss -tulpn.|
|2026-04-03 | Foundation | Nginx Setup | Installed & verified web server. |
|2026-04-08  | Cloud Sim | Docker & LocalStack |Pulled 1.26GB LocalStack image; handled network timeouts with retry logic.|
|2026-04-13 | Automation | Bash Scripting | Created sys_check.sh to monitor IP, Nginx, and Disk Space.|
|2026-04-13 |Cloud Sim | S3 Provisioning | sudiResolved Pro license errors; successfully created S3 bucket via LocalStack v3.0.2.|
|2026-04-28	| Foundations|Critical System Recovery |	Resolved HCS_E_CONNECTION_TIMEOUT by manually restarting the vmcompute service.| Learned that the virtualization host layer can fail even when Windows appears "normal."|
|2026-04-28	| Foundations|OS Security Baseline|Successfully installed ufw on Ubuntu. Implemented the "Principle of Least Privilege" by explicitly allowing only Port 80/tcp and activating the firewall.|
2026-04-28 | Foundations |Env Synchronization| Restored the VS Code-to-WSL bridge (code .) after a software update. Practiced navigating directory structures to ensure git commands are run from the repository root.|


Markdown
# Cloud Learning Journey: Local Cloud Setup (13/04/2026)

## 🚀 Objective
Successfully provisioned a local AWS environment using LocalStack to practice S3 operations without incurring AWS costs.

## 🛠️ Infrastructure Setup
I utilized **LocalStack v3.0.2** (Community Edition) to avoid licensing issues associated with newer development builds.

**Deployment Command:**
```bash
docker run -d --name localstack-final \
  -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e "SERVICES=s3" \
  localstack/localstack:3.0.2

📝 Troubleshooting Log
Issue: Localstack returning with exit code 55 (License activation failed).

Fix: Switched from latest tag to a stable version (3.0.2) and deactivated Pro features.

Issue: Docker not available inside the container.

Fix: Mounted the Docker socket (/var/run/docker.sock) to allow the container to communicate with the host engine.

Issue: x-amz-trailer header error during S3 uploads.

Status: Identified as a version mismatch between AWS CLI v2 and LocalStack. Provisioning (Bucket creation) was successful.

📁 Verified Resources
S3 Bucket: gloria-first-bucket (Created via AWS CLI)


## 🛠️ Infrastructure & Troubleshooting Log (28/04/2026)

### Case Study: Resolving WSL2 Connection Timeouts
**Issue:** Encountered `HCS_E_CONNECTION_TIMEOUT` which prevented the Linux kernel from booting.
**Root Cause:** A "lock" on the Windows Host Compute Service (vmcompute) that standard restarts failed to clear.
**The Fix:**
1. Performed a forced WSL shutdown: `wsl --shutdown`
2. Manually terminated the Host Compute Service: `net stop vmcompute`
3. Cold-started the service to clear memory buffers: `net start vmcompute`
**Outcome:** Restored environment stability without data loss.

### 🛡️ Security Implementation
* **Tool:** UFW (Uncomplicated Firewall)
* **Status:** Active
* **Rule Logic:** Implemented "Least Privilege" by closing all ports except **80/tcp** to allow controlled web traffic while securing the internal OS.
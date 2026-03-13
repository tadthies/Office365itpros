# Active Directory Upgrade Documentation Checklist

## Purpose
This checklist ensures all pertinent information is captured and maintained during the AD domain controller upgrade project.

---

### 1. Domain Controller Inventory
- Hostname
- IP address
- Operating System version
- Hardware/VM specs (CPU, RAM, disk)
- FSMO roles held
- Global Catalog status
- Site membership
- Backup status
- Contact information

### 2. Replication Topology
- Replication partners for each DC
- AD Sites and Services configuration
- Replication schedule
- Replication health baseline

### 3. DNS Configuration
- DNS zones managed by each DC
- SRV records for DCs
- DNS client settings
- Forwarders and conditional forwarders

### 4. Group Policy Objects
- List of GPOs and their targets
- GPO backup/export location
- Security settings and baselines

### 5. Security & Compliance
- Password policies
- Account lockout policies
- Audit policies
- Security baselines
- Compliance requirements

### 6. Backup & Disaster Recovery
- Backup schedule and retention
- Backup location
- Restore procedures
- RTO/RPO targets

### 7. Network Documentation
- Network diagram (with DCs, subnets, sites)
- IP address allocations
- Firewall rules for AD services
- DNS server assignments

### 8. Change Log
- Change request records
- Approval/sign-off records
- Issues log and resolutions
- Testing results
- Post-implementation review

### 9. Decommissioning Records
- Data archival
- Server shutdown/decommission date
- Infrastructure cleanup

### 10. Operational Runbooks
- Daily health check procedure
- DC promotion/demotion steps
- FSMO role transfer/seizure procedures
- Replication troubleshooting guide

---

## Template Usage
- Update this checklist at each phase of the upgrade.
- Attach supporting documents (spreadsheets, diagrams, logs).
- Review and update quarterly post-upgrade.

---

**Date:** March 13, 2026
**Project:** AD Domain Controller Upgrade (2016 → 2025)

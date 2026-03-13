# Active Directory Domain Controller Upgrade Plan

**Project:** Upgrade AD Domain Controllers from Windows Server 2016 to 2025
**Date:** March 13, 2026

---

## 1. Preparation Phase

### 1.1 Inventory & Documentation
- List all current DCs: hostname, IP, OS, FSMO roles, site, backup status.
- Document AD configuration: replication topology, DNS zones, GPOs, trusts.
- Record network diagrams, firewall rules, and AD Sites.

### 1.2 Health Checks
- Run `dcdiag` and `repadmin` on all DCs; resolve issues.
- Verify backups (system state, AD, DNS, GPOs); test restore.
- Export Group Policies and security baselines.

### 1.3 Stakeholder Communication
- Notify stakeholders, schedule maintenance windows, obtain approvals.
- Prepare lab environment for testing (optional).

---

## 2. Implementation Phase

### 2.1 Build New Server 2025 DCs
- Provision three new Windows Server 2025 servers (hardware/VM).
- Configure OS, networking, join each to domain.
- Install AD DS role, promote each to DC.
- Verify DNS registration, Global Catalog status.

### 2.2 Replication & Health Validation
- Confirm new DCs replicate with existing DCs (`dcdiag`, `repadmin`).
- Validate DNS, GPO, authentication, and AD Sites.

---

## 3. Testing & Verification Phase

### 3.1 Functional Testing
- Test user authentication, GPO application, Kerberos, LDAP, DNS, replication, failover, and application compatibility.
- Validate FSMO role accessibility and replication health.

### 3.2 Sign-Off
- Document test results, obtain management sign-off.

---

## 4. Demotion & Decommissioning Phase

### 4.1 Demote Old Server 2016 DCs
- Transfer FSMO roles to new DCs (if not already done).
- Demote Server 2016 DCs one at a time, verify replication and health after each.
- Remove demoted DCs from AD Sites and Services and DNS.
- Wait for replication to complete before next demotion.

### 4.2 Upgrade Functional Levels
- Raise domain functional level to Windows Server 2025.
- Raise forest functional level to Windows Server 2025.
- Validate new features, run post-upgrade health checks.

### 4.3 Decommission Old DCs
- Archive backups and documentation.
- Remove old DCs from monitoring and backup systems.
- Shut down and decommission old servers (physical/virtual).

---

## 5. Documentation & Environment Updates

### 5.1 Update Documentation
- Update environment/network documentation: DC inventory, FSMO roles, replication topology, DNS, GPOs, security baselines.
- Update operational runbooks and disaster recovery procedures.
- Document all changes, test results, and sign-offs.
- Train operations team and schedule periodic reviews.

---

## 6. Documentation Templates

### 6.1 DC Inventory Template
| Hostname | IP | OS | FSMO | Site | Backup | Contact |
|----------|----|----|------|------|--------|--------|
|          |    |    |      |      |        |        |

### 6.2 Replication Health Template
| DC | Partner | Last Success | Errors | Notes |
|----|---------|-------------|--------|-------|
|    |         |             |        |       |

### 6.3 Change Log Template
| Date | Change | By | Approved | Status |
|------|--------|----|---------|--------|
|      |        |    |         |        |

### 6.4 Testing Results Template
| Area | Description | Result | Tester | Date |
|------|-------------|--------|--------|------|
|      |             |        |        |      |

### 6.5 Decommissioning Template
| Server | Date | Archived | Cleanup | Notes |
|--------|------|----------|---------|-------|
|        |      |          |         |       |

---

**End of Plan**

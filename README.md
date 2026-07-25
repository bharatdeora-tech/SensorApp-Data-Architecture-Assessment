# SensorApp Data Modernization Assessment

## Executive Summary

This repository presents my proposed modernization of the legacy **SensorApp** data platform as part of the Data Architect Technical Assessment.

The existing solution stores transactional data, high-volume sensor telemetry, and audit logs within a single SQL Server database. While this architecture satisfies current functional requirements, it introduces scalability, maintainability, and performance challenges as telemetry volume increases.

The proposed solution adopts a **Polyglot Persistence Architecture**, assigning each workload to the database technology best suited for its characteristics while preserving SQL Server as the authoritative system of record.

The design focuses on:

- Scalability
- Performance
- Operational Resilience
- Data Integrity
- Security
- Long-Term Maintainability

---

# Solution Highlights

- Polyglot Persistence Architecture
- SQL Server retained as System of Record
- TimescaleDB for high-volume time-series telemetry
- MongoDB for append-only audit logging
- Zero-Downtime Migration Strategy
- Independent Workload Scaling
- Enterprise Data Modeling
- Performance Optimization
- Production-Ready Deployment Approach

---

# Enterprise Design Highlights

The proposed solution incorporates several enterprise architecture practices:

- Identity-based relational modeling
- Reference data management
- Normalized location model
- Role-based access control (RBAC)
- Data governance metadata
- Telemetry retention and compression policies
- Audit and operational observability
- Independent workload scalability

---

# Architecture Overview

The proposed solution separates application workloads according to their access patterns rather than storing all data within a single relational database.

| Business Capability | Database Platform | Primary Responsibility |
|--------------------|-------------------|------------------------|
| Device Management | SQL Server | Transactional master data and configuration |
| Configuration Management | SQL Server | Device configuration and operational parameters |
| Sensor Telemetry | TimescaleDB | High-volume time-series ingestion and analytics |
| Alert Management | SQL Server | Alert lifecycle and operational state |
| Audit & Logging | MongoDB | Operational events and application diagnostics |

This workload separation reduces database contention, improves scalability, and allows each platform to evolve independently.

---

# Architecture Principles

The proposed architecture follows several key principles:

- Right Database for the Right Workload
- Separation of Concerns
- Independent Scaling
- Security by Design
- Governance First
- Operational Observability

---

# Repository Contents

| Document | Description |
|----------|-------------|
| **DATABASE-ANALYSIS.md** | Assessment of the legacy database and modernization recommendations |
| **ARCHITECTURE.md** | Target architecture and workload separation |
| **DATABASE-DECISION-MATRIX.md** | Technology evaluation and database selection rationale |
| **CONCEPTUAL-DATA-MODEL.md** | High-level business domain model |
| **LOGICAL-DATA-MODEL.md** | Logical entity relationships |
| **PHYSICAL-DATA-MODEL.md** | Physical database implementation |
| **MIGRATION-STRATEGY.md** | Zero-downtime migration, validation, and rollback strategy |
| **PERFORMANCE-STRATEGY.md** | Performance optimization and scalability considerations |
| **SAMPLE-QUERIES.md** | Representative transactional and analytical queries |
| **sqlserver-ddl.sql** | SQL Server initialization scripts |
| **timescaledb-ddl.sql** | TimescaleDB initialization scripts |
| **mongodb-ddl.js** | MongoDB initialization scripts |

---

# Key Architectural Decisions

## SQL Server

SQL Server remains the **System of Record** and is responsible for:

- Device Management
- Configuration Management
- Alert Management
- Reference Data Management

Key benefits:

- ACID transactions
- Referential integrity
- Strong consistency
- Mature backup and recovery
- Enterprise-grade security

---

## TimescaleDB

TimescaleDB is responsible for high-volume telemetry storage and analytics.

Key capabilities include:

- Hypertables
- Automatic partitioning
- Compression
- Retention policies
- Continuous aggregates
- High ingestion throughput

These capabilities make it well suited for rapidly growing time-series workloads.

---

## MongoDB

MongoDB is responsible for audit and operational logging.

Audit events are typically:

- Append-only
- Semi-structured
- Frequently evolving
- Write intensive

The document model provides flexibility while reducing load on the transactional platform.

---

# Enterprise Governance & Security

The solution incorporates:

- Role-Based Access Control (RBAC)
- Data Classification Metadata
- Retention Policy Management
- Auditability and Operational Traceability
- Schema-Level Security Controls

Additional implementation details are documented within the physical data model and database initialization scripts.

---

# Availability & Resilience

The architecture supports future enterprise deployment patterns including:

- SQL Server Always On Availability Groups
- TimescaleDB Replication
- MongoDB Replica Sets
- Automated Backup and Recovery
- Zero-Downtime Migration Strategy

---

# Repository Structure

```text
SensorApp-Data-Architecture-Assessment/
│
├── README.md
├── DATABASE-ANALYSIS.md
├── ARCHITECTURE.md
├── DATABASE-DECISION-MATRIX.md
├── CONCEPTUAL-DATA-MODEL.md
├── LOGICAL-DATA-MODEL.md
├── PHYSICAL-DATA-MODEL.md
├── MIGRATION-STRATEGY.md
├── PERFORMANCE-STRATEGY.md
├── SAMPLE-QUERIES.md
├── sqlserver-ddl.sql
├── timescaledb-ddl.sql
├── mongodb-ddl.js
└── diagrams/
```

---

# Architecture Diagram

https://excalidraw.com/#json=OsvvvImD9oLMCj7QkTzN4,_ig4TOL4CysSU-3jz8BIcg

---

# Assumptions

The proposed architecture is based on the following assumptions:

- SQL Server remains the authoritative transactional database.
- Sensor telemetry is expected to grow to millions of records per day.
- Audit events are append-only and require long-term retention.
- High availability and minimal downtime are mandatory during migration.
- Historical telemetry must be preserved throughout modernization.

---

# Future Enhancements

The proposed architecture establishes a foundation for future enterprise capabilities, including:

- Apache Kafka for event-driven data ingestion
- Change Data Capture (CDC)
- CQRS reporting workloads
- Grafana and Power BI dashboards
- Infrastructure as Code (Terraform / Docker Compose)
- Automated performance benchmarking
- Long-term archival to a data lake

These enhancements can be introduced incrementally without requiring significant architectural changes.

---

# Conclusion

This assessment demonstrates a modernization strategy that transforms a legacy monolithic database into a scalable, maintainable, and production-ready enterprise data platform.

By combining SQL Server for transactional processing, TimescaleDB for time-series telemetry, and MongoDB for operational logging, the proposed architecture applies the principle of **using the right database for the right workload**.

The solution emphasizes scalability, performance, governance, security, operational resilience, and long-term maintainability while providing a safe zero-downtime modernization path.

---

# Assessment Deliverables

- Database Analysis
- Architecture Design
- Technology Decision Matrix
- Conceptual Data Model
- Logical Data Model
- Physical Data Model
- Migration Strategy
- Performance Strategy
- Sample Queries
- Database DDL Scripts
- Architecture Diagram

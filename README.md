# SensorApp Data Modernization Assessment

## Executive Summary
This repository presents my proposed modernization of the legacy **SensorApp** data platform as part of the Data Architect Technical Assessment.

The existing solution stores transactional data, high-volume sensor telemetry, and audit logs within a single SQL Server database. While this architecture satisfies the application's current functional requirements, it introduces scalability, maintainability, and performance challenges as telemetry volume increases.
The proposed solution adopts a **polyglot persistence architecture**, assigning each workload to the database technology best suited for its characteristics while preserving SQL Server as the authoritative system of record.
The design focuses on scalability, operational resilience, data integrity, and long-term maintainability.
---

# Solution Highlights
-Polyglot Persistence Architecture
-SQL Server retained as System of Record
-TimescaleDB for high-volume time-series telemetry
-MongoDB for append-only audit logging
-Zero-Downtime Migration Strategy
-Independent Workload Scaling
-Enterprise Data Modeling
-Performance Optimization
-Production-Ready Migration Plan
---

# Architecture Overview
The proposed solution separates application workloads according to their access patterns rather than storing all data within a single relational database.

| Business Capability      | Database Platform | Primary Responsibility                          |
|--------------------------|-------------------|-------------------------------------------------|
| Device Management        | SQL Server        | Transactional master data and configuration     |
| Configuration Management | SQL Server        | Device configuration and operational parameters |
| Sensor Telemetry         | TimescaleDB       | High-volume time-series ingestion and analytics |
| Alert Management         | SQL Server        | Alert lifecycle and operational state           |
| Audit & Logging          | MongoDB           | Operational events and application diagnostics  |

This workload separation reduces database contention, improves scalability, and allows each platform to evolve independently.
---

# Repository Contents

| Document | Description                                                                                                    |
|---------------------------------|-----------------------------------------------------------------------------------------|
| **DATABASE-ANALYSIS.md**        | Assessment of the legacy database, identified issues, and modernization recommendations |
| **ARCHITECTURE.md**             | Proposed enterprise architecture and workload separation                                |
| **DATABASE-DECISION-MATRIX.md** | Technology evaluation and database selection rationale                                  |
| **CONCEPTUAL-DATA-MODEL.md**    | High-level business domain model                                                        |
| **LOGICAL-DATA-MODEL.md**       | Logical entity relationships                                                            |
| **PHYSICAL-DATA-MODEL.md**      | Physical database implementation                                                        |
| **MIGRATION-STRATEGY.md**       | Zero-downtime migration, validation, and rollback strategy                              |
| **PERFORMANCE-STRATEGY.md**     | Performance optimization and scalability considerations                                 |
| **SAMPLE-QUERIES.md**           | Representative transactional and analytical queries                                     |
| **ddl/**                        | Database initialization scripts for SQL Server, TimescaleDB, and MongoDB                |
---

# Key Architectural Decisions
## Polyglot Persistence

Different workloads have different performance characteristics.
Instead of optimizing a single database for every use case, each workload is assigned to the platform best suited for its operational requirements.
---

## SQL Server
Used as the **System of Record** for:
- Device Management
- Configuration Management
- Alert Management

Benefits include:
- ACID transactions
- Referential integrity
- Mature backup and recovery
- Stable master data management
---

## TimescaleDB
Selected for telemetry because it provides:
- Hypertables
- Automatic partitioning
- Continuous aggregates
- Compression
- Retention policies
- High ingestion throughput

These capabilities make it well suited for rapidly growing time-series workloads.
---

## MongoDB
Selected for audit logging because audit events are:
- Append-only
- Semi-structured
- Frequently evolving
- Write intensive

The document model provides flexibility while reducing load on the transactional database.
---

# Repository Structure

SensorApp-Assessment/
```text
│
├── README.md
│
├── docs/
│   ├── DATABASE-ANALYSIS.md
│   ├── ARCHITECTURE.md
│   ├── DATABASE-DECISION-MATRIX.md
│   ├── CONCEPTUAL-DATA-MODEL.md
│   ├── LOGICAL-DATA-MODEL.md
│   ├── PHYSICAL-DATA-MODEL.md
│   ├── MIGRATION-STRATEGY.md
│   ├── PERFORMANCE-STRATEGY.md
│   └── SAMPLE-QUERIES.md
│
├── ddl/
│   ├── sqlserver/
│   ├── timescaledb/
│   └── mongodb/
│
└── diagrams/
```
## Architecture Diagram
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
- CQRS for reporting workloads
- Grafana and Power BI dashboards
- Infrastructure as Code (Terraform / Docker Compose)
- Automated performance benchmarking
- Long-term archival to a data lake
These enhancements can be introduced incrementally without requiring significant architectural changes.
---

# Conclusion
This assessment demonstrates a modernization strategy that transforms a legacy monolithic database into a scalable, maintainable, and production-ready enterprise data platform.
By combining SQL Server for transactional processing, TimescaleDB for time-series telemetry, and MongoDB for operational logging, the proposed architecture applies the principle of **using the right database for the right workload**.
The solution emphasizes scalability, performance, operational resilience, and long-term maintainability while providing a safe, zero-downtime migration path.
---

## Assessment Deliverabl
Database Analysis
Architecture Design
Technology Decision Matrix
Conceptual, Logical & Physical Data Models
Migration Strategy
Performance Strategy
Sample Queries
Database DDL Scripts
Architecture Diagrams

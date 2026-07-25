# Database Selection & Decision Matrix

## Executive Summary
The legacy SensorApp stores transactional data, telemetry, and operational logs within a single SQL Server database. While this architecture satisfies the current functional requirements, it introduces scalability, performance, and maintainability challenges as telemetry volume increases.
The proposed solution adopts a **polyglot persistence architecture**, selecting the most appropriate database technology for each workload based on its operational characteristics rather than standardizing on a single database platform.
This document explains the evaluation process, architectural trade-offs, and rationale behind each technology selection.
---

# Evaluation Criteria
Candidate database technologies were evaluated using the following architectural criteria.

| Evaluation Criteria         | Description                                                                       |
|-----------------------------|-----------------------------------------------------------------------------------|
| **Workload Suitability**    | Ability to support transactional, time-series, or document workloads efficiently. |
| **Scalability**             | Capacity to scale as data volume and throughput increase.                         |
| **Performance**             | Read/write efficiency for expected access patterns.                               |
| **Consistency & Integrity** | Support for ACID transactions, constraints, and data validation.                  |
| **Operational Complexity**  | Backup, monitoring, maintenance, and deployment effort.                           |
| **Integration**             | Ease of integration with the existing ASP.NET Core application.                   |
---

# Technology Selection Matrix

| Business Capability               | Technologies Evaluated                        | Selected Technology  |
|-----------------------------------|-----------------------------------------------|----------------------|
| Device & Configuration Management | SQL Server, PostgreSQL                        | **SQL Server**       |
| Sensor Telemetry                  | SQL Server, PostgreSQL, TimescaleDB, InfluxDB | **TimescaleDB**      |
| Audit & Operational Logging       | SQL Server, MongoDB, Elasticsearch/OpenSearch | **MongoDB**          |

# Selection Rationale:
**SQL Server**  : Strong transactional consistency, mature relational capabilities, and minimal migration risk.
**TimescaleDB** : Native time-series optimizations including hypertables, compression, retention policies, and continuous aggregates.
**MongoDB**     : Flexible document storage optimized for append-only operational events and evolving schemas.
---

# Architectural Decision Rationale

## SQL Server
### Role
- Device Management
- Configuration Management
- Alert Management

### Why Selected
SQL Server remains the **System of Record** because it provides:
- ACID transactions
- Referential integrity
- Mature indexing
- Reliable backup and recovery
- Stable master data management

### Trade-offs
Although SQL Server excels at transactional processing, it is less suitable for extremely high-volume telemetry ingestion and append-only logging workloads.
---

## TimescaleDB
### Role
- Sensor telemetry
- Historical analytics
- Time-series reporting

### Why Selected
TimescaleDB extends PostgreSQL with features specifically designed for time-series data.
Key capabilities include:
- Hypertables
- Automatic partitioning
- Compression
- Continuous aggregates
- Retention policies
- PostgreSQL compatibility

These capabilities significantly improve ingestion throughput and analytical query performance.

### Trade-offs
Introducing TimescaleDB adds another database platform to maintain, requiring additional operational monitoring and backup procedures.
---

## MongoDB
### Role
- Audit logs
- Operational events
- Exception tracking
- Diagnostic information

### Why Selected
MongoDB is well suited for append-only operational workloads because it offers:
- Flexible document model
- High write throughput
- Schema evolution
- Compound indexes
- TTL indexes for automatic retention

### Trade-offs
MongoDB is not intended for highly relational workloads or complex multi-table joins. This limitation is acceptable because audit events are independent documents.
---

# Alternatives Considered
## PostgreSQL
### Advantages
- Excellent relational database
- Strong SQL support
- Mature ecosystem

### Why Not Selected
While PostgreSQL is an excellent general-purpose database, TimescaleDB provides native time-series capabilities without requiring custom partitioning or additional maintenance.
---

## InfluxDB
### Advantages
- Optimized for time-series workloads
- Excellent ingestion performance

### Why Not Selected
The use of Flux/InfluxQL introduces additional operational complexity and reduces consistency with the SQL-based technology stack already used by the application.
---

## Elasticsearch / OpenSearch
### Advantages
- Powerful search capabilities
- Full-text indexing
- Log analytics

### Why Not Selected
Although powerful, Elasticsearch introduces significant infrastructure and operational overhead. MongoDB provides sufficient functionality for the application's audit logging requirements while remaining simpler to operate.
---

# Architectural Principles
The proposed architecture follows several guiding principles.
- Use the right database for the right workload.
- Preserve SQL Server as the authoritative system of record.
- Isolate high-volume telemetry from transactional processing.
- Separate operational logging from business transactions.
- Enable independent scaling of each workload.
- Minimize coupling through repository abstractions.
---

# Decision Summary

| Workload          | Selected Database | Primary Benefit                    |
|-------------------|-------------------|------------------------------------|
| Device Management | SQL Server        | Transactional consistency          |
| Configuration     | SQL Server        | Referential integrity              |
| Telemetry         | TimescaleDB       | High-volume time-series processing |
| Audit Logging     | MongoDB           | Flexible document storage          |
---

# Long-Term Benefits
The proposed architecture provides several strategic advantages over the existing monolithic database.
- Independent workload scaling
- Improved ingestion throughput
- Reduced database contention
- Better operational resilience
- Simplified schema evolution
- Improved analytical performance
- Reduced maintenance complexity
- Future support for event-driven architectures
---

# Conclusion
The selected technologies were chosen based on workload characteristics rather than database preference.
SQL Server remains the transactional system of record, TimescaleDB provides an optimized platform for high-volume telemetry, and MongoDB supports flexible operational logging.
This workload-oriented approach aligns with modern enterprise data architecture practices and provides a scalable foundation capable of supporting future business growth while minimizing operational risk.
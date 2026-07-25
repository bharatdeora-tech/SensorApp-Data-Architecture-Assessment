# DATABASE-ANALYSIS.md

# Database Analysis & Schema Audit
## Executive Summary

The current SensorApp database is implemented as a single SQL Server database that stores transactional data, high-volume sensor telemetry, and audit logs within the same schema. While this design is adequate for small deployments, it introduces scalability, performance, and maintainability challenges as data volume grows.
The proposed solution modernizes the platform using a **polyglot persistence architecture**, assigning each workload to the database technology best suited for its access patterns and operational requirements.
---

# Current Database Assessment

| Area                      | Observation                         | Business Impact                         | Recommendation                             |
|---------------------------|-------------------------------------|-----------------------------------------|--------------------------------------------|
| **Mixed Workloads**       | Single DB for OLTP, telemetry, logs | Resource contention & performance drops | Split into specialized database stores     |
| **Device Config**         | Pipe-delimited string settings      | High parsing overhead & invalid data    | Use structured JSON/typed attributes       |
| **Location Data**         | Concatenated location strings       | Impaired spatial querying & reporting   | Normalize into explicit location fields    |
| **Telemetry Schema**      | Cryptic column names(`v`,`v2`,`v3`) | Reduced readability & high error rates  | Use explicit names(Temp,Humidity, Pressure)|
| **Referential Integrity** | Missing Foreign Keys on telemetry   | Risk of orphaned data & corrupt records | Enforce relational integrity constraints   |
| **Audit Logging**         | Unstructured logs in relational DB  | Storage bloat & heavy IOPS contention   | Offload to append-only document store      |
---

# Key Architectural Findings

## 1. Mixed Database Workloads
The current architecture stores multiple workload types in a single database:
- Transactional device management
- Sensor telemetry ingestion
- Configuration management
- Audit logging

Each workload has different performance characteristics, resulting in unnecessary contention for CPU, memory, storage, and database locks.
---

## 2. Schema Design Issues
Several schema design decisions reduce maintainability:
- Generic column names do not reflect business meaning.
- Delimited configuration strings require application-side parsing.
- Duplicate and unused columns increase storage complexity.
- Concatenated location values violate normalization principles.

These issues make the schema difficult to understand, extend, and optimize.
---

## 3. Scalability Limitations
Telemetry data grows continuously over time.
As the number of connected devices increases:
- Table sizes grow rapidly.
- Index maintenance becomes more expensive.
- Historical queries become slower.
- Backup and restore operations take longer.
- OLTP transactions compete with analytical workloads.

The current architecture cannot efficiently support long-term telemetry growth.
---

## 4. Data Integrity Risks
The absence of referential constraints allows inconsistent data to be introduced into the system.
Potential issues include:
- Orphaned telemetry records
- Invalid device references
- Reduced confidence in reporting
- Increased application-side validation

Enforcing relational integrity improves overall data quality.
---

# Modernization Strategy
The proposed architecture separates each workload into the database platform best suited for its characteristics.

| Workload              | Selected Database | Design Rationale                                                                                           |
|-----------------------|-------------------|------------------------------------------------------------------------------------------------------------|
| **Device Management** | **SQL Server**    | ACID transactions, referential integrity, and structured master data management.                           |
| **Sensor Telemetry**  | **TimescaleDB**   | Optimized for HighVolume time-series ingestion, automatic partitioning,compression and analytical queries. |
| **Audit Logs**        | **MongoDB**       | Flexible document model supporting high-throughput append-only logging and evolving event structures.      |

This workload separation allows each database to scale independently while reducing resource contention.
---

# Benefits of the Proposed Architecture
The modernized architecture provides several improvements over the current implementation.
- Independent scaling of transactional, telemetry, and logging workloads.
- Improved telemetry ingestion performance.
- Faster historical analytics through time-series optimization.
- Better storage efficiency using compression and retention policies.
- Simplified schema with meaningful business terminology.
- Stronger data integrity through enforced relationships.
- Reduced backup size for transactional databases.
- Improved maintainability through clear separation of responsibilities.
---

# Risks and Trade-offs
Introducing multiple database technologies increases operational complexity.
Additional considerations include:
- Multiple backup and recovery strategies.
- Cross-database monitoring.
- Eventual consistency between independent data stores.
- Operational knowledge across different database platforms.

These trade-offs are acceptable because they enable significantly better scalability, performance, and long-term maintainability.
---

# Future Evolution
The proposed architecture establishes a strong foundation for future enhancements, including:
- Event-driven ingestion using Apache Kafka.
- CQRS-based reporting services.
- Read replicas for analytical workloads.
- Long-term archival to a data lake.
- Real-time monitoring and streaming analytics.

These capabilities can be introduced incrementally without major changes to the core data model.
---

# Conclusion
The current SensorApp database successfully supports the application's functional requirements but combines multiple workload types within a single relational database, limiting scalability and maintainability.
The proposed polyglot persistence architecture assigns each workload to the database technology best suited for its characteristics:
- **SQL Server** for transactional master data
- **TimescaleDB** for time-series telemetry
- **MongoDB** for audit logging

This modernization improves scalability, operational efficiency, maintainability, and long-term system evolution while preserving transactional consistency where it is most important.
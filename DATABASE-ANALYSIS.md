# Database Analysis & Schema Audit

## Executive Summary

The current SensorApp database is implemented as a single SQL Server database that stores transactional data, high-volume sensor telemetry, and audit logs within the same platform.

While this architecture satisfies the application's functional requirements, it introduces scalability, performance, governance, and maintainability challenges as data volume grows.

The proposed solution modernizes the platform using a **Polyglot Persistence Architecture**, assigning each workload to the database technology best suited for its access patterns and operational requirements while preserving SQL Server as the authoritative system of record.

---

# Current Database Assessment

| Area | Observation | Business Impact | Recommendation |
|--------|--------|--------|--------|
| **Mixed Workloads** | Single database supports OLTP, telemetry, and logging | Resource contention and performance degradation | Separate workloads into specialized data platforms |
| **Device Configuration** | Pipe-delimited settings stored as strings | Parsing complexity and poor data validation | Use structured JSON and typed attributes |
| **Location Data** | Concatenated location values | Limited reporting and duplicated data | Normalize into dedicated location entities |
| **Telemetry Schema** | Cryptic column naming (`v`, `v2`, `v3`) | Poor readability and increased support effort | Adopt meaningful domain-oriented names |
| **Identity Strategy** | GUID-based identifiers used throughout | Larger indexes and higher storage overhead | Use identity-based relational keys with external integration identifiers |
| **Referential Integrity** | Limited relationship enforcement | Risk of inconsistent and orphaned data | Enforce relational constraints where appropriate |
| **Audit Logging** | Unstructured logs stored in SQL Server | Storage growth and transactional contention | Offload logging to a document-oriented platform |
| **Governance & Security** | Limited metadata and governance controls | Reduced operational transparency | Introduce governance and security metadata |

---

# Key Architectural Findings

## 1. Mixed Database Workloads

The current architecture stores multiple workload types within a single database:

- Transactional device management
- Configuration management
- Sensor telemetry ingestion
- Audit logging

Each workload exhibits different performance characteristics and scaling requirements.

As data volumes increase, these competing workloads create unnecessary contention for:

- CPU
- Memory
- Storage
- Database locks
- Maintenance operations

---

## 2. Schema Design Issues

Several schema design decisions reduce maintainability and increase operational complexity:

- Generic column names that do not reflect business meaning
- Delimited configuration values requiring application-side parsing
- Duplicate and unused attributes
- Concatenated location values that violate normalization principles
- GUID-based relational keys increasing storage and index overhead

These issues increase development effort and make the platform more difficult to evolve.

---

## 3. Scalability Limitations

Telemetry data grows continuously over time.

As the number of connected devices increases:

- Table sizes grow rapidly
- Index maintenance becomes more expensive
- Historical queries become slower
- Backup and restore operations take longer
- Transactional and analytical workloads compete for resources

The current architecture cannot efficiently support long-term telemetry growth.

---

## 4. Data Integrity Risks

The absence of comprehensive referential constraints increases the risk of inconsistent data.

Potential issues include:

- Orphaned telemetry records
- Invalid device references
- Reduced confidence in reporting
- Increased application-side validation

Enforcing relational integrity improves overall data quality and operational confidence.

---

## 5. Governance & Security Gaps

The legacy platform lacks structured governance and security controls.

Examples include:

- No formal data classification
- No documented retention policies
- Limited role-based access controls
- No governance metadata supporting ownership and stewardship

As platform complexity increases, governance becomes essential for operational transparency, compliance, and long-term sustainability.

---

# Modernization Strategy

The proposed architecture separates each workload into the database platform best suited for its operational characteristics.

| Workload | Selected Database | Design Rationale |
|-----------|-----------|-----------|
| **Transactional Master Data** | **SQL Server** | ACID transactions, referential integrity, governance metadata, and structured master data management |
| **Sensor Telemetry** | **TimescaleDB** | Optimized for high-volume time-series ingestion, partitioning, compression, retention, and analytics |
| **Audit & Operational Logging** | **MongoDB** | Flexible document model supporting append-only logging and evolving event structures |

This workload separation enables each platform to scale independently while reducing contention and improving maintainability.

---

# Benefits Of The Proposed Architecture

The modernized architecture provides several improvements over the current implementation:

- Independent scaling of transactional, telemetry, and logging workloads
- Improved telemetry ingestion performance
- Faster historical analytics through time-series optimization
- Better storage efficiency through compression and retention policies
- Simplified schema using meaningful business terminology
- Stronger data integrity through enforced relationships
- Reduced backup size for transactional databases
- Improved maintainability through separation of responsibilities
- Governance-ready data architecture
- Improved security through role-based access controls

---

# Risks And Trade-Offs

Introducing multiple database technologies increases operational complexity.

Considerations include:

- Multiple backup and recovery strategies
- Cross-platform monitoring
- Eventual consistency between independent data stores
- Operational knowledge across multiple database platforms

These trade-offs are acceptable because they enable significantly greater scalability, performance, governance, and long-term maintainability.

---

# Future Evolution

The proposed architecture establishes a foundation for future enhancements, including:

- Apache Kafka for event-driven ingestion
- Change Data Capture (CDC)
- CQRS-based reporting services
- Read replicas for analytical workloads
- Long-term archival to a data lake
- Real-time monitoring and streaming analytics
- Enterprise data catalog integration
- Data lineage and metadata management

These capabilities can be introduced incrementally without major architectural changes to the core platform.

---

# Conclusion

The current SensorApp database successfully supports the application's functional requirements but combines multiple workload types within a single relational database, limiting scalability, maintainability, and operational flexibility.

The proposed solution separates workloads according to their operational characteristics and assigns them to the database technology best suited for each use case:

- **SQL Server** for transactional master data and configuration management
- **TimescaleDB** for high-volume time-series telemetry
- **MongoDB** for audit and operational logging

The design also introduces foundational governance, security, and operational observability capabilities necessary for future enterprise-scale growth.

This modernization strategy improves scalability, operational efficiency, maintainability, and long-term system evolution while preserving strong transactional consistency where it is most important.

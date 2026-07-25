# ARCHITECTURE.md
# Target Data Architecture

## Objective
The objective of the proposed architecture is to modernize the legacy SensorApp by separating transactional, telemetry, and logging workloads into purpose-built data platforms.
Rather than storing all data within a single relational database, each workload is assigned to the database technology best suited to its characteristics. This improves scalability, maintainability, operational efficiency, and long-term system evolution while preserving SQL Server as the authoritative system of record for transactional data.
---

# Architecture Principles
The proposed solution follows several key architectural principles.
- **Polyglot Persistence** – Use the most appropriate database technology for each workload.
- **Separation of Concerns** – Isolate transactional, telemetry, and logging workloads.
- **Scalability** – Allow each data platform to scale independently.
- **Maintainability** – Organize data by business domain rather than technical implementation.
- **Data Integrity** – Preserve ACID guarantees for transactional operations while optimizing analytical workloads.
---

# Business Capability Mapping

| Business Capability      | Database     | Purpose                             |
|--------------------------|--------------|-------------------------------------|
| Device Management        | SQL Server   | Transactional master data           |
| Configuration Management | SQL Server   | Device configuration and thresholds |
| Telemetry Processing     | TimescaleDB  | High-volume time-series data        |
| Alert Management         | SQL Server   | Alert lifecycle management          |
| Audit & Logging          | MongoDB      | Operational events and diagnostics  |

The database selection is driven by workload characteristics rather than standardizing on a single database technology.

---

# Legacy Architecture
The existing application stores every workload inside a single SQL Server database.

```text
Client Applications
        │
        ▼
 ASP.NET Core API
        │
        ▼
 SQL Server
 ├── Devices
 ├── Configuration
 ├── Telemetry
 ├── Alerts
 └── Audit Logs
```

Although simple, this design causes transactional operations, telemetry ingestion, reporting, and audit logging to compete for the same database resources.
---

# Proposed Target Architecture

```text
                 Client Applications
                         │
                         ▼
                 ASP.NET Core REST API
                         │
                Business Service Layer
                         │
                Repository Abstraction
                         │
        ┌────────────────┼─────────────────┐
        ▼                ▼                 ▼
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │ SQL Server   │ │ TimescaleDB  │ │ MongoDB      │
 ├──────────────┤ ├──────────────┤ ├──────────────┤
 │ Devices      │ │ Telemetry    │ │ Audit Logs   │
 │ Config       │ │ Hypertables  │ │ Events       │
 │ Alerts       │ │ Compression  │ │ Diagnostics  │
 └──────────────┘ └──────────────┘ └──────────────┘
```

Each database is responsible for a single business capability and can evolve independently.
---

# End-to-End Data Flow

```text
Device Registration
        │
        ▼
SQL Server

        │
        ▼
Sensor Reading

        │
        ▼
Validation Layer

        │
        ▼
TimescaleDB

        │
        ▼
Threshold Evaluation

        │
   ┌────┴────┐
   ▼         ▼
Alert      Normal

   │
   ▼
SQL Server

   │
   ▼
Application Event

   │
   ▼
MongoDB Audit Log
```

This workflow keeps transactional operations separate from telemetry ingestion while ensuring operational events are captured independently.
---

# Why This Architecture?
## SQL Server
SQL Server remains the system of record for transactional workloads because it provides:
- ACID transactions
- Referential integrity
- Strong consistency
- Mature backup and recovery
- Stable master data management
---

## TimescaleDB
Telemetry is migrated to TimescaleDB because it is optimized for time-series workloads.
Key capabilities include:
- Hypertables
- Automatic partitioning
- Compression
- Continuous aggregates
- Retention policies
- Efficient range queries

These features significantly improve ingestion performance and historical analytics.
---

## MongoDB
Audit logging is isolated into MongoDB because audit events are:
- Append-only
- Semi-structured
- Frequently evolving
- Rarely updated

A document database provides greater flexibility while reducing unnecessary load on the transactional database.
---

# Scalability Strategy
Each database scales independently according to its workload.

| Database    | Scaling Strategy                                       |
|-------------|--------------------------------------------------------|
| SQL Server  | Vertical scaling for OLTP                              |
| TimescaleDB | Horizontal growth through hypertables and partitioning |
| MongoDB     | Replica Sets with future sharding support              |

Independent scaling avoids resource contention and improves long-term operational efficiency.
---

# Architectural Trade-offs
The proposed architecture introduces additional operational complexity.
Challenges include:
- Multiple database technologies
- Separate backup strategies
- Cross-database monitoring
- Eventual consistency between independent stores

However, these trade-offs are justified by significant improvements in scalability, performance, maintainability, and operational flexibility.
---

# Future Evolution
The architecture has been designed to support future enterprise capabilities without major redesign.
Potential enhancements include:
- Apache Kafka for event streaming
- Change Data Capture (CDC)
- CQRS for reporting
- Read replicas
- Data Lake integration
- Real-time dashboards using Grafana or Power BI

These enhancements can be introduced incrementally as system demand increases.
---

# Conclusion
The proposed architecture transforms the legacy monolithic database into a modern polyglot persistence platform.
By assigning each workload to the database technology best suited for its access patterns, the solution improves scalability, performance, maintainability, and operational resilience while preserving transactional consistency for business-critical operations.
This architecture provides a strong foundation for future growth and aligns with modern enterprise data architecture best practices.
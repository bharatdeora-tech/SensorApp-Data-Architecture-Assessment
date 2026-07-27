# Target Data Architecture

## Objective

The objective of the proposed architecture is to modernize the legacy SensorApp platform by separating transactional, telemetry, and operational logging workloads into purpose-built data platforms.

Rather than storing all data within a single relational database, each workload is assigned to the database technology best suited to its access patterns and scalability requirements.

This approach improves:

- Scalability
- Performance
- Maintainability
- Operational Efficiency
- Long-Term Flexibility

while preserving SQL Server as the authoritative System of Record for transactional data.

---

# Architecture Principles

The proposed solution follows several key architectural principles:

- **Polyglot Persistence** – Use the most appropriate database technology for each workload.
- **Separation of Concerns** – Isolate transactional, telemetry, and logging workloads.
- **Scalability** – Allow each platform to scale independently.
- **Maintainability** – Organize data by business domains and responsibilities.
- **Data Integrity** – Preserve strong consistency for transactional data.
- **Security by Design** – Enforce least-privilege access and controlled data access patterns.
- **Operational Observability** – Maintain operational visibility through telemetry, alerts, and audit events.
- **Future-Ready Architecture** – Support future data platform expansion without significant redesign.

---

# Enterprise Design Considerations

The target architecture incorporates several enterprise-oriented design decisions:

- Polyglot Persistence
- Reference Data Management
- Independent Workload Scaling
- Data Retention Policies
- Auditability and Traceability
- Role-Based Access Control (RBAC)
- Compression and Lifecycle Management
- Future Event-Driven Integration

---

# Business Capability Mapping

| Business Capability | Database | Purpose |
|----------|----------|----------|
| Device Management | SQL Server | Transactional master data |
| Configuration Management | SQL Server | Device configuration and thresholds |
| Alert Management | SQL Server | Alert lifecycle management |
| Reference Data Management | SQL Server | Standardized business classifications |
| Telemetry Processing | TimescaleDB | High-volume time-series telemetry |
| Audit & Operational Events | MongoDB | Operational events and diagnostics |

The selected databases align with workload characteristics rather than enforcing a single technology across all use cases.

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

Although simple, this architecture causes transactional operations, telemetry ingestion, reporting, and audit logging to compete for the same resources.

As telemetry volumes increase, scalability and operational efficiency become increasingly difficult to maintain.

---

# Proposed Target Architecture

```text
                 Client Applications
                         │
                         ▼
                 ASP.NET Core REST API
                         │
                         ▼
                Business Service Layer
                         │
                         ▼
                Repository Abstraction
                         │
        ┌────────────────┼─────────────────┐
        ▼                ▼                 ▼

 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │ SQL Server   │ │ TimescaleDB  │ │ MongoDB      │
 ├──────────────┤ ├──────────────┤ ├──────────────┤
 │ Devices      │ │ Telemetry    │ │ Audit Events │
 │ Config       │ │ Hypertables  │ │ Diagnostics  │
 │ Alerts       │ │ Compression  │ │ Operations   │
 │ Ref Data     │ │ Retention    │ │ TTL Indexes  │
 └──────────────┘ └──────────────┘ └──────────────┘
```

Each database platform is optimized for a specific workload and can evolve independently without impacting the others.

---

# End-To-End Data Flow

```text
Device Registration
        │
        ▼
SQL Server
(Device Master Data)

        │
        ▼
Telemetry Ingestion

        │
        ▼
TimescaleDB
(Sensor Readings)

        │
        ▼
Business Rule Evaluation

        │
   ┌────┴────┐
   ▼         ▼
Alert      Normal

   │
   ▼
SQL Server
(Alert Management)

   │
   ▼
Audit Event

   │
   ▼
MongoDB
(Operational Logging)
```

This workflow separates transactional processing from telemetry ingestion while preserving operational traceability through audit and event logging.


# Architecture Diagram

[https://excalidraw.com/#json=OsvvvImD9oLMCj7QkTzN4,_ig4TOL4CysSU-3jz8BIcg
](https://excalidraw.com/#json=pEu0ItS_TCAO197virSR3,YqecibeiDxb-_XiFcm0-ww)


# Workload Allocation Strategy

## SQL Server

SQL Server remains the authoritative System of Record.

Responsibilities include:

- Device Management
- Configuration Management
- Alert Management
- Reference Data Management

Key capabilities:

- ACID Transactions
- Referential Integrity
- Strong Consistency
- Mature Backup & Recovery
- Enterprise Security Features

---

## TimescaleDB

TimescaleDB is responsible for telemetry storage and analytics.

Key capabilities:

- Hypertables
- Automatic Partitioning
- Compression Policies
- Retention Policies
- Continuous Aggregates
- Efficient Range Queries

These features significantly improve telemetry ingestion performance and historical analytical workloads.

---

## MongoDB

MongoDB is responsible for operational and audit event storage.

Key capabilities:

- Flexible Document Model
- High Write Throughput
- Schema Evolution
- TTL Retention Policies
- Compound Indexes
- Operational Event Storage

MongoDB allows the platform to capture evolving operational events without introducing additional complexity into transactional systems.

---

# Scalability Strategy

Each database platform scales independently according to workload requirements.

| Database | Scaling Strategy |
|----------|----------|
| SQL Server | Vertical scaling for transactional workloads |
| TimescaleDB | Chunk management, compression, and storage scaling |
| MongoDB | Replica Sets with future sharding support |

This independent scaling model prevents telemetry and logging growth from negatively impacting transactional workloads.

---

# Architectural Trade-Offs

The proposed architecture introduces some additional operational complexity.

Considerations include:

- Multiple database technologies
- Independent backup strategies
- Cross-platform monitoring
- Operational skills across multiple platforms
- Eventual consistency between specialized data stores

These trade-offs are justified by significant improvements in scalability, workload isolation, performance, and long-term maintainability.

---

# Future Evolution

The architecture provides a foundation for future enterprise capabilities.

Potential enhancements include:

- Apache Kafka Event Streaming
- Change Data Capture (CDC)
- CQRS Reporting Models
- Read Replicas
- Data Lake Integration
- Predictive Maintenance Analytics
- AI-Assisted Operational Analytics
- Grafana and Power BI Dashboards

These capabilities can be introduced incrementally as platform requirements evolve.

---

# Conclusion

The proposed architecture transforms the legacy monolithic database into a modern Polyglot Persistence platform.

By assigning each workload to the database technology best suited for its characteristics:

- SQL Server manages transactional master data.
- TimescaleDB manages time-series telemetry.
- MongoDB manages audit and operational events.

The result is a scalable, maintainable, and operationally efficient architecture that supports future growth while preserving transactional consistency for business-critical operations.

This architecture aligns with modern enterprise data platform practices and establishes a strong foundation for future expansion.

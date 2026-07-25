# Physical Data Model

## Purpose

The Physical Data Model defines how the logical data model is implemented using the selected database technologies. While the Logical Data Model remains technology-independent, this document translates those business entities into optimized physical storage structures, indexing strategies, constraints, partitioning policies, and operational configurations.
The proposed architecture adopts a **polyglot persistence** approach, where each database platform is selected according to its workload characteristics rather than attempting to satisfy all requirements with a single database engine.

This implementation aligns with the overall modernization strategy by:
- Preserving SQL Server as the authoritative System of Record
- Moving high-volume telemetry into TimescaleDB
- Isolating operational logging within MongoDB
- Supporting horizontal scalability
- Maintaining strong data integrity
- Improving operational performance
- Enabling future event-driven expansion
---

# Physical Design Principles
The physical implementation follows several architectural principles.

| Principle              | Implementation                                                                                                 |
|------------------------|----------------------------------------------------------------------------------------------------------------|
| Workload Isolation     | Separate transactional, analytical, and logging workloads into dedicated platforms.                            |
| Technology Alignment   | Select each database according to workload characteristics rather than standardizing on a single engine.       |
| Performance First      | Optimize indexing, partitioning, compression, and retention for each workload.                                 |
| Data Integrity         | Preserve transactional consistency through SQL Server while maintaining logical relationships across platforms.|
| Scalability            | Allow each database to scale independently based on workload demand.                                           |
| Operational Simplicity | Standardize naming conventions, schemas, backup policies, and monitoring across all platforms.                 |
---

# Enterprise Naming Standards
A consistent naming convention is adopted across all physical databases to improve readability, maintainability, and cross-platform integration.

## Entity Identifiers
Every business entity uses an explicit identifier.

| Entity         | Naming Standard          |
|----------------|--------------------------|
| Device         | device_identifier        |
| Configuration  | configuration_identifier |
| Sensor Reading | reading_identifier       |
| Alert          | alert_identifier         |
| Audit Event    | event_identifier         |
| Correlation    | correlation_identifier   |
---

## Timestamp Fields
All temporal attributes use the `_at` suffix.
Examples:
- registered_at
- created_at
- updated_at
- recorded_at
- triggered_at
- acknowledged_at
- resolved_at
---

## Status Fields
Operational state is explicitly represented.
Examples
- device_status
- configuration_status
- alert_status
- quality_status
---

## Database Objects

| Object             | Convention           |
|--------------------|----------------------|
| Primary Key        | PK_<schema>_<table>  |
| Foreign Key        | FK_<child>_<parent>  |
| Unique Constraint  | UQ_<table>_<column>  |
| Check Constraint   | CK_<table>_<column>  |
| Default Constraint | DF_<table>_<column>  |
| Index              | IX_<table>_<columns> |
---

# Platform Responsibilities
Each database platform owns a clearly defined business capability.

| Platform    | Primary Responsibility                                        | Workload Characteristics   |
|-------------|---------------------------------------------------------------|----------------------------|
| SQL Server  | Device Management, Configuration Management, Alert Management | Transactional OLTP         |
| TimescaleDB | Sensor Telemetry                                              | High-volume Time-Series    |
| MongoDB     | Operational Logging & Audit                                   | Append-only Document Store |

This separation prevents competing workloads from affecting overall application performance while allowing each platform to leverage its native optimization capabilities.
---

# Physical Architecture Overview

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
                   Repository Abstraction Layer
      ┌───────────────────────┼────────────────────────┐
      ▼                       ▼                        ▼
SQL Server              TimescaleDB              MongoDB
(System of Record)      (Telemetry)           (Audit & Logs)

asset.*                 telemetry.*          audit.*
configuration.*         Continuous           application_logs
alert.*                 Aggregates           TTL Indexes
reference.*             Compression          JSON Documents
```
---

# SQL Server Physical Model
## Purpose
SQL Server remains the authoritative transactional platform for the SensorApp ecosystem. It manages business entities requiring strong consistency, referential integrity, transactional guarantees, and predictable relational query performance.
Unlike telemetry and logging workloads, master data changes relatively infrequently but require strict validation and ACID compliance.
SQL Server therefore serves as the enterprise **System of Record**.
---

# SQL Server Database Organization
Rather than placing every object inside the default `dbo` schema, business domains are separated into dedicated schemas.

| Schema        | Responsibility                |
|---------------|-------------------------------|
| asset         | Device master data            |
| configuration | Device operating parameters   |
| alert         | Alert lifecycle management    |
| reference     | Static lookup data            |
| integration   | External integration metadata |
| security      | Security and access control   |

This structure improves maintainability, simplifies security management, and establishes clear ownership boundaries.
---

# Primary Entity — asset.devices
The `asset.devices` table stores the master definition of every registered sensor device.

## Columns
| Column            | Description                       |
|-------------------|-----------------------------------|
| device_identifier | Primary business identifier       | 
| device_code       | Human-readable unique device code |
| device_name       | Display name                      |
| sensor_type       | Sensor classification             |
| device_status     | Operational status                |
| location_name     | Physical installation location    |
| registered_at     | Registration timestamp            |
| created_at        | Audit timestamp                   |
| updated_at        | Last modification timestamp       |
---

## Constraints
Primary Key:

```
PK_asset_devices
```

Unique Constraint:

```
UQ_asset_devices_device_code
```

Check Constraints:
- Device status validation
- Sensor type validation
---

## Index Strategy

| Index                        | Purpose                |
|------------------------------|------------------------|
| PK_asset_devices             | Clustered primary key  |
| UQ_asset_devices_device_code | Fast business lookups  |
| IX_asset_devices_status      | Active device searches |
| IX_asset_devices_location    | Location-based queries |

This indexing strategy supports the most common application access patterns while minimizing write overhead.

# SQL Server Physical Implementation
## Core Physical Entities
The SQL Server database stores business-critical transactional entities that require strong consistency, relational integrity, and ACID-compliant transactions.
---

## asset.devices
The `asset.devices` table is the authoritative source for all registered sensor devices.

### Physical Structure

| Column | Data Type | Constraint | Description |
|-------------------|-----------|------------|-------------|
| device_identifier | UNIQUEIDENTIFIER | Primary Key | Unique identifier for the device |
| device_code       | NVARCHAR(50) | UNIQUE | Human-readable device code |
| device_name       | NVARCHAR(150) | NOT NULL | Display name |
| sensor_type       | NVARCHAR(50) | NOT NULL | Device classification |
| device_status     | NVARCHAR(20) | NOT NULL | Operational state |
| location_name     | NVARCHAR(150) | NULL | Installation location |
| registered_at     | DATETIME2        | NOT NULL | Registration timestamp |
| created_at        | DATETIME2        | NOT NULL | Audit timestamp |
| updated_at        | DATETIME2        | NULL | Last modification timestamp |

### Constraints
Primary Key:

```
PK_asset_devices
```

Unique Constraint:

```
UQ_asset_devices_device_code
```

Check Constraints:

```
CK_asset_devices_status
```

Allowed Values
- Active
- Inactive
- Maintenance
- Retired
---

### Index Strategy

| Index                        | Purpose               |
|------------------------------|-----------------------|
| PK_asset_devices             | Clustered Primary Key |
| UQ_asset_devices_device_code | Fast device lookup    |
| IX_asset_devices_status      | Dashboard filtering   |
| IX_asset_devices_location    | Location searches     |
---

## configuration.device_configurations
Stores active and historical operating parameters for each device.

### Physical Structure

| Column                   | Data Type         | Constraint |
|--------------------------|------------------|-------------|
| configuration_identifier | UNIQUEIDENTIFIER | Primary Key |
| device_identifier        | UNIQUEIDENTIFIER | Foreign Key |
| reporting_interval       | INT              | NOT NULL    |
| threshold_value          | DECIMAL(10,2)    | NOT NULL    |
| configuration_status     | NVARCHAR(20)     | NOT NULL    |
| effective_from           | DATETIME2        | NOT NULL    |
| effective_to             | DATETIME2        | NULL        |
| created_at               | DATETIME2        | NOT NULL    |

### Foreign Key
```
FK_configuration_device
```

```
configuration.device_configurations
asset.devices
```

### Business Rules
- One Device may have multiple historical configurations.
- Only one active configuration is permitted.
- Historical configurations are retained for audit purposes.
---

### Index Strategy

| Index                    | Purpose                         |
|--------------------------|---------------------------------|
| PK_device_configurations | Clustered Primary Key           |
| IX_configuration_device  | Device lookups                  |
| IX_configuration_active  | Current configuration retrieval |
---

## alert.alerts
Stores operational alerts generated from telemetry evaluation.

### Physical Structure

| Column            | Data Type        |
|-------------------|------------------|
| alert_identifier  | UNIQUEIDENTIFIER |
| device_identifier | UNIQUEIDENTIFIER |
| alert_type        | NVARCHAR(50)     |
| alert_severity    | NVARCHAR(20)     |
| alert_status      | NVARCHAR(20)     |
| triggered_at      | DATETIME2        |
| acknowledged_at   | DATETIME2        |
| resolved_at       | DATETIME2        |

### Relationships
```
asset.devices
      │
      └───────────────┐
                      │
                      ▼
               alert.alerts
```

### Business Rules
- Every Alert references a valid Device.
- Alerts cannot exist independently.
- Alert history is retained for compliance and reporting.
---

### Index Strategy
| Index              | Purpose             |
|--------------------|---------------------|
| PK_alerts          | Primary Key         |
| IX_alert_status    | Dashboard queries   |
| IX_alert_device    | Device history      |
| IX_alert_triggered | Time-range searches |
---

# Referential Integrity
SQL Server enforces relational consistency using foreign key constraints.

```text
asset.devices
      │
      ├───────────────┐
      ▼               ▼
configuration     alert
```

Relationships

| Parent  | Child         | Cardinality |
|---------|---------------|-------------|
| Device  | Configuration | 1 : N       |
| Device  | Alert         | 1 : N       |

Referential integrity prevents orphaned records and guarantees transactional consistency.
---

# Data Validation
Validation is enforced as close to the data as possible.

| Validation              | Implementation       |
|-------------------------|----------------------|
| Required Attributes     | NOT NULL constraints |
| Device Code Uniqueness  | UNIQUE constraint    |
| Status Validation       | CHECK constraints    |
| Configuration Ownership | Foreign Key          |
| Default Values          | DEFAULT constraints  |
---

# Storage Optimization
Although SQL Server stores only transactional data, physical optimization remains important.

### Row Storage
- Narrow transactional rows
- Explicit data types
- No redundant columns
- Avoid variable-length columns where unnecessary

### Index Maintenance
Recommended maintenance includes:
- Periodic index rebuild/reorganize
- Statistics updates
- Fragmentation monitoring
- Query plan review
---

# Transaction Management
SQL Server remains the only platform responsible for transactional consistency.
Typical transactions include:
- Device Registration
- Configuration Updates
- Alert Lifecycle Management

All operations execute within ACID-compliant transactions to ensure consistency and durability.
---

# Physical Design Summary
The SQL Server implementation provides:
- Strong referential integrity
- ACID transaction support
- Optimized indexing
- Enterprise naming standards
- Efficient transactional storage
- Clear schema separation
- High maintainability

This platform remains the authoritative System of Record for the SensorApp ecosystem while delegating telemetry and operational logging to specialized databases.

# TimescaleDB Physical Implementation
## Purpose
TimescaleDB is the dedicated platform for storing and analyzing high-volume sensor telemetry. Unlike traditional relational databases, it is optimized for sequential time-series ingestion, time-window queries, compression, and continuous aggregation.
By isolating telemetry from transactional workloads, the platform eliminates contention on SQL Server while enabling independent scalability for IoT data ingestion.
---

# telemetry.sensor_readings
The `telemetry.sensor_readings` hypertable stores immutable sensor measurements generated by registered devices.

## Physical Structure

| Column             | Data Type        | Constraint  | Description                            |
|--------------------|------------------|-------------|----------------------------------------|
| reading_identifier | UUID             | Primary Key | Unique telemetry record identifier     |
| device_identifier  | UUID             | NOT NULL    | Logical reference to registered device |
| recorded_at        | TIMESTAMPTZ      | NOT NULL    | Measurement timestamp (UTC)            |
| temperature        | DOUBLE PRECISION | NULL        | Temperature measurement                |
| humidity           | DOUBLE PRECISION | NULL        | Humidity measurement                   |
| pressure           | DOUBLE PRECISION | NULL        | Pressure measurement                   |
| quality_status     | VARCHAR(20)      | NOT NULL    | Reading quality indicator              |
| created_at         | TIMESTAMPTZ      | NOT NULL    | Record creation timestamp              |
---

## Hypertable Configuration
The table is converted into a TimescaleDB hypertable using the `recorded_at` timestamp.

**Partitioning Strategy**

| Configuration    | Value       |
|------------------|-------------|
| Partition Column | recorded_at |
| Chunk Interval   | 7 Days      |
| Time Zone        | UTC         |
| Compression      | Enabled     |
| Retention        | Enabled     |

This strategy enables efficient chunk pruning during time-range queries and significantly improves ingestion performance.
---

## Index Strategy

| Index                          | Purpose                   |
|--------------------------------|---------------------------|
| PK_sensor_readings             | Primary Key               |
| IX_sensor_readings_device_time | Latest readings by device |
| IX_sensor_readings_recorded_at | Time-range analytics      |
| IX_sensor_readings_quality     | Data quality filtering    |

These indexes are designed to support the application's primary query patterns while minimizing write overhead.
---

## Compression Policy
Historical telemetry is automatically compressed after the operational window.

| Policy            | Value                                                        |
|-------------------|--------------------------------------------------------------|
| Compression Start | After 30 Days                                                |
| Compression Type  | Native TimescaleDB Compression                               |
| Compression Goal  | Reduce storage footprint while maintaining query performance |

Compression significantly reduces storage requirements for historical telemetry without affecting recent operational data.
---

## Data Retention Policy
To control long-term storage growth, telemetry data follows a retention policy.

| Policy                    | Value   |
|---------------------------|---------|
| Raw Data Retention        | 2 Years |
| Aggregated Data Retention | 5 Years |
| Automatic Cleanup         | Enabled |

Retention policies are executed automatically using TimescaleDB background jobs.
---

## Continuous Aggregates
Frequently requested analytical summaries are precomputed using Continuous Aggregates.

Examples include:
- Hourly Average Temperature
- Daily Humidity Summary
- Weekly Pressure Trends
- Device Health Statistics

This approach minimizes expensive aggregation queries on raw telemetry while improving dashboard performance.
---

## Physical Optimization
The telemetry platform is optimized for high-throughput ingestion.

### Optimizations
- Sequential writes
- Time-based partition pruning
- Native compression
- Continuous aggregates
- Lightweight indexing
- Batch ingestion support

These optimizations enable predictable performance as telemetry volumes increase.
---

# MongoDB Physical Implementation

## Purpose
MongoDB stores operational events, application diagnostics, audit records, and exception logs.
Unlike transactional data, operational logs are append-only, semi-structured, and frequently evolve over time. MongoDB's flexible document model allows new event types to be introduced without requiring schema migrations.
---

# audit.application_logs
The `application_logs` collection stores immutable operational events generated by the application.

## Document Structure

| Field                  | Type          | Description                           |
|------------------------|---------------|---------------------------------------|
| event_identifier       | UUID          | Unique event identifier               |
| correlation_identifier | UUID          | End-to-end request correlation        |
| device_identifier      | UUID          | Related device                        |
| event_type             | String        | Business event classification         |
| severity               | String        | Information, Warning, Error, Critical |
| created_at             | Date          | Event timestamp                       |
| payload                | JSON Document | Event-specific details                |
---

## Example Document
```json
{
  "event_identifier": "7d4f4b1d-6e8d-4d8d-9d52-fd7b9aaf9b20",
  "correlation_identifier": "cf53d731-85db-4c5e-b3d0-9341b49e1b84",
  "device_identifier": "1a4ef2d3-8f12-4c8d-b7f1-e0d417ffab73",
  "event_type": "TelemetryValidationFailed",
  "severity": "Warning",
  "created_at": "2026-07-24T10:30:15Z",
  "payload": {
    "receivedTemperature": 125.4,
    "configuredThreshold": 100.0,
    "validationResult": "Rejected"
  }
}
```
---

## Collection Index Strategy
| Index                          | Purpose               |
|--------------------------------|-----------------------|
| IX_logs_event_identifier       | Event lookup          |
| IX_logs_correlation_identifier | Distributed tracing   |
| IX_logs_device_created         | Device history        |
| IX_logs_created_at             | Time-range filtering  |

Compound indexes are designed around the application's operational troubleshooting queries.
---

## TTL Policy
Operational logs do not require indefinite retention.

| Policy               | Value     |
|----------------------|-----------|
| Retention Period     | 90 Days   |
| Expiration Mechanism | TTL Index |
| Cleanup              | Automatic |

TTL indexes remove expired documents without manual intervention, reducing operational overhead.
---

## Schema Validation
Although MongoDB supports flexible documents, validation rules are applied to maintain data quality.
Required fields include:
- event_identifier
- correlation_identifier
- event_type
- created_at
- severity

Optional event-specific details are stored within the `payload` document.
---

## Physical Optimization
MongoDB is optimized for append-only workloads.

### Optimizations
- Sequential inserts
- Compound indexes
- Automatic TTL cleanup
- Immutable event documents
- Efficient JSON storage

This design supports high write throughput while maintaining fast diagnostic queries.
---

# Cross-Platform Physical Integration
Although each platform stores different workloads, they remain logically connected through shared business identifiers.

```text
                  SQL Server
             asset.devices
                    │
         device_identifier
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
 TimescaleDB              MongoDB
sensor_readings       application_logs
```

The application enforces these logical relationships through the Repository Layer, ensuring that all telemetry and audit events reference valid registered devices.
---

# Physical Design Summary
The specialized implementation of TimescaleDB and MongoDB enables the SensorApp platform to scale efficiently while preserving clear workload boundaries.
Key characteristics include:
- High-throughput telemetry ingestion
- Efficient time-series analytics
- Automatic compression and retention
- Flexible document storage
- Optimized indexing strategies
- Independent scalability
- Reduced operational overhead

Together with SQL Server, these platforms provide a resilient and production-ready physical architecture that aligns with the overall modernization strategy.

# Security & Access Control
Protecting operational and business data is a fundamental requirement of the SensorApp platform. Each database platform implements security according to the principle of least privilege while maintaining a consistent enterprise security model.
---

## Authentication
Authentication is centrally managed through the enterprise identity provider.

| Platform    | Authentication Method               |
|-------------|-------------------------------------|
| SQL Server  | Active Directory / Service Accounts |
| TimescaleDB | PostgreSQL Roles                    |
| MongoDB     | SCRAM Authentication                |

Application services authenticate using dedicated service accounts with permissions limited to the operations required by each workload.
---

## Authorization
Role-Based Access Control (RBAC) is implemented across all database platforms.

| Role                   | Responsibilities                        |
|------------------------|-----------------------------------------|
| Application Service    | Read and write application data         |
| Operations             | Performance monitoring and maintenance  |
| Database Administrator | Schema management, backup, and recovery |
| Reporting              | Read-only analytical access             |
| Security Administrator | Audit and access management             |

Direct write access to production databases is restricted to approved application services and administrative personnel.
---

## Encryption
Sensitive data is protected both in transit and at rest.

| Security Control      | Implementation             |
|-----------------------|----------------------------|
| Encryption in Transit | TLS 1.2+                   |
| Encryption at Rest    | Native database encryption |
| Credential Storage    | Enterprise Secrets Manager |
| Backup Encryption     | Enabled                    |

This approach protects sensitive operational information throughout its lifecycle.
---

## Audit & Compliance
Administrative activities are audited to support operational governance and compliance requirements.
Examples include:
- User authentication
- Permission changes
- Schema modifications
- Administrative maintenance
- Backup and restore operations

Audit records are retained according to organizational retention policies.
---

# Backup & Recovery Strategy
Each database platform follows a backup strategy appropriate for its workload and recovery requirements.
---

## SQL Server

| Backup Type            | Frequency        |
|------------------------|------------------|
| Full Backup            | Daily            |
| Differential Backup    | Every 6 Hours    |
| Transaction Log Backup | Every 15 Minutes |

Recovery supports Point-in-Time Restore (PITR) to minimize data loss.
---

## TimescaleDB
Telemetry data is protected through:
- Full database backups
- WAL (Write-Ahead Log) archiving
- Streaming replication
- Periodic recovery validation

Compressed historical data is included in backup procedures.
---

## MongoDB
MongoDB backups include:
- Scheduled snapshots
- Oplog capture
- Replica Set synchronization
- Periodic restore verification

Operational logs remain recoverable throughout the configured retention period.
---

# High Availability
High availability is implemented independently for each platform, allowing failures to be isolated without affecting the entire application.

| Platform    | High Availability Strategy       |
|-------------|----------------------------------|
| SQL Server  | Always On Availability Groups    |
| TimescaleDB | PostgreSQL Streaming Replication |
| MongoDB     | Replica Set                      |

This architecture eliminates single points of failure while allowing maintenance with minimal service interruption.
---

# Disaster Recovery
Disaster recovery procedures ensure business continuity in the event of infrastructure failures.

## Recovery Objectives

| Objective                      | Target       |
|--------------------------------|--------------|
| Recovery Time Objective (RTO)  | < 60 Minutes |
| Recovery Point Objective (RPO) | < 15 Minutes |

Recovery procedures include:
- Automated infrastructure provisioning
- Database restoration
- Application configuration deployment
- Validation testing
- Controlled production cutover

Recovery procedures should be tested regularly to verify operational readiness.
---

# Monitoring & Operational Management
Operational visibility is essential for maintaining system reliability.
---

## SQL Server Monitoring
Monitor:
- CPU utilization
- Memory consumption
- Query performance
- Index fragmentation
- Blocking and deadlocks
- Transaction log growth
---

## TimescaleDB Monitoring
Monitor:
- Ingestion throughput
- Chunk creation
- Compression effectiveness
- Continuous Aggregate refresh
- Storage growth
- Query latency
---

## MongoDB Monitoring
Monitor:
- Document insertion rate
- Replica Set health
- Index utilization
- TTL cleanup activity
- Collection growth
- Query response times
---

## Platform Health Dashboard
Operational dashboards should provide visibility into:
- API response times
- Database availability
- Telemetry ingestion rate
- Alert generation rate
- Storage utilization
- Backup success
- Replication status
- Error rates

These metrics enable proactive identification of operational issues before they impact business services.
---

# Operational Maintenance
Routine maintenance activities are scheduled according to platform requirements.

| Platform    | Maintenance Activities                                            |
|-------------|-------------------------------------------------------------------|
| SQL Server  | Index maintenance, statistics updates, integrity checks           |
| TimescaleDB | Compression jobs, retention jobs, Continuous Aggregate refresh    |
| MongoDB     | Index optimization, Replica Set health checks, storage monitoring |

Maintenance windows should be coordinated to minimize operational impact.
---

# Scalability Strategy
Each database platform scales independently according to workload characteristics.

### SQL Server
- Vertical scaling for transactional workloads
- Optimized indexing
- Connection pooling
- Query optimization

### TimescaleDB
- Increased storage capacity
- Additional compute resources
- Efficient chunk management
- Compression of historical data

### MongoDB
- Replica Sets for high availability
- Sharding (if required)
- Independent storage expansion
- Horizontal scaling for operational workloads

This independent scaling strategy ensures that increasing telemetry volumes do not affect transactional performance.
---

# Future Evolution
The proposed physical architecture supports future enhancements without requiring major redesign.
Potential enhancements include:
- Change Data Capture (CDC)
- Event streaming with Apache Kafka
- Real-time analytics
- Data Lake integration
- Machine Learning pipelines
- Predictive maintenance
- IoT edge processing
- Multi-region deployment

These capabilities can be introduced incrementally while preserving the existing architecture.
---

# Physical Data Model Summary
The Physical Data Model transforms the technology-independent logical design into a production-ready implementation optimized for the SensorApp workload.
Key implementation characteristics include:
- Purpose-built database selection
- Strong transactional consistency
- Optimized time-series storage
- Flexible document persistence
- Enterprise naming standards
- Efficient indexing strategies
- Compression and retention policies
- High availability and disaster recovery
- Secure operational management
- Independent scalability

By aligning each workload with the database technology best suited to its characteristics, the proposed architecture delivers improved scalability, maintainability, operational resilience, and long-term extensibility while preserving SQL Server as the authoritative System of Record.
---

# Conclusion
The proposed Physical Data Model provides a robust foundation for modernizing the SensorApp platform. Transactional data remains protected within SQL Server, high-volume telemetry is efficiently managed by TimescaleDB, and operational events are isolated within MongoDB.
This workload-driven architecture improves performance, simplifies maintenance, supports future growth, and establishes a scalable, enterprise-ready data platform capable of evolving with future business and operational requirements.
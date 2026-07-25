# Database Selection & Decision Matrix

## Executive Summary

The legacy SensorApp platform stores transactional data, telemetry, and operational logs within a single SQL Server database.

As telemetry volume grows, this approach creates scalability, performance, and maintainability challenges.

To address these limitations, a **Polyglot Persistence Architecture** is proposed where each workload is assigned to the database platform best suited to its operational characteristics.

---

# Evaluation Criteria

Technologies were evaluated using the following criteria:

- Workload Suitability
- Scalability
- Performance
- Consistency & Integrity
- Operational Complexity
- Integration Requirements

---

# Technology Selection

| Workload | Candidates Evaluated | Selected |
|-----------|---------------------|-----------|
| Transactional Data | SQL Server, PostgreSQL | **SQL Server** |
| Telemetry | SQL Server, PostgreSQL, TimescaleDB, InfluxDB | **TimescaleDB** |
| Audit & Logging | SQL Server, MongoDB, Elasticsearch/OpenSearch | **MongoDB** |

---

# Why These Technologies?

## SQL Server

**Purpose**

- Device Management
- Configuration Management
- Alert Management

**Why?**

- ACID Transactions
- Referential Integrity
- Strong Security
- Mature Backup & Recovery
- Minimal Migration Risk

---

## TimescaleDB

**Purpose**

- Sensor Telemetry
- Historical Analytics
- Time-Series Reporting

**Why?**

- Hypertables
- Compression
- Continuous Aggregates
- Retention Policies
- High Ingestion Throughput
- PostgreSQL Compatibility

---

## MongoDB

**Purpose**

- Audit Logs
- Operational Events
- Exception Tracking

**Why?**

- Flexible Document Model
- High Write Performance
- Schema Evolution
- Compound Indexes
- TTL-Based Retention

---

# Alternatives Considered

### PostgreSQL

Strong relational platform but lacks the native time-series optimizations provided by TimescaleDB.

### InfluxDB

Excellent for telemetry workloads but introduces additional tooling and query language complexity.

### Elasticsearch/OpenSearch

Powerful for search and observability, but operationally more complex than required for SensorApp audit logging.

---

# Architecture Principles

- Right Database for the Right Workload
- Preserve SQL Server as System of Record
- Separate Telemetry from OLTP Workloads
- Separate Logging from Business Transactions
- Enable Independent Scaling
- Minimize Platform Coupling

---

# Decision Summary

| Workload | Database | Primary Benefit |
|-----------|-----------|------------------|
| Device & Configuration Management | SQL Server | Transactional Consistency |
| Alert Management | SQL Server | Referential Integrity |
| Telemetry | TimescaleDB | Time-Series Optimization |
| Audit & Logging | MongoDB | Flexible Event Storage |

---

# Conclusion

The proposed architecture aligns each workload with the database platform best suited to its requirements:

- **SQL Server** for transactional data
- **TimescaleDB** for telemetry
- **MongoDB** for audit logging

This approach improves scalability, reduces contention, and provides a solid foundation for future growth while minimizing migration risk.

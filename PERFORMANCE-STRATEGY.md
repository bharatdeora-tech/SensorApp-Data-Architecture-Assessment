# Performance Strategy
## Objective
The objective of the proposed architecture is to improve scalability and query performance by separating workloads according to their access patterns instead of storing every data type in a single relational database.
The legacy application uses SQL Server for transactional data, high-volume telemetry, and audit logging. While this design is simple, it causes resource contention as data volume increases.
The modernized architecture introduces purpose-built data stores:
Each database is optimized for its workload, allowing independent scaling, improved query performance, and lower operational overhead.

| Workload          | Database    |
|-------------------|-------------|
| Device Management | SQL Server  |
| Sensor Telemetry  | TimescaleDB |
| Audit Logs        | MongoDB     |

---

# Current Performance Challenges
The existing architecture exhibits several characteristics that limit long-term scalability.

## Mixed Workloads
The transactional database processes:
- Device registration
- Sensor configuration
- Continuous telemetry ingestion
- Audit logging
- Historical reporting
These workloads compete for CPU, memory, storage, and locking resources.
---

## Rapid Table Growth
Sensor readings continuously increase table size.
As telemetry grows into millions or billions of rows:
- Index maintenance becomes more expensive.
- Backup duration increases.
- Historical queries require scanning significantly larger datasets.
- OLTP operations experience increased contention.
---

## Logging Overhead
Audit events are append-only data but currently reside in the transactional database.
This increases:
- Write amplification
- Storage requirements
- Backup size
- Index maintenance
  while providing little transactional value.
---

## Historical Analytics
Queries such as:
- Last 24 hours
- Last 30 days
- Average temperature
- Maximum pressure
  must repeatedly scan large relational tables that were not designed for time-series analytics.
---

# Proposed Performance Strategy
## SQL Server
### Responsibilities

- Device Management
- Configuration Management
- Alert Management
- Reference Data
- Transactional Operations

### Optimization Strategy
- Clustered Primary Keys
- Foreign Key indexes
- Covering indexes for frequently executed queries
- Fully normalized schema
- Optimistic concurrency where appropriate

### Expected Characteristics
- Low latency transactions
- Strong ACID consistency
- Minimal lock contention
- Predictable response times
---

## TimescaleDB
### Responsibilities
- Sensor readings
- Historical telemetry
- Time-series analytics

### Optimization Strategy
- Hypertables
- Automatic chunking
- Time-based partitioning
- Compression policies
- Retention policies
- Continuous aggregates

### Expected Characteristics
- High ingestion throughput
- Efficient range scans
- Chunk pruning during queries
- Reduced storage consumption
- Fast analytical queries

Example analytical query:

```sql
SELECT
    device_identifier,
    AVG(measured_value)
FROM telemetry.sensor_readings
WHERE sensor_type = 'TEMPERATURE'
  AND recorded_at >= NOW() - INTERVAL '24 HOURS'
GROUP BY device_identifier;
```

The query benefits from:

- Time-based chunk pruning
- Parallel execution
- Continuous aggregates (when available)

instead of scanning the complete telemetry history.
---

## MongoDB
### Responsibilities
- Audit logs
- Operational events

### Optimization Strategy

- Append-only document storage
- Compound indexes for correlation tracing
- Device-based investigation indexes
- Event type and severity indexes
- TTL indexes for automatic retention
- Flexible schema for evolving event structures

### Expected Characteristics
- High write throughput
- Low storage overhead
- Fast event lookup
- Automatic archival of expired records
---

# Representative Performance Validation
The proposed architecture should be validated using representative workloads rather than synthetic assumptions.

## Telemetry Ingestion
Measure:
- Records/sec
- Average insert latency
- CPU utilization
Expected observation:
TimescaleDB maintains consistent ingestion throughput as telemetry volume increases because writes are distributed across time-based chunks.
---

## Transaction Response Time
Measure:
- Device registration
- Configuration updates
- Alert creation
Expected observation:
 Transactional latency remains stable because telemetry writes no longer compete with OLTP operations.
---

## Historical Analytics
Representative query:

Average measured value by sensor type for the last 30 days.

Validation:

- Execution Plan
- Execution Time
- Logical Reads
Expected observation:
  Queries access only relevant chunks instead of scanning the entire dataset.
---

## Audit Log Retrieval
Representative query:

```
Retrieve ERROR events from the last 7 days.
```

Validation:

- Query latency
- Index usage
- Documents examined
Expected observation:
  MongoDB performs indexed document retrieval without impacting transactional workloads.
---

# Execution Plan Validation
Representative execution plans should be captured before and after modernization.
Typical evidence includes:
- SQL Server Actual Execution Plan
- PostgreSQL EXPLAIN ANALYZE
- Index Scan vs Table Scan
- Logical Reads
- Execution Time

Example validation:
Before:
- Clustered Table Scan
- High logical reads
- Increasing execution time

After:
- Index Seek
- Chunk Pruning
- Reduced logical reads
- Stable execution time
---

# Scalability Considerations
The proposed architecture is designed to scale independently.
-This allows each workload to grow without affecting the others.

| Component   | Scaling Strategy                          |
|-------------|-------------------------------------------|
| SQL Server  | Vertical scaling for OLTP                 |
| TimescaleDB | Horizontal expansion and chunk management |
| MongoDB     | Replica Sets and Sharding (future)        |


---

# Expected Benefits
Compared to the legacy implementation, the proposed architecture provides:
- Reduced database contention
- Improved telemetry ingestion throughput
- Faster historical analytics
- Independent workload scaling
- Smaller transactional database
- Lower backup duration
- Better storage efficiency
- Improved long-term maintainability
- Retention policy enforcement through platform-native lifecycle management
---

# Conclusion
Separating transactional, telemetry, and logging workloads into purpose-built databases significantly improves scalability, performance, and operational efficiency.
Rather than optimizing a single database to support conflicting access patterns, the proposed architecture applies the "right database for the right workload" principle, enabling predictable performance as the system grows while preserving transactional consistency where it is most important.

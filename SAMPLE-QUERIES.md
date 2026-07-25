````markdown
# Sample Queries

## Purpose

The following sample queries demonstrate how each database platform supports its designated workload within the proposed polyglot persistence architecture.

Rather than simply retrieving data, each query is designed to align with the strengths of its underlying database engine, ensuring predictable performance, efficient resource utilization, and long-term scalability.

---

# SQL Server : Transactional Workloads

SQL Server acts as the authoritative system of record and is responsible for highly consistent transactional operations such as device master data, device configuration, location assignment, and alert lifecycle management.

---

## 1. Retrieve Active Device Information

```sql
DECLARE @device_code NVARCHAR(50) = N'TEMP-001';

SELECT
    d.device_identifier,
    d.device_external_identifier,
    d.device_code,
    d.device_name,
    st.sensor_type_code,
    st.sensor_type_name,
    ds.device_status_code,
    ds.device_status_name,
    l.location_code,
    l.building_name,
    l.floor_number,
    l.room_code,
    l.room_name,
    d.manufacturer,
    d.model_number,
    d.serial_number,
    d.registered_at
FROM asset.devices d
INNER JOIN ref.sensor_types st
    ON d.sensor_type_identifier = st.sensor_type_identifier
INNER JOIN ref.device_statuses ds
    ON d.device_status_code = ds.device_status_code
LEFT JOIN asset.locations l
    ON d.location_identifier = l.location_identifier
WHERE d.device_code = @device_code
  AND d.device_status_code = N'ACTIVE';
````

### Business Purpose

Retrieves the active device master record used during device registration, monitoring, alert processing, and API requests.

### Performance Characteristics

* Uses the unique constraint/index on `device_code`.
* Joins to reference tables using indexed primary keys.
* Uses normalized location data instead of repeated building/room text.
* Expected execution plan: `Index Seek + Key Lookup/Join`.
* Complexity: `O(log n)` for device lookup.

***

## 2. Retrieve Active Device Configuration

```sql
DECLARE @device_identifier BIGINT = 1;

SELECT
    c.configuration_identifier,
    c.configuration_external_identifier,
    c.device_identifier,
    c.reporting_interval_seconds,
    c.threshold_value,
    c.measurement_unit,
    c.configuration_status_code,
    c.is_current,
    c.effective_from,
    c.effective_to,
    c.configuration_json
FROM configuration.device_configurations c
WHERE c.device_identifier = @device_identifier
  AND c.configuration_status_code = N'ACTIVE'
  AND c.is_current = 1;
```

### Business Purpose

Retrieves the currently active device configuration used by the application to validate incoming sensor readings and processing rules.

### Performance Characteristics

* Uses the filtered unique index on current active configuration per device.
* Avoids scanning historical configuration versions.
* Supports versioned configuration design using `effective_from`, `effective_to`, and `is_current`.
* Expected execution plan: `Index Seek`.

***

## 3. Retrieve Device Configuration History

```sql
DECLARE @device_identifier BIGINT = 1;

SELECT
    c.configuration_identifier,
    c.device_identifier,
    c.reporting_interval_seconds,
    c.threshold_value,
    c.measurement_unit,
    c.configuration_status_code,
    c.is_current,
    c.effective_from,
    c.effective_to,
    c.created_at,
    c.created_by
FROM configuration.device_configurations c
WHERE c.device_identifier = @device_identifier
ORDER BY c.effective_from DESC;
```

### Business Purpose

Displays historical configuration changes for a device, supporting auditability and troubleshooting.

### Performance Characteristics

* Uses index on `(device_identifier, effective_from DESC, effective_to)`.
* Query is optimized for device-specific historical lookup.
* Expected execution plan: `Index Seek + Ordered Scan`.

***

## 4. Retrieve Critical Active Alerts

```sql
SELECT
    a.alert_identifier,
    a.alert_external_identifier,
    a.device_identifier,
    d.device_code,
    d.device_name,
    a.alert_type_code,
    at.alert_type_name,
    a.alert_severity_code,
    sev.alert_severity_name,
    sev.severity_rank,
    a.alert_status_code,
    ast.alert_status_name,
    a.alert_message,
    a.threshold_value,
    a.measured_value,
    a.measurement_unit,
    a.triggered_at
FROM alert.alerts a
INNER JOIN asset.devices d
    ON a.device_identifier = d.device_identifier
INNER JOIN ref.alert_types at
    ON a.alert_type_code = at.alert_type_code
INNER JOIN ref.alert_severities sev
    ON a.alert_severity_code = sev.alert_severity_code
INNER JOIN ref.alert_statuses ast
    ON a.alert_status_code = ast.alert_status_code
WHERE a.alert_status_code IN
(
    N'OPEN',
    N'ACKNOWLEDGED'
)
AND a.alert_severity_code = N'CRITICAL'
ORDER BY a.triggered_at DESC;
```

### Business Purpose

Supports operational dashboards by retrieving active critical incidents requiring immediate attention.

### Performance Characteristics

* Uses filtered index on active alerts.
* Uses reference tables for alert type, severity, and status instead of hardcoded text.
* Sorts by `triggered_at DESC` to show newest incidents first.
* Expected execution plan: `Index Seek + Ordered Scan`.

***

## 5. Retrieve Device Alert History

```sql
DECLARE @device_identifier BIGINT = 1;

SELECT
    a.alert_identifier,
    a.device_identifier,
    a.alert_type_code,
    a.alert_severity_code,
    a.alert_status_code,
    a.alert_message,
    a.threshold_value,
    a.measured_value,
    a.measurement_unit,
    a.triggered_at,
    a.acknowledged_at,
    a.resolved_at,
    a.closed_at
FROM alert.alerts a
WHERE a.device_identifier = @device_identifier
ORDER BY a.triggered_at DESC;
```

### Business Purpose

Provides alert lifecycle history for a device, useful for support teams and operational investigation.

### Performance Characteristics

* Uses index on `(device_identifier, triggered_at DESC)`.
* Optimized for device-based troubleshooting.
* Expected execution plan: `Index Seek`.

***

# TimescaleDB : Time-Series Analytics

TimescaleDB stores high-volume telemetry generated by connected devices. Its architecture is optimized for sequential writes, time-based partitioning, compression, retention, and analytical queries.

***

## 6. Retrieve Latest Sensor Readings

```sql
SELECT
    recorded_at,
    device_identifier,
    sensor_type,
    measured_value,
    measurement_unit,
    quality_status,
    ingestion_source
FROM telemetry.sensor_readings
WHERE device_identifier = :device_identifier
ORDER BY recorded_at DESC
LIMIT 100;
```

### Business Purpose

Displays the most recent telemetry readings for real-time monitoring dashboards.

### Performance Characteristics

* Uses composite index on `(device_identifier, recorded_at DESC)`.
* Uses TimescaleDB chunk pruning based on time partitioning.
* Reads only the latest telemetry records.
* Expected execution plan: `Index Scan with Chunk Pruning`.

***

## 7. Retrieve Sensor Readings For A Time Range

```sql
SELECT
    recorded_at,
    device_identifier,
    sensor_type,
    measured_value,
    measurement_unit,
    quality_status,
    ingestion_source
FROM telemetry.sensor_readings
WHERE device_identifier = :device_identifier
  AND sensor_type = :sensor_type
  AND recorded_at >= NOW() - INTERVAL '24 hours'
ORDER BY recorded_at DESC;
```

### Business Purpose

Retrieves device-specific telemetry for a selected sensor type and time window.

### Performance Characteristics

* Uses device and time-based access pattern.
* Benefits from hypertable partition pruning.
* Supports operational troubleshooting and near-real-time monitoring.
* Expected execution plan: `Chunk-Aware Index Scan`.

***

## 8. Hourly Telemetry Analytics

```sql
SELECT
    bucket,
    device_identifier,
    sensor_type,
    average_value,
    minimum_value,
    maximum_value,
    total_readings
FROM telemetry.hourly_sensor_statistics
WHERE device_identifier = :device_identifier
  AND bucket >= NOW() - INTERVAL '7 days'
ORDER BY bucket DESC;
```

### Business Purpose

Provides historical telemetry analytics without repeatedly scanning raw telemetry data.

### Performance Characteristics

* Uses TimescaleDB continuous aggregate view.
* Avoids expensive aggregation over raw telemetry records.
* Supports dashboard and trend analysis workloads.
* Expected execution plan: `Continuous Aggregate Scan`.

***

## 9. Daily Sensor Trend Analysis

```sql
SELECT
    time_bucket(INTERVAL '1 day', recorded_at) AS reading_day,
    device_identifier,
    sensor_type,
    AVG(measured_value) AS average_value,
    MIN(measured_value) AS minimum_value,
    MAX(measured_value) AS maximum_value,
    COUNT(*) AS total_readings
FROM telemetry.sensor_readings
WHERE device_identifier = :device_identifier
  AND sensor_type = :sensor_type
  AND recorded_at >= NOW() - INTERVAL '30 days'
GROUP BY
    reading_day,
    device_identifier,
    sensor_type
ORDER BY reading_day DESC;
```

### Business Purpose

Analyzes telemetry trends over a 30-day period for device health, threshold tuning, and operational reporting.

### Performance Characteristics

* Uses TimescaleDB `time_bucket` for time-series aggregation.
* Benefits from hypertable chunk pruning.
* Suitable for medium-range analytical workloads.
* For frequent dashboard access, this pattern can be promoted to a continuous aggregate.

***

# MongoDB : Audit & Operational Logging

MongoDB stores append-only operational events generated by the application. The document model provides flexibility for evolving event structures while maintaining high write throughput.

***

## 10. Retrieve Events By Correlation Identifier

```javascript
db.application_logs.find(
    {
        correlation_identifier: "c8f9a2b1-4e2d-4f1a-8c3b-1a2b3c4d5e6f"
    }
)
.sort(
    {
        event_timestamp: -1
    }
);
```

### Business Purpose

Supports distributed request tracing across application services.

### Performance Characteristics

* Uses compound index on `(correlation_identifier, event_timestamp)`.
* Retrieves all events related to a single request or transaction.
* Supports root cause analysis across distributed components.
* Expected execution plan: `Indexed Query`.

***

## 11. Retrieve Device Audit History

```javascript
db.application_logs.find(
    {
        device_identifier: "d1e2f3a4-5b6c-7d8e-9f0a-1b2c3d4e5f6a"
    }
)
.sort(
    {
        event_timestamp: -1
    }
)
.limit(50);
```

### Business Purpose

Displays recent operational or audit history for a specific device.

### Performance Characteristics

* Uses compound index on `(device_identifier, event_timestamp)`.
* Avoids querying nested payload fields when top-level indexed field exists.
* Limited result set improves response time.
* Expected execution plan: `Indexed Query`.

***

## 12. Retrieve Critical Security Or Exception Events

```javascript
db.application_logs.find(
    {
        event_type: {
            $in: [
                "Security",
                "Exception"
            ]
        },
        severity: {
            $in: [
                "Error",
                "Critical"
            ]
        }
    }
)
.sort(
    {
        event_timestamp: -1
    }
)
.limit(100);
```

### Business Purpose

Supports operational monitoring and incident investigation by retrieving high-severity security and exception events.

### Performance Characteristics

* Uses compound index on `(event_type, severity, event_timestamp)`.
* Optimized for operational support dashboards.
* Limits results to recent high-priority events.
* Expected execution plan: `Indexed Query`.

***

## 13. Retrieve Audit Events For A Time Window

```javascript
db.application_logs.find(
    {
        event_type: "Audit",
        event_timestamp: {
            $gte: ISODate("2026-07-01T00:00:00Z"),
            $lt: ISODate("2026-07-02T00:00:00Z")
        }
    }
)
.sort(
    {
        event_timestamp: -1
    }
);
```

### Business Purpose

Retrieves audit events for compliance review, operational investigation, and change tracking.

### Performance Characteristics

* Uses compound event type and timestamp index.
* Efficient for time-window-based audit retrieval.
* Aligns with append-only logging pattern.
* Expected execution plan: `Indexed Query`.

***

# Cross-Database Query Responsibility

The architecture intentionally avoids direct cross-database joins between SQL Server, TimescaleDB, and MongoDB.

Instead:

* SQL Server stores authoritative master and transactional data.
* TimescaleDB stores telemetry readings and time-series aggregates.
* MongoDB stores audit, exception, security, and operational logs.
* The application/service layer combines data across platforms when required.

This avoids coupling databases together and keeps each platform optimized for its assigned workload.

***

# Performance Summary

| Database    | Primary Workload              | Optimization Strategy                                          | Expected Execution      |
| ----------- | ----------------------------- | -------------------------------------------------------------- | ----------------------- |
| SQL Server  | Transactional Processing      | Identity PKs, Foreign Keys, Reference Tables, Filtered Indexes | Index Seek              |
| TimescaleDB | Time-Series Telemetry         | Hypertables, Chunk Pruning, Compression, Continuous Aggregates | Chunk-Aware Index Scan  |
| MongoDB     | Audit And Operational Logging | Compound Indexes, TTL Indexes, Document Storage                | Indexed Document Lookup |

***

# Architectural Observations

The sample queries demonstrate that each database platform is responsible for workloads aligned with its native strengths.

* SQL Server delivers strong transactional consistency through relational modeling, normalized reference data, and indexed lookup patterns.
* TimescaleDB efficiently manages high-volume telemetry using hypertables, chunk pruning, compression, retention policies, and continuous aggregates.
* MongoDB provides flexible, high-throughput storage for append-only audit and operational events.

This workload specialization minimizes resource contention, improves scalability, and enables each database platform to evolve independently while maintaining a consistent application architecture.

***

# Conclusion

The corrected query strategy reflects the architectural principle of using the right database for the right workload.

By combining SQL Server for transactional processing, TimescaleDB for time-series telemetry, and MongoDB for operational logging, the solution delivers improved performance, predictable scalability, and efficient resource utilization while preserving clear separation of concerns across the data platform.

```

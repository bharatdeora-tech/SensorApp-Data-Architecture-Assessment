/******************************************************************************
 Project      : SensorApp Modernization Assessment
 File         : 01_init_telemetry.sql
 Description  : TimescaleDB Telemetry Storage
******************************************************************************/
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE SCHEMA IF NOT EXISTS telemetry;

------------------------------------------------------------------------------
-- Create Telemetry Table
------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS telemetry.sensor_readings
(
    --------------------------------------------------------------------------
    -- Device Reference
    --------------------------------------------------------------------------

    device_identifier UUID NOT NULL,

    --------------------------------------------------------------------------
    -- Measurement Time
    --------------------------------------------------------------------------

    recorded_at TIMESTAMPTZ NOT NULL,

    --------------------------------------------------------------------------
    -- Sensor Information
    --------------------------------------------------------------------------

    sensor_type VARCHAR(30) NOT NULL,

    measured_value DOUBLE PRECISION NOT NULL,

    measurement_unit VARCHAR(10) NOT NULL,

    quality_status VARCHAR(20) NOT NULL DEFAULT 'Valid',

    ingestion_source VARCHAR(20) NOT NULL DEFAULT 'API',

    --------------------------------------------------------------------------
    -- Constraints
    --------------------------------------------------------------------------

    CONSTRAINT PK_sensor_readings
        PRIMARY KEY
        (
            recorded_at,
            device_identifier,
            sensor_type
        ),

    CONSTRAINT CK_measured_value
        CHECK (measured_value >= 0),

    CONSTRAINT CK_quality_status
        CHECK
        (
            quality_status IN
            (
                'Valid',
                'Invalid',
                'Estimated'
            )
        ),

    CONSTRAINT CK_ingestion_source
        CHECK
        (
            ingestion_source IN
            (
                'API',
                'Gateway',
                'Migration'
            )
        )
);

------------------------------------------------------------------------------
-- Convert to Hypertable
------------------------------------------------------------------------------

SELECT create_hypertable
(
    'telemetry.sensor_readings',
    'recorded_at',
    if_not_exists => TRUE,
    chunk_time_interval => INTERVAL '7 days'
);

------------------------------------------------------------------------------
-- Compression
------------------------------------------------------------------------------

ALTER TABLE telemetry.sensor_readings
SET
(
    timescaledb.compress,
    timescaledb.compress_segmentby='device_identifier',
    timescaledb.compress_orderby='recorded_at DESC'
);

SELECT add_compression_policy
(
    'telemetry.sensor_readings',
    INTERVAL '30 days',
    if_not_exists => TRUE
);

------------------------------------------------------------------------------
-- Retention Policy
------------------------------------------------------------------------------

SELECT add_retention_policy
(
    'telemetry.sensor_readings',
    INTERVAL '365 days',
    if_not_exists => TRUE
);

------------------------------------------------------------------------------
-- Indexes
------------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS IX_sensor_readings_device_time
ON telemetry.sensor_readings
(
    device_identifier,
    recorded_at DESC
);

CREATE INDEX IF NOT EXISTS IX_sensor_readings_sensor
ON telemetry.sensor_readings
(
    sensor_type,
    recorded_at DESC
);

------------------------------------------------------------------------------
-- Continuous Aggregate
------------------------------------------------------------------------------

CREATE MATERIALIZED VIEW IF NOT EXISTS telemetry.hourly_sensor_statistics
WITH
(
    timescaledb.continuous
)
AS

SELECT

    time_bucket
    (
        INTERVAL '1 hour',
        recorded_at
    ) AS bucket,

    device_identifier,

    sensor_type,

    AVG(measured_value) AS average_value,

    MIN(measured_value) AS minimum_value,

    MAX(measured_value) AS maximum_value,

    COUNT(*) AS total_readings

FROM telemetry.sensor_readings

GROUP BY

    bucket,

    device_identifier,

    sensor_type

WITH NO DATA;

------------------------------------------------------------------------------
-- Refresh Policy
------------------------------------------------------------------------------

SELECT add_continuous_aggregate_policy
(
    'telemetry.hourly_sensor_statistics',

    start_offset => INTERVAL '7 days',

    end_offset => INTERVAL '1 hour',

    schedule_interval => INTERVAL '1 hour',

    if_not_exists => TRUE
);
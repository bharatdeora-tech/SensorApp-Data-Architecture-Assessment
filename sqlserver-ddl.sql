/******************************************************************************
 Project      : SensorApp Modernization Assessment
 File         : 01_create_schemas.sql
 Description  : Creates logical database schemas for the SensorApp platform.
******************************************************************************/

USE SensorApp;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY

    BEGIN TRANSACTION;

    ----------------------------------------------------------------------------
    -- Create asset schema
    ----------------------------------------------------------------------------
    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.schemas
        WHERE name = N'asset'
    )
    BEGIN
        EXEC ('CREATE SCHEMA asset AUTHORIZATION dbo;');
    END;

    ----------------------------------------------------------------------------
    -- Create configuration schema
    ----------------------------------------------------------------------------
    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.schemas
        WHERE name = N'configuration'
    )
    BEGIN
        EXEC ('CREATE SCHEMA configuration AUTHORIZATION dbo;');
    END;

    ----------------------------------------------------------------------------
    -- Create alert schema
    ----------------------------------------------------------------------------
    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.schemas
        WHERE name = N'alert'
    )
    BEGIN
        EXEC ('CREATE SCHEMA alert AUTHORIZATION dbo;');
    END;

    COMMIT TRANSACTION;

    PRINT 'Schemas created successfully.';

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO

/******************************************************************************
 Project      : SensorApp Modernization Assessment
 File         : 03_asset_tables.sql
 Description  : Asset Domain - Device Master
 Author       : Bharat Singh Deora
******************************************************************************/

USE SensorApp;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY

BEGIN TRANSACTION;

------------------------------------------------------------------------------
-- Create asset.devices
------------------------------------------------------------------------------

IF OBJECT_ID(N'asset.devices', N'U') IS NULL
BEGIN

    CREATE TABLE asset.devices
    (
        ----------------------------------------------------------------------
        -- Primary Identifier
        ----------------------------------------------------------------------

        device_identifier UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_asset_devices
            PRIMARY KEY CLUSTERED
            DEFAULT NEWSEQUENTIALID(),

        ----------------------------------------------------------------------
        -- Business Identifier
        ----------------------------------------------------------------------

        device_code NVARCHAR(50) NOT NULL,

        ----------------------------------------------------------------------
        -- Device Information
        ----------------------------------------------------------------------

        device_name NVARCHAR(200) NOT NULL,

        sensor_type NVARCHAR(50) NOT NULL,

        manufacturer NVARCHAR(100) NULL,

        model_number NVARCHAR(100) NULL,

        serial_number NVARCHAR(100) NULL,

        ----------------------------------------------------------------------
        -- Physical Location
        ----------------------------------------------------------------------

        building NVARCHAR(100) NOT NULL,

        room NVARCHAR(100) NULL,

        ----------------------------------------------------------------------
        -- Device Status
        ----------------------------------------------------------------------

        device_status NVARCHAR(20) NOT NULL
            CONSTRAINT DF_asset_devices_status
            DEFAULT ('Active'),

        ----------------------------------------------------------------------
        -- Registration
        ----------------------------------------------------------------------

        registered_at DATETIME2(3) NOT NULL
            CONSTRAINT DF_asset_devices_registered_at
            DEFAULT SYSUTCDATETIME(),

        ----------------------------------------------------------------------
        -- Audit
        ----------------------------------------------------------------------

        created_at DATETIME2(3) NOT NULL
            CONSTRAINT DF_asset_devices_created_at
            DEFAULT SYSUTCDATETIME(),

        updated_at DATETIME2(3) NOT NULL
            CONSTRAINT DF_asset_devices_updated_at
            DEFAULT SYSUTCDATETIME(),

        created_by NVARCHAR(100) NOT NULL
            CONSTRAINT DF_asset_devices_created_by
            DEFAULT SUSER_SNAME(),

        updated_by NVARCHAR(100) NOT NULL
            CONSTRAINT DF_asset_devices_updated_by
            DEFAULT SUSER_SNAME(),

        ----------------------------------------------------------------------
        -- Optimistic Concurrency
        ----------------------------------------------------------------------

        row_version ROWVERSION NOT NULL,

        ----------------------------------------------------------------------
        -- Constraints
        ----------------------------------------------------------------------

        CONSTRAINT UQ_asset_devices_device_code
            UNIQUE (device_code),

        CONSTRAINT UQ_asset_devices_serial_number
            UNIQUE (serial_number),

        CONSTRAINT CK_asset_devices_status
            CHECK
            (
                device_status IN
                (
                    'Active',
                    'Inactive',
                    'Maintenance',
                    'Retired'
                )
            )
    );

END;
GO

------------------------------------------------------------------------------
-- Index : Device Status
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_asset_devices_status'
      AND object_id = OBJECT_ID(N'asset.devices')
)
BEGIN

    CREATE INDEX IX_asset_devices_status
    ON asset.devices(device_status);

END;
GO

------------------------------------------------------------------------------
-- Index : Building
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_asset_devices_building'
      AND object_id = OBJECT_ID(N'asset.devices')
)
BEGIN

    CREATE INDEX IX_asset_devices_building
    ON asset.devices(building);

END;
GO

------------------------------------------------------------------------------
-- Index : Device Name
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_asset_devices_name'
      AND object_id = OBJECT_ID(N'asset.devices')
)
BEGIN

    CREATE INDEX IX_asset_devices_name
    ON asset.devices(device_name);

END;
GO

------------------------------------------------------------------------------
-- Index : Sensor Type
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_asset_devices_sensor_type'
      AND object_id = OBJECT_ID(N'asset.devices')
)
BEGIN

    CREATE INDEX IX_asset_devices_sensor_type
    ON asset.devices(sensor_type);

END;
GO

PRINT 'asset.devices created successfully.';

COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO

/******************************************************************************
 Project      : SensorApp Modernization Assessment
 File         : 04_configuration_tables.sql
 Description  : Device Configuration Tables
 Author       : Bharat Singh Deora
******************************************************************************/

USE SensorApp;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY

BEGIN TRANSACTION;

------------------------------------------------------------------------------
-- Create configuration.device_configurations
------------------------------------------------------------------------------

IF OBJECT_ID(N'configuration.device_configurations', N'U') IS NULL
BEGIN

    CREATE TABLE configuration.device_configurations
    (
        ----------------------------------------------------------------------
        -- Primary Identifier
        ----------------------------------------------------------------------

        configuration_identifier UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_device_configurations
            PRIMARY KEY CLUSTERED
            DEFAULT NEWSEQUENTIALID(),

        ----------------------------------------------------------------------
        -- Device Reference
        ----------------------------------------------------------------------

        device_identifier UNIQUEIDENTIFIER NOT NULL,

        ----------------------------------------------------------------------
        -- Configuration
        ----------------------------------------------------------------------

        configuration_json NVARCHAR(MAX) NOT NULL,

        reporting_interval_seconds INT NOT NULL,

        threshold_value DECIMAL(10,2) NOT NULL,

        measurement_unit NVARCHAR(20) NOT NULL,

        configuration_status NVARCHAR(20) NOT NULL
            CONSTRAINT DF_configuration_status
            DEFAULT ('Active'),

        ----------------------------------------------------------------------
        -- Configuration Validity
        ----------------------------------------------------------------------

        effective_from DATETIME2(3) NOT NULL
            CONSTRAINT DF_effective_from
            DEFAULT SYSUTCDATETIME(),

        effective_to DATETIME2(3) NULL,

        ----------------------------------------------------------------------
        -- Audit
        ----------------------------------------------------------------------

        created_at DATETIME2(3) NOT NULL
            CONSTRAINT DF_configuration_created_at
            DEFAULT SYSUTCDATETIME(),

        updated_at DATETIME2(3) NOT NULL
            CONSTRAINT DF_configuration_updated_at
            DEFAULT SYSUTCDATETIME(),

        created_by NVARCHAR(100) NOT NULL
            CONSTRAINT DF_configuration_created_by
            DEFAULT SUSER_SNAME(),

        updated_by NVARCHAR(100) NOT NULL
            CONSTRAINT DF_configuration_updated_by
            DEFAULT SUSER_SNAME(),

        ----------------------------------------------------------------------
        -- Optimistic Concurrency
        ----------------------------------------------------------------------

        row_version ROWVERSION NOT NULL,

        ----------------------------------------------------------------------
        -- Foreign Key
        ----------------------------------------------------------------------

        CONSTRAINT FK_configuration_device
            FOREIGN KEY (device_identifier)
            REFERENCES asset.devices(device_identifier)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        ----------------------------------------------------------------------
        -- JSON Validation
        ----------------------------------------------------------------------

        CONSTRAINT CK_configuration_json
            CHECK
            (
                ISJSON(configuration_json)=1
            ),

        ----------------------------------------------------------------------
        -- Status Validation
        ----------------------------------------------------------------------

        CONSTRAINT CK_configuration_status
            CHECK
            (
                configuration_status IN
                (
                    'Active',
                    'Inactive',
                    'Draft'
                )
            ),

        ----------------------------------------------------------------------
        -- Reporting Interval
        ----------------------------------------------------------------------

        CONSTRAINT CK_reporting_interval
            CHECK
            (
                reporting_interval_seconds > 0
            ),

        ----------------------------------------------------------------------
        -- Threshold Validation
        ----------------------------------------------------------------------

        CONSTRAINT CK_threshold
            CHECK
            (
                threshold_value >= 0
            ),

        ----------------------------------------------------------------------
        -- Effective Dates
        ----------------------------------------------------------------------

        CONSTRAINT CK_effective_dates
            CHECK
            (
                effective_to IS NULL
                OR effective_to > effective_from
            )
    );

END;
GO

------------------------------------------------------------------------------
-- Active Configuration Index
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name='IX_configuration_active'
)
BEGIN

CREATE INDEX IX_configuration_active
ON configuration.device_configurations
(
    device_identifier,
    configuration_status
);

END;
GO

------------------------------------------------------------------------------
-- Effective Date Index
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name='IX_configuration_effective'
)
BEGIN

CREATE INDEX IX_configuration_effective
ON configuration.device_configurations
(
    effective_from DESC
);

END;
GO

------------------------------------------------------------------------------
-- Reporting Interval Index
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name='IX_configuration_reporting_interval'
)
BEGIN

CREATE INDEX IX_configuration_reporting_interval
ON configuration.device_configurations
(
    reporting_interval_seconds
);

END;
GO

PRINT 'configuration.device_configurations created successfully.';

COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO

/******************************************************************************
 Project      : SensorApp Modernization Assessment
 File         : 05_alert_tables.sql
 Description  : Alert Management Tables
 Author       : Bharat Singh Deora
******************************************************************************/

USE SensorApp;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY

BEGIN TRANSACTION;

------------------------------------------------------------------------------
-- Create alert.alerts
------------------------------------------------------------------------------

IF OBJECT_ID(N'alert.alerts', N'U') IS NULL
BEGIN

    CREATE TABLE alert.alerts
    (
        ----------------------------------------------------------------------
        -- Primary Identifier
        ----------------------------------------------------------------------

        alert_identifier UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_alerts
            PRIMARY KEY CLUSTERED
            DEFAULT NEWSEQUENTIALID(),

        ----------------------------------------------------------------------
        -- Device Reference
        ----------------------------------------------------------------------

        device_identifier UNIQUEIDENTIFIER NOT NULL,

        ----------------------------------------------------------------------
        -- Alert Information
        ----------------------------------------------------------------------

        alert_type NVARCHAR(30) NOT NULL,

        alert_severity NVARCHAR(20) NOT NULL,

        alert_status NVARCHAR(20) NOT NULL
            CONSTRAINT DF_alert_status
            DEFAULT ('Open'),

        alert_message NVARCHAR(500) NULL,

        threshold_value DECIMAL(10,2) NULL,

        measured_value DECIMAL(10,2) NULL,

        ----------------------------------------------------------------------
        -- Alert Timeline
        ----------------------------------------------------------------------

        triggered_at DATETIME2(3) NOT NULL
            CONSTRAINT DF_alert_triggered_at
            DEFAULT SYSUTCDATETIME(),

        acknowledged_at DATETIME2(3) NULL,

        resolved_at DATETIME2(3) NULL,

        ----------------------------------------------------------------------
        -- Audit
        ----------------------------------------------------------------------

        created_at DATETIME2(3) NOT NULL
            CONSTRAINT DF_alert_created_at
            DEFAULT SYSUTCDATETIME(),

        updated_at DATETIME2(3) NOT NULL
            CONSTRAINT DF_alert_updated_at
            DEFAULT SYSUTCDATETIME(),

        created_by NVARCHAR(100) NOT NULL
            CONSTRAINT DF_alert_created_by
            DEFAULT SUSER_SNAME(),

        updated_by NVARCHAR(100) NOT NULL
            CONSTRAINT DF_alert_updated_by
            DEFAULT SUSER_SNAME(),

        ----------------------------------------------------------------------
        -- Optimistic Concurrency
        ----------------------------------------------------------------------

        row_version ROWVERSION NOT NULL,

        ----------------------------------------------------------------------
        -- Foreign Key
        ----------------------------------------------------------------------

        CONSTRAINT FK_alert_device
            FOREIGN KEY (device_identifier)
            REFERENCES asset.devices(device_identifier)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        ----------------------------------------------------------------------
        -- Alert Type Validation
        ----------------------------------------------------------------------

        CONSTRAINT CK_alert_type
            CHECK
            (
                alert_type IN
                (
                    'Temperature',
                    'Humidity',
                    'Pressure',
                    'Connectivity',
                    'Battery'
                )
            ),

        ----------------------------------------------------------------------
        -- Alert Severity
        ----------------------------------------------------------------------

        CONSTRAINT CK_alert_severity
            CHECK
            (
                alert_severity IN
                (
                    'Low',
                    'Medium',
                    'High',
                    'Critical'
                )
            ),

        ----------------------------------------------------------------------
        -- Alert Status
        ----------------------------------------------------------------------

        CONSTRAINT CK_alert_status
            CHECK
            (
                alert_status IN
                (
                    'Open',
                    'Acknowledged',
                    'Resolved',
                    'Closed'
                )
            ),

        ----------------------------------------------------------------------
        -- Measurement Validation
        ----------------------------------------------------------------------

        CONSTRAINT CK_alert_measured_value
            CHECK
            (
                measured_value IS NULL
                OR measured_value >= 0
            ),

        ----------------------------------------------------------------------
        -- Alert Timeline Validation
        ----------------------------------------------------------------------

        CONSTRAINT CK_alert_acknowledged
            CHECK
            (
                acknowledged_at IS NULL
                OR acknowledged_at >= triggered_at
            ),

        CONSTRAINT CK_alert_resolved
            CHECK
            (
                resolved_at IS NULL
                OR resolved_at >= triggered_at
            )
    );

END;
GO

------------------------------------------------------------------------------
-- Index : Device Alerts
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_alert_device'
      AND object_id = OBJECT_ID(N'alert.alerts')
)
BEGIN

    CREATE INDEX IX_alert_device
        ON alert.alerts(device_identifier);

END;
GO

------------------------------------------------------------------------------
-- Index : Status & Severity
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_alert_status'
      AND object_id = OBJECT_ID(N'alert.alerts')
)
BEGIN

    CREATE INDEX IX_alert_status
        ON alert.alerts
        (
            alert_status,
            alert_severity
        );

END;
GO

------------------------------------------------------------------------------
-- Index : Triggered Time
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_alert_triggered_at'
      AND object_id = OBJECT_ID(N'alert.alerts')
)
BEGIN

    CREATE INDEX IX_alert_triggered_at
        ON alert.alerts(triggered_at DESC);

END;
GO

------------------------------------------------------------------------------
-- Filtered Index : Active Alerts
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_alert_active'
      AND object_id = OBJECT_ID(N'alert.alerts')
)
BEGIN

    CREATE INDEX IX_alert_active
        ON alert.alerts
        (
            device_identifier,
            triggered_at DESC
        )
        WHERE alert_status IN ('Open','Acknowledged');

END;
GO

PRINT 'alert.alerts created successfully.';

COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO

/******************************************************************************
 Project      : SensorApp Modernization Assessment
 File         : 07_seed_reference_data.sql
 Description  : Sample Reference Data
 Author       : Bharat Singh Deora
******************************************************************************/

USE SensorApp;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY

BEGIN TRANSACTION;

------------------------------------------------------------------------------
-- Sample Device
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM asset.devices
    WHERE device_code = 'TEMP-001'
)
BEGIN

    INSERT INTO asset.devices
    (
        device_code,
        device_name,
        sensor_type,
        manufacturer,
        model_number,
        serial_number,
        building,
        room,
        device_status
    )
    VALUES
    (
        'TEMP-001',
        'Temperature Sensor - Lab 1',
        'Temperature',
        'Acme Sensors',
        'TS-1000',
        'SN-000001',
        'Building A',
        'Laboratory 101',
        'Active'
    );

END;

------------------------------------------------------------------------------
-- Sample Configuration
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM configuration.device_configurations
)
BEGIN

    DECLARE @device_identifier UNIQUEIDENTIFIER;

    SELECT
        @device_identifier = device_identifier
    FROM asset.devices
    WHERE device_code = 'TEMP-001';

    INSERT INTO configuration.device_configurations
    (
        device_identifier,
        configuration_json,
        reporting_interval_seconds,
        threshold_value,
        measurement_unit,
        configuration_status,
        effective_from
    )
    VALUES
    (
        @device_identifier,
        N'{
            "samplingInterval":30,
            "threshold":75,
            "unit":"C"
        }',
        30,
        75,
        'C',
        'Active',
        SYSUTCDATETIME()
    );

END;

------------------------------------------------------------------------------
-- Sample Alert
------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM alert.alerts
)
BEGIN

    DECLARE @device_identifier_alert UNIQUEIDENTIFIER;

    SELECT
        @device_identifier_alert = device_identifier
    FROM asset.devices
    WHERE device_code = 'TEMP-001';

    INSERT INTO alert.alerts
    (
        device_identifier,
        alert_type,
        alert_severity,
        alert_status,
        alert_message,
        threshold_value,
        measured_value
    )
    VALUES
    (
        @device_identifier_alert,
        'Temperature',
        'High',
        'Open',
        'Temperature exceeded configured threshold.',
        75,
        82
    );

END;

COMMIT TRANSACTION;

PRINT 'Sample reference data inserted successfully.';

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO

/******************************************************************************
 Project      : SensorApp Modernization Assessment
 File         : 08_security.sql
 Description  : Database Security & Permissions
 Author       : Bharat Singh Deora
******************************************************************************/

USE SensorApp;
GO

SET NOCOUNT ON;
GO

/******************************************************************************
 Create Database Roles
******************************************************************************/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'SensorApp_ReadOnly'
)
BEGIN
    CREATE ROLE SensorApp_ReadOnly;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'SensorApp_Application'
)
BEGIN
    CREATE ROLE SensorApp_Application;
END;
GO

/******************************************************************************
 Read-Only Reporting Access
******************************************************************************/

GRANT SELECT
ON SCHEMA::asset
TO SensorApp_ReadOnly;

GRANT SELECT
ON SCHEMA::configuration
TO SensorApp_ReadOnly;

GRANT SELECT
ON SCHEMA::alert
TO SensorApp_ReadOnly;
GO

/******************************************************************************
 Application Permissions
******************************************************************************/

GRANT SELECT,
      INSERT,
      UPDATE
ON SCHEMA::asset
TO SensorApp_Application;

GRANT SELECT,
      INSERT,
      UPDATE
ON SCHEMA::configuration
TO SensorApp_Application;

GRANT SELECT,
      INSERT,
      UPDATE
ON SCHEMA::alert
TO SensorApp_Application;
GO

/******************************************************************************
 Explicit Restrictions
******************************************************************************/

DENY DELETE
ON SCHEMA::asset
TO SensorApp_Application;

DENY DELETE
ON SCHEMA::configuration
TO SensorApp_Application;

DENY DELETE
ON SCHEMA::alert
TO SensorApp_Application;
GO

/******************************************************************************
 Notes

• Database administrators retain full control.
• Application access should be provided through
  SensorApp_Application.
• Reporting and BI users should use
  SensorApp_ReadOnly.
• Authentication (Azure AD / Windows Authentication)
  is managed outside this script.
******************************************************************************/

PRINT 'Database security configuration completed successfully.';
GO


/******************************************************************************
 Project      : SensorApp Modernization Assessment
 File         : 01_init_logs.js
 Description  : MongoDB Audit & Operational Logging
******************************************************************************/

const databaseName = "sensor_app";
const collectionName = "application_logs";

db = db.getSiblingDB(databaseName);

/******************************************************************************
 Create Collection (Idempotent)
******************************************************************************/

if (!db.getCollectionNames().includes(collectionName)) {

    db.createCollection(collectionName, {

        validator: {

            $jsonSchema: {

                bsonType: "object",

                required: [
                    "event_identifier",
                    "event_timestamp",
                    "event_type",
                    "severity",
                    "message"
                ],

                properties: {

                    event_identifier: {
                        bsonType: "string",
                        description: "Unique event identifier"
                    },

                    correlation_identifier: {
                        bsonType: "string",
                        description: "Correlation identifier used for distributed tracing"
                    },

                    device_identifier: {
                        bsonType: "string",
                        description: "Logical device identifier"
                    },

                    event_timestamp: {
                        bsonType: "date"
                    },

                    event_type: {
                        enum: [
                            "Application",
                            "Audit",
                            "Telemetry",
                            "Security",
                            "Exception"
                        ]
                    },

                    severity: {
                        enum: [
                            "Information",
                            "Warning",
                            "Error",
                            "Critical"
                        ]
                    },

                    message: {
                        bsonType: "string"
                    },

                    source: {
                        bsonType: "string"
                    },

                    payload: {
                        bsonType: "object"
                    },

                    exception: {
                        bsonType: "object"
                    }
                }

            }

        },

        validationLevel: "strict",
        validationAction: "error"

    });

}

/******************************************************************************
 Compound Index : Correlation Tracing
******************************************************************************/

db.application_logs.createIndex(
{
    correlation_identifier: 1,
    event_timestamp: -1
},
{
    name: "IX_logs_correlation_timestamp"
});

/******************************************************************************
 Device Investigation Index
******************************************************************************/

db.application_logs.createIndex(
{
    device_identifier: 1,
    event_timestamp: -1
},
{
    name: "IX_logs_device_timestamp"
});

/******************************************************************************
 Event Type Index
******************************************************************************/

db.application_logs.createIndex(
{
    event_type: 1,
    severity: 1,
    event_timestamp: -1
},
{
    name: "IX_logs_event_type"
});

/******************************************************************************
 TTL Index (90 Days)
******************************************************************************/

db.application_logs.createIndex(
{
    event_timestamp: 1
},
{
    expireAfterSeconds: 7776000,
    name: "IX_logs_retention"
});

print("MongoDB logging collection initialized successfully.");
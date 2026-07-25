# Conceptual Data Model

## Purpose

This document defines the core business concepts and relationships for the SensorApp modernization initiative.

The model is intentionally technology-independent and establishes a common business vocabulary that serves as the foundation for the Logical and Physical Data Models.

---

## Modeling Principles

- Business capability driven
- Technology independent
- Single source of truth
- Clear ownership boundaries
- Consistent business terminology
- Separation of operational workloads

---

## Business Capability Overview

```text
                IoT Sensor Platform
                        |
                        v
                 Device Management
                        |
          +-------------+-------------+
          |                           |
          v                           v
   Location Management     Configuration Management
                                        |
                                        v
                               Telemetry Management
                                        |
                                        v
                                Alert Management
                                        |
                                        v
                                Audit Management

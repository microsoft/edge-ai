---
title: Vision-on-Edge and Hybrid Industrial IoT Pilot Scenarios
description: Customer-facing pilot scenarios combining vision (ONVIF cameras, AI inference, video capture) with industrial IoT (OPC-UA, Modbus, BACnet, bidirectional messaging, Fabric RTI) for manufacturing quality control, retail analytics, predictive maintenance, smart buildings, process optimization, connected products, multi-site energy management, and legacy equipment integration
author: Edge AI Team
ms.date: 2025-11-24
ms.topic: customer-scenario
estimated_reading_time: 25
keywords:
  - vision-on-edge
  - hybrid-scenarios
  - industrial-iot
  - customer pilots
  - ONVIF cameras
  - AI inference
  - OPC-UA
  - Modbus
  - BACnet
  - quality control
  - manufacturing
  - retail analytics
  - predictive maintenance
  - smart buildings
  - process optimization
  - connected products
  - energy monitoring
  - fabric-rti
  - computer vision
  - edge ai
  - multi-modal analytics
---

## Executive Summary

Organizations across manufacturing, retail, healthcare, and facilities management are looking to **deploy AI-powered vision systems at the edge** to enable real-time quality control, operational intelligence, and safety monitoring.

This document outlines **eight production-ready pilot scenarios** that combine ONVIF camera discovery, intelligent video capture, GPU-accelerated AI inference, industrial IoT protocols, and real-time analytics to deliver immediate business value with minimal infrastructure investment.

### Platform Capabilities

The edge AI platform provides integrated capabilities across vision, industrial IoT, and real-time analytics:

**Vision Components**:

1. **ONVIF Connector** - Automated camera discovery and control
2. **Media Connector** - Multi-source media ingestion with MQTT/filesystem output
3. **Media Capture Service** - Event-driven video segment extraction
4. **AI Inference Service** - Real-time edge ML with <200ms latency

**Industrial IoT Components**:

- **OPC-UA/Modbus/BACnet Connectors** - Industrial protocol integration (1000+ tags/sec)
- **REST/HTTP Connector** - Legacy HTTP API integration to MQTT
- **Bidirectional MQTT Messaging** - Cloud-to-edge command and control
- **Azure IoT Operations** - Unified edge runtime and orchestration

**Real-Time Analytics**:

- **Microsoft Fabric RTI** - EventStream ingestion and Eventhouse analytics
- **Multi-Modal Data Fusion** - Correlate sensor data, video, and telemetry

### Scenario Categories

**Pure Vision Scenarios** (1-4):

- Manufacturing Quality Control
- Retail Customer Analytics
- Predictive Maintenance with Vision
- Smart Building Security and Occupancy

**Hybrid Vision + Industrial IoT Scenarios** (5-8):

- Industrial Process Optimization with Vision-Based Quality Control
- Connected Product Telemetry with Remote Visual Diagnostics
- Multi-Site Energy Monitoring with Occupancy-Aware HVAC Control
- Legacy Equipment Integration with REST API and Vision Modernization

### Architecture Diagrams

Visual architecture diagrams for all scenarios are available in the `diagrams/` directory:

- [Scenario 1: Manufacturing Quality Control](./diagrams/scenario-1-manufacturing-quality-control.drawio)
- [Scenario 2: Retail Customer Analytics](./diagrams/scenario-2-retail-customer-analytics.drawio)
- [Scenario 3: Predictive Maintenance with Vision](./diagrams/scenario-3-predictive-maintenance.drawio)
- [Scenario 4: Smart Building Security and Occupancy](./diagrams/scenario-4-smart-building.drawio)
- [Scenario 5: Industrial Process Optimization](./diagrams/scenario-5-industrial-process.drawio)
- [Scenario 6: Connected Product Telemetry](./diagrams/scenario-6-connected-product.drawio)
- [Scenario 7: Multi-Site Energy Monitoring](./diagrams/scenario-7-multi-site-energy.drawio)
- [Scenario 8: Legacy Equipment Integration](./diagrams/scenario-8-legacy-equipment-integration.drawio)

These diagrams can be opened and edited using [draw.io](https://app.diagrams.net/) or the Draw.io integration extension in VS Code.

### Customer Value

- **Immediate ROI**: 4-hour → 5-minute camera onboarding, 60-80% reduction in manual inspection time
- **Multi-Modal Intelligence**: 15-20% accuracy improvement via sensor + vision fusion
- **Proven Performance**: 99.9% uptime, 155-220ms inference latency, 85% bandwidth savings
- **Scalable Architecture**: From single-line pilots to enterprise-wide deployments
- **Production Ready**: Azure IoT Operations (production-ready release), 8 Fortune 500 customers deployed

## Scenario 1: Manufacturing Quality Control

**Architecture Diagram**: [Manufacturing Quality Control Architecture](./diagrams/scenario-1-manufacturing-quality-control.drawio)

### Business Problem

**Challenge**: Manual visual inspection creates bottlenecks on high-speed production lines, resulting in:

- 2-4% defect escape rate costing $250K+ annually
- 45-60 seconds per inspection creating throughput constraints
- Inconsistent quality assessment across shifts (15% variability)
- Limited traceability for regulatory compliance

**Customer Profile**: Mid-size manufacturers producing 10K-100K units/day with critical quality requirements (automotive, electronics, medical devices, consumer goods).

### Technical Solution

**Architecture**:

```text
ONVIF IP Cameras (2-4 per line)
    ↓ [Automated discovery via ONVIF Connector]
Production Line Event Triggers (PLC/SCADA)
    ↓ [MQTT event to Media Capture Service]
Video Segment Capture (5-10 second clips)
    ↓ [Stored in Azure Container Storage Accelerator]
AI Inference Service (edge GPU)
    ↓ [Defect detection model <200ms latency]
Real-time Quality Decision
    ↓ [Pass/Fail/Retest via MQTT]
Production Line Control + Cloud Quality Dashboard
```

**Component Integration**:

**Azure IoT Operations (Baseline Platform)**:

- **ONVIF Connector** (built-in): Discovers 2-4 GigE Vision cameras per line, subscribes to motion/tampering events
- **Media Connector** (built-in): Snapshot-to-MQTT for real-time AI, clip-to-filesystem for evidence storage
- **MQTT Broker**: Routes events between cameras, AI services, and PLCs
- **Device Registry**: Camera and PLC asset management
- **Azure Container Storage Accelerator**: Video buffering and cloud sync

**Custom Components**:

- **AI Inference Service** (custom deployment): Defect detection with model options:
  - **Primary**: EfficientDet-D0 (15 MB, 30-50ms, 34.6% mAP) - Superior small defect detection
  - **Alternative**: Mask R-CNN (178 MB, 200-400ms, 37.1% mAP) - Pixel-perfect defect boundaries for offline audit
  - **Text Verification**: CRAFT + TrOCR for part ID/serial number validation
  - **Legacy**: TinyYOLOv2 (63 MB, 155-220ms) - Proven baseline
- **Quality Dashboard** (custom app): Real-time quality metrics and pass/fail visualization
- **Cloud Analytics** (Azure Blob Storage): Quality data for historical analysis

**Model Selection Rationale**:

- EfficientDet-D0 offers 5% better mAP than YOLOv3-Tiny with similar latency
- Mask R-CNN provides instance segmentation for precise defect area measurement
- CRAFT+TrOCR combo enables automated part verification without manual barcode scanning

> **Note on PLC Integration**: The architecture diagram assumes PLCs communicate via MQTT for simplicity. In production deployments, PLCs typically use industrial protocols (OPC-UA, Modbus, Ethernet/IP) and require protocol translation via built-in OPC-UA Connector, Modbus Connector in Azure IoT Operations. These connectors bridge industrial protocols to MQTT for unified edge messaging. For pilot simplicity, diagrams show direct MQTT communication.

### Deployment Configuration

**Edge Infrastructure** (per production line):

- 1x Edge compute node (16 cores, 32GB RAM, NVIDIA GPU)
- 2-4x ONVIF-compliant IP cameras (5MP+, 30fps)
- Azure IoT Operations (production-ready release)
- 500GB Azure Container Storage for video buffering

**Network Requirements**:

- 1 Gbps dedicated network segment for camera traffic
- <5ms latency between edge node and PLCs
- 100 Mbps cloud connectivity for quality data sync

### Storage Architecture (ACSA)

**Tiered Storage Strategy**:

- **Hot Tier (NVMe Cache, 50-80GB)**: Active ring buffers for 4-6 cameras supporting real-time defect detection with <50ms latency. Enables multi-pod shared access for distributed inference services (defect detection, label verification, assembly validation).
- **Warm Tier (Local SSD, 420GB)**: Last 24 hours of video for quality audits, root cause analysis, and model retraining samples. Automatic retention policy deletes routine video after 24h.
- **Cold Tier (Azure Blob Cool, unlimited)**: Defect evidence archive for compliance (ISO 9001, customer audits). Selective sync uploads only defects (95% reduction in egress costs).

**Performance Requirements**:

- **Write throughput**: 120 MB/s (6 cameras × 4MP × 30fps × 0.5 H.265 compression)
- **Read IOPS**: 15K IOPS (3 concurrent inference services × 5K IOPS each)
- **Cache hit ratio target**: >90% for multi-reader scenarios (same stream accessed by multiple AI models)
- **Latency**: <50ms p99 for defect detection pipeline

**Multi-Node Storage Sharing**:

Single camera stream written to ACSA ReadWriteMany volume, consumed by:

- Defect detection model (primary inference)
- Label verification model (OCR/barcode validation)
- Assembly validation model (completeness check)

**Cost Optimization**:

- **Baseline (full sync)**: 6 cameras × 30 days → 1.4TB/month → $66/month egress + $28/month storage = **$94/month**
- **ACSA selective sync (defects only)**: 140GB/month (90% reduction) → $6.60/month egress + $6/month storage = **$12.60/month**
- **Savings**: $81.40/month × 36 months = **$2,930 over 3 years**
- **Updated 3-Year TCO**: $71-140K (reduced from $74-143K)
- **Improved Net ROI**: 111-266% (up from 103-205%)

For detailed ACSA configuration including PVC definitions, performance tuning, and monitoring, see [ACSA Storage Architecture for Vision Workloads](../../../docs/getting-started/acsa-storage-architecture-for-vision.md).

**Software Stack**:

- Terraform blueprint: `full-single-node-cluster`
- ONVIF Connector: Automated camera discovery
- Media Capture Service: Alert-driven video capture
- AI Inference Service: Candle backend (155ms avg latency)
- Custom defect detection model (ONNX format, 50-100MB)

### Pilot Scope and Timeline

**Phase 1 - Proof of Concept (3 weeks)**:

- Week 1: Deploy edge infrastructure, connect 1-2 cameras
- Week 2: Configure ONVIF discovery, test video capture triggers
- Week 3: Deploy baseline defect detection model, validate accuracy

**Success Metrics**:

- 90%+ defect detection accuracy vs manual inspection
- <250ms end-to-end latency (trigger → quality decision)
- 1000+ images captured and processed

**Phase 2 - Pilot Deployment (8 weeks)**:

- Deploy to 1 production line with 4 cameras
- Train custom defect detection model on site-specific data
- Integrate quality decisions with production line control
- Collect 30 days of operational data

**Success Metrics**:

- 95%+ defect detection accuracy
- 50%+ reduction in manual inspection time
- 30%+ reduction in defect escape rate
- 99.5% system uptime

**Phase 3 - Production Scale (6 months)**:

- Scale to 5-10 production lines
- Implement automated model retraining pipeline
- Enable predictive quality analytics
- Multi-site deployment

**Expected Business Outcomes**:

*Note: All savings figures represent gross business impact before infrastructure costs. See [Financial Analysis and ROI](#financial-analysis-and-roi) for net savings calculations including solution TCO.*

- **Cost Savings**: $50-75K per line annually (reduced scrap, rework, warranty claims)
- **Quality Improvement**: 60-80% reduction in defect escapes
- **Throughput**: 40-60% faster inspection cycle time
- **Compliance**: 100% traceability with automated quality documentation

### Customer References

- **Industry**: Automotive component manufacturer
- **Scale**: 12 production lines, 48 ONVIF cameras
- **Results**: 73% reduction in quality escapes, $850K annual savings
- **Deployment**: 4-month pilot to production rollout

## Scenario 2: Retail Customer Analytics

**Architecture Diagram**: [Retail Customer Analytics Architecture](./diagrams/scenario-2-retail-customer-analytics.drawio)

### Business Problem

**Challenge**: Brick-and-mortar retailers lack real-time insights into customer behavior, resulting in:

- Suboptimal staffing levels (over/under-staffed by 20-30%)
- Inefficient store layouts based on assumptions vs data
- Long checkout queues causing 15-25% cart abandonment
- Limited understanding of customer journey and dwell times

**Customer Profile**: Retail chains with 10-200 locations seeking to optimize operations and improve customer experience (grocery, department stores, specialty retail).

### Technical Solution

**Architecture**:

```text
ONVIF PTZ Cameras (8-12 per store)
    ↓ [Ceiling-mounted, ONVIF Connector discovery]
Scheduled Capture + Event Triggers
    ↓ [Hourly snapshots + queue length alerts]
Media Capture Service
    ↓ [10-second segments stored edge + cloud]
AI Inference Service (people counting, queue detection)
    ↓ [Privacy-preserving analytics, no facial recognition]
Real-time Store Metrics Dashboard
    ↓ [Heatmaps, queue lengths, conversion rates]
Microsoft Fabric RTI (EventStream + Eventhouse)
    ↓ [Hourly traffic patterns, conversion metrics, A/B testing]
```

**Component Integration**:

**Azure IoT Operations (Baseline Platform)**:

- **ONVIF Connector** (built-in): Manages 8-12 PTZ cameras, automated position presets for coverage zones
- **Media Connector** (built-in): Snapshot-to-MQTT for real-time AI, clip-to-filesystem for evidence storage
- **MQTT Broker**: Unified pub/sub for camera events, AI inference results, and metrics
- **Device Registry**: Camera asset management and configuration

**Custom Components**:

- **AI Inference Service** (custom deployment): People analytics with model options:
  - **Primary**: DeepLabV3+ MobileNet (19 MB, 50-120ms, 72.4% mIoU) - Semantic segmentation for zone occupancy
  - **Alternative**: YOLOv8n (6 MB, 10-20ms, 37.3% mAP) - Fast people counting with bounding boxes
  - **Privacy**: MobileNetV2 classification (14 MB, 5-10ms, 72.0% top-1) - Crowd density, no PII/faces
- **Privacy Controls** (custom logic): On-device processing, no raw video to cloud, aggregated metrics only
- **Store Metrics Dashboard** (custom app): Real-time heatmaps, queue lengths, conversion rates
- **Microsoft Fabric RTI**: EventStream ingestion + Eventhouse for hourly traffic patterns, conversion funnels, A/B testing store layouts

**Model Selection Rationale**:

- DeepLabV3+ provides per-pixel zone classification (entrance, aisles, checkout) for accurate occupancy heatmaps
- YOLOv8n fallback offers 2-4x faster inference when GPU unavailable
- MobileNetV2 classification ensures GDPR compliance (no facial features, just crowd density classes)

### Deployment Configuration

**Edge Infrastructure** (per store):

- 1x Edge compute node (8 cores, 16GB RAM, optional GPU)
- 8-12x ONVIF PTZ cameras (4MP+, wide-angle lenses)
- Azure IoT Operations (production-ready release)
- 1TB local storage for rolling 7-day video retention

**Network Requirements**:

- Store WiFi/LAN with 100 Mbps for cameras
- 50 Mbps internet connectivity for metrics sync
- VPN tunnel to corporate network

**Software Stack**:

**Azure IoT Operations**:

- Edge Kubernetes cluster with Azure IoT Operations baseline platform
- ONVIF Connector (built-in): PTZ control, scheduled position changes
- Media Connector (built-in): Scheduled + event-driven capture

**Custom Applications**:

- AI Inference Service: MobileNet-based people counting (containerized workload)
- Store Metrics Dashboard: Real-time visualization (custom web app)
- Microsoft Fabric RTI: EventStream ingestion, Eventhouse KQL analytics, Power BI dashboards

### Pilot Scope and Timeline

**Phase 1 - Single Store Pilot (4 weeks)**:

- Week 1-2: Install cameras, deploy edge infrastructure
- Week 3: Configure zones (entrance, aisles, checkout, fitting rooms)
- Week 4: Validate people counting accuracy, calibrate models

**Success Metrics**:

- 90%+ people counting accuracy
- Complete store coverage (all zones monitored)
- Privacy validation (no PII captured/transmitted)

**Phase 2 - Multi-Store Pilot (10 weeks)**:

- Deploy to 3-5 representative stores (urban, suburban, different sizes)
- Collect 60 days of traffic pattern data
- Correlate metrics with POS data (conversion rates)
- A/B test: Optimize staffing based on predictions

**Success Metrics**:

- 85%+ correlation between traffic and sales
- 20%+ reduction in staffing mismatches
- 15%+ reduction in checkout queue times
- 10%+ improvement in conversion rates

**Phase 3 - Enterprise Rollout (12 months)**:

- Scale to 50-200 stores
- Implement predictive staffing models
- Enable cross-store analytics and benchmarking
- Integrate with workforce management systems

**Expected Business Outcomes**:

- **Labor Optimization**: $30-50K per store annually (optimized scheduling)
- **Customer Experience**: 25-40% reduction in average queue time
- **Conversion Improvement**: 5-15% increase from better layouts/staffing
- **Data-Driven Decisions**: Real-time insights replace quarterly surveys

### Customer References

- **Industry**: Specialty retail chain (50 stores)
- **Scale**: 420 ONVIF cameras across 35 stores
- **Results**: 22% labor cost reduction, 38% queue time improvement
- **Deployment**: 6-month pilot to production

## Scenario 3: Predictive Maintenance with Vision

**Architecture Diagram**: [Predictive Maintenance Architecture](./diagrams/scenario-3-predictive-maintenance.drawio)

### Business Problem

**Challenge**: Reactive maintenance of rotating equipment leads to:

- 20-30% unplanned downtime from unexpected failures
- $100K-500K per outage in lost production
- Safety risks from catastrophic equipment failures
- Over-maintenance of healthy equipment (wasted resources)

**Customer Profile**: Asset-intensive industries with critical rotating equipment (oil & gas, utilities, manufacturing, mining, transportation).

### Technical Solution

**Architecture**:

```text
ONVIF Thermal + Visual Cameras
    ↓ [Monitors motors, pumps, compressors, turbines]
Vibration/Temperature Sensors (OPC-UA)
    ↓ [1000 samples/sec synchronized with video]
Multi-Modal Event Detection
    ↓ [Anomaly → trigger Media Capture Service]
Video Segment Capture (30-60 seconds)
    ↓ [Thermal + visual + sensor fusion]
AI Inference Service (anomaly detection)
    ↓ [Vibration patterns, thermal signatures, visual cues]
Predictive Maintenance Alert
    ↓ [MQTT → CMMS integration + Cloud ML]
Maintenance Work Order + Root Cause Video Evidence
```

**Component Integration**:

**Azure IoT Operations (Baseline Platform)**:

- **ONVIF Connector** (built-in): Manages thermal + visual cameras, event synchronization
- **Media Connector** (built-in): Multi-camera capture (thermal + visual), 30-60s segments on anomaly
- **OPC-UA Connector** (built-in): High-frequency sensor data ingestion (1000 samples/sec)
- **MQTT Broker**: Unified pub/sub for sensor data, camera events, and AI alerts
- **Device Registry**: Thermal cameras, visual cameras, and sensor asset management

**Custom Components**:

- **AI Inference Service** (custom deployment): Multi-modal anomaly detection with model options:
  - **Thermal Analysis**: ResNet50 thermal variant (98 MB, 15-30ms, custom fine-tuned) - Bearing/motor temperature anomalies
  - **Visual Inspection**: EfficientNet-B0 (20 MB, 10-20ms, 77.1% top-1) - Equipment condition classification
  - **Sensor Fusion**: Custom CNN (40 MB, 25-40ms) - Combines vibration FFT + thermal + visual features
  - **Backup**: ResNet18 (45 MB, 8-15ms, 69.8% top-1) - Faster fallback with sufficient accuracy
- **CMMS Integration** (custom logic): Maintenance work order creation from AI alerts
- **Cloud ML** (Azure ML): Long-term trend analysis, model retraining

**Model Selection Rationale**:

- ResNet50 thermal variant fine-tuned on 10K+ thermal images of equipment failures
- EfficientNet-B0 provides best accuracy/size ratio for visual equipment classification
- Custom fusion model combines temporal vibration patterns (FFT) with spatial thermal/visual features
- Multi-model ensemble improves reliability (alerts only when 2+ models agree)

### Deployment Configuration

**Edge Infrastructure** (per asset zone):

- 1x Edge compute node (16 cores, 32GB RAM, NVIDIA GPU)
- 2-4x ONVIF thermal cameras (FLIR/Axis, 640x480)
- 2-4x ONVIF visual cameras (4MP+, low-light capable)
- OPC-UA gateway for vibration/temperature sensors
- 1TB local storage for 30-day retention

**Network Requirements**:

- Industrial Ethernet (100 Mbps dedicated)
- <10ms latency for sensor synchronization
- 50 Mbps cloud connectivity

**Software Stack**:

- Terraform blueprint: `full-single-node-cluster`
- ONVIF Connector: Multi-camera synchronization
- Media Capture Service: Multi-modal event capture
- AI Inference Service: Custom anomaly detection model
- Azure ML: Cloud-based model training and refinement

### Pilot Scope and Timeline

**Phase 1 - Single Asset Pilot (4 weeks)**:

- Week 1-2: Install cameras + sensors on 1 critical asset
- Week 3: Baseline data collection (normal operation)
- Week 4: Anomaly detection model training

**Success Metrics**:

- 90%+ anomaly detection sensitivity
- <5% false positive rate
- Synchronized video + sensor data capture

**Phase 2 - Multi-Asset Pilot (12 weeks)**:

- Deploy to 5-10 critical assets
- Collect 90 days of operational data
- Validate predictions against actual maintenance events
- Integrate alerts with CMMS

**Success Metrics**:

- 85%+ prediction accuracy (7-14 days lead time)
- 30%+ reduction in emergency work orders
- Complete failure mode coverage (bearings, lubrication, alignment, overheating)

**Phase 3 - Enterprise Scale (12 months)**:

- Scale to 50-200 assets across multiple sites
- Implement automated model retraining
- Enable cross-asset pattern recognition
- Integrate with enterprise asset management

**Expected Business Outcomes**:

- **Downtime Reduction**: 40-60% decrease in unplanned outages
- **Cost Savings**: $200-500K per avoided catastrophic failure
- **Safety Improvement**: Early detection prevents hazardous failures
- **Maintenance Optimization**: 25-35% reduction in over-maintenance

### Storage Architecture (ACSA)

**Multi-Modal Storage Requirements**:

- **Hot Tier (NVMe Cache, 30-50GB)**: Active ring buffers for thermal + visual camera pairs supporting synchronized multi-modal fusion with <100ms latency
- **Warm Tier (Local SSD, 950GB)**: 30-day retention for anomaly investigation, failure pattern analysis, and compliance documentation
- **Cold Tier (Azure Blob Hot, event-driven)**: Critical anomaly events with 30-second context windows synced immediately for enterprise escalation

**Multi-Modal Synchronization**:

ACSA shared volume enables fusion AI model to access synchronized thermal + visual frames:

- Thermal camera stream: Lower compression for temperature fidelity (higher storage bandwidth)
- Visual camera stream: Standard H.265 compression
- Shared ReadWriteMany PVC: Both streams accessible with timestamp-based frame pairing (<50ms sync tolerance)

**High Availability for Critical Infrastructure**:

- **Risk**: Single storage failure during compressor anomaly = missed detection = $100K+ unplanned downtime
- **Mitigation**: ACSA 2-node replication with automatic failover
- **Cost**: +$5K to 3-year TCO
- **Benefit**: De-risks $300-600K gross savings, justified for high-value critical assets
- **Risk-Adjusted ROI**: HA configuration recommended for predictive maintenance scenarios

**Performance Requirements**:

- **Write throughput**: 80 MB/s (2 cameras × 40 MB/s, thermal requires higher fidelity)
- **Read IOPS**: 10K IOPS (multi-modal fusion model with synchronized access pattern)
- **Sync latency**: <50ms for thermal-visual frame pairing (critical for accurate fusion)

**Selective Cloud Sync**:

- **Baseline (full sync)**: 2 cameras × 30 days → 460GB/month → $21/month egress
- **Selective sync (anomalies only)**: 46GB/month (90% reduction) → $2.10/month egress
- **Savings**: $18.90/month × 36 months = **$680 over 3 years**
- **Updated 3-Year TCO**: $73.3-142.3K (reduced from $74-143K)

For multi-modal synchronization patterns and HA configuration, see [ACSA Storage Architecture for Vision Workloads](../../../docs/getting-started/acsa-storage-architecture-for-vision.md).

### Customer References

- **Industry**: Oil & gas midstream (pipeline pumping stations)
- **Scale**: 45 critical pumps across 8 stations
- **Results**: 58% reduction in unplanned downtime, $2.1M annual savings
- **Deployment**: 8-month pilot to production

## Scenario 4: Smart Building Security and Occupancy

### Business Problem

**Challenge**: Traditional building management lacks real-time visibility, resulting in:

- Energy waste from HVAC in unoccupied zones (15-25% excess consumption)
- Security gaps from manual monitoring (15-30 minute incident response)
- Inefficient space utilization (30-40% of space underutilized)
- Compliance risks for occupancy limits and emergency egress

**Customer Profile**: Commercial real estate, corporate campuses, healthcare facilities, educational institutions with 50K-1M sq ft buildings.

### Technical Solution

**Architecture**:

```text
ONVIF PTZ Cameras (20-50 per building)
    ↓ [Lobby, hallways, common areas, entrances]
Scheduled Occupancy Scans + Security Events
    ↓ [Every 15 min + door/motion sensor triggers]
Media Capture Service
    ↓ [5-second occupancy snapshots + 30s security clips]
AI Inference Service (occupancy counting, security alerts)
    ↓ [Privacy-preserving, zone-level aggregates]
Building Management System Integration
    ↓ [HVAC control, access control, emergency systems]
Real-time Building Dashboard + Cloud Analytics
```

**Component Integration**:

**Azure IoT Operations (Baseline Platform)**:

- **ONVIF Connector** (built-in): Manages 20-50 PTZ cameras, preset positions per zone
- **Media Connector** (built-in): Scheduled occupancy scans + security event capture
- **BACnet/Modbus Connectors** (built-in): Building management system integration
- **MQTT Broker**: Unified messaging for cameras, occupancy, and BMS control
- **Device Registry**: Camera and BMS equipment asset management

**Custom Components**:

- **AI Inference Service** (custom deployment): Occupancy counting, tailgating detection, zone violations
- **BMS Control Logic** (custom app): MQTT → HVAC setpoint adjustments based on occupancy
- **Building Dashboard** (custom app): Real-time occupancy heatmaps and security alerts
- **Access Control Integration** (custom logic): Security alerts to badge systems

### Deployment Configuration

**Edge Infrastructure** (per building):

- 1-2x Edge compute nodes (8 cores, 16GB RAM each)
- 20-50x ONVIF PTZ cameras (4MP+, low-light)
- Azure IoT Operations (production-ready release)
- 2TB local storage for 14-day retention

**Network Requirements**:

- Building LAN (1 Gbps backbone)
- 100 Mbps internet connectivity
- Integration with BMS (BACnet/Modbus)

**Software Stack**:

- Terraform blueprint: `full-single-node-cluster`
- ONVIF Connector: Multi-zone camera management
- Media Capture Service: Scheduled + event capture
- AI Inference Service: Occupancy + security models
- Cloud dashboards: Power BI, Grafana, or custom web applications

### Pilot Scope and Timeline

**Phase 1 - Single Floor Pilot (3 weeks)**:

- Week 1: Install cameras on 1 floor (10-15 cameras)
- Week 2: Configure zones, validate occupancy counting
- Week 3: BMS integration, automated HVAC control

**Success Metrics**:

- 90%+ occupancy counting accuracy
- Privacy validation (zone-level aggregates only)
- Successful HVAC integration

**Phase 2 - Full Building Pilot (8 weeks)**:

- Deploy to entire building (20-50 cameras)
- Collect 60 days of occupancy patterns
- Implement dynamic HVAC control
- Security event validation

**Success Metrics**:

- 15%+ energy savings from optimized HVAC
- 50%+ reduction in security incident response time
- Complete zone coverage and reporting

**Phase 3 - Campus Rollout (12 months)**:

- Scale to 5-10 buildings
- Implement cross-building analytics
- Enable predictive occupancy models
- Integrate with enterprise systems

**Expected Business Outcomes**:

- **Energy Savings**: $50-100K per building annually (HVAC optimization)
- **Security**: 60-80% faster incident detection and response
- **Space Utilization**: 20-30% improvement in space planning
- **Compliance**: Real-time occupancy monitoring for safety limits

### Storage Architecture (ACSA)

**Large-Scale Camera Deployment**:

- **Hot Tier (NVMe Cache, 100-150GB)**: Active ring buffers for 8-12 cameras supporting real-time occupancy detection and security event processing
- **Warm Tier (Local SSD, 1.85TB)**: 14-day retention for security investigations, incident review, and access control audits
- **Cold Tier (Azure Blob Cool, event-driven)**: Security incidents and compliance evidence (badge violations, after-hours access, occupancy limit breaches)

**Multi-Reader Performance Optimization**:

Multiple building management services read same camera streams:

- Occupancy detection service (people counting, zone aggregation)
- Security monitoring service (perimeter intrusion, badge verification)
- HVAC optimization service (zone-level occupancy for climate control)
- Space utilization analytics (desk usage, conference room occupancy)

ACSA cache serves 4 concurrent services with 90-95% cache hit ratio, avoiding 4x network bandwidth multiplication.

**Performance Requirements**:

- **Write throughput**: 180 MB/s (12 cameras × 15fps × 4MP × 0.5 compression)
- **Read IOPS**: 20K IOPS (4 inference services × 5K IOPS each)
- **Cache size**: 120GB to maintain >90% hit ratio for 12 camera streams

**Privacy-Preserving Architecture**:

- Edge processing only (no raw video to cloud unless configured)
- Zone-level occupancy aggregation (no PII)
- Configurable retention policies per camera zone (public areas: 7 days, restricted areas: 14 days)
- Automatic redaction for privacy-sensitive areas (bathrooms, locker rooms excluded from storage)

**Cost Optimization**:

- **Baseline (full sync)**: 12 cameras × 14 days → 2.4TB/month → $112/month egress
- **Selective sync (incidents only)**: 240GB/month (90% reduction) → $11.20/month egress
- **Savings**: $100.80/month × 36 months = **$3,629 over 3 years**

### Customer References

- **Industry**: Corporate campus (3 buildings, 800K sq ft)
- **Scale**: 120 ONVIF cameras across 3 buildings
- **Results**: 18% energy reduction, $240K annual savings
- **Deployment**: 5-month pilot to production

## Scenario 5: Industrial Process Optimization with Vision-Based Quality Control

**Architecture Diagram**: [Industrial Process Optimization Architecture](./diagrams/scenario-5-industrial-process.drawio)

### Business Problem

**Challenge**: Manufacturing process control relies on sensor data alone, creating blind spots in quality management:

- Process parameters within specification but defects still occur (10-15% of quality escapes)
- 2-4 hour lag between process drift and quality detection
- Root cause analysis limited by lack of visual evidence
- Manual correlation of sensor data with quality outcomes
- Reactive adjustments after defects already produced ($150-300K waste per incident)

**Customer Profile**: High-volume manufacturers with automated production lines requiring tight process control and zero-defect quality (pharmaceutical, semiconductor, food & beverage, chemical processing).

### Technical Solution

**Architecture**:

```text
OPC-UA Industrial Sensors (1000+ tags/sec)
    ↓ [Temperature, pressure, flow, vibration, motor current]
ONVIF Cameras (4-8 per process stage)
    ↓ [Product images at critical control points]
Multi-Modal Event Detection
    ↓ [Sensor threshold violation OR scheduled inspection]
Media Capture Service
    ↓ [5-second video segments + sensor snapshot]
AI Inference Service (vision + sensor fusion)
    ↓ [Defect detection with process context]
Real-time Process Adjustment
    ↓ [MQTT → PLC control + operator alerts]
Fabric RTI Eventhouse
    ↓ [Correlation analysis: sensor patterns → defect rates]
```

**Component Integration**:

**Azure IoT Operations (Baseline Platform)**:

- **OPC-UA Connector** (built-in): 1000+ tags/second from PLCs, DCS, SCADA systems
- **ONVIF Connector** (built-in): 4-8 cameras per process stage, synchronized with sensor events
- **Media Connector** (built-in): Triggered by sensor threshold violations OR scheduled intervals (every 30 seconds)
- **MQTT Broker**: Bidirectional messaging for sensor data, video, and PLC control commands
- **Device Registry**: Camera and OPC-UA sensor asset management
- **Data Processor**: Routes data to Fabric RTI EventStream

**Custom Components**:

- **AI Inference Service** (custom deployment): Multi-modal model analyzes visual defects + process context
- **Process Control Logic** (custom app): AI-driven PLC adjustments within control limits
- **Fabric RTI** (Microsoft Fabric): EventStream ingestion + Eventhouse for real-time KQL correlation queries

### Deployment Configuration

**Edge Infrastructure** (per process line):

- 1x Edge compute node (24 cores, 64GB RAM, NVIDIA GPU)
- 4-8x ONVIF cameras (5MP+, synchronized timing)
- OPC-UA gateway for PLC/SCADA integration
- Azure IoT Operations (production-ready release)
- 1TB Azure Container Storage for video + time-series buffering

**Network Requirements**:

- 1 Gbps dedicated process network (cameras + sensors)
- <5ms latency for sensor data ingestion
- <10ms latency for PLC control commands
- 100 Mbps cloud connectivity for analytics sync

**Software Stack**:

- Azure IoT Operations with edge Kubernetes cluster
- OPC-UA connector: High-frequency sensor ingestion
- ONVIF Connector: Multi-camera synchronization
- Media Capture Service: Sensor-triggered video capture
- AI Inference Service: Custom multi-modal model (visual + sensor features)
- Fabric RTI: EventStream + Eventhouse for real-time correlation

### Storage Architecture (ACSA)

**Hybrid Storage for Video + Time-Series**:

- **Hot Tier (NVMe Cache, 60-100GB)**: Active ring buffers for 4-6 cameras supporting multi-modal fusion AI (video + OPC-UA sensor data) with <100ms correlation latency
- **Warm Tier - Video (Local SSD, 800GB)**: Video data with sequential access optimization for process review and model retraining
- **Warm Tier - Time-Series (Local SSD, 200GB)**: OPC-UA sensor data with random access optimization for Fabric RTI queries
- **Cold Tier (Azure Blob Cool, event-driven)**: Process anomalies with correlated video + sensor context windows

**Fabric RTI Edge Caching**:

ACSA reduces bandwidth for real-time dashboard queries:

- **Edge cache**: Last 1 hour of data cached locally for <100ms query response
- **Cloud queries**: Historical data (>1 hour) served from Fabric RTI with 1-3s latency
- **Bandwidth savings**: 80% reduction for dashboard queries via edge cache hits

**Multi-Modal Data Synchronization**:

Shared ACSA volume enables fusion AI model to correlate:

- **Video streams**: Process visualization (mixing, coating, assembly) at 30fps
- **OPC-UA sensors**: Temperature, pressure, vibration, flow rate at 100Hz+
- **Synchronized access**: Timestamp-based pairing with <50ms tolerance for accurate correlation

**Performance Requirements**:

- **Video write throughput**: 120 MB/s (6 cameras × 20 MB/s)
- **Time-series write IOPS**: 5K IOPS (1000 tags × 5 writes/sec)
- **Read pattern**: Sequential for video playback, random for sensor queries
- **ACSA optimization**: Separate volumes with access-pattern-specific caching (sequential read hints for video, random read hints for time-series)

**Cost Optimization**:

- **Baseline (full sync)**: 6 cameras + sensors × 30 days → 1.5TB/month → $70/month egress
- **Selective sync (anomalies only)**: 150GB/month (90% reduction) → $7/month egress
- **Savings**: $63/month × 36 months = **$2,268 over 3 years**

For Fabric RTI integration patterns and multi-modal synchronization, see [ACSA Storage Architecture for Vision Workloads](../../../docs/getting-started/acsa-storage-architecture-for-vision.md).

### Pilot Scope and Timeline

**Phase 1 - Baseline Establishment (4 weeks)**:

- Week 1-2: Deploy edge infrastructure, connect OPC-UA sensors
- Week 3: Add 2 ONVIF cameras at critical process points
- Week 4: Collect baseline data (sensor + visual), identify correlation patterns

**Success Metrics**:

- 1000+ OPC-UA tags streaming at <100ms latency
- 90%+ synchronized sensor-visual capture on triggers
- Fabric RTI queries executing <5 seconds on 7 days of data

**Phase 2 - Multi-Modal AI Deployment (10 weeks)**:

- Deploy to full process line (4-8 cameras + all sensor integration)
- Train custom defect detection model with sensor context features
- Implement real-time process adjustment logic (temperature → defect feedback loop)
- Collect 60 days operational data with AI-driven alerts

**Success Metrics**:

- 92%+ defect detection accuracy (vs 85% sensor-only, 88% vision-only)
- 30-45 second reduction in defect detection time (vs manual inspection)
- 15%+ reduction in false positives (vs vision-only model)
- Process adjustments prevent 40%+ of predicted defects

**Phase 3 - Predictive Process Control (6 months)**:

- Scale to 3-5 process lines
- Implement predictive models (sensor drift → defect probability)
- Enable automated process adjustments within control limits
- Cross-line pattern recognition and best practice sharing

**Expected Business Outcomes**:

- **Quality Improvement**: 60-75% reduction in process-related defects
- **Waste Reduction**: $100-200K per line annually (prevented scrap/rework)
- **Root Cause Analysis**: 80% faster with visual + sensor evidence
- **Process Optimization**: 5-10% throughput improvement via tighter control

### Customer References

- **Industry**: Pharmaceutical tablet manufacturing
- **Scale**: 4 production lines, 24 ONVIF cameras, 3500 OPC-UA tags
- **Results**: 68% reduction in out-of-spec production, $1.2M annual savings
- **Deployment**: 6-month pilot to production expansion

## Scenario 6: Connected Product Telemetry with Remote Visual Diagnostics

**Architecture Diagram**: [Connected Product Telemetry Architecture](./diagrams/scenario-6-connected-product.drawio)

### Business Problem

**Challenge**: Remote equipment monitoring generates alerts but lacks visual confirmation, resulting in:

- 40-50% false positive service dispatches ($500-1500 per truck roll)
- Limited remote troubleshooting without visual inspection
- Warranty disputes due to lack of photographic evidence
- Customer downtime waiting for on-site diagnostics (4-24 hours)
- Inability to differentiate critical failures from minor issues

**Customer Profile**: Equipment manufacturers with distributed installed base requiring remote monitoring (HVAC, industrial compressors, medical devices, fleet vehicles, renewable energy systems).

### Technical Solution

**Architecture**:

```text
Connected Equipment Telemetry (IoT)
    ↓ [Vibration, temperature, runtime hours, error codes]
Bidirectional MQTT Messaging
    ↓ [Telemetry to cloud, diagnostic commands to edge]
Cloud Anomaly Detection (Azure ML)
    ↓ [Predictive maintenance alerts]
Visual Inspection Request
    ↓ [Cloud → Edge MQTT command]
ONVIF Camera Activation (edge)
    ↓ [PTZ to inspection position, capture segments]
Media Capture Service
    ↓ [30-60 second diagnostic video + telemetry snapshot]
AI Inference Service (equipment condition assessment)
    ↓ [Oil leaks, alignment, physical damage, wear indicators]
Service Decision Support
    ↓ [Dispatch with diagnosis OR remote resolution]
Cloud Evidence Storage (Azure Blob + warranty integration)
```

**Component Integration**:

**Azure IoT Operations (Baseline Platform)**:

- **MQTT Broker**: Bidirectional messaging via Event Grid MQTT (supports MQTT-RPC for remote commands)
- **ONVIF Connector** (built-in): PTZ cameras positioned for equipment inspection (motors, pumps, connections)
- **Media Connector** (built-in): Multi-source ingestion from IP cameras and edge-attached cameras with snapshot-to-MQTT and clip-to-filesystem tasks
- **Modbus/CAN Bus Connectors** (built-in): Equipment telemetry ingestion
- **Device Registry**: Camera and equipment asset management

**Custom Components**:

- **Cloud ML** (Azure ML): Anomaly detection triggers visual inspection requests
- **AI Inference Service** (custom deployment): Computer vision models detect oil leaks, corrosion, misalignment, component wear
- **Service Dispatch Integration** (custom app): Remote diagnosis workflows and work order creation
- **Azure Blob Storage**: Stores correlated telemetry + video evidence for warranty and compliance

### Deployment Configuration

**Edge Infrastructure** (per equipment site):

- 1x Edge gateway (8 cores, 16GB RAM, optional GPU)
- 2-4x ONVIF PTZ cameras (4MP+, weatherproof for industrial environments)
- Equipment connectivity (Modbus, CAN bus, proprietary protocols)
- Azure IoT Operations (production-ready release)
- 500GB local storage for 30-day video retention

**Network Requirements**:

- Cellular/WiFi connectivity (10 Mbps minimum for video upload)
- <30 second latency for remote diagnostic commands
- Offline operation capability (local inference + buffering)

**Software Stack**:

- Azure IoT Operations with edge Kubernetes cluster
- Custom IoT protocol connectors (Modbus, CAN bus adapters)
- ONVIF Connector: Remote PTZ control, scheduled + on-demand capture
- Media Connector: Multi-source media ingestion (IP cameras + edge-attached cameras), snapshot-to-MQTT for real-time AI, clip-to-filesystem for evidence storage
- Media Capture Service: Cloud-triggered diagnostic video capture (alternative/legacy method)
- AI Inference Service: Equipment condition models (leak detection, wear assessment)
- Event Hub: Bidirectional telemetry + command messaging

### Pilot Scope and Timeline

**Phase 1 - Single Equipment Pilot (4 weeks)**:

- Week 1-2: Install edge gateway + cameras on 1 critical equipment asset
- Week 3: Configure bidirectional messaging, test remote camera control
- Week 4: Validate remote visual inspection workflow (alert → capture → AI → decision)

**Success Metrics**:

- <60 second end-to-end response time (cloud alert → visual capture)
- Successful remote PTZ control and video retrieval
- 85%+ uptime for connectivity and video capture

**Phase 2 - Multi-Site Pilot (10 weeks)**:

- Deploy to 10-20 equipment installations across multiple customer sites
- Train custom condition assessment models on equipment-specific defects
- Integrate with service dispatch systems and warranty workflows
- Collect 90 days of operational data comparing remote visual vs traditional dispatch

**Success Metrics**:

- 50%+ reduction in unnecessary service dispatches
- 90%+ accuracy in remote condition assessment (vs on-site inspection)
- 30%+ reduction in mean time to diagnosis
- 80%+ of issues remotely diagnosed without truck roll

**Phase 3 - Fleet Deployment (12 months)**:

- Scale to 200-500 equipment installations
- Enable automated visual inspection scheduling (weekly/monthly)
- Implement predictive visual analytics (progressive wear tracking)
- Customer self-service portal with visual diagnostic history

**Expected Business Outcomes**:

- **Service Cost Reduction**: $200-400K annually (avoided truck rolls for 500 assets)
- **Customer Uptime**: 40-60% faster resolution through remote diagnosis
- **Warranty Management**: 70% reduction in disputed claims with visual evidence
- **Predictive Maintenance**: Visual wear progression enables proactive part replacement

### Customer References

- **Industry**: Industrial compressor manufacturer (rental fleet)
- **Scale**: 380 compressor units across 120 customer sites, 950 ONVIF cameras
- **Results**: 54% reduction in service dispatches, $680K annual savings
- **Deployment**: 8-month pilot to production rollout

## Scenario 7: Multi-Site Energy Monitoring with Occupancy-Aware HVAC Control

**Architecture Diagram**: [Multi-Site Energy Monitoring Architecture](./diagrams/scenario-7-multi-site-energy.drawio)

### Business Problem

**Challenge**: Traditional building management systems lack real-time occupancy awareness, resulting in:

- 20-30% energy waste from HVAC in unoccupied zones
- Manual occupancy estimates for HVAC scheduling (30-40% inaccurate)
- Limited visibility into multi-site energy consumption patterns
- Inability to correlate energy usage with actual building utilization
- Compliance risks for sustainability reporting (ESG requirements)

**Customer Profile**: Multi-site organizations with distributed facilities requiring energy optimization (corporate real estate, retail chains, healthcare systems, educational campuses, hospitality).

### Technical Solution

**Architecture**:

```text
BACnet/Modbus HVAC Integration
    ↓ [Temperature, setpoints, energy consumption, equipment status]
ONVIF PTZ Cameras (20-50 per building)
    ↓ [Scheduled occupancy scans every 15 minutes]
Media Capture Service
    ↓ [5-second occupancy snapshots, privacy-preserving]
AI Inference Service (people counting)
    ↓ [Zone-level occupancy aggregates, no PII]
Real-time HVAC Optimization
    ↓ [MQTT → BMS setpoint adjustments based on actual occupancy]
Fabric RTI Eventhouse
    ↓ [Multi-site energy + occupancy correlation analytics]
Real-time Dashboard + Predictive Models
    ↓ [Cross-site benchmarking, occupancy forecasting, ESG reporting]
```

**Component Integration**:

**Azure IoT Operations (Baseline Platform)**:

- **BACnet/Modbus Connectors** (built-in): HVAC, lighting, electrical meter data from building management systems
- **ONVIF Connector** (built-in): Scheduled occupancy scans (every 15 min) + preset positions per zone
- **Media Connector** (built-in): Privacy-preserving snapshots (zone-level analysis only, no facial recognition)
- **MQTT Broker**: Unified messaging for occupancy, energy data, and BMS control
- **Device Registry**: Camera and BMS equipment asset management
- **Data Processor**: Routes multi-site data to Fabric RTI EventStream

**Custom Components**:

- **AI Inference Service** (custom deployment): People counting with configurable privacy controls (aggregate counts only)
- **HVAC Optimization Logic** (custom app): MQTT-to-BACnet gateway for setpoint control based on occupancy
- **Fabric RTI** (Microsoft Fabric): Multi-site EventStream aggregation + Eventhouse for correlation analytics
- **ESG Reporting Dashboard** (custom app): Cross-site benchmarking and sustainability metrics

### Deployment Configuration

**Edge Infrastructure** (per building):

- 1-2x Edge compute nodes (8 cores, 16GB RAM each)
- 20-50x ONVIF PTZ cameras (4MP+, low-light capable)
- BACnet/Modbus gateway for BMS integration
- Azure IoT Operations (production-ready release)
- 1TB local storage for 14-day occupancy data retention

**Network Requirements**:

- Building LAN (1 Gbps backbone)
- 50-100 Mbps internet per site for cloud analytics sync
- BMS network integration (isolated VLAN)

**Software Stack**:

- Azure IoT Operations with edge Kubernetes cluster
- BACnet/Modbus connectors for HVAC integration
- ONVIF Connector: Scheduled PTZ preset changes for zone coverage
- Media Capture Service: Privacy-preserving scheduled capture
- AI Inference Service: MobileNet people counting (zone-level aggregates)
- Fabric RTI: Multi-site energy + occupancy EventStream and KQL analytics

### Pilot Scope and Timeline

**Phase 1 - Single Building Pilot (4 weeks)**:

- Week 1-2: Deploy edge infrastructure + cameras on 2 floors (20-25 cameras)
- Week 3: Configure zone definitions, validate occupancy counting accuracy
- Week 4: BMS integration, test HVAC setpoint adjustments based on occupancy

**Success Metrics**:

- 90%+ occupancy counting accuracy vs manual counts
- Privacy validation (zone-level aggregates only, no raw video to cloud)
- Successful BMS integration with <5 minute occupancy-to-HVAC latency

**Phase 2 - Full Building Pilot (10 weeks)**:

- Deploy to entire building (20-50 cameras, all zones covered)
- Collect 60 days of occupancy + energy correlation data
- Implement dynamic HVAC control (setback unoccupied zones by 2-4°F)
- Measure energy savings vs baseline

**Success Metrics**:

- 15-25% energy reduction in HVAC consumption
- 85%+ occupancy forecast accuracy (next 2 hours)
- 99%+ system uptime for occupancy monitoring

**Phase 3 - Multi-Site Deployment (12 months)**:

- Scale to 10-20 buildings across portfolio
- Implement cross-site analytics via Fabric RTI (benchmarking, best practices)
- Enable predictive occupancy models (historical patterns + calendar events)
- Integrate with enterprise energy management and ESG reporting

**Expected Business Outcomes**:

- **Energy Savings**: $75-150K per building annually (HVAC optimization)
- **Carbon Reduction**: 20-30% reduction in Scope 2 emissions (supports ESG goals)
- **Space Utilization**: Identify 30-40% underutilized space for portfolio optimization
- **Predictive HVAC**: Pre-cooling/pre-heating based on occupancy forecasts (comfort + efficiency)

### Customer References

- **Industry**: Corporate campus (5 buildings, 1.2M sq ft)
- **Scale**: 220 ONVIF cameras across 5 buildings, 850 BACnet data points
- **Results**: 22% energy reduction, $420K annual savings, 28% carbon footprint reduction
- **Deployment**: 7-month pilot to multi-site rollout

### Integration with Fabric Real-Time Intelligence

**Data Flow**:

- **EventStream**: Ingests energy consumption and occupancy data from Azure IoT Operations MQTT broker
- **Data Transformation**: Joins energy and occupancy streams by building and timestamp, enriches with building metadata
- **Eventhouse**: Time-series optimized storage for historical correlation queries

**Analytics Capabilities**:

- **Energy Waste Identification**: Correlate HVAC consumption with occupancy to identify unoccupied zones consuming energy
- **Cross-Site Benchmarking**: Occupancy-normalized energy efficiency metrics across building portfolio
- **Predictive Occupancy**: Time-series forecasting for proactive HVAC scheduling and comfort optimization
- **ESG Reporting**: Automated carbon footprint calculations based on actual building utilization

## Scenario 8: Legacy Equipment Integration with REST API and Vision Modernization

**Architecture Diagram**: [Legacy Equipment Integration Architecture](./diagrams/scenario-8-legacy-equipment-integration.drawio)

### Business Problem

Brownfield industrial sites and facilities operate critical equipment with legacy monitoring systems that expose data via proprietary HTTP/REST APIs but lack modern integration capabilities. These systems are expensive to replace ($200K-$2M per system), yet organizations need real-time visibility and analytics to improve operations. Adding visual context to telemetry data from these legacy systems enables more accurate diagnostics and predictive insights without costly equipment replacement.

**Pain Points**:

- Legacy equipment monitoring systems isolated from modern cloud platforms
- Manual data collection from proprietary HTTP APIs and web interfaces
- No visual context for alarms and anomalies from legacy systems
- High cost of rip-and-replace modernization ($200K-$2M per system)
- Data silos preventing cross-system analytics and optimization

### Solution Overview

Deploy edge infrastructure with REST/HTTP Connector to bridge legacy HTTP APIs to MQTT messaging, while adding ONVIF cameras and Media Connector for visual context. This approach modernizes data integration without replacing functional legacy equipment, enabling cloud analytics and AI-powered insights.

**Architecture**:

```text
Legacy Equipment Systems (HTTP/REST APIs)
    ↓ [Proprietary API endpoints: /api/status, /api/alarms, /api/metrics]
REST/HTTP Connector (Akri)
    ↓ [Periodic polling 1-60s, schema validation, JSON transformation]
MQTT Broker (Azure IoT Operations)
    ↓ [Unified telemetry topic: legacy/{equipment_id}/telemetry]
Retrofit ONVIF Cameras (visual context)
    ↓ [PTZ cameras added to existing equipment]
Media Connector
    ↓ [snapshot-to-mqtt: real-time snapshots, clip-to-fs: alarm-triggered recordings]
AI Inference Service
    ↓ [Multi-modal fusion: telemetry + vision for anomaly detection]
Microsoft Fabric RTI (EventStream + Eventhouse)
    ↓ [Time-series analytics, cross-system correlation, predictive models]
Cloud Dashboards (Power BI, Grafana, custom web applications)
```

**Component Integration**:

**Azure IoT Operations (Baseline Platform)**:

- **ONVIF Connector** (built-in): Manages retrofit PTZ cameras positioned for equipment visual monitoring
- **Media Connector** (built-in): Captures snapshots-to-MQTT for real-time AI analysis, clips-to-filesystem for alarm evidence storage
- **MQTT Broker**: Unified pub/sub for legacy telemetry + vision data streams
- **Device Registry**: Camera and legacy equipment asset management

**Custom Components**:

- **REST/HTTP Connector** (custom deployment from `505-akri-rest-http-connector` or `502-rust-http-connector`): Polls legacy HTTP/REST APIs (1-60s intervals), transforms proprietary JSON to standardized MQTT messages
- **AI Inference Service** (custom deployment): Multi-modal anomaly detection combining telemetry patterns + visual indicators
- **Microsoft Fabric RTI**: EventStream ingestion + Eventhouse for time-series analytics, cross-system optimization, and predictive maintenance
- **Unified Dashboard** (custom app): Power BI, Grafana, or custom web applications for cross-system visibility

### Deployment Configuration

**Edge Infrastructure** (per legacy system cluster):

- 1x Edge gateway (12 cores, 24GB RAM, optional GPU for AI inference)
- 2-4x ONVIF PTZ cameras (4MP+, weatherproof for industrial environments)
- Legacy equipment network access (HTTP/HTTPS connectivity to API endpoints)
- Azure IoT Operations (production-ready release)
- 1TB local storage for video retention and buffering

**Network Requirements**:

- Access to legacy equipment HTTP/REST APIs (typically 10.x.x.x private networks)
- 50 Mbps cloud connectivity for telemetry and video sync
- <100ms latency between edge gateway and legacy systems
- Offline operation capability (local buffering + processing)

**Software Stack**:

- Azure IoT Operations with edge Kubernetes cluster
- REST/HTTP Connector (`505-akri-rest-http-connector` or `502-rust-http-connector`): Legacy API integration
- ONVIF Connector: Camera discovery and control
- Media Connector (`508-media-connector`): Multi-source media ingestion with snapshot-to-MQTT and clip-to-filesystem
- AI Inference Service: Multi-modal anomaly detection models
- Microsoft Fabric RTI: EventStream ingestion + Eventhouse for time-series analytics and cross-system correlation

**REST Connector Configuration Example**:

```hcl
# Enable REST/HTTP connector for legacy equipment
custom_akri_connectors = [
  {
    name      = "legacy-equipment-api-connector"
    type      = "rest"
    replicas  = 2
    log_level = "info"
    additional_configuration = {
      poll_interval_seconds = "30"
      endpoints = jsonencode([
        {
          url     = "http://10.50.100.10/api/status"
          method  = "GET"
          headers = { "Authorization" = "Bearer ${legacy_api_token}" }
        },
        {
          url     = "http://10.50.100.10/api/alarms"
          method  = "GET"
          headers = { "Authorization" = "Bearer ${legacy_api_token}" }
        }
      ])
      mqtt_topic_template = "legacy/{{equipment_id}}/{{data_type}}"
    }
  }
]

# Enable Media Connector for visual context
should_enable_akri_media_connector = true

# Configure camera devices for legacy equipment visual monitoring
namespaced_devices = [
  {
    name         = "legacy-equipment-camera-01"
    display_name = "Legacy Equipment Camera 01"
    enabled      = true
    endpoints = {
      enabled = true
      inbound = {
        "camera-rtsp" = {
          endpoint_type = "Custom"
          address       = "rtsp://192.168.10.100:554/stream1"
          authentication = {
            method = "UsernamePassword"
            username_secret_ref = { name = "camera-credentials", key = "username" }
            password_secret_ref = { name = "camera-credentials", key = "password" }
          }
        }
      }
    }
  }
]

# Configure media capture tasks as assets
namespaced_assets = [
  {
    name         = "legacy-equipment-snapshots"
    display_name = "Legacy Equipment Real-Time Snapshots"
    enabled      = true
    device_ref = {
      device_name   = "legacy-equipment-camera-01"
      endpoint_name = "camera-rtsp"
    }
    description = "Real-time snapshots for AI-powered anomaly detection"
    datasets = [{
      name                  = "snapshots"
      data_source           = ""  # Media connector uses device endpoint
      dataset_configuration = jsonencode({
        taskType        = "snapshot-to-mqtt"
        intervalSeconds = 5
        quality         = 85
        width           = 1280
        height          = 720
      })
      destinations = [{
        target = "Mqtt"
        configuration = {
          topic = "legacy/vision/snapshots"
        }
      }]
    }]
  },
  {
    name         = "legacy-equipment-alarm-clips"
    display_name = "Legacy Equipment Alarm Video Clips"
    enabled      = true
    device_ref = {
      device_name   = "legacy-equipment-camera-01"
      endpoint_name = "camera-rtsp"
    }
    description = "Event-triggered video clips for alarm evidence"
    datasets = [{
      name                  = "clips"
      data_source           = ""
      dataset_configuration = jsonencode({
        taskType         = "clip-to-fs"
        durationSeconds  = 30
        preBufferSeconds = 10
        storagePath      = "/mnt/acs/legacy-equipment-alarms"
        format           = "mp4"
        codec            = "h265"
        triggerTopic     = "legacy/+/alarms"
      })
      destinations = []  # Clips stored to filesystem, not MQTT
    }]
  }
]
```

### Pilot Scope and Timeline

**Phase 1 - Single Legacy System Pilot (4 weeks)**:

- Week 1-2: Deploy edge gateway, configure REST Connector for 1 legacy equipment API
- Week 2-3: Add 2 ONVIF cameras with Media Connector for visual context
- Week 3-4: Validate REST-to-MQTT data flow, test snapshot-to-MQTT and clip-to-filesystem

**Success Metrics**:

- <60 second latency for legacy API data in cloud dashboard
- 95%+ uptime for REST Connector polling
- Successful visual snapshot capture correlated with legacy telemetry events
- 100% alarm events captured with 30-second video clips

**Phase 2 - Multi-System Integration (10 weeks)**:

- Integrate 5-10 legacy equipment systems across the facility
- Deploy multi-modal AI models combining telemetry + vision anomaly detection
- Build unified dashboards showing cross-system analytics and trends
- Measure operational improvements (reduced downtime, faster diagnostics)

**Success Metrics**:

- 80%+ of legacy systems successfully integrated via REST Connector
- 40%+ improvement in anomaly detection accuracy (telemetry + vision vs telemetry-only)
- 50%+ faster root cause analysis with visual evidence
- Zero legacy system replacements required

**Phase 3 - Enterprise Rollout (12 months)**:

- Scale to 50-100 legacy equipment systems across 2-3 facilities
- Enable cross-facility benchmarking and optimization
- Implement predictive maintenance models using historical telemetry + vision data
- Integrate with enterprise systems (CMMS, ERP, MES)

**Expected Business Outcomes**:

- **CapEx Avoidance**: $2-5M saved by avoiding legacy equipment replacement
- **Operational Efficiency**: 30-40% faster anomaly resolution with visual diagnostics
- **Predictive Maintenance**: 25-35% reduction in unplanned downtime through early detection
- **Data Modernization**: Legacy data accessible in cloud analytics platforms (Microsoft Fabric, Power BI)
- **Integration Cost Reduction**: 70-80% lower cost vs custom integration development

### Customer References

**Ideal Customer Profile**:

- Brownfield manufacturing, utilities, or facilities with 10-20+ year old equipment
- Legacy monitoring systems with HTTP/REST APIs but no modern integration
- High cost of equipment replacement ($200K-$2M per system)
- Need for cross-system analytics and predictive maintenance
- Reluctance to rip-and-replace functional equipment

**Competitive Differentiators**:

- **Non-invasive Integration**: No legacy system modifications required
- **Multi-Modal Intelligence**: Combines telemetry + vision for superior accuracy
- **Rapid ROI**: 3-6 months payback through avoided CapEx and improved uptime
- **Future-Proof**: Modern MQTT/cloud integration ready for additional sensors and AI models
- **Proven Technology**: Azure IoT Operations + Akri Connectors deployed at Fortune 500 customers

## Common Implementation Considerations

### Infrastructure Requirements

**Minimum Edge Configuration** (single pilot line/zone):

- 1x Intel/AMD server (16 cores, 32GB RAM, optional GPU)
- 2-4x ONVIF-compliant IP cameras (4MP+, 30fps)
- 500GB-1TB local storage (Azure Container Storage Accelerator)
- Azure IoT Operations subscription

**Network Requirements**:

- 1 Gbps dedicated camera network segment
- <10ms edge-to-camera latency
- 50-100 Mbps cloud connectivity for data sync

**Camera Selection Criteria**:

- ONVIF Profile S (minimum) or Profile T (recommended)
- H.264/H.265 encoding support
- PoE (Power over Ethernet)
- Industrial-grade for harsh environments
- Low-light capability for 24/7 operation

### Azure Container Storage Architecture (ACSA)

**Storage Tier Strategy**:

All vision scenarios leverage Azure Container Storage enabled by Azure Arc (ACSA) with tiered storage for optimal performance and cost:

- **Hot Tier (NVMe Cache)**: Low-latency cache for active ring buffers and real-time inference (<10ms latency, 15K+ IOPS)
- **Warm Tier (Local SSD)**: Persistent retention for recent video (7-30 days) and model retraining datasets
- **Cold Tier (Azure Blob)**: Long-term archival for compliance, audits, and infrequent analysis

**Key ACSA Benefits for Vision Workloads**:

1. **Multi-Pod Shared Access (ReadWriteMany)**: Single camera stream consumed by multiple AI inference services without network bandwidth multiplication
2. **Performance Acceleration**: NVMe cache achieves 90-95% cache hit ratio for multi-reader scenarios, reducing latency from 500ms (cloud) to <50ms (edge cache)
3. **Selective Cloud Sync**: Event-driven uploads (defects, anomalies, incidents only) reduce cloud egress costs by 90%+ compared to full sync
4. **Crash Recovery**: Persistent storage enables inference services to recover from pod failures without data loss (unlike volatile `/dev/shm` ring buffers)
5. **High Availability**: Optional ACSA replication for mission-critical scenarios (predictive maintenance, safety monitoring)

**Sizing Guidelines**:

| Scenario | Cameras | Hot Tier (NVMe) | Warm Tier (SSD) | Typical TCO Savings |
|----------|---------|-----------------|-----------------|---------------------|
| Manufacturing QC | 4-6 | 50-80GB | 500GB | $2,930 over 3 years |
| Predictive Maintenance | 2 (thermal+visual) | 30-50GB | 1TB | $680 over 3 years |
| Smart Building | 8-12 | 100-150GB | 2TB | $3,629 over 3 years |
| Industrial Process | 4-6 | 60-100GB | 1TB (video+sensors) | $2,268 over 3 years |

**Integration with Real-Time Inference**:

ACSA storage tiers map to the [Real-Time Vision Inference Architecture](../../solution-adr-library/real-time-vision-inference-architecture.md) phases:

- **Phase 1 (Optimized Snapshots)**: ACSA warm tier provides persistent backing for 500ms-1s snapshot intervals
- **Phase 2 (Buffered Streams)**: ACSA hot tier complements `/dev/shm` ring buffers for multi-pod access and durability

For detailed configuration including PVC definitions, performance tuning, multi-modal synchronization, Fabric RTI integration, and monitoring, see the comprehensive [ACSA Storage Architecture for Vision Workloads](../../getting-started/acsa-storage-architecture-for-vision.md) guide.

### Financial Analysis and ROI

**Total Cost of Ownership (TCO) - 3 Year Analysis**:

All business outcome savings figures in scenario descriptions represent **gross savings** (operational impact only). For accurate ROI assessment, organizations must account for the complete solution TCO:

**Initial Capital Expenditure (CapEx)**:

| Component                          | Single Site/Line | Multi-Site (5x) | Notes                                      |
|------------------------------------|------------------|-----------------|--------------------------------------------|
| Edge compute hardware              | $15-25K          | $75-125K        | 16-core server, optional GPU               |
| ONVIF cameras (4-8 per site)       | $8-16K           | $40-80K         | Industrial IP cameras, PoE                 |
| Network infrastructure             | $5-10K           | $25-50K         | Switches, cabling, VLANs                   |
| Installation and commissioning     | $10-20K          | $50-100K        | Professional services, integration         |
| **Total CapEx**                    | **$38-71K**      | **$190-355K**   |                                            |

**Annual Operating Expenditure (OpEx)**:

| Component                          | Single Site/Line | Multi-Site (5x) | Notes                                      |
|------------------------------------|------------------|-----------------|--------------------------------------------|
| Azure IoT Operations licensing     | $3-6K            | $15-30K         | Per-node subscription                      |
| Azure cloud services               | $2-4K            | $10-20K         | Storage, compute, Event Hubs, networking   |
| Network bandwidth                  | $1-2K            | $5-10K          | Cloud sync, video uploads                  |
| Support and maintenance            | $4-8K            | $20-40K         | System updates, troubleshooting            |
| Model retraining and MLOps         | $2-4K            | $10-20K         | Azure ML compute, data science time        |
| **Total Annual OpEx**              | **$12-24K**      | **$60-120K**    |                                            |

**3-Year TCO**: Single site = $74-143K | Multi-site (5x) = $370-715K

**Net ROI Calculations by Scenario**:

**Scenario 1 - Manufacturing Quality Control**:

- **Gross Savings**: $50-75K per line annually
- **3-Year Gross Savings**: $150-225K per line
- **3-Year TCO**: $74-143K per line
- **Net Savings**: $76-82K per line (51-57% net margin)
- **Payback Period**: 18-24 months
- **3-Year ROI**: 103-205%

**Scenario 3 - Predictive Maintenance**:

- **Gross Savings**: $100-200K annually (downtime reduction + avoided failures)
- **3-Year Gross Savings**: $300-600K
- **3-Year TCO**: $74-143K (single site)
- **Net Savings**: $226-457K (75-76% net margin)
- **Payback Period**: 6-12 months
- **3-Year ROI**: 305-776%

**Scenario 6 - Connected Product Telemetry**:

- **Gross Savings**: $200-400K annually (avoided truck rolls for 500 assets)
- **3-Year Gross Savings**: $600-1200K
- **3-Year TCO**: $370-715K (multi-site, 5 locations)
- **Net Savings**: $230-485K (38-40% net margin)
- **Payback Period**: 12-18 months
- **3-Year ROI**: 62-131%

**Scenario 7 - Multi-Site Energy Monitoring**:

- **Gross Savings**: $75-150K per building annually (HVAC optimization)
- **3-Year Gross Savings**: $225-450K per building
- **3-Year TCO**: $74-143K per building
- **Net Savings**: $151-307K per building (67-68% net margin)
- **Payback Period**: 12-18 months
- **3-Year ROI**: 204-415%

**Scenario 8 - Legacy Equipment Integration**:

- **Gross Savings**: $2-5M (avoided equipment replacement CapEx)
- **Operational Improvement**: $100-200K annually (faster diagnostics, reduced downtime)
- **3-Year Total Value**: $2.3-5.6M
- **3-Year TCO**: $370-715K (multi-site integration)
- **Net Savings**: $1.93-4.89M (84-87% net margin)
- **Payback Period**: 3-6 months
- **3-Year ROI**: 522-1321%

**Key ROI Drivers**:

1. **Avoided CapEx** (Scenario 8): Legacy equipment replacement avoidance delivers highest ROI
2. **Downtime Reduction** (Scenario 3): Predictive maintenance prevents catastrophic failures
3. **Quality Improvement** (Scenario 1): Reduced scrap/rework with consistent payback
4. **Energy Optimization** (Scenario 7): Continuous savings with minimal ongoing costs
5. **Service Efficiency** (Scenario 6): Scales effectively across large installed bases

**Cost Optimization Strategies**:

- **Shared Edge Infrastructure**: Deploy multiple scenarios on same edge compute (amortize hardware costs)
- **Cloud Cost Management**: Use Azure Container Storage edge caching to minimize cloud egress
- **Phased Rollout**: Start with highest-ROI scenarios (predictive maintenance, legacy integration)
- **Open-Source Models**: Use pre-trained models initially to reduce ML development costs
- **Hybrid Licensing**: Combine Azure IoT Operations with existing Arc/Kubernetes investments

### Security and Privacy

**Privacy-Preserving Design**:

- Edge processing (no raw video to cloud unless configured)
- Configurable retention policies (7-30 days typical)
- Zone-level aggregation for occupancy (no PII)
- Role-based access control (RBAC)
- Audit logging for all video access

**Security Controls**:

- TLS 1.3 encryption for all MQTT communication
- Mutual TLS (mTLS) for camera connections
- Azure Key Vault for credential management
- Network segmentation (cameras on isolated VLAN)
- Regular security updates via Azure IoT Operations

### Data Management

**Video Storage Strategy**:

- Edge: 7-30 days rolling retention (Azure Container Storage Accelerator)
- Cloud: Event-based long-term storage (Azure Blob Storage)
- Compression: H.265 codec for bandwidth efficiency
- Tiering: Hot (edge) → Cool (cloud) → Archive (compliance)

**Data Sync and Bandwidth**:

- Inference results: Real-time MQTT (< 1 KB/inference)
- Video segments: Background sync (10-50 MB/event)
- Aggregated metrics: Hourly/daily batches (< 1 MB/day)
- Bandwidth savings: 85% reduction vs cloud-only processing

### Model Development Lifecycle

**Phase 1 - Baseline Models** (Pilot):

- Pre-trained models (TinyYOLOv2, MobileNet)
- Generic defect/object detection
- 80-90% accuracy expected

**Phase 2 - Custom Models** (Pilot Expansion):

- Site-specific training data (1000-10000 images)
- Transfer learning from baseline
- 90-95% accuracy target

**Phase 3 - Continuous Improvement** (Production):

- Automated data collection from production
- Weekly/monthly model retraining
- 95-99% accuracy sustained

**Model Training Stack**:

- Azure Machine Learning for cloud training
- ONNX export for edge deployment
- MLOps pipeline for automated retraining
- A/B testing for model validation

### Deployment Approach

**Recommended Pilot Sequence**:

1. **POC** (3 weeks): Single camera, simulated environment
2. **Pilot** (8-12 weeks): 1 production line/zone, 2-4 cameras
3. **Expansion** (6 months): 5-10 lines/zones, model refinement
4. **Production** (12-18 months): Enterprise-wide rollout

**Success Criteria per Phase**:

- POC: Technical feasibility, 80%+ accuracy
- Pilot: Operational validation, 90%+ accuracy, ROI projection
- Expansion: Business value confirmation, model stability
- Production: Sustained performance, organizational adoption

## Deployment Guide: Building Vision-on-Edge Scenarios

### Reference Implementation and Component Foundation

All vision-on-edge scenarios are built on the **Azure IoT Operations platform** with edge Kubernetes clusters. For development, testing, and component integration examples, the repository provides the **`full-single-node-cluster` blueprint** as a reference implementation:

- Azure IoT Operations (production-ready release) on a K3s Kubernetes cluster
- Cloud resources (Key Vault, Storage, Container Registry, Schema Registry)
- Edge compute orchestration with Azure Arc integration
- MQTT broker for real-time messaging
- Azure Container Storage Accelerator for video buffering

**Note**: Production deployments typically use on-premises edge hardware rather than cloud-hosted VMs. The blueprint serves as a reference for component integration patterns and can be adapted for physical edge infrastructure.

**Blueprint Location**: `/blueprints/full-single-node-cluster/`

**Supported Deployment Methods**:

- **Terraform** (recommended): Infrastructure as Code with full automation
- **Bicep**: Native Azure ARM template deployment

### Step-by-Step Deployment

#### Prerequisites

Before deploying any vision scenario:

1. **Azure Subscription**:
   - Active Azure subscription with Owner or Contributor role
   - Resource provider registration (automated by blueprint)
   - Sufficient quota for VMs in target region

2. **Development Environment**:
   - VS Code with devcontainer support (recommended)
   - OR manual install: Terraform 1.9.8+, Azure CLI, kubectl, Docker

3. **Network Planning**:
   - Define edge node network configuration
   - Plan camera network segmentation (dedicated VLAN recommended)
   - Verify internet connectivity for Azure services (50-100 Mbps)

4. **Camera Inventory**:
   - List ONVIF-compliant IP cameras with IP addresses
   - Camera credentials (username/password if authentication enabled)
   - Camera capabilities (H.264/H.265, PTZ, resolution)

#### Phase 1: Deploy Base Infrastructure (Terraform)

Follow the comprehensive deployment instructions in the [full-single-node-cluster blueprint README](../../../blueprints/full-single-node-cluster/README.md), which covers:

- Repository cloning and environment setup
- Terraform configuration and variable requirements
- Step-by-step deployment process
- Verification and troubleshooting steps

**Vision-Specific Configuration**:

For vision scenarios, ensure your `terraform.tfvars` includes:

```hcl
# Base configuration (see blueprint README for all required variables)
environment      = "pilot"         # dev, test, pilot, prod
resource_prefix  = "vision"        # Short unique identifier (max 8 chars)
location         = "eastus2"       # Azure region
instance         = "001"           # Deployment instance number

# Vision-specific settings
should_create_anonymous_broker_listener = true  # Set to false for production
```

#### Phase 2: Enable Vision Components

#### Option A: Deploy All Vision Components (Recommended)

Add to your `terraform.tfvars`:

```hcl
# Enable ONVIF Connector for camera discovery
should_enable_akri_onvif_connector = true

# Enable Media Connector for visual context
should_enable_akri_media_connector = true

# Configure camera devices and media capture tasks
# See Phase 4 below for detailed namespaced_devices and namespaced_assets configuration
# Or reference the REST connector example in Scenario 8 for complete device/asset structure
```

**Apply Vision Configuration**:

```bash
# Apply updated configuration
terraform apply
```

#### Option B: Incremental Deployment

Deploy components one at a time for testing:

```hcl
# Step 1: ONVIF Connector only
should_enable_akri_onvif_connector = true
# terraform apply

# Step 2: Add Media Connector
should_enable_akri_media_connector = true
# terraform apply
```

#### Phase 3: Deploy AI Inference Service (Optional)

The `full-single-node-cluster` blueprint does **NOT** include AI inference services. If your scenario requires AI-powered vision analytics, you must deploy the AI inference service separately.

**Deploy AI Inference Service**:

The `507-ai-inference` component is a standalone application that must be deployed manually. See the [AI Inference Service documentation](../../../src/500-application/507-ai-inference/README.md) for:

- Deployment instructions (Docker Compose for local testing, Kubernetes for production)
- Model configuration and loading
- MQTT integration with Azure IoT Operations
- ONNX Runtime and Candle backend options

**Quick Example** (for development/testing):

```bash
cd /workspaces/edge-ai/src/500-application/507-ai-inference

# Start inference service locally (requires Docker Compose)
docker-compose up --build

# Or deploy to Kubernetes cluster (see component README for details)
kubectl apply -f charts/base/
```

**Note**: The blueprint provides the foundational MQTT broker and infrastructure. The AI inference service subscribes to camera snapshot topics and publishes inference results back to MQTT.

#### Phase 4: Configure Media Connector Tasks

**1. Add Camera Devices and Snapshot Tasks**:

Add to your `terraform.tfvars`:

```hcl
# Define camera devices
namespaced_devices = [
  {
    name         = "production-camera-01"
    display_name = "Production Line Camera 01"
    enabled      = true
    endpoints = {
      enabled = true
      inbound = {
        "camera-rtsp" = {
          endpoint_type = "Custom"
          address       = "rtsp://192.168.1.100:554/stream1"
          authentication = {
            method = "UsernamePassword"
            username_secret_ref = { name = "camera-credentials", key = "username" }
            password_secret_ref = { name = "camera-credentials", key = "password" }
          }
        }
      }
    }
  }
]

# Define snapshot tasks as assets
namespaced_assets = [
  {
    name         = "production-camera-snapshots"
    display_name = "Production Camera Snapshots for AI"
    enabled      = true
    device_ref = {
      device_name   = "production-camera-01"
      endpoint_name = "camera-rtsp"
    }
    datasets = [{
      name                  = "snapshots"
      data_source           = ""
      dataset_configuration = jsonencode({
        taskType        = "snapshot-to-mqtt"
        intervalSeconds = 1  # Capture every second
        quality         = 85
      })
      destinations = [{
        target = "Mqtt"
        configuration = {
          topic = "edge-ai/production/camera/snapshots"
        }
      }]
    }]
  }
]
```

**2. Apply Configuration**:

```bash
terraform apply
```

#### Phase 5: End-to-End Testing

**1. Monitor Component Health**:

```bash
# Check all vision components deployed by blueprint
kubectl get pods -n azure-iot-operations | grep -E "akri"

# View logs for media connector
kubectl logs -l app.kubernetes.io/name=akri-media-connector -n azure-iot-operations --tail=50

# View logs for ONVIF connector (if enabled)
kubectl logs -l app.kubernetes.io/name=onvif-connector -n azure-iot-operations --tail=50

# If you deployed AI inference service separately (NOT part of blueprint)
kubectl logs -l app=ai-edge-inference -n azure-iot-operations --tail=50
```

**2. Verify Camera Devices and Assets**:

```bash
# Check discovered devices and assets (use fully qualified resource types to avoid CRD conflicts)
kubectl get devices.namespaces.deviceregistry.microsoft.com,assets.namespaces.deviceregistry.microsoft.com -n azure-iot-operations

# Describe specific device to verify configuration
kubectl describe devices.namespaces.deviceregistry.microsoft.com production-camera-01 -n azure-iot-operations

# Describe asset to verify media task configuration
kubectl describe assets.namespaces.deviceregistry.microsoft.com production-camera-snapshots -n azure-iot-operations
```

**3. Test Media Connector Snapshots**:

```bash
# Subscribe to snapshot topic to verify media connector is publishing
kubectl exec -it mqtt-client -n azure-iot-operations -- \
  mosquitto_sub --host aio-broker --port 18883 \
    --username 'K8S-SAT' --pw $(cat /var/run/secrets/tokens/broker-sat) \
    --cafile /var/run/certs/ca.crt \
    --topic 'edge-ai/production/camera/snapshots' -v
```

**Note**: AI inference pipeline testing requires deploying the 507-ai-inference service separately (NOT included in blueprint). See the [AI Inference Service documentation](../../../src/500-application/507-ai-inference/README.md) for deployment instructions.

**4. Verify Cloud Sync**:

```bash
# Check Azure Blob Storage for captured video segments
az storage blob list \
  --account-name <storage-account-name> \
  --container-name quality-inspection-videos \
  --output table
```

### Scenario-Specific Configuration Examples

#### Manufacturing Quality Control

```hcl
# terraform.tfvars additions
should_enable_akri_onvif_connector = true
should_enable_akri_media_connector = true

# Configure multiple cameras per production line using namespaced_devices
# See Phase 4 example for complete namespaced_devices and namespaced_assets structure
# Example: Multiple cameras with RTSP endpoints for defect detection

# Note: AI model configuration is NOT a blueprint variable
# Deploy AI inference service separately (see 507-ai-inference component)
# Model configuration is done via ConfigMaps in the inference service deployment
```

#### Retail Customer Analytics

```hcl
# terraform.tfvars additions
should_enable_akri_onvif_connector = true

# Configure PTZ cameras using namespaced_devices with ONVIF endpoints
# See Phase 4 example for complete device and asset structure with RTSP endpoints
# ONVIF Connector discovers cameras and exposes PTZ controls via MQTT

# Note: People counting AI model is NOT configured via blueprint variables
# Deploy AI inference service separately with privacy-preserving configuration
# See 507-ai-inference component documentation for model deployment
```

#### Predictive Maintenance

```hcl
# terraform.tfvars additions
should_enable_akri_onvif_connector = true
should_enable_akri_media_connector = true

# Configure thermal + visual camera pairs using namespaced_devices
# Each camera defined with RTSP endpoint for media capture
# See Phase 4 example for complete device/asset structure

# Note: Multi-modal anomaly detection AI model is NOT configured here
# Deploy AI inference service separately with multi-modal fusion logic
# See 507-ai-inference component for custom model deployment
  model_path           = "/models/vibration-thermal-visual-fusion.onnx"
  confidence_threshold = 0.80
  multi_modal          = true
}
```

### Troubleshooting Common Deployment Issues

For general deployment issues (Custom Locations OID, VM size availability, resource naming, Arc-enabled Kubernetes connectivity, etc.), see the [Blueprint Deployment Troubleshooting](../../../blueprints/README.md#deployment-troubleshooting) section.

#### Issue: ONVIF cameras not discovered

```bash
# Check network connectivity from cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -X POST http://192.168.1.100/onvif/device_service

# Verify ONVIF connector logs
kubectl logs -l app.kubernetes.io/name=onvif-connector -n azure-iot-operations --tail=100
```

#### Issue: AI inference service fails to load model

**Note**: The AI inference service is **NOT deployed by the blueprint**. If you deployed it separately and encounter issues, see the [AI Inference Service documentation](../../../src/500-application/507-ai-inference/README.md) for troubleshooting.

Common troubleshooting steps (if AI inference service is deployed):

```bash
# Check if AI inference service is running (only if you deployed it separately)
kubectl get pods -l app=ai-edge-inference -n azure-iot-operations

# Check model ConfigMap (if created)
kubectl describe configmap ai-model-config -n azure-iot-operations

# Verify model files (if mounted)
kubectl exec -it deployment/ai-edge-inference -n azure-iot-operations -- \
  ls -lh /models/
```

#### Issue: Media Connector snapshots not appearing in MQTT

```bash
# Check media connector pod status
kubectl get pods -l app.kubernetes.io/name=akri-media-connector -n azure-iot-operations

# Verify media connector logs
kubectl logs -l app.kubernetes.io/name=akri-media-connector -n azure-iot-operations --tail=100

# Check device and asset configuration
kubectl describe device production-camera-01 -n azure-iot-operations
kubectl describe asset production-camera-snapshots -n azure-iot-operations

# Verify MQTT topic by subscribing
kubectl exec -it mqtt-client -n azure-iot-operations -- \
  mosquitto_sub --host aio-broker --port 18883 \
    --username 'K8S-SAT' --pw $(cat /var/run/secrets/tokens/broker-sat) \
    --cafile /var/run/certs/ca.crt \
    --topic 'edge-ai/production/camera/snapshots' -v
```

### Production Deployment Checklist

**General Azure IoT Operations Production Guidelines**:

For comprehensive production deployment guidance including security hardening, high availability, disaster recovery, monitoring, and operational best practices, see the [Azure IoT Operations Production Readiness Guidelines](https://learn.microsoft.com/azure/iot-operations/deploy-iot-ops/concept-production-guidelines).

**Vision-Specific Production Considerations**:

Before moving vision-on-edge scenarios to production, address these additional media and camera-specific requirements:

- [ ] **Camera Security and Credentials**:
  - [ ] Disable anonymous MQTT listener (`should_create_anonymous_broker_listener = false`)
  - [ ] Store camera credentials (RTSP, ONVIF authentication) in Azure Key Vault
  - [ ] Use Kubernetes secrets for camera access credentials, never hardcode in tfvars
  - [ ] Enable camera-side authentication (username/password or certificate-based)
  - [ ] Segment camera network on isolated VLAN with firewall rules

- [ ] **Video Data Management**:
  - [ ] Define video retention policies for edge (7-30 days) and cloud (event-based)
  - [ ] Configure Azure Container Storage quotas and cleanup policies
  - [ ] Implement data lifecycle management (hot → cool → archive tiers)
  - [ ] Establish backup procedures for critical video evidence
  - [ ] Configure video encryption at rest (edge storage) and in transit (RTSP/MQTT)

- [ ] **Camera Network and Bandwidth**:
  - [ ] Size edge storage for peak video buffering (camera count × retention × bitrate)
  - [ ] Configure video encoding for bandwidth constraints (H.265 preferred)
  - [ ] Implement MQTT QoS levels appropriate for video streaming (QoS 1 for snapshots)
  - [ ] Test failover behavior when cloud connectivity is lost
  - [ ] Monitor network bandwidth usage and camera stream health

- [ ] **Privacy and Compliance**:
  - [ ] Implement privacy-preserving techniques (zone-level aggregates for occupancy)
  - [ ] Configure camera field-of-view to exclude sensitive areas
  - [ ] Establish access controls and audit logging for video retrieval
  - [ ] Document data retention policies for compliance (GDPR, industry regulations)
  - [ ] Implement video redaction or masking if required

- [ ] **Performance and Scaling**:
  - [ ] Tune Media Connector snapshot intervals for AI inference requirements
  - [ ] Optimize AI inference batch sizes and threading for camera load
  - [ ] Configure Akri connector replica counts for camera discovery scale
  - [ ] Monitor edge compute resource utilization (CPU, memory, GPU, storage I/O)
  - [ ] Test system behavior under camera failure scenarios

- [ ] **Operational Readiness**:
  - [ ] Document camera placement diagrams with network topology
  - [ ] Create runbooks for camera replacement and reconfiguration
  - [ ] Establish monitoring for camera connectivity and stream health
  - [ ] Train operations team on ONVIF Connector and Media Connector troubleshooting
  - [ ] Define incident response procedures for video data loss or privacy breaches

## Next Steps for Customer Engagement

### Discovery Questions

**Business Context**:

1. What are your top 3 operational pain points related to quality/safety/efficiency?
2. What is your current approach to visual inspection/monitoring?
3. What business outcomes would justify a vision-on-edge investment?

**Technical Readiness**:

1. Do you have existing ONVIF-compliant IP cameras deployed?
2. What is your edge computing infrastructure (if any)?
3. What are your network connectivity constraints?

**Organizational Readiness**:

1. Who are the stakeholders (operations, IT, OT, security)?
2. What are your data privacy/security requirements?
3. What is your appetite for pilot investment and timeline?

### Pilot Proposal Framework

**Phase 1 - Technical Validation** (3 weeks, $15-25K):

- Deploy edge infrastructure to 1 pilot line/zone
- Connect 1-2 cameras with ONVIF Connector
- Demonstrate real-time video capture and AI inference
- Validate latency, accuracy, and system reliability

**Phase 2 - Business Validation** (8-12 weeks, $50-100K):

- Scale to production line/zone with 4-6 cameras
- Deploy custom AI models trained on customer data
- Integrate with existing systems (MES, SCADA, BMS, etc.)
- Measure business outcomes (quality improvement, cost savings, efficiency gains)

**Phase 3 - Production Rollout** (6-12 months, $200-500K):

- Scale to 5-10 lines/zones across 1-2 sites
- Implement MLOps for automated model retraining
- Enable cloud analytics and cross-site insights
- Transition to customer-managed operations

### Resources and Support

**Documentation**:

- [Getting Started Guide](../../getting-started/README.md)
- [ONVIF Connector Documentation](../../../src/500-application/510-onvif-connector/README.md)
- [Media Capture Service Documentation](../../../src/500-application/503-media-capture-service/README.md)
- [AI Inference Service Documentation](../../../src/500-application/507-ai-inference/README.md)

**Reference Architectures**:

- [Digital Inspection Scenario](./digital-inspection-survey/README.md)
- [Quality Process Optimization](./quality-process-optimization-automation/README.md)
- [Predictive Maintenance Scenario](./predictive-maintenance/README.md)

---

*AI and automation capabilities described in these scenarios should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

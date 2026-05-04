# Blob Storage Organization Diagram

This diagram shows the hierarchical structure and organization of video segments in Azure Blob Storage, including path organization, metadata, and lifecycle management.

## Container Structure

**Container Name**: `media-capture-data`

### Path Hierarchy

```text
media-capture-data/
├── a1/                          # Hash prefix (2 hex chars)
│   └── camera-01/               # Camera ID
│       └── 2026/                # Year
│           └── 01/              # Month
│               └── 20/          # Day
│                   ├── 10/      # Hour
│                   │   ├── video-2026-01-20T10-00-00Z.mp4       # Video segment
│                   │   ├── video-2026-01-20T10-00-00Z.json      # Metadata
│                   │   ├── video-2026-01-20T10-05-00Z.mp4
│                   │   └── video-2026-01-20T10-05-00Z.json
│                   └── 11/
│                       └── ...
└── b2/                          # Different hash prefix
    └── camera-02/
        └── ...
```

## Storage Organization Features

### 1. Hash Prefix Distribution

- **Purpose**: Load balancing and performance optimization
- **Format**: First 2 characters of MD5 hash of camera ID
- **Example**: camera-01 → MD5(camera-01) → a1b2c3d4... → prefix "a1"
- **Benefit**: Distributes camera data across multiple storage partitions

### 2. Hierarchical Folder Structure

- **Year/Month/Day/Hour**: Logical organization for time-based queries
- **Fast navigation** to specific time ranges
- **Efficient indexing** with Blob Index Tags

### 3. File Naming Convention

```text
video-{YYYY}-{MM}-{DD}T{HH}-{mm}-{ss}Z.mp4
```

- ISO 8601 format with UTC timezone
- Sortable and parseable filenames
- Example: `video-2026-01-20T10-00-00Z.mp4`

### 4. Metadata Files

Each video segment has a companion JSON metadata file:

```json
{
  "camera_id": "camera-01",
  "location": "Building-A/Floor-2/Zone-3",
  "segment_start": "2026-01-20T10:00:00Z",
  "segment_end": "2026-01-20T10:05:00Z",
  "duration_seconds": 300,
  "file_path": "/media-capture-backed-acsa/a1/camera-01/2026/01/20/10/video-2026-01-20T10-00-00Z.mp4"
}
```

**Metadata Field Descriptions**:

- `camera_id`: Unique identifier for the camera
- `location`: Physical location of the camera (e.g., building/floor/zone)
- `segment_start`: Recording start timestamp in ISO 8601 format (UTC)
- `segment_end`: Recording end timestamp in ISO 8601 format (UTC)
- `duration_seconds`: Segment duration in seconds (calculated from end - start)
- `file_path`: Full ACSA volume path to the video file

## Blob Index Tags

Each video segment is tagged for efficient querying:

| Tag Name         | Example Value        | Purpose                          |
|------------------|----------------------|----------------------------------|
| camera_id        | camera-01            | Filter by specific camera        |
| start_time       | 2026-01-20T10:00:00Z | Filter by time range             |
| duration_seconds | 300                  | Find segments of specific length |
| tier             | hot/cool/archive     | Track current storage tier       |

**Query Example**:

```text
camera_id = 'camera-01' AND
start_time >= '2026-01-20T10:00:00Z' AND
start_time < '2026-01-20T11:00:00Z'
```

## Lifecycle Management Policies

### Automatic Tier Transitions

| Storage Tier | Age Range   | Cost per GB/month | Transition Rule |
|--------------|-------------|-------------------|-----------------|
| Hot          | 0-7 days    | $0.018            | Initial upload  |
| Cool         | 7-30 days   | $0.01             | After 7 days    |
| Archive      | 30-365 days | $0.0015           | After 30 days   |
| Deleted      | > 365 days  | $0                | After 1 year    |

### Transition Details

1. **Day 0**: Upload to Hot tier (immediate access)
2. **Day 7**: Move to Cool tier (access within hours)
3. **Day 30**: Move to Archive tier (rehydration required)
4. **Day 365**: Permanent deletion

### Cost Optimization Example

**Scenario**: 100GB video per camera per day

| Period      | Storage Amount | Tier      | Cost             |
|-------------|----------------|-----------|------------------|
| Days 0-7    | 700GB          | Hot       | $12.60/month     |
| Days 7-30   | 2,300GB        | Cool      | $23.00/month     |
| Days 30-365 | 33,500GB       | Archive   | $50.25/month     |
| **Total**   | **36,500GB**   | **Mixed** | **$85.85/month** |

**vs. keeping all in Hot tier**: $657/month
**Savings**: 87% cost reduction

## Query Optimization

### Efficient Query Patterns

1. **Use Blob Index Tags**: Faster than path-based filtering
2. **Narrow time ranges**: Request only needed segments
3. **Leverage hierarchical paths**: Navigate directly to year/month/day/hour
4. **Cache frequently accessed**: Keep recent queries in Hot tier longer

### Anti-Patterns to Avoid

- ❌ Listing entire container (use tags instead)
- ❌ Wide time ranges without filtering (query specific hours)
- ❌ Frequent archive rehydration (move back to Hot if needed regularly)
- ❌ Ignoring hash prefixes (they're essential for performance)

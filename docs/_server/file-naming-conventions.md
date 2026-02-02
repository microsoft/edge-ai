# File Naming Conventions for Progress Tracking

## Overview

This document defines the file naming conventions for all progress tracking files in the `.copilot-tracking/learning/` directory. These conventions ensure consistency, enable proper synchronization, and support schema validation across the entire learning system.

## Directory Structure

All progress tracking files are stored in:

```text
/.copilot-tracking/learning/
```

## File Naming Patterns

### Kata Progress Files

**Pattern**: `kata-progress-{kataId}-{timestamp}.json`

**Rules**:

- `kataId` must be in kebab-case format (e.g., `ai-development-fundamentals`)
- `timestamp` is ISO 8601 UTC format: `YYYY-MM-DDTHH-mm-ss-sssZ`
- File reuse: Same kataId updates existing file instead of creating new ones
- Maximum 5 files per kata for history tracking
- Auto-cleanup managed by progress system

**Examples**:

- `kata-progress-ai-development-fundamentals-2025-01-10T16-43-10-000Z.json`
- `kata-progress-prompt-engineering-basics-2025-01-10T16-45-30-125Z.json`

### Lab Progress Files

**Pattern**: `lab-progress-{labId}-{timestamp}.json`

**Rules**:

- `labId` must be in kebab-case format (e.g., `azure-iot-end-to-end`)
- `timestamp` is ISO 8601 UTC format: `YYYY-MM-DDTHH-mm-ss-sssZ`
- File reuse: Same labId updates existing file instead of creating new ones
- Multi-session support: Same lab file updated across multiple coaching sessions
- Maximum 5 files per lab for history tracking
- Auto-cleanup managed by progress system

**Examples**:

- `lab-progress-azure-iot-end-to-end-2025-01-10T16-43-10-000Z.json`
- `lab-progress-terraform-multi-environment-2025-01-10T16-45-30-125Z.json`

### Self-Assessment Files

**Pattern**: `self-assessment-{assessmentId}-{timestamp}.json`

**Rules**:

- `assessmentId` must be in kebab-case format (e.g., `learning-skill-assessment`)
- `timestamp` is ISO 8601 UTC format: `YYYY-MM-DDTHH-mm-ss-sssZ`
- File reuse: Same assessmentId updates existing file instead of creating new ones
- Support for multiple assessment types (skill-assessment, competency-evaluation, etc.)
- Maximum 5 files per assessment type for history tracking
- Auto-cleanup managed by progress system

**Examples**:

- `self-assessment-learning-skill-assessment-2025-01-10T16-43-10-000Z.json`
- `self-assessment-competency-evaluation-2025-01-10T16-45-30-125Z.json`

### Learning Path Files

**Pattern**: `path-progress-{pathId}-{timestamp}.json`

**Rules**:

- `pathId` must be in kebab-case format with category prefix (e.g., `category-ai-assisted-engineering`)
- `timestamp` is ISO 8601 UTC format: `YYYY-MM-DDTHH-mm-ss-sssZ`
- File reuse: Same pathId updates existing file instead of creating new ones
- Used for category-level and training lab tracking
- Maximum 5 files per path for history tracking
- Auto-cleanup managed by progress system

**Examples**:

- `path-progress-category-ai-assisted-engineering-2025-01-10T16-43-10-000Z.json`
- `path-progress-lab-azure-iot-2025-01-10T16-45-30-125Z.json`

## Schema Validation

Each file type must conform to its corresponding schema:

- **Kata Progress**: `/docs/_server/schemas/kata-progress-schema.json`
- **Lab Progress**: `/docs/_server/schemas/lab-progress-schema.json`
- **Self-Assessment**: `/docs/_server/schemas/self-assessment-schema.json`
- **Learning Path**: Schema referenced in existing path progress files

## Identifier Consistency Rules

### KataId Consistency

- Must match the kata directory structure in `/learning/katas/`
- Use kebab-case format: `ai-development-fundamentals`
- Do not include category prefix in kataId
- Category information stored in metadata section

### LabId Consistency

- Must match the lab directory structure in `/learning/training-labs/`
- Use kebab-case format: `azure-iot-end-to-end`
- Include descriptive context: `terraform-multi-environment`
- Lab type information stored in metadata section

### AssessmentId Consistency

- Use descriptive kebab-case format: `learning-skill-assessment`
- Include assessment type context: `competency-evaluation`
- Assessment type enum stored in metadata section

## File Management Strategy

### Intelligent File Updates

- **Per-Item Updates**: Files are named with timestamp but **the same file is updated** for the same item
- **File Reuse**: When saving progress for an item that already has a file, the existing file gets updated instead of creating a new one
- **New Item = New File**: Only new items get new files
- **Auto-cleanup**: System maintains maximum 5 files per item for history
- **CRITICAL**: Must use consistent identifier values to ensure proper file grouping

### Source Tracking

All files must include source identification in metadata:

- `"source": "coach"` - Files created by coaching interactions
- `"source": "ui"` - Files created by website save operations
- `"source": "file-watcher"` - Files created by file system monitoring
- `"source": "server"` - Files created by progress server operations
- `"source": "import"` - Files created by data import operations
- `"source": "manual"` - Files created by manual operations

### Version Control

- All files include `"version"` field in metadata for compatibility tracking
- Schema version tracking enables migration support
- `"lastUpdated"` timestamp tracks file modification time

## Synchronization Support

### File Watcher Integration

- File names enable proper file monitoring and change detection
- Timestamp comparison supports conflict resolution
- Source tracking prevents circular update loops
- Coach and UI systems coordinate through file naming

### Progress Server Integration

- RESTful API endpoints map to file naming patterns
- CORS-enabled for cross-origin synchronization
- Debounced auto-save prevents file system thrashing
- Batch operations support multiple file updates

## Best Practices

### For Coaches

1. **Use consistent identifiers** - Always use the same kataId/labId/assessmentId format
2. **Set source to "coach"** - Always use `"source": "coach"` in metadata
3. **Include meaningful timestamps** - Use ISO 8601 UTC format for all timestamps
4. **Document coaching interactions** - Include coaching notes and recommendations
5. **Track competency development** - Note specific skills being demonstrated

### For UI Integration

1. **Validate before save** - Ensure schema compliance before writing files
2. **Set source to "ui"** - Always use `"source": "ui"` in metadata
3. **Handle sync conflicts** - Check for newer files before overwriting
4. **Provide user feedback** - Show save status and sync information
5. **Support offline mode** - Queue operations when server unavailable

### For Server Operations

1. **Enforce schema validation** - Reject files that don't match schema
2. **Implement rate limiting** - Prevent excessive file system operations
3. **Support batch operations** - Handle multiple file updates efficiently
4. **Monitor file system health** - Track disk usage and performance
5. **Implement backup strategy** - Regular backup of learning progress data

## Migration and Compatibility

### Version Compatibility

- Schema version tracking enables automatic migration
- Backward compatibility maintained for at least 2 major versions
- Forward compatibility warnings for newer schema versions

### File Format Migration

- Automated migration tools for schema updates
- Batch processing for large-scale migrations
- Rollback support for migration failures

## Error Handling

### Invalid File Names

- System rejects files that don't match naming patterns
- Error messages include proper naming format examples
- Automatic correction suggestions for common mistakes

### Duplicate Files

- System prevents creation of duplicate files for same item
- Automatic merging of conflicting progress data
- History preservation during conflict resolution

### Schema Validation Errors

- Detailed error messages for schema violations
- Automatic recovery for minor schema issues
- Manual intervention support for complex conflicts

## Implementation Notes

This document serves as the authoritative reference for file naming conventions. All components of the progress tracking system must adhere to these conventions to ensure proper synchronization and data integrity.

For implementation details, refer to:

- `/docs/_server/schemas/` - Schema definitions
- `/docs/_server/PROGRESS-SYSTEM.md` - System architecture
- `/learning/kata-progress-tracking.md` - User guide
- `/.github/agents/learning-*-coach.agent.md` - Coach integration

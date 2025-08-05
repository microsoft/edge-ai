/*
 * EventStream DAG Node Configuration
 */

variable "streams_default" {
  type = list(object({
    name       = optional(string, null)
    properties = optional(object({}), {})
    inputNodes = list(string)
  }))
  description = <<-EOT
    DefaultStream required.

    List of Default Streams one or more sources to one or more destination

    ## Properties

    - `name`: Unique name for the DefaultStream - default: es-{var.resource_prefix}-{var.environment}-{var.instance}-stream
    - `properties`: Always an empty object
    - `inputNodes`: List of sources to provide DefaultStream
  EOT
  default     = []
}

variable "sources_custom_endpoints" {
  type = list(object({
    name       = string
    properties = optional(object({}), {})
  }))
  description = <<-EOT
    List of CustomEndpoint sources with their configuration.

    Custom Endpoint sources provide an endpoint URL for external applications to send data to the EventStream.
    The endpoint handles authentication and data ingestion automatically.

    ## Properties

    - `name`: Unique name for the source within the EventStream
  EOT
  default     = []
}

variable "destinations_eventhouse" {
  type = list(object({
    name       = string
    inputNodes = list(string)
    properties = object({
      dataIngestionMode = optional(string, "ProcessedIngestion")
      workspaceId       = string
      itemId            = string
      databaseName      = string
      tableName         = optional(string, null)
      inputSerialization = optional(object({
        type = optional(string, "Json")
        properties = optional(object({
          encoding = optional(string, "UTF8")
          }), {
          encoding = "UTF8"
        })
        }), {
        type = "Json"
        properties = {
          encoding = "UTF8"
        }
      })
    })
  }))
  description = <<-EOT
    List of Eventhouse destinations with their configuration and input connections.

    Eventhouse destinations route processed data to KQL databases for real-time analytics and querying.
    When workspaceId, itemId, or databaseName are not provided, the component uses automatically
    configured references from the fabric_workspace and fabric_eventhouse dependencies.

    ## Properties

    - `name`: Unique name for the destination within the EventStream
    - `inputNodes`: List of source or operator node names that feed into this destination
    - `properties.dataIngestionMode`: Ingestion mode ("DirectIngestion", "ProcessedIngestion") - default: "ProcessedIngestion"
    - `properties.workspaceId`: Fabric workspace ID
    - `properties.itemId`: Eventhouse Database ID
    - `properties.databaseName`: KQL database name
    - `properties.tableName`: Target KQL table name (optional for direct ingestion, auto-created if not specified)
    - `properties.inputSerialization`: Data serialization configuration
      - `type`: Serialization format ("Json", "Avro", "Csv") - default: "Json"
      - `properties.encoding`: Character encoding ("UTF8", "UTF16", "UTF32") - default: "UTF8"
  EOT
  default     = []
}

variable "destinations_lakehouse" {
  type = list(object({
    name       = string
    inputNodes = list(string)
    properties = object({
      workspaceId              = string
      itemId                   = string
      schema                   = optional(string, "dbo")
      deltaTable               = string
      minimumRows              = optional(number, 100000)
      maximumDurationInSeconds = optional(number, 120)
      inputSerialization = optional(object({
        type = optional(string, "Json")
        properties = optional(object({
          encoding = optional(string, "UTF8")
          }), {
          encoding = "UTF8"
        })
        }), {
        type = "Json"
        properties = {
          encoding = "UTF8"
        }
      })
    })
  }))
  description = <<-EOT
    List of Lakehouse destinations with their configuration and input connections.

    Lakehouse destinations route processed data to Delta tables in Fabric Lakehouses for data lake analytics.
    When workspaceId or itemId are not provided, the component uses automatically configured references.

    ## Properties

    - `name`: Unique name for the destination within the EventStream
    - `inputNodes`: List of source or operator node names that feed into this destination
    - `properties.workspaceId`: Fabric workspace ID (optional, defaults to component workspace)
    - `properties.itemId`: Lakehouse item ID (optional, requires explicit configuration)
    - `properties.schema`: Schema name within the lakehouse (optional) - default: "dbo"
    - `properties.deltaTable`: Target Delta table name (required)
    - `properties.minimumRows`: Minimum number of rows to buffer before writing to Delta table - default: 100000
    - `properties.maximumDurationInSeconds`: Maximum time in seconds to buffer before forcing write - default: 120
    - `properties.inputSerialization`: Data serialization configuration
      - `type`: Serialization format ("Json", "Avro", "Csv") - default: "Json"
      - `properties.encoding`: Character encoding ("UTF8", "UTF16", "UTF32") - default: "UTF8"
  EOT
  default     = []
}

variable "streams_derived" {
  type = list(object({
    name       = string
    inputNodes = list(string)
    properties = optional(object({
      inputSerialization = optional(object({
        type = optional(string, "Json")
        properties = optional(object({
          encoding = optional(string, "UTF8")
          }), {
          encoding = "UTF8"
        })
        }), {
        type = "Json"
        properties = {
          encoding = "UTF8"
        }
      })
    }), {})
  }))
  description = <<-EOT
    List of DerivedStream configurations with their input connections.

    DerivedStreams are processed data streams that result from operator transformations.
    They can be consumed by destinations or used as inputs to other operators.

    ## Properties

    - `name`: Unique name for the derived stream within the EventStream
    - `inputNodes`: List of operator node names that produce data for this stream
    - `properties.inputSerialization`: Data serialization configuration
      - `type`: Serialization format ("Json", "Avro", "Csv") - default: "Json"
      - `properties.encoding`: Character encoding ("UTF8", "UTF16", "UTF32") - default: "UTF8"
  EOT
  default     = []
}

variable "operators_filter" {
  type = list(object({
    name       = string
    inputNodes = list(string)
    properties = object({
      conditions = list(object({
        column = object({
          node           = optional(string)
          columnName     = string
          columnPath     = optional(string)
          expressionType = optional(string, "ColumnReference")
        })
        operatorType = string
        value = object({
          dataType       = optional(string, "String")
          value          = string
          expressionType = optional(string, "Literal")
        })
      }))
    })
  }))
  description = <<-EOT
    List of Filter operators with their conditions and input connections.

    Filter operators evaluate conditions on streaming data and only pass events that meet all specified criteria.
    Multiple conditions are combined with logical AND operations.

    ## Properties

    - `name`: Unique name for the filter operator within the EventStream
    - `inputNodes`: List of source or stream node names that feed into this operator
    - `properties.conditions`: Array of filter conditions to evaluate
      - `column.node`: Reference node name (optional, null for same stream)
      - `column.columnName`: Name of the field/column to evaluate
      - `column.columnPath`: JSONPath for nested fields (optional)
      - `column.expressionType`: Expression type ("ColumnReference") - default: "ColumnReference"
      - `operatorType`: Comparison operator ("Equals", "NotEquals", "GreaterThan", "LessThan", "GreaterThanOrEqual", "LessThanOrEqual", "Contains", "StartsWith", "EndsWith")
      - `value.dataType`: Data type for comparison ("String", "Double", "Long", "Boolean", "DateTime") - default: "String"
      - `value.value`: The literal value to compare against (as string)
      - `value.expressionType`: Value expression type ("Literal") - default: "Literal"
  EOT
  default     = []
}

variable "operators_group_by" {
  type = list(object({
    name       = string
    inputNodes = list(string)
    properties = object({
      aggregations = list(object({
        aggregateFunction = string
        column = object({
          node       = optional(string)
          columnName = string
        })
        alias = string
      }))
      groupBy = list(object({
        node       = optional(string)
        columnName = string
      }))
      window = object({
        type = string
        properties = object({
          duration = object({
            value = number
            unit  = string
          })
          offset = optional(object({
            value = number
            unit  = string
          }))
        })
      })
    })
  }))
  description = <<-EOT
    List of GroupBy operators with their aggregation configuration and input connections.

    GroupBy operators group events by specified fields and apply aggregation functions within time windows.
    Results are emitted when the time window completes.

    ## Properties

    - `name`: Unique name for the GroupBy operator within the EventStream
    - `inputNodes`: List of source or stream node names that feed into this operator
    - `properties.aggregations`: Array of aggregation functions to apply
      - `aggregateFunction`: Function to apply ("Count", "Sum", "Average", "Min", "Max", "First", "Last")
      - `column.node`: Reference node name (optional, null for same stream)
      - `column.columnName`: Name of the field/column to aggregate ("*" for count operations)
      - `alias`: Output field name for the aggregation result
    - `properties.groupBy`: Array of fields to group by
      - `node`: Reference node name (optional, null for same stream)
      - `columnName`: Name of the field/column to group by
    - `properties.window`: Time window configuration
      - `type`: Window type ("Tumbling", "Hopping", "Session")
      - `properties.duration`: Window duration
        - `value`: Duration value (number)
        - `unit`: Time unit ("Second", "Minute", "Hour", "Day")
      - `properties.offset`: Window offset (optional, for Hopping windows)
        - `value`: Offset value (number)
        - `unit`: Time unit ("Second", "Minute", "Hour", "Day")
  EOT
  default     = []
}

variable "operators_join" {
  type = list(object({
    name       = string
    inputNodes = list(string)
    properties = object({
      joinType = string
      joinOn = list(object({
        left = object({
          node       = string
          columnName = string
        })
        right = object({
          node       = string
          columnName = string
        })
      }))
      duration = object({
        value = number
        unit  = string
      })
    })
  }))
  description = <<-EOT
    List of Join operators with their join configuration and input connections.

    Join operators combine data from two input streams based on matching key fields within a time window.
    The operator maintains a buffer of events from both streams for the specified duration.

    ## Properties

    - `name`: Unique name for the Join operator within the EventStream
    - `inputNodes`: List of exactly two source or stream node names (left and right streams)
    - `properties.joinType`: Type of join operation ("Inner", "LeftOuter")
    - `properties.joinOn`: Array of join conditions specifying field mappings
      - `left.node`: Name of the left stream node
      - `left.columnName`: Field name in the left stream to join on
      - `right.node`: Name of the right stream node
      - `right.columnName`: Field name in the right stream to join on
    - `properties.duration`: Time window for maintaining join state
      - `value`: Duration value (number)
      - `unit`: Time unit ("Second", "Minute", "Hour", "Day")
  EOT
  default     = []
}

variable "operators_manage_fields" {
  type = list(object({
    name       = string
    inputNodes = list(string)
    properties = object({
      columns = list(object({
        type = string
        properties = optional(object({
          column = optional(object({
            node       = optional(string)
            columnName = string
          }))
          targetDataType = optional(string)
          expression     = optional(string)
        }))
        alias = optional(string)
      }))
    })
  }))
  description = <<-EOT
    List of ManageFields operators with their field operations and input connections.

    ManageFields operators modify the schema of streaming data by adding, removing, renaming,
    or casting fields. Multiple operations can be applied in sequence.

    ## Properties

    - `name`: Unique name for the ManageFields operator within the EventStream
    - `inputNodes`: List of source or stream node names that feed into this operator
    - `properties.columns`: Array of field operations to perform
      - `type`: Operation type ("Add", "Remove", "Rename", "Cast")
      - `properties.column`: Source field reference (required for Remove, Rename, Cast)
        - `node`: Reference node name (optional, null for same stream)
        - `columnName`: Name of the source field
      - `properties.targetDataType`: Target data type for Cast operations ("String", "Double", "Long", "Boolean", "DateTime")
      - `properties.expression`: Expression for Add operations (literal value or formula)
      - `alias`: New field name (required for Add, Rename, Cast operations)
  EOT
  default     = []
}

variable "operators_aggregate" {
  type = list(object({
    name       = string
    inputNodes = list(string)
    properties = object({
      aggregations = list(object({
        aggregateFunction = string
        column = object({
          node       = optional(string)
          columnName = string
        })
        alias = string
        partitionBy = optional(list(object({
          node       = optional(string)
          columnName = string
        })), [])
        duration = object({
          value = number
          unit  = string
        })
      }))
    })
  }))
  description = <<-EOT
    List of Aggregate operators with their aggregation configuration and input connections.

    Aggregate operators calculate rolling aggregations over time windows with optional partitioning.
    Unlike GroupBy, Aggregate operators emit results continuously as events arrive.

    ## Properties

    - `name`: Unique name for the Aggregate operator within the EventStream
    - `inputNodes`: List of source or stream node names that feed into this operator
    - `properties.aggregations`: Array of aggregation functions to apply
      - `aggregateFunction`: Function to apply ("Count", "Sum", "Average", "Min", "Max", "First", "Last")
      - `column.node`: Reference node name (optional, null for same stream)
      - `column.columnName`: Name of the field/column to aggregate ("*" for count operations)
      - `alias`: Output field name for the aggregation result
      - `partitionBy`: Array of fields to partition aggregations by (optional)
        - `node`: Reference node name (optional, null for same stream)
        - `columnName`: Name of the field/column to partition by
      - `duration`: Time window for the aggregation
        - `value`: Duration value (number)
        - `unit`: Time unit ("Second", "Minute", "Hour", "Day")
  EOT
  default     = []
}

variable "operators_union" {
  type = list(object({
    name       = string
    inputNodes = list(string)
    properties = optional(object({}), {})
  }))
  description = <<-EOT
    List of Union operators with their input connections.

    Union operators combine multiple streams with matching field schemas into a single output stream.
    All input streams must have compatible schemas (same field names and types).

    ## Properties

    - `name`: Unique name for the Union operator within the EventStream
    - `inputNodes`: List of two or more source or stream node names to combine
    - `properties`: Empty object (no additional configuration required)
  EOT
  default     = []
}

variable "operators_expand" {
  type = list(object({
    name       = string
    inputNodes = list(string)
    properties = object({
      column = object({
        node       = optional(string)
        columnName = string
      })
      ignoreMissingOrEmpty = optional(bool, false)
    })
  }))
  description = <<-EOT
    List of Expand operators with their expansion configuration and input connections.

    Expand operators flatten array fields by creating separate output events for each array element.
    This is useful for processing nested JSON structures with arrays.

    ## Properties

    - `name`: Unique name for the Expand operator within the EventStream
    - `inputNodes`: List of source or stream node names that feed into this operator
    - `properties.column`: Array field to expand
      - `node`: Reference node name (optional, null for same stream)
      - `columnName`: Name of the array field to expand
    - `properties.ignoreMissingOrEmpty`: Whether to ignore missing or empty arrays (default: false)
      - `true`: Skip events with missing/empty arrays
      - `false`: Pass through events with missing/empty arrays unchanged
  EOT
  default     = []
}

/*
 * EventStream Properties Configuration
 */

variable "retention_days" {
  type        = number
  description = <<-EOT
    Retention days for the EventStream data storage.

    This setting controls how long event data is retained in the EventStream before automatic cleanup.
    Affects both stream buffer and historical data availability for replay scenarios.

    Valid range: 1-90 days
  EOT
  default     = 7
}

variable "throughput_level" {
  type        = string
  description = <<-EOT
    Event throughput level optimization for EventStream performance.

    Controls the underlying resource allocation and performance characteristics:

    - "Low": Up to 1 MB/s throughput, suitable for development and low-volume scenarios
    - "Medium": Up to 5 MB/s throughput, balanced performance for most production workloads
    - "High": Up to 10 MB/s throughput, maximum performance for high-volume scenarios

    Higher levels may incur additional costs but provide better performance guarantees.
  EOT
  default     = "Medium"
}

/*
 * Optional Template File Override Configuration
 */

variable "eventstream_template_file_path" {
  type        = string
  description = <<-EOT
    Optional file path to custom eventstream.json template for advanced scenarios.

    When provided, this template file will be used instead of the auto-generated DAG configuration.
    The template should be a Go text/template format file that will be processed with the
    tokens provided in the template_tokens variable.

    Use this for:

    - Complex EventStream configurations not supported by the DAG variables
    - Custom JSON structures requiring specific formatting
    - Advanced template-based configuration management

    If null (default), the component generates the EventStream definition from DAG variables.
  EOT
  default     = null
}

variable "template_tokens" {
  type        = map(string)
  description = <<-EOT
    Optional map of template tokens for custom template file substitution.

    Used when eventstream_template_file_path is provided to replace placeholders
    in the custom template file. Token keys should match placeholders in the template.

    Example template placeholders:

    - `{{.WorkspaceId}}` - Fabric workspace identifier
    - `{{.DatabaseName}}` - KQL database name
    - `{{.Content}}` - JSON content (when using auto-generated configuration)

    When eventstream_template_file_path is null, this map is ignored and auto-generated
    tokens are used instead.
  EOT
  default     = {}
}

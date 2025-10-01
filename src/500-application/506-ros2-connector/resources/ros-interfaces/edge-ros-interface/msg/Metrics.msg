# Metrics.msg

# This file defines a Metrics message.

# The source of this message.
string source

# The timestamp of the metric.
# This field represents the timestamp of the metric using the builtin_interfaces/Time message type.
builtin_interfaces/Time timestamp

# The values of the metric.
# This field represents an array of MetricValue messages, which contain the actual values of the metric.
edge_ros_interface/MetricValue[] values

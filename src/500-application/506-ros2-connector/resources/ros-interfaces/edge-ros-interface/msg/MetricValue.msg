# This file defines the unit constants for the MetricValue message.
#
# The MetricValue message represents a metric value along with its unit.
# It provides constants for different unit types such as unknown, raw, percent, and degrees Celsius.

# Unit constants
uint8 UNIT_UNKNOWN=0
uint8 UNIT_RAW=1
uint8 UNIT_PERCENT=2
uint8 UNIT_DEG_CELSIUS=3
uint8 UNIT_GIGA_BYTES=4
uint8 UNIT_VOLT=5
uint8 UNIT_AMPERE=6

# Name of the value.
string name

# Unit type of the value.
uint8 unit

# Measured value
float64 value

# Lower limit of the value. If nan there is no limit
float64 lower_limit

# Upper limit of the value. If nan there is no limit
float64 upper_limit

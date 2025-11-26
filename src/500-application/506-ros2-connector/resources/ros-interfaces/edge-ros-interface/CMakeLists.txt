cmake_minimum_required(VERSION 3.22)

project(edge_ros_interface LANGUAGES C CXX)

# --------------------------------------------------------------------------------------------------

find_package(ament_cmake CONFIG REQUIRED)
find_package(rosidl_default_generators CONFIG REQUIRED)

find_package(builtin_interfaces CONFIG REQUIRED)


# ==================================================================================================

rosidl_generate_interfaces(${PROJECT_NAME}
  # System Sensing
  "msg/MetricValue.msg"
  "msg/Metrics.msg"
  DEPENDENCIES
    builtin_interfaces
)

# ==================================================================================================


# Silence a lot of `warning: redundant redeclaration of ... in same scope` warnings with enabled Unity builds.
if(TARGET ${PROJECT_NAME}__rosidl_typesupport_fastrtps_cpp)
  target_compile_options(${PROJECT_NAME}__rosidl_typesupport_fastrtps_cpp
                         PRIVATE -Wno-redundant-decls)
endif()

# ==================================================================================================

ament_export_dependencies(rosidl_default_runtime)

ament_package()

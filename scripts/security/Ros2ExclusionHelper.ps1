# ROS2 components rely on rolling tags; upstream prunes timestamped builds so matching assets are excluded. See docs/build-cicd/security-analysis-workflow.md.
function Get-Ros2ImageExclusionList {
    [OutputType([string[]])]
    param()

    return @(
        '*506-ros2-connector*',
        '*ros2-*'
    )
}

#!/usr/bin/env python3
"""
ROS2 Robot Simulator Node for testing ros2-connector.

This simulator publishes realistic robotic data to various ROS2 topics
that the ros2-connector can subscribe to for testing purposes.

Topics simulated:
- /chatter: Simple string messages
- /ability_hand_left/joint_states: Left hand joint states
- /ability_hand_right/joint_states: Right hand joint states
- /arm_left/joint_states: Left arm joint states
- /arm_right/joint_states: Right arm joint states
- /joy: Joystick input simulation
"""

import time
import math
import os
from threading import Thread
from typing import Optional, Set

import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, DurabilityPolicy
from std_msgs.msg import String
from sensor_msgs.msg import JointState, Joy
from geometry_msgs.msg import PoseStamped
from flask import Flask, jsonify

# Optional bag playback
USE_BAG_PLAYBACK = os.getenv('USE_BAG_PLAYBACK', 'false').lower() in {
    '1', 'true', 'yes', 'on'}
if USE_BAG_PLAYBACK:
    from ros2_bag_player import BagPlayer  # type: ignore

# Configuration from environment variables
HEALTH_PORT = 8080
PUBLISH_RATE = float(os.getenv('SIMULATOR_PUBLISH_RATE', '2.0'))  # Hz

# Flask app for health checks
app = Flask(__name__)


@app.route('/health')
def health_check():
    """Health check endpoint for Docker container monitoring."""
    return jsonify({
        'status': 'healthy',
        'timestamp': time.time(),
        'service': 'ros2-simulator'
    })


class RobotSimulator(Node):
    """ROS2 Node that simulates various robotic components and publishes
    realistic test data for the ros2-connector to consume."""

    def __init__(self):
        """Initialize the simulator node and set up publishers."""
        super().__init__('robot_simulator')

        # QoS profile for reliable delivery
        qos_profile = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            durability=DurabilityPolicy.TRANSIENT_LOCAL,
            depth=10
        )

        # Create publishers for different topics
        self.topic_publishers = self._create_publishers(qos_profile)

        # Initialize simulation state
        self.start_time = time.time()
        self.counter = 0

        # Joint names for different robot parts
        self.hand_joints = ['thumb', 'index', 'middle', 'ring', 'pinky']
        self.arm_joints = ['shoulder_pan', 'shoulder_lift', 'elbow',
                           'wrist_1', 'wrist_2', 'wrist_3']

        # Create timer for publishing
        timer_period = 1.0 / PUBLISH_RATE  # seconds
        self.timer = self.create_timer(timer_period, self.publish_data)

        logger = self.get_logger()
        logger.info(f'Robot Simulator started with {PUBLISH_RATE} Hz')
        logger.info(f'Health check available at '
                    f'http://localhost:{HEALTH_PORT}/health')

    def _create_publishers(self, qos_profile):
        """Create all the publishers for different topics."""
        publishers = {}

        # String message publisher (chatter)
        publishers['chatter'] = self.create_publisher(
            String, '/chatter', qos_profile)

        # Joint state publishers
        publishers['hand_left'] = self.create_publisher(
            JointState, '/ability_hand_left/joint_states', qos_profile)
        publishers['hand_right'] = self.create_publisher(
            JointState, '/ability_hand_right/joint_states', qos_profile)
        publishers['arm_left'] = self.create_publisher(
            JointState, '/arm_left/joint_states', qos_profile)
        publishers['arm_right'] = self.create_publisher(
            JointState, '/arm_right/joint_states', qos_profile)

        # Joy/gamepad input publisher
        publishers['joy'] = self.create_publisher(
            Joy, '/joy', qos_profile)

        # Pose publishers for arm targets
        publishers['arm_left_pose'] = self.create_publisher(
            PoseStamped, '/arm_left/target_pose', qos_profile)
        publishers['arm_right_pose'] = self.create_publisher(
            PoseStamped, '/arm_right/target_pose', qos_profile)

        return publishers

    def publish_data(self):
        """Main publishing function called by timer."""
        current_time = time.time()
        elapsed_time = current_time - self.start_time
        self.counter += 1

        # Publish different types of data
        self._publish_chatter_message(elapsed_time)
        self._publish_joint_states(elapsed_time)
        self._publish_joy_data(elapsed_time)
        self._publish_arm_poses(elapsed_time)

        if self.counter % 10 == 0:  # Log every 10 messages
            logger = self.get_logger()
            logger.info(f'Published simulation data #{self.counter}')

    def _publish_chatter_message(self, elapsed_time):
        """Publish simple string messages to /chatter topic."""
        msg = String()
        msg.data = (f'Simulation running for {elapsed_time:.1f}s - '
                    f'Message #{self.counter}')
        try:
            self.topic_publishers['chatter'].publish(msg)
            if self.counter % 50 == 0:  # Log occasionally for debugging
                self.get_logger().info(f'Published chatter: {msg.data}')
        except Exception as e:
            self.get_logger().error(f'Failed to publish chatter: {e}')

    def _publish_joint_states(self, elapsed_time):
        """Publish joint state data for hands and arms."""
        # Create realistic joint movements using sine waves
        wave1 = math.sin(elapsed_time * 0.5)  # Slow wave
        wave2 = math.sin(elapsed_time * 2.0)  # Faster wave
        wave3 = math.sin(elapsed_time * 1.5)  # Medium wave

        # Hand joint states (finger movements)
        for side in ['left', 'right']:
            msg = JointState()
            msg.header.stamp = self.get_clock().now().to_msg()
            msg.header.frame_id = f'ability_hand_{side}'
            msg.name = [f'{joint}_{side}' for joint in self.hand_joints]

            # Simulate finger flexion (0 to 1.5 radians)
            base_positions = [0.3, 0.5, 0.4, 0.6, 0.2]  # Different bases
            msg.position = [
                float(max(0.0, base + 0.3 * wave1 + 0.1 * wave2))
                for base in base_positions
            ]
            msg.velocity = [float(0.1 * wave2)] * len(self.hand_joints)
            msg.effort = [0.0] * len(self.hand_joints)

            publisher_key = f'hand_{side}'
            self.topic_publishers[publisher_key].publish(msg)

        # Arm joint states (shoulder, elbow, wrist movements)
        for side in ['left', 'right']:
            msg = JointState()
            msg.header.stamp = self.get_clock().now().to_msg()
            msg.header.frame_id = f'hexagarm_{side}'
            msg.name = [f'{joint}_{side}' for joint in self.arm_joints]

            # Simulate realistic arm movements
            side_multiplier = 1 if side == 'left' else -1
            msg.position = [
                float(0.3 * wave1 * side_multiplier),  # shoulder_pan
                float(-0.5 + 0.2 * wave2),             # shoulder_lift
                float(-1.2 + 0.3 * wave1),             # elbow
                float(0.1 * wave3 * side_multiplier),  # wrist_1
                float(0.1 * wave2),                    # wrist_2
                float(0.2 * wave1 * side_multiplier)   # wrist_3
            ]
            msg.velocity = [float(0.1 * wave3)] * len(self.arm_joints)
            msg.effort = [0.0] * len(self.arm_joints)

            publisher_key = f'arm_{side}'
            self.topic_publishers[publisher_key].publish(msg)

    def _publish_joy_data(self, elapsed_time):
        """Publish joystick/gamepad simulation data."""
        msg = Joy()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = 'joystick'

        # Simulate joystick axes (left stick, right stick, triggers)
        wave = math.sin(elapsed_time * 0.3)
        msg.axes = [
            float(0.5 * wave),      # left stick X
            float(0.3 * wave),      # left stick Y
            0.0,                    # left trigger
            float(0.2 * wave),      # right stick X
            float(-0.1 * wave),     # right stick Y
            0.0                     # right trigger
        ]

        # Simulate button presses (cycling through buttons)
        button_cycle = int(elapsed_time) % 4
        msg.buttons = [
            1 if button_cycle == 0 else 0,  # Button A
            1 if button_cycle == 1 else 0,  # Button B
            1 if button_cycle == 2 else 0,  # Button X
            1 if button_cycle == 3 else 0,  # Button Y
        ]

        self.topic_publishers['joy'].publish(msg)

    def _publish_arm_poses(self, elapsed_time):
        """Publish target poses for arm end-effectors."""
        for side in ['left', 'right']:
            msg = PoseStamped()
            msg.header.stamp = self.get_clock().now().to_msg()
            msg.header.frame_id = f'base_link_{side}'

            # Simulate circular motion for end-effector targets
            radius = 0.3
            angle = elapsed_time * 0.5
            side_offset = 0.5 if side == 'left' else -0.5

            msg.pose.position.x = float(radius * math.cos(angle))
            msg.pose.position.y = float(side_offset + radius * math.sin(angle))
            msg.pose.position.z = 0.8  # Fixed height

            # Simple orientation (no rotation)
            msg.pose.orientation.x = 0.0
            msg.pose.orientation.y = 0.0
            msg.pose.orientation.z = 0.0
            msg.pose.orientation.w = 1.0

            publisher_key = f'arm_{side}_pose'
            self.topic_publishers[publisher_key].publish(msg)


def run_health_server():
    """Run the Flask health check server in a separate thread."""
    app.run(host='0.0.0.0', port=HEALTH_PORT, debug=False)


def _env_set(name: str) -> Optional[Set[str]]:
    val = os.getenv(name)
    if not val:
        return None
    items = {v.strip() for v in val.split(',') if v.strip()}
    return items or None


def main(args=None):
    """Main entry point: simulation or bag playback based on env flag."""
    health_thread = Thread(target=run_health_server, daemon=True)
    health_thread.start()

    rclpy.init(args=args)

    if USE_BAG_PLAYBACK:
        bag_path = os.getenv('BAG_PATH')
        if not bag_path or not os.path.isdir(bag_path):
            print('ERROR: USE_BAG_PLAYBACK set but BAG_PATH invalid')
            rclpy.shutdown()
            return
        loop = os.getenv('PLAY_LOOP', 'true').lower() in {
            '1', 'true', 'yes', 'on'}
        try:
            rate = float(os.getenv('PLAY_RATE', '1.0'))
        except ValueError:
            rate = 1.0
        include = _env_set('PLAY_INCLUDE')
        exclude = _env_set('PLAY_EXCLUDE') or set()
        player = BagPlayer(bag_path, loop=loop, rate=rate,
                           include=include, exclude=exclude)
        try:
            print('ROS2 Bag Playback mode active')
            print(f'Playing bag: {bag_path} loop={loop} rate={rate}')
            print(f'Health: http://localhost:{HEALTH_PORT}/health')
            player.play()
        except KeyboardInterrupt:
            pass
        finally:
            player.destroy_node()
            rclpy.shutdown()
        return

    simulator = RobotSimulator()
    try:
        print('ROS2 Robot Simulator started')
        print(f'Publishing at {PUBLISH_RATE} Hz to multiple topics')
        print(
            f'Health check available at: http://localhost:{HEALTH_PORT}/health')
        rclpy.spin(simulator)
    except KeyboardInterrupt:
        print('Shutting down simulator...')
    simulator.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()

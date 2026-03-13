#!/usr/bin/env python3
"""
Data Scientist Workflow Example for Video Capture Query Blueprint

This example demonstrates how to:
1. Query historical video from specific cameras and timeframes
2. Download video segments for analysis
3. Perform frame-by-frame analysis with OpenCV
4. Extract insights from video data

Prerequisites:
- pip install video-query-sdk opencv-python numpy pandas
- Azure credentials configured (Azure CLI login or environment variables)
- Video Query API deployed and accessible
"""

import argparse
import cv2
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Tuple

try:
    from video_query_sdk import VideoQueryClient
except ImportError:
    print("ERROR: video_query_sdk not installed")
    print("Install with: pip install video-query-sdk")
    exit(1)


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Query and analyze historical video from cameras"
    )
    parser.add_argument(
        "--api-url",
        required=True,
        help="Video Query API URL (e.g., https://func-app.azurewebsites.net/api)"
    )
    parser.add_argument(
        "--camera",
        required=True,
        help="Camera identifier (e.g., camera-01)"
    )
    parser.add_argument(
        "--start",
        required=True,
        help="Start timestamp in ISO 8601 format (e.g., 2026-01-20T10:00:00Z)"
    )
    parser.add_argument(
        "--end",
        required=True,
        help="End timestamp in ISO 8601 format (e.g., 2026-01-20T10:30:00Z)"
    )
    parser.add_argument(
        "--output-dir",
        default="./video_analysis",
        help="Output directory for downloaded videos and analysis results"
    )
    parser.add_argument(
        "--analysis",
        choices=["motion", "object_count", "brightness", "all"],
        default="all",
        help="Type of analysis to perform"
    )
    return parser.parse_args()


def query_video(
    client: VideoQueryClient,
    camera_id: str,
    start_time: datetime,
    end_time: datetime,
    output_dir: Path
) -> Path:
    """
    Query video from API and download to local storage.

    Args:
        client: Initialized VideoQueryClient
        camera_id: Camera identifier
        start_time: Start timestamp
        end_time: End timestamp
        output_dir: Directory to save downloaded video

    Returns:
        Path to downloaded video file
    """
    print(f"\n🔍 Querying video from {camera_id}")
    print(f"   Timeframe: {start_time} to {end_time}")
    print(f"   Duration: {(end_time - start_time).total_seconds()} seconds")

    try:
        video_url = client.get_video(
            camera_id=camera_id,
            start_time=start_time,
            end_time=end_time
        )
        print(f"✅ Video URL retrieved: {video_url[:50]}...")

        video_filename = f"{camera_id}_{start_time.strftime('%Y%m%d_%H%M%S')}.mp4"
        video_path = output_dir / video_filename

        print(f"⬇️  Downloading video to {video_path}")
        client.download_video(video_url, str(video_path))
        print(
            f"✅ Download complete: {video_path.stat().st_size / (1024*1024):.2f} MB")

        return video_path

    except Exception as e:
        print(f"❌ Error querying video: {e}")
        raise


def analyze_motion(video_path: Path) -> pd.DataFrame:
    """
    Detect motion in video using frame differencing.

    Args:
        video_path: Path to video file

    Returns:
        DataFrame with motion detection results
    """
    print("\n🎬 Analyzing motion...")

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise ValueError(f"Failed to open video: {video_path}")

    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    results = []
    prev_frame = None
    frame_idx = 0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(gray, (21, 21), 0)

        if prev_frame is not None:
            frame_diff = cv2.absdiff(prev_frame, gray)
            thresh = cv2.threshold(frame_diff, 25, 255, cv2.THRESH_BINARY)[1]
            motion_pixels = np.sum(thresh) / 255
            motion_percentage = (motion_pixels / thresh.size) * 100

            timestamp = frame_idx / fps
            results.append({
                'frame': frame_idx,
                'timestamp_sec': timestamp,
                'motion_pixels': motion_pixels,
                'motion_percentage': motion_percentage,
                'motion_detected': motion_percentage > 1.0
            })

        prev_frame = gray
        frame_idx += 1

        if frame_idx % 100 == 0:
            print(
                f"   Processed {frame_idx}/{frame_count} frames ({frame_idx/frame_count*100:.1f}%)")

    cap.release()

    df = pd.DataFrame(results)
    print(f"✅ Motion analysis complete: {len(df)} frames analyzed")
    print(
        f"   Motion detected in {df['motion_detected'].sum()} frames ({df['motion_detected'].mean()*100:.1f}%)")

    return df


def analyze_brightness(video_path: Path) -> pd.DataFrame:
    """
    Analyze brightness levels in video.

    Args:
        video_path: Path to video file

    Returns:
        DataFrame with brightness analysis results
    """
    print("\n💡 Analyzing brightness...")

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise ValueError(f"Failed to open video: {video_path}")

    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    results = []
    frame_idx = 0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        mean_brightness = np.mean(gray)
        std_brightness = np.std(gray)

        timestamp = frame_idx / fps
        results.append({
            'frame': frame_idx,
            'timestamp_sec': timestamp,
            'mean_brightness': mean_brightness,
            'std_brightness': std_brightness
        })

        frame_idx += 1

        if frame_idx % 100 == 0:
            print(
                f"   Processed {frame_idx}/{frame_count} frames ({frame_idx/frame_count*100:.1f}%)")

    cap.release()

    df = pd.DataFrame(results)
    print(f"✅ Brightness analysis complete")
    print(f"   Mean brightness: {df['mean_brightness'].mean():.2f} (0-255)")
    print(
        f"   Brightness range: {df['mean_brightness'].min():.2f} - {df['mean_brightness'].max():.2f}")

    return df


def count_objects_simple(video_path: Path) -> pd.DataFrame:
    """
    Simple object counting using background subtraction.

    Args:
        video_path: Path to video file

    Returns:
        DataFrame with object counting results
    """
    print("\n🔢 Counting objects (simple background subtraction)...")

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise ValueError(f"Failed to open video: {video_path}")

    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    back_sub = cv2.createBackgroundSubtractorMOG2(
        history=500,
        varThreshold=16,
        detectShadows=True
    )

    results = []
    frame_idx = 0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        fg_mask = back_sub.apply(frame)
        fg_mask = cv2.threshold(fg_mask, 244, 255, cv2.THRESH_BINARY)[1]
        fg_mask = cv2.morphologyEx(
            fg_mask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))

        contours, _ = cv2.findContours(
            fg_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        object_count = 0
        for contour in contours:
            area = cv2.contourArea(contour)
            if area > 500:
                object_count += 1

        timestamp = frame_idx / fps
        results.append({
            'frame': frame_idx,
            'timestamp_sec': timestamp,
            'object_count': object_count,
            'foreground_pixels': np.sum(fg_mask) / 255
        })

        frame_idx += 1

        if frame_idx % 100 == 0:
            print(
                f"   Processed {frame_idx}/{frame_count} frames ({frame_idx/frame_count*100:.1f}%)")

    cap.release()

    df = pd.DataFrame(results)
    print(f"✅ Object counting complete")
    print(f"   Average objects per frame: {df['object_count'].mean():.2f}")
    print(f"   Max objects detected: {df['object_count'].max()}")

    return df


def save_analysis_results(
    output_dir: Path,
    camera_id: str,
    start_time: datetime,
    motion_df: pd.DataFrame = None,
    brightness_df: pd.DataFrame = None,
    object_df: pd.DataFrame = None
) -> None:
    """
    Save analysis results to CSV files.

    Args:
        output_dir: Output directory
        camera_id: Camera identifier
        start_time: Start timestamp
        motion_df: Motion analysis results
        brightness_df: Brightness analysis results
        object_df: Object counting results
    """
    print("\n💾 Saving analysis results...")

    timestamp_str = start_time.strftime('%Y%m%d_%H%M%S')

    if motion_df is not None:
        motion_file = output_dir / f"{camera_id}_{timestamp_str}_motion.csv"
        motion_df.to_csv(motion_file, index=False)
        print(f"✅ Motion analysis saved: {motion_file}")

    if brightness_df is not None:
        brightness_file = output_dir / \
            f"{camera_id}_{timestamp_str}_brightness.csv"
        brightness_df.to_csv(brightness_file, index=False)
        print(f"✅ Brightness analysis saved: {brightness_file}")

    if object_df is not None:
        object_file = output_dir / f"{camera_id}_{timestamp_str}_objects.csv"
        object_df.to_csv(object_file, index=False)
        print(f"✅ Object counting saved: {object_file}")


def print_summary(
    camera_id: str,
    start_time: datetime,
    end_time: datetime,
    video_path: Path,
    motion_df: pd.DataFrame = None,
    brightness_df: pd.DataFrame = None,
    object_df: pd.DataFrame = None
) -> None:
    """Print analysis summary."""
    print("\n" + "="*70)
    print("📊 ANALYSIS SUMMARY")
    print("="*70)
    print(f"Camera: {camera_id}")
    print(f"Timeframe: {start_time} to {end_time}")
    print(f"Duration: {(end_time - start_time).total_seconds()} seconds")
    print(f"Video file: {video_path}")
    print(f"Video size: {video_path.stat().st_size / (1024*1024):.2f} MB")
    print("-"*70)

    if motion_df is not None:
        print("\n🎬 Motion Analysis:")
        print(f"   Total frames analyzed: {len(motion_df)}")
        print(f"   Frames with motion: {motion_df['motion_detected'].sum()}")
        print(
            f"   Motion percentage: {motion_df['motion_detected'].mean()*100:.1f}%")
        print(
            f"   Average motion intensity: {motion_df['motion_percentage'].mean():.2f}%")

    if brightness_df is not None:
        print("\n💡 Brightness Analysis:")
        print(
            f"   Mean brightness: {brightness_df['mean_brightness'].mean():.2f}/255")
        print(
            f"   Brightness range: {brightness_df['mean_brightness'].min():.2f} - {brightness_df['mean_brightness'].max():.2f}")
        print(
            f"   Brightness variability (std): {brightness_df['std_brightness'].mean():.2f}")

    if object_df is not None:
        print("\n🔢 Object Counting:")
        print(f"   Average objects: {object_df['object_count'].mean():.2f}")
        print(f"   Max objects: {object_df['object_count'].max()}")
        print(
            f"   Frames with objects: {(object_df['object_count'] > 0).sum()}")

    print("="*70)


def main():
    """Main workflow execution."""
    args = parse_arguments()

    print("="*70)
    print("🎥 VIDEO CAPTURE QUERY - DATA SCIENTIST WORKFLOW")
    print("="*70)

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"📁 Output directory: {output_dir.absolute()}")

    start_time = datetime.fromisoformat(args.start.replace('Z', '+00:00'))
    end_time = datetime.fromisoformat(args.end.replace('Z', '+00:00'))

    client = VideoQueryClient(api_url=args.api_url)

    try:
        video_path = query_video(
            client=client,
            camera_id=args.camera,
            start_time=start_time,
            end_time=end_time,
            output_dir=output_dir
        )

        motion_df = None
        brightness_df = None
        object_df = None

        if args.analysis in ["motion", "all"]:
            motion_df = analyze_motion(video_path)

        if args.analysis in ["brightness", "all"]:
            brightness_df = analyze_brightness(video_path)

        if args.analysis in ["object_count", "all"]:
            object_df = count_objects_simple(video_path)

        save_analysis_results(
            output_dir=output_dir,
            camera_id=args.camera,
            start_time=start_time,
            motion_df=motion_df,
            brightness_df=brightness_df,
            object_df=object_df
        )

        print_summary(
            camera_id=args.camera,
            start_time=start_time,
            end_time=end_time,
            video_path=video_path,
            motion_df=motion_df,
            brightness_df=brightness_df,
            object_df=object_df
        )

        print("\n✅ Workflow complete!")

    except KeyboardInterrupt:
        print("\n⚠️  Workflow interrupted by user")
        return 1
    except Exception as e:
        print(f"\n❌ Workflow failed: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0


if __name__ == "__main__":
    exit(main())

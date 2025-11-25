use anyhow::{Context, Result};
use std::path::Path;
use std::process::Command;
use tracing::info;

pub fn check_ffmpeg_available() -> Result<String> {
    let output = Command::new("ffmpeg")
        .arg("-version")
        .output()
        .context("FFmpeg not found. Please install FFmpeg.")?;

    if !output.status.success() {
        anyhow::bail!("FFmpeg executable found but returned non-zero exit code");
    }

    let version = String::from_utf8_lossy(&output.stdout);
    Ok(version.lines().next().unwrap_or("Unknown").to_string())
}

pub fn convert_two_pass(
    input: &Path,
    output: &Path,
    fps: u32,
    width: u32,
    dither: &str,
) -> Result<()> {
    let palette_file = "/tmp/palette.png";

    info!("Pass 1/2: Generating optimized color palette");
    let palette_filter = format!(
        "fps={},scale={}:-1:flags=lanczos,palettegen=stats_mode=diff",
        fps, width
    );

    let status = Command::new("ffmpeg")
        .args([
            "-i",
            input.to_str().unwrap(),
            "-vf",
            &palette_filter,
            "-y",
            palette_file,
        ])
        .status()
        .context("Failed to generate palette")?;

    if !status.success() {
        anyhow::bail!("Palette generation failed");
    }

    info!("Pass 2/2: Creating GIF with optimized palette");
    let gif_filter = format!(
        "fps={},scale={}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither={}:diff_mode=rectangle",
        fps, width, dither
    );

    let status = Command::new("ffmpeg")
        .args([
            "-i",
            input.to_str().unwrap(),
            "-i",
            palette_file,
            "-lavfi",
            &gif_filter,
            "-y",
            output.to_str().unwrap(),
        ])
        .status()
        .context("Failed to create GIF")?;

    if !status.success() {
        anyhow::bail!("GIF creation failed");
    }

    let _ = std::fs::remove_file(palette_file);
    Ok(())
}

pub fn convert_single_pass(input: &Path, output: &Path, fps: u32, width: u32) -> Result<()> {
    info!("Single-pass conversion (faster, lower quality)");
    let filter = format!("fps={},scale={}:-1:flags=lanczos", fps, width);

    let status = Command::new("ffmpeg")
        .args([
            "-i",
            input.to_str().unwrap(),
            "-vf",
            &filter,
            "-y",
            output.to_str().unwrap(),
        ])
        .status()
        .context("Failed to convert video")?;

    if !status.success() {
        anyhow::bail!("Video conversion failed");
    }

    Ok(())
}

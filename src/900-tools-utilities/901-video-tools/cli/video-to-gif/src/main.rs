use anyhow::{Context, Result};
use clap::Parser;
use std::path::PathBuf;
use tracing::{info, warn};

mod converter;

#[derive(Parser, Debug)]
#[command(name = "video-to-gif")]
#[command(author, version, about = "Convert video files to optimized GIFs", long_about = None)]
struct Args {
    /// Input video file path
    #[arg(short, long)]
    input: PathBuf,

    /// Output GIF file path
    #[arg(short, long)]
    output: PathBuf,

    /// Frames per second (1-30)
    #[arg(long, default_value_t = 10)]
    #[arg(value_parser = clap::value_parser!(u32).range(1..=30))]
    fps: u32,

    /// Maximum width in pixels (100-1920)
    #[arg(long, default_value_t = 480)]
    #[arg(value_parser = clap::value_parser!(u32).range(100..=1920))]
    width: u32,

    /// Dithering algorithm
    #[arg(long, default_value = "sierra2_4a")]
    #[arg(value_parser = ["sierra2_4a", "floyd_steinberg", "bayer", "none"])]
    dither: String,

    /// Skip two-pass palette generation (faster but lower quality)
    #[arg(long)]
    skip_palette: bool,

    /// Enable verbose output
    #[arg(short, long)]
    verbose: bool,
}

fn main() -> Result<()> {
    let args = Args::parse();

    tracing_subscriber::fmt()
        .with_env_filter(if args.verbose { "debug" } else { "info" })
        .init();

    match converter::check_ffmpeg_available() {
        Ok(version) => info!("Using FFmpeg: {}", version),
        Err(e) => {
            eprintln!("ERROR: {}", e);
            eprintln!("\nTo install FFmpeg:");
            eprintln!("  Ubuntu/Debian: sudo apt-get install ffmpeg");
            eprintln!("  macOS:         brew install ffmpeg");
            eprintln!("  Windows:       choco install ffmpeg");
            std::process::exit(1);
        }
    }

    if !args.input.exists() {
        anyhow::bail!("Input file does not exist: {}", args.input.display());
    }

    if let Some(parent) = args.output.parent() {
        std::fs::create_dir_all(parent).context(format!(
            "Failed to create output directory: {}",
            parent.display()
        ))?;
    }

    info!(
        "Converting {} to {}",
        args.input.display(),
        args.output.display()
    );
    info!(
        "Settings: fps={}, width={}, dither={}",
        args.fps, args.width, args.dither
    );

    if args.skip_palette {
        warn!("Single-pass mode: GIF quality may be reduced");
        converter::convert_single_pass(&args.input, &args.output, args.fps, args.width)?;
    } else {
        converter::convert_two_pass(
            &args.input,
            &args.output,
            args.fps,
            args.width,
            &args.dither,
        )?;
    }

    let file_size = std::fs::metadata(&args.output)
        .map(|m| m.len())
        .unwrap_or(0);
    info!(
        "Conversion complete: {} ({} KB)",
        args.output.display(),
        file_size / 1024
    );

    Ok(())
}

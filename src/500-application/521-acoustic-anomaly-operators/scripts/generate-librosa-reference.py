"""Generates librosa reference features for the featurize-acoustic parity test.

Mirrors the DCASE 2020 Task 2 baseline feature extraction, which ran on
librosa 0.6 where centered STFT frames used reflect padding. Newer librosa
defaults to zero padding, so pad_mode="reflect" is set explicitly. Run with
librosa 0.11.0 installed:

    python3 generate-librosa-reference.py \
      > ../operators/featurize-acoustic/tests/fixtures/librosa-reference.json
    npx prettier --write ../operators/featurize-acoustic/tests/fixtures/librosa-reference.json
"""

import json
import sys

import librosa
import numpy as np

SR = 16000
N = 4096


def signal() -> np.ndarray:
    t = np.arange(N, dtype=np.float64) / SR
    state = 12345
    noise = np.empty(N)
    for i in range(N):
        state = (1103515245 * state + 12345) % 2**31
        noise[i] = state / 2**31 - 0.5
    y = 0.3 * np.sin(2 * np.pi * 440.0 * t) + 0.2 * np.sin(2 * np.pi * 3200.0 * t) + 0.05 * noise
    return y.astype(np.float32)


y = signal()
mel = librosa.feature.melspectrogram(
    y=y, sr=SR, n_fft=1024, hop_length=512, n_mels=128, power=2.0, center=True, pad_mode="reflect"
)
log_mel = 20.0 / 2.0 * np.log10(mel + sys.float_info.epsilon)
frames = 5
windows = log_mel.shape[1] - frames + 1
rows = np.zeros((windows, 128 * frames))
for t in range(frames):
    rows[:, 128 * t : 128 * (t + 1)] = log_mel[:, t : t + windows].T

indices = [0, 7, 37, 64, 100, 127, 128, 200, 300, 383, 450, 511, 600, 639]
fixture = {
    "librosa_version": librosa.__version__,
    "sample_rate": SR,
    "num_samples": N,
    "signal": "0.3*sin(2*pi*440*t) + 0.2*sin(2*pi*3200*t) + 0.05*(lcg(12345)/2^31 - 0.5), float32",
    "pad_mode": "reflect",
    "windows": windows,
    "indices": indices,
    "values": [[round(float(rows[w, i]), 4) for i in indices] for w in range(windows)],
    "row_means": [round(float(rows[w].mean()), 4) for w in range(windows)],
}
print(json.dumps(fixture, indent=2))

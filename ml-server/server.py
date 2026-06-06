from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
import io
import os
import soundfile as sf
import librosa

app = Flask(__name__)

MODEL_PATH = os.environ.get("MODEL_PATH", "./meow_tf_cnn")
model = tf.keras.models.load_model(MODEL_PATH)

labels = ["angry", "happy", "hungry"]

MODEL_SAMPLE_RATE = 16000
TARGET_SECONDS = 4
TARGET_SAMPLES = MODEL_SAMPLE_RATE * TARGET_SECONDS

FRAME_LENGTH = 400
FRAME_STEP = 160
NUM_MELS = 64
FMIN = 80.0
FMAX = 7600.0

_MEL_MATRIX = tf.constant(
    tf.signal.linear_to_mel_weight_matrix(
        num_mel_bins=NUM_MELS,
        num_spectrogram_bins=257,
        sample_rate=MODEL_SAMPLE_RATE,
        lower_edge_hertz=FMIN,
        upper_edge_hertz=FMAX,
    ),
    dtype=tf.float32,
)

def read_audio(raw):
    fmt = request.headers.get("X-Audio-Format", "").lower()
    input_sr = int(request.headers.get("X-Sample-Rate", MODEL_SAMPLE_RATE))

    try:
        waveform, sr = sf.read(io.BytesIO(raw), dtype="float32", always_2d=False)
        if waveform.ndim > 1:
            waveform = waveform[:, 0]
        input_sr = sr
    except Exception:
        if fmt in ["s16", "s16le", "int16", "pcm_s16le"]:
            waveform = np.frombuffer(raw, dtype="<i2").astype(np.float32) / 32768.0
        else:
            waveform = np.frombuffer(raw, dtype="<f4").astype(np.float32)

    if input_sr != MODEL_SAMPLE_RATE:
        waveform = librosa.resample(
            waveform,
            orig_sr=input_sr,
            target_sr=MODEL_SAMPLE_RATE,
        )

    return waveform.astype(np.float32)

def pad_or_trim(waveform):
    if len(waveform) < TARGET_SAMPLES:
        waveform = np.pad(waveform, (0, TARGET_SAMPLES - len(waveform)))
    else:
        waveform = waveform[:TARGET_SAMPLES]

    return waveform.astype(np.float32)

def waveform_to_logmelspec(waveform):
    x = tf.convert_to_tensor(waveform, dtype=tf.float32)

    stft = tf.signal.stft(
        x,
        frame_length=FRAME_LENGTH,
        frame_step=FRAME_STEP,
        fft_length=512,
    )

    mag2 = tf.abs(stft) ** 2
    mels = tf.tensordot(mag2, _MEL_MATRIX, axes=1)
    logmels = tf.math.log(mels + 1e-6)

    return tf.expand_dims(logmels, -1)

@app.route("/", methods=["GET"])
def home():
    return jsonify({"status": "ML server running"})

@app.route("/predict", methods=["POST"])
def predict():
    raw = request.data

    if not raw:
        return jsonify({"error": "No audio received"}), 400

    waveform = read_audio(raw)
    waveform = pad_or_trim(waveform)

    rms = float(np.sqrt(np.mean(waveform ** 2)))
    peak = float(np.max(np.abs(waveform)))

    print("bytes:", len(raw), "samples:", len(waveform), "rms:", rms, "peak:", peak)

    spec = waveform_to_logmelspec(waveform)
    spec = tf.expand_dims(spec, 0)

    probs = model.predict(spec, verbose=0)[0]
    idx = int(np.argmax(probs))

    return jsonify({
        "label": labels[idx],
        "rms": rms,
        "peak": peak,
        "probs": {
            labels[i]: float(probs[i])
            for i in range(len(labels))
        }
    })

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5005))
    app.run(host="0.0.0.0", port=port)
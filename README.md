# Offline Voice Notes

[![CI](https://github.com/slvrkskc/offline_voice_notes/actions/workflows/ci.yml/badge.svg)](https://github.com/slvrkskc/offline_voice_notes/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

On-device voice notes for Turkish and English. Record, transcribe, summarize and
auto-tag — entirely on the phone, with no network permission at all.

> **Status: architecture and skeleton. Not yet buildable.**
> The design is complete and documented; implementation starts after the
> measurement spikes. See [Current status](#current-status) — nothing here is
> oversold, and every unmeasured number in the docs is marked as such.

---

## The claim, stated precisely

Most "private" apps ask to be trusted. This one is built so that trust is not
required: **the app declares no network permission**, so the operating system
itself prevents it from opening a socket. No audio, transcript, metadata or
analytics can leave the device, because there is no channel for it to leave by.

That is enforced in two places:

- [`app/src/main/AndroidManifest.xml`](app/src/main/AndroidManifest.xml) actively
  **rejects** `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE` and
  `CHANGE_NETWORK_STATE` with `tools:node="remove"`. Library manifests are merged
  into the app's, so *not declaring* a permission is not the same as *refusing*
  it — a single dependency can reintroduce `INTERNET` silently.
- [`tools/verify-no-network.sh`](tools/verify-no-network.sh) inspects the **built**
  APK/AAB and fails the build if any of them reappears. "Not in the source" and
  "not in the artifact" are different statements; only the second one matters.
  The script also fails when its tooling is missing, so *"we could not check"*
  is never reported as *"it is fine"*.

### Verify it yourself

Once the project builds, this is the whole audit:

```bash
./gradlew :app:assembleRelease
tools/verify-no-network.sh app/build/outputs/apk/release/app-release.apk
```

Models are delivered through **Play Asset Delivery install-time packs**, which
is what makes zero network permission possible while still shipping ~1.9 GB of
model weights: Google Play delivers the files, the app never fetches them.
See [ADR-004](ARCHITECTURE.md#adr-004--model-dağıtımı-install-time-play-asset-delivery--kullanıcı-importu).

---

## What it does

Record → voice activity detection → speech recognition → punctuation and
normalization → language detection → chunking → map-reduce summarization →
tagging → indexing. Every stage checkpoints to an encrypted database, so an
interrupted 60-minute recording resumes exactly where it stopped rather than
starting over.

Turkish and English are both first-class, including the case that actually
happens in practice: speaking Turkish while using English technical terms.
The expected limits of that are documented honestly rather than glossed over.

---

## Key decisions

| Area | Decision | Why |
|---|---|---|
| Speech recognition | whisper.cpp + Whisper `small` | The only model family with usable Turkish. NVIDIA Parakeet v3 has no Turkish; Vosk's Turkish model is weak and unpunctuated. Shares the `ggml` backend with the summarizer, so one native build serves both — and ships Silero VAD built in. |
| Summarization | llama.cpp + a ~1.7B Apache-2.0 GGUF model, tiered by device | **Android's ML Kit GenAI summarization supports only English, Japanese and Korean — no Turkish.** Apple's Foundation Models were not available in Turkish at launch and need hardware above our floor. Platform models cannot be the main path. |
| Tagging | Canonical English tag keys + GBNF grammar-constrained JSON | Grammar restricts tokens during decoding, so schema-invalid output is impossible rather than merely unlikely — which matters a lot at 1–2B parameters. Canonical keys remove Turkish/English tag duplication entirely. |
| Storage | SQLCipher + Android Keystore + Google Tink | `androidx.security:security-crypto` is fully deprecated, so file encryption drops one layer down to Tink, which it was built on. SQLCipher also brings its own SQLite, which is how we get reliable FTS5. |
| Search | FTS5 with diacritic folding + prefix matching | FTS5 has no Turkish stemmer. Turkish suffixes attach at the **end** of words, so `toplantı*` recovers most of what a stemmer would give, for free. |

Full reasoning, trade-offs and consequences for all ten decisions:
**[ARCHITECTURE.md](ARCHITECTURE.md)**.

---

## Target hardware

Deliberately **not** flagship-only:

- **Android 12+** (API 31), 4–6 GB RAM mid-range devices — the primary target
- **iOS 17+**, with device eligibility resolved at runtime via
  `os_proc_available_memory()` rather than a model allowlist, because
  "A13 or newer" does not imply 4 GB of RAM — the iPhone SE 2nd generation has
  an A13 and 3 GB

Every performance figure in the documentation is currently a **vendor benchmark
from a flagship device or an estimate**. Not one number has been measured on the
target class yet. That is the entire purpose of the spike phase, and the docs
mark each one accordingly.

---

## Repository layout

```
ARCHITECTURE.md          Architecture, ADRs, data model, spike list
docs/SETUP.md            Toolchain setup and verification
docs/THIRD-PARTY.md      Licence inventory and the gate for adding dependencies
docs/spikes/             Spike results — measurements and the decisions they drove
app/                     Compose host; the privacy-critical manifest
core/                    crypto, database, audio, model-manager, device
domain/                  Pure Kotlin, no Android imports (KMP-ready)
ml/                      Engine interfaces + the shared C/C++ core (whisper.cpp, llama.cpp)
pipeline/                Orchestrator, durable queue, foreground service
feature/                 UI
benchmark/golden/        Golden audio set — manifest and reference transcripts only
tools/                   CI gates, including the network-permission check
```

Audio recordings and model weights are never committed: recordings are personal
data, and weights are large and carry their own upstream licences. CI enforces
both, so the rule cannot quietly erode.

---

## Current status

| | |
|---|---|
| Architecture | ✅ Complete — 10 ADRs, data model, threat model, test strategy |
| Desk research | ✅ Model/library candidates compared; licenses verified |
| Project skeleton | ✅ Module graph, privacy manifest, CI gate script |
| Toolchain | ⬜ Not set up — see [docs/SETUP.md](docs/SETUP.md) |
| Measurement spikes | ⬜ Not started — S1–S4 drive the remaining decisions |
| Implementation | ⬜ Not started |

The version-dependent build files are intentionally absent until the toolchain
baseline exists; writing unverifiable version combinations would be guesswork.
[docs/SETUP.md §3](docs/SETUP.md) explains the approach.

---

## Roadmap

- **MVP** — Android only: record, VAD, transcription, encrypted storage,
  full-text search, extractive summaries, and the no-network proof locked in CI
- **v1** — LLM summarization and tagging, map-reduce for long recordings,
  language handling, background processing with thermal and battery policy
- **v2** — iOS (requires a Mac), semantic search, speaker diarization

---

## License

Licensed under the **Apache License 2.0** — see [LICENSE](LICENSE).

Copyright 2026 slvrkskc

Apache-2.0 was chosen over MIT for its explicit patent grant, which matters for
a project built around on-device inference. The dependency set is permissive and
compatible throughout: whisper.cpp, llama.cpp and Silero VAD are MIT; Qwen3,
Google Tink and sherpa-onnx are Apache-2.0. Model weights are **not**
redistributed in this repository and carry their own upstream licenses.

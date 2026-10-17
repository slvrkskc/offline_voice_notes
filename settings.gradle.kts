// Module graph from ARCHITECTURE.md §9.
//
// NOTE: the plugin/version wiring (root build.gradle.kts and
// gradle/libs.versions.toml) is intentionally NOT written yet - see
// docs/SETUP.md. AGP 9.x changed how Kotlin is applied, so those files should
// come from an Android Studio generated baseline that is known to sync, rather
// than from hand-written version guesses.

pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    // Fail loudly if a module declares its own repository: a single, explicit
    // dependency source is part of the supply-chain story (ARCHITECTURE.md §13.3, P4).
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "offline-voice-notes"

// ---------------------------------------------------------------------------
// app
// ---------------------------------------------------------------------------
include(":app")

// ---------------------------------------------------------------------------
// core - platform-facing infrastructure
// ---------------------------------------------------------------------------
include(":core:common")
include(":core:designsystem")
include(":core:crypto")          // Keystore / StrongBox, Tink (ADR-005)
include(":core:database")        // Room + SQLCipher + FTS5 (ADR-005, ADR-006)
include(":core:audio")           // AudioRecord, chunked WAV writer, Opus
include(":core:model-manager")   // model registry, PAD access, SHA-256 (ADR-004)
include(":core:device")          // device tier, thermal + battery observers

// ---------------------------------------------------------------------------
// domain - pure Kotlin, no Android imports (KMP-ready, ADR-001)
// ---------------------------------------------------------------------------
include(":domain")

// ---------------------------------------------------------------------------
// ml - engines behind stable interfaces
// ---------------------------------------------------------------------------
include(":ml:api")               // AsrEngine / LlmEngine / VadEngine interfaces
include(":ml:native")            // CMake + JNI: whisper.cpp + llama.cpp (ADR-002)
include(":ml:asr")
include(":ml:llm")
include(":ml:nlp")               // ITN, Turkish normalization, extractive summary
include(":ml:embedding")         // v2

// ---------------------------------------------------------------------------
// pipeline - orchestration, queue, foreground service (ADR-008)
// ---------------------------------------------------------------------------
include(":pipeline:orchestrator")
include(":pipeline:queue")
include(":pipeline:service")

// ---------------------------------------------------------------------------
// feature - UI
// ---------------------------------------------------------------------------
include(":feature:record")
include(":feature:notes")
include(":feature:notedetail")
include(":feature:search")
include(":feature:settings")

// ---------------------------------------------------------------------------
// benchmark - golden set harness + macrobenchmark (ARCHITECTURE.md §14)
// ---------------------------------------------------------------------------
include(":benchmark:harness")
include(":benchmark:macrobenchmark")

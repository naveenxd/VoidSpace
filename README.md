<p align="center">
  <h1 align="center">Void Space</h1>
  <p align="center">
    A minimal, offline-first knowledge space — built for clarity, calm, and focus.
    <br />
    <em>No noise. No gimmicks. Just your thoughts.</em>
  </p>
</p>

---

## Philosophy

Void Space isn't another productivity tool. It's a quiet digital room for your links, notes, and references — designed to stay out of your way.

- **Minimal & calm** — A distraction-free interface that reduces cognitive load.
- **No productivity theater** — Let ideas exist without forcing artificial structure.
- **Privacy-first** — Your data lives on your device. No accounts, no cloud, no tracking.

## Features

### 🧠 Semantic Search
Find your thoughts naturally. Void Space runs a local [all-MiniLM-L6-v2](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2) ONNX model on-device to generate 384-dimensional embeddings, powering cosine-similarity search with automatic keyword fallback.

### ⚡ Frictionless Capture
Save links, text, and images instantly from any app using Android's native Share Intent. A dedicated share entry point (`shareMain`) launches a lightweight floating orb UI — so saving content feels instantaneous.

### 🤖 AI-Powered Analysis
Content is automatically analyzed using Cloudflare Workers AI (Llama 3.2) to extract:
- Smart, contextual **tags**
- A concise **TL;DR** (single sentence)
- A longer **summary** (3–5 sentences)
- Cleaned-up **titles**

Falls back to keyword-based heuristics when AI is unavailable.

### 🔗 Rich Link Metadata
When you save a URL, Void Space scrapes Open Graph metadata (title, description, image) and auto-classifies the link type — `video`, `social`, or generic `link` — based on the domain.

### 🔐 Biometric Lock
Optional biometric/PIN authentication via the `local_auth` package. The lock screen prompt reads *"Handshake required to enter the void."*

### 🎨 Polished UI
- Staggered grid layout with shimmer loading states
- Inline editing for titles, tags, and notes
- Custom animations and pull-to-refresh
- Dark/Light mode with system detection
- Onboarding flow with profile setup
- Custom painters and glass-morphism effects

### 📦 Data Portability
Import and export your entire vault as JSON — keep full ownership of your data.


## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | [Flutter](https://flutter.dev/) 3.10+ / Dart 3.10+ |
| **Local Storage** | [Hive](https://pub.dev/packages/hive) — fast, encrypted NoSQL |
| **State Management** | [Provider](https://pub.dev/packages/provider) |
| **On-Device AI** | [ONNX Runtime](https://pub.dev/packages/onnxruntime) — all-MiniLM-L6-v2 |
| **Cloud AI** | Cloudflare Workers AI — Llama 3.2 |
| **Metadata** | Open Graph scraping via `http` + `html` |
| **Auth** | [local_auth](https://pub.dev/packages/local_auth) — biometric/PIN |
| **UI** | Google Fonts, Staggered Grid, Shimmer, Custom Painters |

## Getting Started

### Prerequisites

- Flutter SDK `^3.10.7` or later
- Dart SDK (bundled with Flutter)
- Android Studio for Android builds (primary platform)

### Installation

```bash
# Clone the repository
git clone https://github.com/naveenxd/VoidSpace.git
cd VoidSpace

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### ONNX Model

The semantic search model (`assets/models/model.onnx`) and tokenizer (`assets/models/tokenizer.json`) are bundled in the repo. No additional downloads are required.

## License

TBD

# Barnaby - Privacy-Focused digital butler

**⚠️ Still in development - not ready for production use**

A privacy-focused, modular, offline-first digital butler platform that runs locally on your own hardware.

## Quick Start

### Prerequisites
- Rust (latest stable)
- Flutter SDK
- SQLite3
- Docker (optional)

### Running the Backend

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies and run:
```bash
cargo run
```
or
```bash
cargo run --bin barnaby-server
```

The server will start on `http://localhost:8080` or `http://0.0.0.0:8080`

### Running the Web UI

1. Navigate to the web-ui directory:
```bash
cd web-ui
```

2. Install dependencies and run:
```bash
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

### Running the Mobile App

1. Navigate to the mobile-app directory:
```bash
cd mobile-app
```

2. Install dependencies and run:
```bash
flutter pub get
flutter run
```

### Development Scripts

Use the provided development scripts for easier setup:

```bash
# Backend development
./scripts/dev-backend.sh

# Web UI development  
./scripts/dev-web.sh

# Mobile app development
./scripts/dev-mobile.sh
```

### Docker Setup (Alternative)

```bash
docker-compose up -d
```

## Project Overview

Build a privacy-focused, modular, offline-first voice assistant platform that:

- Runs on a local server (Rust backend) with optional multi-user support
- Supports headless Raspberry Pi Zero W satellites for audio capture + wake word detection
- Provides a Flutter web admin UI and Flutter mobile companion app
- Supports user roles (admin, regular) with secure authentication
- Integrates with home automation (OpenHAB, MQTT)
- Has architecture extensible for local LLM support in the future

## Architecture

```
+-----------------------+        +----------------------------+       +--------------------+
| Raspberry Pi Satellite | <----> | Local Server (Rust backend)| <-->  | Database (SQLite)   |
| (Wake Word + Audio)    | MQTT/WS| - STT, Intent parsing      |       | - Users, Roles      |
|                       |        | - TTS, Command processing  |       | - Command logs      |
+-----------------------+        | - REST + WebSocket API     |       +--------------------+
                                 | - User Auth (JWT + bcrypt) |
                                 +----------------------------+
                                            ^
                                            |
                                     Flutter Web Admin UI
                                     Flutter Mobile App
```

## Components

### Rust Backend Server
- Audio ingestion from satellites
- STT engine integration (Whisper.cpp / Vosk bindings)
- Intent parsing & Command execution
- TTS engine integration (Piper / eSpeak NG)
- User management & Authentication (JWT tokens, bcrypt password hashing)
- Role-based access control (admin vs regular user)
- API endpoints (REST + WebSocket) for mobile and web clients
- OpenHAB / MQTT Bridge for home automation commands
- Command / voice history logging

### Raspberry Pi Satellite (Rust)
- Wake Word Detection using Porcupine or custom DSP
- Audio Capture (mic input via ALSA/PortAudio)
- Stream audio to server (MQTT or WebSocket)
- Play TTS responses locally
- Lightweight, auto-reconnect, secure comms (TLS)

### Flutter Web Admin UI
- Login / Logout
- User management (list users, add, edit roles)
- View command history & logs with filters
- Manage satellites (status, restart, config)
- System settings (STT model selection, TTS voice selection, home automation settings)
- Responsive UI for desktop and tablet

### Flutter Mobile App
- Login / Logout
- Voice command trigger (mic button)
- View recent commands and assistant responses
- Send text commands manually
- Show system status (satellite connection, server uptime)
- Optional push notifications (future)

## Technical Stack

| Layer | Technology / Tools |
|-------|-------------------|
| Backend Server | Rust (actix-web or axum) |
| STT | whisper.cpp Rust bindings, or vosk-rs |
| TTS | Piper (Rust), eSpeak NG |
| Wake Word (satellite) | Porcupine SDK (C++ / Rust FFI) |
| Satellite Audio Capture | Rust + ALSA / PortAudio |
| Communication | MQTT (Mosquitto), WebSocket |
| Authentication | JWT, bcrypt |
| Database | SQLite |
| Frontend (Web & Mobile) | Flutter |
| Home Automation Bridge | MQTT / REST API to OpenHAB |

## Security Features

- HTTPS / WSS for all client-server and satellite-server communication
- Passwords stored with bcrypt hashing and proper salting
- JWT tokens for session auth, short expiry times with refresh tokens
- Role-based API permissions (admin vs regular)
- Rate limiting on APIs to prevent abuse
- Secure MQTT with TLS + username/password authentication
- Input validation on all endpoints

## Development Roadmap

| Phase | Tasks | Est. Time (hours) |
|-------|-------|------------------|
| Phase 1 - MVP | Basic Rust backend + STT + simple intent parsing + SQLite DB | 80–100 |
| Phase 2 - Satellite | Rust audio capture client + wake word + MQTT streaming | 30–40 |
| Phase 3 - UI | Flutter web admin + mobile app MVP | 50–70 |
| Phase 4 - Security | Auth system + role management + HTTPS + MQTT TLS | 30–40 |
| Phase 5 - Home Automation | MQTT/OpenHAB bridge + command execution | 20–30 |
| Phase 6 - Polish | Testing, optimizations, error handling | 20–30 |

## Future Extensions

- **Local LLM Integration**: Microservice or Rust binding to run LLM inference (e.g. Llama, GPT4All)
- **Push Notifications**: Real-time alerts for users from server
- **Multi-language Support**: UI and STT/TTS expansion
- **Third-party Integrations**: Home automation platforms, calendar, reminders, weather APIs

## License

See [LICENSE](LICENSE) file for details.

1. Project Overview
Build a privacy-focused, modular, offline-first voice assistant platform that:

Runs on a local server (Rust backend) with optional multi-user support

Supports headless Raspberry Pi Zero W satellites that do audio capture + wake word detection and stream audio to server

Provides a Flutter web admin UI and Flutter mobile companion app

Supports user roles (admin, regular) with secure authentication

Integrates with home automation (OpenHAB, MQTT)

Has architecture extensible for local LLM support in the future



2. Architecture
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



3. Components & Responsibilities
3.1 Raspberry Pi Satellite (Rust)
Wake Word Detection using Porcupine or custom DSP

Audio Capture (mic input via ALSA/PortAudio)

Stream audio to server (MQTT or WebSocket)

Play TTS responses locally

Lightweight, auto-reconnect, secure comms (TLS)

3.2 Rust Backend Server
Audio ingestion from satellites

STT engine integration (Whisper.cpp / Vosk bindings)

Intent parsing & Command execution

TTS engine integration (Piper / eSpeak NG)

User management & Authentication (JWT tokens, bcrypt password hashing)

Role-based access control (admin vs regular user)

API endpoints (REST + WebSocket) for mobile and web clients

OpenHAB / MQTT Bridge for home automation commands

Command / voice history logging

3.3 Database (SQLite)
User accounts (username, email, hashed password, role)

Command history (timestamp, user, command text, intent)

Configuration (system-wide settings, satellite info)

Session management

3.4 Flutter Web Admin UI
Login / Logout

User management (list users, add, edit roles)

View command history & logs with filters

Manage satellites (status, restart, config)

System settings (STT model selection, TTS voice selection, home automation settings)

Responsive UI for desktop and tablet

3.5 Flutter Mobile App
Login / Logout

Voice command trigger (mic button)

View recent commands and assistant responses

Send text commands manually

Show system status (satellite connection, server uptime)

Optional push notifications (future)



4. Security Considerations
Use HTTPS / WSS for all client-server and satellite-server communication

Passwords stored with bcrypt hashing and proper salting

JWT tokens for session auth, short expiry times with refresh tokens

Role-based API permissions (admin vs regular)

Rate limiting on APIs to prevent abuse

Secure MQTT with TLS + username/password authentication

Input validation on all endpoints



5. Technical Stack
Layer	Technology / Tools
Backend Server	Rust (actix-web or axum)
STT	whisper.cpp Rust bindings, or vosk-rs
TTS	Piper (Rust), eSpeak NG
Wake Word (satellite)	Porcupine SDK (C++ / Rust FFI)
Satellite Audio Capture	Rust + ALSA / PortAudio
Communication	MQTT (Mosquitto), WebSocket
Authentication	JWT, bcrypt
Database	SQLite
Frontend (Web & Mobile)	Flutter
Home Automation Bridge	MQTT / REST API to OpenHAB



6. UI Design (High-Level)
6.1 Login Screen
Email & Password inputs

Submit button

Forgot password link (optional)

Error feedback on failure

6.2 Admin Dashboard (Web)
Sidebar Navigation: Users, Satellites, Logs, Settings

Users Page:

List users with search/filter

Add/Edit user modal (email, role dropdown, reset password)

Satellites Page:

List of connected satellites, status (online/offline), restart button

Logs Page:

Table of command history: timestamp, user, command, intent, status

Search & date filter

Settings Page:

STT model select dropdown

TTS voice select dropdown

MQTT broker settings

OpenHAB API config

6.3 Mobile App
Home Screen:

Large mic button for voice command

List of recent commands and responses

Status Indicator: Satellite connection status, backend online/offline

Settings: Account info, logout



7. Future Extensions
Local LLM Integration

Microservice or Rust binding to run LLM inference (e.g. Llama, GPT4All)

Extended intent parsing and conversational context

Push Notifications

Real-time alerts for users from server

Multi-language Support

UI and STT/TTS expansion

Third-party Integrations

Home automation platforms, calendar, reminders, weather APIs




8. Milestones & Timeline (Rough)
Phase	Tasks	Est. Time (hours)
Phase 1 - MVP	Basic Rust backend + STT + simple intent parsing + SQLite DB	80–100
Phase 2 - Satellite	Rust audio capture client + wake word + MQTT streaming	30–40
Phase 3 - UI	Flutter web admin + mobile app MVP	50–70
Phase 4 - Security	Auth system + role management + HTTPS + MQTT TLS	30–40
Phase 5 - Home Automation	MQTT/OpenHAB bridge + command execution	20–30
Phase 6 - Polish	Testing, optimizations, error handling	20–30





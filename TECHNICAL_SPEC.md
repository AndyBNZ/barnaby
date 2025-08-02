# Barnaby Voice Assistant Technical Specification

## 1. System Architecture

### 1.1 High-Level Architecture
```
┌─────────────────────┐    ┌──────────────────────────┐    ┌─────────────────┐
│ Raspberry Pi        │    │ Rust Backend Server      │    │ SQLite Database │
│ Satellites          │◄──►│ - STT/TTS Engine         │◄──►│ - Users/Roles   │
│ - Wake Word         │    │ - Intent Parser          │    │ - Command Logs  │
│ - Audio Capture     │    │ - WebSocket/REST API     │    │ - Config        │
│ - Local TTS         │    │ - Authentication         │    └─────────────────┘
└─────────────────────┘    │ - MQTT Bridge            │
                           └──────────────────────────┘
                                      ▲
                                      │
                           ┌──────────┴──────────┐
                           │                     │
                    ┌─────────────┐    ┌─────────────┐
                    │ Flutter Web │    │ Flutter     │
                    │ Admin UI    │    │ Mobile App  │
                    └─────────────┘    └─────────────┘
```

### 1.2 Communication Protocols
- **Satellite ↔ Server**: MQTT over TLS (audio streaming, commands)
- **Web/Mobile ↔ Server**: WebSocket + REST API over HTTPS
- **Home Automation**: MQTT/HTTP to OpenHAB

## 2. Backend Server Specification

### 2.1 Core Dependencies
```toml
[dependencies]
# Web Framework
axum = "0.7"
tokio = { version = "1.0", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "fs"] }

# Database
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "sqlite"] }
uuid = { version = "1.0", features = ["v4"] }

# Authentication
jsonwebtoken = "9.0"
bcrypt = "0.15"

# Audio Processing
whisper-rs = "0.10"  # STT
tts = "0.26"         # TTS

# MQTT
rumqttc = "0.24"

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# WebSocket
axum-tungstenite = "0.20"

# Configuration
config = "0.14"
```

### 2.2 Project Structure
```
src/
├── main.rs
├── config/
│   ├── mod.rs
│   └── settings.rs
├── database/
│   ├── mod.rs
│   ├── models.rs
│   ├── migrations/
│   └── queries.rs
├── auth/
│   ├── mod.rs
│   ├── jwt.rs
│   └── middleware.rs
├── audio/
│   ├── mod.rs
│   ├── stt.rs
│   └── tts.rs
├── intent/
│   ├── mod.rs
│   └── parser.rs
├── mqtt/
│   ├── mod.rs
│   └── client.rs
├── api/
│   ├── routes/
│   │   ├── auth.rs
│   │   ├── users.rs
│   │   ├── commands.rs
│   │   └── satellites.rs
│   └── websocket.rs
└── home_automation/
    ├── mod.rs
    └── openhab.rs
```

### 2.3 Database Schema
```sql
-- Users table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'user')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Satellites table
CREATE TABLE satellites (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    mac_address TEXT UNIQUE,
    ip_address TEXT,
    status TEXT DEFAULT 'offline',
    last_seen DATETIME,
    config JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Command history
CREATE TABLE command_history (
    id TEXT PRIMARY KEY,
    user_id TEXT REFERENCES users(id),
    satellite_id TEXT REFERENCES satellites(id),
    command_text TEXT NOT NULL,
    intent TEXT,
    response TEXT,
    confidence REAL,
    processing_time_ms INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Sessions for JWT refresh tokens
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT REFERENCES users(id),
    refresh_token TEXT UNIQUE NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- System configuration
CREATE TABLE config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 2.4 API Endpoints

#### Authentication
```
POST /api/auth/login
POST /api/auth/logout
POST /api/auth/refresh
GET  /api/auth/me
```

#### Users (Admin only)
```
GET    /api/users
POST   /api/users
GET    /api/users/{id}
PUT    /api/users/{id}
DELETE /api/users/{id}
```

#### Commands
```
GET  /api/commands/history
POST /api/commands/execute
```

#### Satellites
```
GET    /api/satellites
GET    /api/satellites/{id}
PUT    /api/satellites/{id}
POST   /api/satellites/{id}/restart
```

#### WebSocket
```
WS /ws/audio     # Audio streaming from satellites
WS /ws/events    # Real-time events for UI
```

### 2.5 Configuration Structure
```rust
#[derive(Debug, Deserialize)]
pub struct Settings {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub auth: AuthConfig,
    pub audio: AudioConfig,
    pub mqtt: MqttConfig,
    pub home_automation: HomeAutomationConfig,
}

#[derive(Debug, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
    pub tls_cert: Option<String>,
    pub tls_key: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AudioConfig {
    pub stt_model_path: String,
    pub tts_voice: String,
    pub sample_rate: u32,
    pub chunk_size: usize,
}
```

## 3. Raspberry Pi Satellite Specification

### 3.1 Dependencies
```toml
[dependencies]
tokio = { version = "1.0", features = ["full"] }
rumqttc = "0.24"
alsa = "0.9"
pv-porcupine = "3.0"  # Wake word detection
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
uuid = { version = "1.0", features = ["v4"] }
config = "0.14"
```

### 3.2 Satellite Structure
```
src/
├── main.rs
├── config/
│   ├── mod.rs
│   └── settings.rs
├── audio/
│   ├── mod.rs
│   ├── capture.rs
│   ├── playback.rs
│   └── wake_word.rs
├── mqtt/
│   ├── mod.rs
│   └── client.rs
└── utils/
    ├── mod.rs
    └── reconnect.rs
```

### 3.3 MQTT Topics
```
# Audio streaming
barnaby/satellites/{satellite_id}/audio/stream
barnaby/satellites/{satellite_id}/audio/end

# Commands
barnaby/satellites/{satellite_id}/commands/tts
barnaby/satellites/{satellite_id}/commands/restart
barnaby/satellites/{satellite_id}/commands/config

# Status
barnaby/satellites/{satellite_id}/status/heartbeat
barnaby/satellites/{satellite_id}/status/online
barnaby/satellites/{satellite_id}/status/offline
```

## 4. Flutter Applications

### 4.1 Shared Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  web_socket_channel: ^2.4.0
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

### 4.2 State Management Structure
```dart
// Models
class User {
  final String id;
  final String username;
  final String email;
  final UserRole role;
}

class Satellite {
  final String id;
  final String name;
  final String status;
  final DateTime? lastSeen;
}

class CommandHistory {
  final String id;
  final String commandText;
  final String? intent;
  final String? response;
  final DateTime createdAt;
}

// Providers
class AuthProvider extends ChangeNotifier
class SatelliteProvider extends ChangeNotifier
class CommandProvider extends ChangeNotifier
```

## 5. Security Implementation

### 5.1 Authentication Flow
```rust
// JWT Token Structure
#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,        // user_id
    pub username: String,
    pub role: String,
    pub exp: usize,         // expiration
    pub iat: usize,         // issued at
}

// Password hashing
pub fn hash_password(password: &str) -> Result<String> {
    bcrypt::hash(password, bcrypt::DEFAULT_COST)
        .map_err(|e| anyhow::anyhow!("Failed to hash password: {}", e))
}
```

### 5.2 Rate Limiting
```rust
use tower::limit::RateLimitLayer;
use std::time::Duration;

// Apply to sensitive endpoints
let rate_limit = RateLimitLayer::new(10, Duration::from_secs(60));
```

## 6. Development Phases

### Phase 1: Core Backend (80-100 hours)
**Week 1-2:**
- [ ] Project setup and basic Axum server
- [ ] SQLite database setup with migrations
- [ ] Basic user model and authentication
- [ ] JWT token generation and validation

**Week 3-4:**
- [ ] STT integration (Whisper.cpp)
- [ ] TTS integration (Piper)
- [ ] Basic intent parsing
- [ ] Command history logging

**Deliverable:** Working backend that can process audio and return responses

### Phase 2: Satellite Client (30-40 hours)
**Week 5:**
- [ ] Raspberry Pi audio capture setup
- [ ] Wake word detection integration
- [ ] MQTT client implementation
- [ ] Audio streaming to server

**Deliverable:** Raspberry Pi that can detect wake words and stream audio

### Phase 3: UI Development (50-70 hours)
**Week 6-7:**
- [ ] Flutter web admin dashboard
- [ ] User management interface
- [ ] Command history viewer
- [ ] Satellite management

**Week 8:**
- [ ] Flutter mobile app
- [ ] Voice command interface
- [ ] Recent commands view

**Deliverable:** Complete web and mobile interfaces

### Phase 4: Security Hardening (30-40 hours)
**Week 9:**
- [ ] HTTPS/TLS implementation
- [ ] MQTT security (TLS + auth)
- [ ] Rate limiting
- [ ] Input validation
- [ ] Security testing

**Deliverable:** Production-ready security

### Phase 5: Home Automation (20-30 hours)
**Week 10:**
- [ ] OpenHAB integration
- [ ] MQTT bridge for home automation
- [ ] Command execution framework

**Deliverable:** Working home automation integration

### Phase 6: Polish & Testing (20-30 hours)
**Week 11:**
- [ ] Comprehensive testing
- [ ] Error handling improvements
- [ ] Performance optimization
- [ ] Documentation

**Deliverable:** Production-ready system

## 7. Testing Strategy

### 7.1 Backend Testing
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_user_authentication() {
        // Test JWT generation and validation
    }
    
    #[tokio::test]
    async fn test_stt_processing() {
        // Test audio processing pipeline
    }
}
```

### 7.2 Integration Testing
- MQTT message flow testing
- WebSocket connection testing
- Database transaction testing
- Audio pipeline end-to-end testing

## 8. Deployment Considerations

### 8.1 Server Requirements
- **CPU:** ARM64 or x86_64 (Raspberry Pi 4+ recommended)
- **RAM:** 4GB minimum (8GB recommended for STT models)
- **Storage:** 32GB+ (models require significant space)
- **Network:** Stable WiFi/Ethernet for MQTT communication

### 8.2 Configuration Files
```yaml
# config/production.yaml
server:
  host: "0.0.0.0"
  port: 8443
  tls_cert: "/etc/barnaby/cert.pem"
  tls_key: "/etc/barnaby/key.pem"

database:
  url: "sqlite:///var/lib/barnaby/barnaby.db"

audio:
  stt_model_path: "/var/lib/barnaby/models/whisper-base.bin"
  tts_voice: "en_US-lessac-medium"

mqtt:
  broker: "localhost"
  port: 8883
  username: "barnaby"
  password: "${MQTT_PASSWORD}"
  use_tls: true
```

This specification provides a comprehensive roadmap for building the Barnaby system with clear milestones, technical details, and implementation guidance.

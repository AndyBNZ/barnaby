# Barnaby Phase 1: Core Backend - Detailed Plan
**Timeline: 5-6 weeks (80-100 hours) at 2-4 hours/day**

## Week 1: Foundation & Setup (14-16 hours)

### Day 1 (2-3 hours): Project Setup
**Tasks:**
- [ ] Run `./setup.sh` to initialize project structure
- [ ] Install cargo-watch: `cargo install cargo-watch`
- [ ] Test basic server startup: `./scripts/dev-backend.sh`
- [ ] Verify database creation and admin user

**Expected Output:**
- Server responds to `curl http://localhost:3000`
- Database file `backend/barnaby.db` exists
- Admin user can be queried from database

### Day 2 (2-3 hours): Configuration System
**Tasks:**
- [ ] Create `src/config/mod.rs` and `src/config/settings.rs`
- [ ] Implement configuration loading from files and environment
- [ ] Add configuration validation
- [ ] Test different config scenarios

**Code Focus:**
```rust
// src/config/settings.rs
#[derive(Debug, Deserialize)]
pub struct Settings {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub auth: AuthConfig,
}
```

### Day 3 (2-3 hours): Database Models
**Tasks:**
- [ ] Create `src/database/mod.rs` and `src/database/models.rs`
- [ ] Implement User, Satellite, CommandHistory structs
- [ ] Add SQLx database connection pool
- [ ] Create basic CRUD operations for User model

**Code Focus:**
```rust
// src/database/models.rs
#[derive(Debug, sqlx::FromRow, Serialize)]
pub struct User {
    pub id: String,
    pub username: String,
    pub email: String,
    pub password_hash: String,
    pub role: UserRole,
}
```

### Day 4 (2-3 hours): Authentication Foundation
**Tasks:**
- [ ] Create `src/auth/mod.rs` and `src/auth/jwt.rs`
- [ ] Implement JWT token generation and validation
- [ ] Add password hashing with bcrypt
- [ ] Create auth middleware structure

**Code Focus:**
```rust
// src/auth/jwt.rs
pub fn generate_token(user: &User) -> Result<String>
pub fn validate_token(token: &str) -> Result<Claims>
```

### Day 5 (2-4 hours): Basic API Endpoints
**Tasks:**
- [ ] Create `src/api/routes/auth.rs`
- [ ] Implement POST /api/auth/login endpoint
- [ ] Implement POST /api/auth/register endpoint
- [ ] Add proper error handling and responses
- [ ] Test endpoints with curl or Postman

**Expected Output:**
- Can register new users via API
- Can login and receive JWT token
- Token validation works

## Week 2: Authentication & User Management (14-16 hours)

### Day 6 (2-3 hours): Auth Middleware
**Tasks:**
- [ ] Create `src/auth/middleware.rs`
- [ ] Implement JWT validation middleware
- [ ] Add role-based access control
- [ ] Protect admin-only endpoints

**Code Focus:**
```rust
// src/auth/middleware.rs
pub async fn auth_middleware(
    req: Request<Body>,
    next: Next<Body>,
) -> Result<Response, StatusCode>
```

### Day 7 (2-3 hours): User Management API
**Tasks:**
- [ ] Create `src/api/routes/users.rs`
- [ ] Implement GET /api/users (admin only)
- [ ] Implement POST /api/users (admin only)
- [ ] Add user validation and error handling

### Day 8 (2-3 hours): Database Queries
**Tasks:**
- [ ] Create `src/database/queries.rs`
- [ ] Implement user CRUD operations with SQLx
- [ ] Add database transaction handling
- [ ] Create database connection management

### Day 9 (2-3 hours): Error Handling & Logging
**Tasks:**
- [ ] Implement proper error types with thiserror
- [ ] Add structured logging with tracing
- [ ] Create error response formatting
- [ ] Add request/response logging middleware

### Day 10 (2-4 hours): Testing & Validation
**Tasks:**
- [ ] Write unit tests for auth functions
- [ ] Test user registration/login flow
- [ ] Validate JWT token expiration
- [ ] Test role-based access control

**Expected Output:**
- Complete user authentication system
- Admin can manage users via API
- Proper error handling and logging
- All auth tests pass

## Week 3: Audio Processing Foundation (14-16 hours)

### Day 11 (3-4 hours): STT Research & Setup
**Tasks:**
- [ ] Research Whisper.cpp Rust bindings
- [ ] Add whisper-rs dependency (or alternative)
- [ ] Download a small Whisper model for testing
- [ ] Create `src/audio/mod.rs` and `src/audio/stt.rs`

**Note:** This may take longer due to model setup complexity

### Day 12 (2-3 hours): Basic STT Implementation
**Tasks:**
- [ ] Implement basic audio file processing
- [ ] Create STT service structure
- [ ] Add audio format validation
- [ ] Test with sample audio files

**Code Focus:**
```rust
// src/audio/stt.rs
pub struct SttService {
    model: WhisperModel,
}

impl SttService {
    pub async fn transcribe(&self, audio_data: Vec<u8>) -> Result<String>
}
```

### Day 13 (2-3 hours): TTS Integration
**Tasks:**
- [ ] Research TTS options (Piper, eSpeak, or cloud API)
- [ ] Create `src/audio/tts.rs`
- [ ] Implement basic text-to-speech
- [ ] Test audio output generation

### Day 14 (2-3 hours): Audio API Endpoints
**Tasks:**
- [ ] Create `src/api/routes/audio.rs`
- [ ] Implement POST /api/audio/transcribe
- [ ] Implement POST /api/audio/synthesize
- [ ] Add audio file upload handling

### Day 15 (2-4 hours): Audio Pipeline Testing
**Tasks:**
- [ ] Test complete STT pipeline with real audio
- [ ] Test TTS output quality
- [ ] Measure processing performance
- [ ] Add error handling for audio processing

**Expected Output:**
- Can upload audio and get transcription
- Can send text and get audio response
- Basic audio processing pipeline works

## Week 4: Intent Processing & Commands (14-16 hours)

### Day 16 (2-3 hours): Intent Parser Foundation
**Tasks:**
- [ ] Create `src/intent/mod.rs` and `src/intent/parser.rs`
- [ ] Implement basic keyword matching
- [ ] Define intent types and structures
- [ ] Create intent confidence scoring

**Code Focus:**
```rust
// src/intent/parser.rs
#[derive(Debug, Serialize)]
pub struct Intent {
    pub name: String,
    pub confidence: f32,
    pub parameters: HashMap<String, String>,
}

pub fn parse_intent(text: &str) -> Result<Intent>
```

### Day 17 (2-3 hours): Command Execution Framework
**Tasks:**
- [ ] Create command execution system
- [ ] Implement basic commands (time, weather placeholder, etc.)
- [ ] Add command response generation
- [ ] Create command registry

### Day 18 (2-3 hours): Command History
**Tasks:**
- [ ] Create `src/api/routes/commands.rs`
- [ ] Implement command history logging
- [ ] Add GET /api/commands/history endpoint
- [ ] Create command statistics

### Day 19 (2-3 hours): Voice Command Pipeline
**Tasks:**
- [ ] Integrate STT → Intent → Command → TTS pipeline
- [ ] Create POST /api/voice/process endpoint
- [ ] Add pipeline error handling
- [ ] Test complete voice processing flow

### Day 20 (2-4 hours): Command Testing & Refinement
**Tasks:**
- [ ] Test various voice commands
- [ ] Refine intent recognition accuracy
- [ ] Add more command types
- [ ] Performance optimization

**Expected Output:**
- Complete voice command processing pipeline
- Can speak to system and get audio responses
- Command history is logged and retrievable

## Week 5: MQTT & Satellite Preparation (12-14 hours)

### Day 21 (2-3 hours): MQTT Client Setup
**Tasks:**
- [ ] Create `src/mqtt/mod.rs` and `src/mqtt/client.rs`
- [ ] Implement MQTT connection and reconnection
- [ ] Add topic subscription handling
- [ ] Test with local Mosquitto broker

### Day 22 (2-3 hours): Satellite Communication Protocol
**Tasks:**
- [ ] Define MQTT message formats for satellites
- [ ] Implement satellite registration system
- [ ] Create `src/api/routes/satellites.rs`
- [ ] Add satellite status tracking

### Day 23 (2-3 hours): Audio Streaming Over MQTT
**Tasks:**
- [ ] Implement audio chunk streaming
- [ ] Add audio reassembly on server side
- [ ] Test audio quality over MQTT
- [ ] Add streaming error handling

### Day 24 (2-4 hours): WebSocket Support
**Tasks:**
- [ ] Create `src/api/websocket.rs`
- [ ] Implement WebSocket connections for real-time updates
- [ ] Add client notification system
- [ ] Test WebSocket communication

**Expected Output:**
- MQTT communication working
- Satellite registration system
- Audio streaming capability
- WebSocket real-time updates

## Week 6: Integration & Polish (10-12 hours)

### Day 25 (2-3 hours): End-to-End Testing
**Tasks:**
- [ ] Test complete system integration
- [ ] Verify all API endpoints work
- [ ] Test error scenarios
- [ ] Performance testing

### Day 26 (2-3 hours): Security Hardening
**Tasks:**
- [ ] Add input validation to all endpoints
- [ ] Implement rate limiting
- [ ] Add CORS configuration
- [ ] Security audit of authentication

### Day 27 (2-3 hours): Documentation & Cleanup
**Tasks:**
- [ ] Add API documentation
- [ ] Clean up code and add comments
- [ ] Update configuration examples
- [ ] Create deployment guide

### Day 28 (2-4 hours): Final Testing & Preparation
**Tasks:**
- [ ] Comprehensive system testing
- [ ] Performance benchmarking
- [ ] Prepare for Phase 2 (satellite development)
- [ ] Create Phase 1 completion report

## Success Criteria for Phase 1:

✅ **Authentication System:**
- Users can register, login, and manage accounts
- JWT tokens work correctly
- Role-based access control functions

✅ **Audio Processing:**
- STT converts speech to text accurately
- TTS generates clear audio responses
- Audio pipeline processes requests in <3 seconds

✅ **Voice Commands:**
- System recognizes basic intents
- Commands execute and return responses
- Command history is logged

✅ **Communication:**
- MQTT client connects and handles messages
- WebSocket provides real-time updates
- API endpoints are documented and tested

✅ **Infrastructure:**
- Database operations are reliable
- Error handling is comprehensive
- Logging provides useful debugging info

## Daily Development Tips:

### 2-Hour Sessions (Weekdays):
- Focus on single, well-defined tasks
- Prioritize coding over research
- Use existing examples and documentation
- Commit progress frequently

### 4-Hour Sessions (Weekends):
- Tackle complex integration tasks
- Do research and experimentation
- Write comprehensive tests
- Refactor and optimize code

### Productivity Tips:
- Start each session by reviewing previous day's work
- Keep a development journal of decisions and blockers
- Use `cargo watch` for fast iteration
- Test frequently with curl commands
- Don't get stuck on perfect solutions - iterate

### When You Get Stuck:
- Break the problem into smaller pieces
- Look for existing Rust examples online
- Use placeholder implementations initially
- Ask for help on specific technical issues
- Document what you tried for future reference

This detailed plan gives you a clear roadmap for the next 5-6 weeks, with realistic daily goals that fit your 2-4 hour schedule!

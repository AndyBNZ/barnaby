#!/bin/bash

# Barnaby Voice Assistant Setup Script
set -e

echo "🚀 Setting up Barnaby (Voice Assistant System) project..."

# Check prerequisites
check_prerequisites() {
    echo "📋 Checking prerequisites..."
    
    if ! command -v rustc &> /dev/null; then
        echo "❌ Rust not found. Please install Rust from https://rustup.rs/"
        exit 1
    fi
    
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter not found. Please install Flutter from https://flutter.dev/"
        exit 1
    fi
    
    if ! command -v sqlite3 &> /dev/null; then
        echo "❌ SQLite not found. Please install SQLite3"
        exit 1
    fi
    
    echo "✅ All prerequisites found!"
}

# Create project structure
create_structure() {
    echo "📁 Creating project structure..."
    
    mkdir -p {backend,satellite,web-ui,mobile-app,docs,scripts,docker,tests}
    
    # Create backend Rust project
    cd backend
    if [ ! -f Cargo.toml ]; then
        cargo init --name barnaby-server
        echo "✅ Backend Rust project initialized"
    fi
    cd ..
    
    # Create satellite Rust project
    cd satellite
    if [ ! -f Cargo.toml ]; then
        cargo init --name barnaby-satellite
        echo "✅ Satellite Rust project initialized"
    fi
    cd ..
    
    # Create Flutter web project
    cd web-ui
    if [ ! -f pubspec.yaml ]; then
        flutter create . --project-name barnaby_web_ui --platforms web
        echo "✅ Flutter web project initialized"
    fi
    cd ..
    
    # Create Flutter mobile project
    cd mobile-app
    if [ ! -f pubspec.yaml ]; then
        flutter create . --project-name barnaby_mobile --platforms android,ios
        echo "✅ Flutter mobile project initialized"
    fi
    cd ..
}

# Setup backend dependencies
setup_backend() {
    echo "🦀 Setting up backend dependencies..."
    
    cd backend
    
    # Create Cargo.toml with dependencies
    cat > Cargo.toml << 'EOF'
[package]
name = "barnaby-server"
version = "0.1.0"
edition = "2021"

[dependencies]
# Web Framework
axum = { version = "0.7", features = ["ws", "headers"] }
tokio = { version = "1.0", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "fs", "trace"] }

# Database
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "sqlite", "uuid", "chrono"] }
uuid = { version = "1.0", features = ["v4", "serde"] }

# Authentication
jsonwebtoken = "9.0"
bcrypt = "0.15"

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Configuration
config = "0.14"
dotenvy = "0.15"

# Logging
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }

# Error handling
anyhow = "1.0"
thiserror = "1.0"

# MQTT
rumqttc = "0.24"

# Time
chrono = { version = "0.4", features = ["serde"] }

# Audio (placeholder - will need platform-specific setup)
# whisper-rs = "0.10"  # Uncomment when ready for STT
# tts = "0.26"         # Uncomment when ready for TTS
EOF

    # Create basic project structure
    mkdir -p src/{config,database,auth,api,mqtt}
    mkdir -p migrations
    
    # Create main.rs
    cat > src/main.rs << 'EOF'
use axum::{
    routing::{get, post},
    Router,
    response::Json,
    http::StatusCode,
};
use serde_json::{json, Value};
use tower_http::cors::CorsLayer;
use tracing::{info, Level};
use tracing_subscriber;

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_max_level(Level::INFO)
        .init();

    info!("Starting Barnaby server...");

    // Build our application with routes
    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health_check))
        .route("/api/auth/login", post(login_placeholder))
        .layer(CorsLayer::permissive());

    // Run the server
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    info!("Barnaby server running on http://0.0.0.0:3000");
    
    axum::serve(listener, app).await.unwrap();
}

async fn root() -> Json<Value> {
    Json(json!({
        "message": "Barnaby Voice Assistant is running!",
        "version": "0.1.0"
    }))
}

async fn health_check() -> Json<Value> {
    Json(json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now()
    }))
}

async fn login_placeholder() -> Result<Json<Value>, StatusCode> {
    // Placeholder for authentication
    Ok(Json(json!({
        "message": "Authentication endpoint - not implemented yet"
    })))
}
EOF

    # Create initial database migration
    cat > migrations/001_initial.sql << 'EOF'
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
    config TEXT, -- JSON config
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

-- Insert default admin user (password: admin123)
INSERT INTO users (id, username, email, password_hash, role) VALUES 
('admin-001', 'admin', 'admin@barnaby.local', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PJ/..G', 'admin');
EOF

    # Create .env file
    cat > .env << 'EOF'
DATABASE_URL=sqlite:barnaby.db
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
MQTT_BROKER=localhost
MQTT_PORT=1883
RUST_LOG=info
EOF

    echo "✅ Backend setup complete!"
    cd ..
}

# Setup database
setup_database() {
    echo "🗄️ Setting up database..."
    
    cd backend
    
    # Create database and run migrations
    sqlite3 barnaby.db < migrations/001_initial.sql
    
    echo "✅ Database initialized with default admin user"
    echo "   Username: admin"
    echo "   Password: admin123"
    
    cd ..
}

# Setup development scripts
setup_scripts() {
    echo "📜 Creating development scripts..."
    
    # Backend development script
    cat > scripts/dev-backend.sh << 'EOF'
#!/bin/bash
cd backend
export RUST_LOG=debug
cargo watch -x run
EOF

    # Frontend development script
    cat > scripts/dev-web.sh << 'EOF'
#!/bin/bash
cd web-ui
flutter run -d chrome --web-port 8080
EOF

    # Mobile development script
    cat > scripts/dev-mobile.sh << 'EOF'
#!/bin/bash
cd mobile-app
flutter run
EOF

    # Make scripts executable
    chmod +x scripts/*.sh
    
    echo "✅ Development scripts created!"
}

# Create Docker setup
setup_docker() {
    echo "🐳 Creating Docker configuration..."
    
    # Backend Dockerfile
    cat > docker/Dockerfile.backend << 'EOF'
FROM rust:1.75 as builder

WORKDIR /app
COPY backend/Cargo.toml backend/Cargo.lock ./
COPY backend/src ./src
COPY backend/migrations ./migrations

RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/target/release/barnaby-server .
COPY --from=builder /app/migrations ./migrations

EXPOSE 3000
CMD ["./barnaby-server"]
EOF

    # Docker Compose
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  barnaby-server:
    build:
      context: .
      dockerfile: docker/Dockerfile.backend
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=sqlite:/app/data/barnaby.db
      - RUST_LOG=info
    volumes:
      - barnaby_data:/app/data
    restart: unless-stopped

  mosquitto:
    image: eclipse-mosquitto:2.0
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./docker/mosquitto.conf:/mosquitto/config/mosquitto.conf
      - mosquitto_data:/mosquitto/data
      - mosquitto_logs:/mosquitto/log
    restart: unless-stopped

volumes:
  barnaby_data:
  mosquitto_data:
  mosquitto_logs:
EOF

    # Mosquitto config
    mkdir -p docker
    cat > docker/mosquitto.conf << 'EOF'
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF

    echo "✅ Docker configuration created!"
}

# Main setup function
main() {
    echo "🎯 Barnaby Voice Assistant Setup"
    echo "================================"
    
    check_prerequisites
    create_structure
    setup_backend
    setup_database
    setup_scripts
    setup_docker
    
    echo ""
    echo "🎉 Barnaby project setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Start the backend server:"
    echo "   ./scripts/dev-backend.sh"
    echo ""
    echo "2. Test the server:"
    echo "   curl http://localhost:3000"
    echo ""
    echo "3. Start web UI development:"
    echo "   ./scripts/dev-web.sh"
    echo ""
    echo "4. Read the technical specification:"
    echo "   cat TECHNICAL_SPEC.md"
    echo ""
    echo "5. Follow the development roadmap:"
    echo "   cat DEVELOPMENT_ROADMAP.md"
    echo ""
    echo "Happy coding with Barnaby! 🤖"
}

# Run main function
main "$@"

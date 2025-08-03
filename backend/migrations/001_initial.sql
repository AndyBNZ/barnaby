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
('admin-001', 'admin', 'admin@barnaby.local', '$2b$12$Ev7dYM1ZZrUIOe31e6HHKuFLMocxY1HWtKj/4OvB.tN1bJfwZxlxi', 'admin');

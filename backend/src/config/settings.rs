use serde::Deserialize;

#[derive(Debug, Deserialize, Clone)]
pub struct Settings {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub auth: AuthConfig,
    pub audio: AudioConfig,
    pub mqtt: MqttConfig,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

#[derive(Debug, Deserialize, Clone)]
pub struct DatabaseConfig {
    pub url: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct AuthConfig {
    pub jwt_secret: String,
    pub jwt_expiration: u64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct AudioConfig {
    pub sample_rate: u32,
    pub chunk_size: usize,
}

#[derive(Debug, Deserialize, Clone)]
pub struct MqttConfig {
    pub broker: String,
    pub port: u16,
    pub username: Option<String>,
    pub password: Option<String>,
}

impl Settings {
    pub fn new() -> Result<Self, config::ConfigError> {
        let settings = config::Config::builder()
            .add_source(config::Environment::with_prefix("BARNABY"))
            .set_default("server.host", "0.0.0.0")?
            .set_default("server.port", 3000)?
            .set_default("database.url", "sqlite:barnaby.db")?
            .set_default("auth.jwt_secret", "your-secret-key-change-in-production")?
            .set_default("auth.jwt_expiration", 3600)?
            .set_default("audio.sample_rate", 16000)?
            .set_default("audio.chunk_size", 1024)?
            .set_default("mqtt.broker", "localhost")?
            .set_default("mqtt.port", 1883)?
            .build()?;

        settings.try_deserialize()
    }
}
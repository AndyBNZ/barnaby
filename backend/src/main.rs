mod api;
mod auth;
mod config;
mod database;
mod middleware;
mod mqtt;
mod nlu;
mod services;

use axum::{
    routing::get,
    Router,
    response::Json,
};
use serde_json::{json, Value};
use sqlx::SqlitePool;
use tower_http::cors::CorsLayer;
use tracing::{error, info, Level};
use tracing_subscriber;

use config::Settings;
use mqtt::MqttService;
use nlu::RasaManager;

#[derive(Clone)]
pub struct AppState {
    pub db: SqlitePool,
    pub config: Settings,
    pub mqtt: Option<MqttService>,
    pub nlu_url: String,
}



#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_max_level(Level::INFO)
        .init();

    info!("Starting Barnaby Digital Butler server...");

    // Load configuration
    let config = match Settings::new() {
        Ok(config) => config,
        Err(e) => {
            error!("Failed to load configuration: {}", e);
            std::process::exit(1);
        }
    };

    // Setup database
    let db = match database::create_pool(&config.database.url).await {
        Ok(pool) => pool,
        Err(e) => {
            error!("Failed to create database pool: {}", e);
            std::process::exit(1);
        }
    };

    // Start Rasa NLU server
    let mut rasa_manager = RasaManager::new();
    if let Err(e) = rasa_manager.start().await {
        error!("Failed to start Rasa NLU: {}. Falling back to Rust NLU.", e);
    }

    // MQTT client disabled for now - can be enabled when broker is available
    info!("MQTT client disabled - enable when broker is configured");
    let mqtt = None;

    // Create application state
    let state = AppState {
        db,
        config: config.clone(),
        mqtt,
        nlu_url: "http://localhost:5005".to_string(),
    };

    // Build application with routes
    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health_check))
        .merge(api::create_routes())
        .layer(axum::middleware::from_fn(middleware::logging_middleware))
        .layer(CorsLayer::permissive())
        .with_state(state);

    // Start server
    let bind_addr = format!("{}:{}", config.server.host, config.server.port);
    let listener = match tokio::net::TcpListener::bind(&bind_addr).await {
        Ok(listener) => listener,
        Err(e) => {
            error!("Failed to bind to {}: {}. Port may already be in use.", bind_addr, e);
            std::process::exit(1);
        }
    };
    info!("Barnaby server running on http://{}", bind_addr);
    
    if let Err(e) = axum::serve(listener, app).await {
        error!("Server error: {}", e);
    }
}

async fn root() -> Json<Value> {
    Json(json!({
        "message": "Barnaby Digital Butler is running!",
        "version": "0.1.0",
        "status": "operational"
    }))
}

async fn health_check() -> Json<Value> {
    Json(json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now(),
        "service": "barnaby-digital-butler"
    }))
}

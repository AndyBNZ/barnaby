use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use uuid::Uuid;

use crate::{database::models::CommandHistory, nlu::{NluService, RustNlu}, services::weather::WeatherService, AppState};
use tracing::info;

#[derive(Debug, Deserialize)]
pub struct ProcessVoiceRequest {
    pub audio_data: String, // Base64 encoded audio or "text:message" for text input
    pub satellite_id: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ProcessVoiceResponse {
    pub transcription: String,
    pub intent: String,
    pub response: String,
    pub audio_response: String, // Base64 encoded TTS audio
}

pub fn create_routes() -> Router<AppState> {
    Router::new()
        .route("/history", get(get_command_history))
        .route("/process", post(process_voice_command))
}

pub async fn get_command_history(
    State(state): State<AppState>,
) -> Result<Json<Value>, StatusCode> {
    let commands = sqlx::query_as::<_, CommandHistory>(
        "SELECT * FROM command_history ORDER BY created_at DESC LIMIT 50",
    )
    .fetch_all(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(json!({
        "commands": commands
    })))
}

pub async fn process_voice_command(
    State(state): State<AppState>,
    Json(payload): Json<ProcessVoiceRequest>,
) -> Result<Json<ProcessVoiceResponse>, StatusCode> {
    info!("Processing voice command: {:?}", payload);
    // 1. STT: Convert audio to text or extract text input
    let transcription = if payload.audio_data.starts_with("text:") {
        payload.audio_data.strip_prefix("text:").unwrap_or(&payload.audio_data)
    } else {
        "Audio processing not yet implemented" // TODO: Implement actual STT
    };
    
    info!("Transcription: {}", transcription);
    
    // 2. Intent parsing using LLM -> Rasa NLU -> Rust NLU fallback chain
    let mut nlu_service = NluService::new(state.nlu_url.clone());
    
    // Add LLM service if available
    if let Some(llm) = &state.llm_service {
        nlu_service = nlu_service.with_llm(llm.clone());
    }
    
    let rust_nlu = RustNlu::new();
    let (rust_intent, rust_entities) = rust_nlu.parse(transcription);
    
    let (intent, confidence, entities) = match nlu_service.parse_intent_with_llm(transcription).await {
        Ok(response) => {
            info!("LLM/Rasa NLU success: intent={}, confidence={:.2}", response.intent.name, response.intent.confidence);
            (response.intent.name, response.intent.confidence, rust_entities)
        }
        Err(e) => {
            info!("LLM/Rasa NLU failed, using Rust NLU fallback: {}", e);
            (rust_intent.name, rust_intent.confidence, rust_entities)
        }
    };
    info!("NLU response: intent={}, confidence={:.2}", intent, confidence);
    info!("Extracted entities: {:?}", entities);
    
    info!("Detected intent: {}", intent);
    
    // 3. Command execution
    let response = execute_command(&intent, &entities).await;
    info!("Generated response: {}", response);
    
    // 4. TTS: Convert response to audio
    let audio_response = "placeholder_audio_response"; // Placeholder
    
    // 5. Log command
    let command_id = Uuid::new_v4().to_string();
    sqlx::query(
        "INSERT INTO command_history (id, satellite_id, command_text, intent, response, confidence, processing_time_ms) VALUES (?, ?, ?, ?, ?, ?, ?)",
    )
    .bind(&command_id)
    .bind(&payload.satellite_id)
    .bind(transcription)
    .bind(&intent)
    .bind(&response)
    .bind(confidence as f32)
    .bind(150i32)
    .execute(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ProcessVoiceResponse {
        transcription: transcription.to_string(),
        intent,
        response,
        audio_response: audio_response.to_string(),
    }))
}

fn parse_intent_fallback(text: &str) -> String {
    // Simple keyword-based intent parsing
    let text_lower = text.to_lowercase();
    
    if text_lower.contains("time") {
        "get_time".to_string()
    } else if text_lower.contains("weather") {
        "get_weather".to_string()
    } else if text_lower.contains("light") {
        "control_lights".to_string()
    } else {
        "unknown".to_string()
    }
}

async fn execute_command(intent: &str, entities: &[crate::nlu::RustEntity]) -> String {
    match intent {
        "get_time" => {
            let now = chrono::Utc::now();
            format!("The current time is {}", now.format("%H:%M"))
        }
        "get_timezone" => {
            let now = chrono::Local::now();
            format!("You are in timezone: {}", now.format("%Z %z"))
        }
        "get_weather" => {
            let weather_service = WeatherService::new();
            
            // Check if location entity is present
            let location_entity = entities.iter().find(|e| e.name == "location");
            info!("Location entity found: {:?}", location_entity);
            
            let result = if let Some(location) = location_entity {
                info!("Getting weather for location: {}", location.value);
                weather_service.get_weather_for_location(&location.value).await
            } else {
                info!("No location specified, getting current weather");
                weather_service.get_current_weather().await
            };
            
            match result {
                Ok(weather) => {
                    let location_text = if let Some(loc) = location_entity {
                        format!(" in {}", loc.value)
                    } else {
                        " for your location".to_string()
                    };
                    format!(
                        "The current weather{} is {}°C with {}. Wind speed is {} km/h.",
                        location_text, weather.temperature, weather.description, weather.wind_speed
                    )
                },
                Err(e) => {
                    if e.to_string().contains("Location not found") {
                        "Sorry, I couldn't find that location. Please try a different city name.".to_string()
                    } else {
                        "Sorry, there's a connection issue and I cannot get that information right now.".to_string()
                    }
                }
            }
        }
        "control_lights" => "Light control is not yet implemented.".to_string(),
        "greet" => "Hello! How can I help you today?".to_string(),
        "goodbye" => "Goodbye! Have a great day!".to_string(),
        _ => "I didn't understand that command.".to_string(),
    }
}
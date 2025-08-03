use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::post,
    Router,
};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::fs::OpenOptions;
use std::io::Write;

use crate::AppState;

#[derive(Debug, Deserialize)]
pub struct FeedbackRequest {
    pub text: String,
    pub predicted_intent: String,
    pub correct_intent: String,
    pub confidence: f64,
}

pub fn create_routes() -> Router<AppState> {
    Router::new()
        .route("/intent", post(submit_intent_feedback))
}

pub async fn submit_intent_feedback(
    State(_state): State<AppState>,
    Json(payload): Json<FeedbackRequest>,
) -> Result<Json<Value>, StatusCode> {
    // Log feedback for manual review and future training
    let feedback_entry = format!(
        "- intent: {}\n  examples: |\n    - {}\n",
        payload.correct_intent, payload.text
    );
    
    // Append to a feedback file
    if let Ok(mut file) = OpenOptions::new()
        .create(true)
        .append(true)
        .open("../nlu/rasa/data/feedback.yml")
    {
        let _ = writeln!(file, "{}", feedback_entry);
    }
    
    Ok(Json(json!({
        "status": "feedback_recorded",
        "message": "Thank you for the feedback. This will help improve the system."
    })))
}
use serde::{Deserialize, Serialize};
use reqwest;

mod rasa_manager;
mod rust_nlu;
pub use rasa_manager::RasaManager;
pub use rust_nlu::{RustNlu, Entity as RustEntity};
pub use crate::services::llm::{LlmService, LlmIntent, LlmEntity};

#[derive(Debug, Serialize)]
pub struct NluRequest {
    pub text: String,
}

#[derive(Debug, Deserialize)]
pub struct NluResponse {
    pub intent: Intent,
    pub entities: Vec<Entity>,
}

#[derive(Debug, Deserialize)]
pub struct Intent {
    pub name: String,
    pub confidence: f64,
}

#[derive(Debug, Deserialize)]
pub struct Entity {
    pub entity: String,
    pub value: String,
    pub confidence: f64,
}

pub struct NluService {
    rasa_url: String,
    client: reqwest::Client,
    llm_service: Option<LlmService>,
}

impl NluService {
    pub fn new(rasa_url: String) -> Self {
        Self {
            rasa_url,
            client: reqwest::Client::new(),
            llm_service: None,
        }
    }

    pub fn with_llm(mut self, llm_service: LlmService) -> Self {
        self.llm_service = Some(llm_service);
        self
    }

    pub async fn parse_intent_with_llm(&self, text: &str) -> Result<NluResponse, Box<dyn std::error::Error>> {
        // Try LLM first if available
        if let Some(llm) = &self.llm_service {
            if llm.is_available().await {
                match llm.parse_intent(text).await {
                    Ok(llm_result) => {
                        return Ok(NluResponse {
                            intent: Intent {
                                name: llm_result.intent,
                                confidence: llm_result.confidence,
                            },
                            entities: llm_result.entities.into_iter().map(|e| Entity {
                                entity: e.name,
                                value: e.value,
                                confidence: 0.9,
                            }).collect(),
                        });
                    }
                    Err(e) => {
                        tracing::warn!("LLM parsing failed: {}, falling back to Rasa", e);
                    }
                }
            }
        }

        // Fallback to Rasa
        self.parse_intent(text).await
    }

    pub async fn parse_intent(&self, text: &str) -> Result<NluResponse, Box<dyn std::error::Error>> {
        let request = NluRequest {
            text: text.to_string(),
        };

        let response = self
            .client
            .post(&format!("{}/model/parse", self.rasa_url))
            .json(&request)
            .send()
            .await?;

        if response.status().is_success() {
            let nlu_response: NluResponse = response.json().await?;
            Ok(nlu_response)
        } else {
            Err(format!("Rasa API error: {}", response.status()).into())
        }
    }
}
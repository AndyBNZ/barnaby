use serde::{Deserialize, Serialize};
use reqwest;

mod rasa_manager;
mod rust_nlu;
pub use rasa_manager::RasaManager;
pub use rust_nlu::{RustNlu, Entity as RustEntity};

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
}

impl NluService {
    pub fn new(rasa_url: String) -> Self {
        Self {
            rasa_url,
            client: reqwest::Client::new(),
        }
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
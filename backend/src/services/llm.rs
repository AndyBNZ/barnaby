use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::{info, warn};

#[derive(Debug, Serialize, Deserialize)]
pub struct LlmIntent {
    pub intent: String,
    pub confidence: f64,
    pub entities: Vec<LlmEntity>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LlmEntity {
    pub name: String,
    pub value: String,
}

#[derive(Clone)]
pub struct LlmService {
    model_loaded: Arc<Mutex<bool>>,
    model_path: String,
}

impl LlmService {
    pub fn new(model_path: String) -> Self {
        Self {
            model_loaded: Arc::new(Mutex::new(false)),
            model_path,
        }
    }

    pub async fn initialize(&self) -> Result<()> {
        info!("Mock LLM service initializing with model path: {}", self.model_path);
        
        // Mock initialization - in real implementation, load actual model here
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
        
        let mut loaded = self.model_loaded.lock().await;
        *loaded = true;
        
        info!("Mock LLM service initialized successfully");
        Ok(())
    }

    pub async fn parse_intent(&self, text: &str) -> Result<LlmIntent> {
        let loaded = self.model_loaded.lock().await;
        if !*loaded {
            return Err(anyhow::anyhow!("Model not initialized"));
        }
        drop(loaded);

        info!("Mock LLM processing: {}", text);
        
        // Mock LLM processing with enhanced intent detection
        let text_lower = text.to_lowercase();
        
        let (intent, confidence, entities) = if text_lower.contains("weather") {
            let mut entities = vec![];
            
            // Enhanced location extraction
            if let Some(location) = self.extract_location(&text_lower) {
                entities.push(LlmEntity {
                    name: "location".to_string(),
                    value: location,
                });
            }
            
            ("get_weather".to_string(), 0.95, entities)
        } else if text_lower.contains("time") || text_lower.contains("clock") {
            ("get_time".to_string(), 0.92, vec![])
        } else if text_lower.contains("light") {
            let mut entities = vec![];
            
            // Enhanced room extraction
            if let Some(room) = self.extract_room(&text_lower) {
                entities.push(LlmEntity {
                    name: "room".to_string(),
                    value: room,
                });
            }
            
            ("control_lights".to_string(), 0.90, entities)
        } else if text_lower.contains("hello") || text_lower.contains("hi") || text_lower.contains("hey") {
            ("greet".to_string(), 0.88, vec![])
        } else if text_lower.contains("bye") || text_lower.contains("goodbye") {
            ("goodbye".to_string(), 0.85, vec![])
        } else {
            ("unknown".to_string(), 0.3, vec![])
        };

        Ok(LlmIntent {
            intent,
            confidence,
            entities,
        })
    }
    
    fn extract_location(&self, text: &str) -> Option<String> {
        // Enhanced location extraction patterns
        let patterns = [
            r"in ([a-zA-Z\s,]+?)(?:\?|$|\s+(?:today|tomorrow|now))",
            r"for ([a-zA-Z\s,]+?)(?:\?|$|\s+(?:today|tomorrow|now))",
            r"at ([a-zA-Z\s,]+?)(?:\?|$|\s+(?:today|tomorrow|now))",
        ];
        
        for pattern in &patterns {
            if let Ok(re) = regex::Regex::new(pattern) {
                if let Some(captures) = re.captures(text) {
                    if let Some(location) = captures.get(1) {
                        return Some(location.as_str().trim().to_string());
                    }
                }
            }
        }
        None
    }
    
    fn extract_room(&self, text: &str) -> Option<String> {
        let rooms = ["living room", "bedroom", "kitchen", "bathroom", "office", "dining room"];
        
        for room in &rooms {
            if text.contains(room) {
                return Some(room.to_string());
            }
        }
        None
    }

    fn extract_intent_fallback(&self, response: &str) -> String {
        let response_lower = response.to_lowercase();
        
        if response_lower.contains("weather") {
            "get_weather".to_string()
        } else if response_lower.contains("time") {
            "get_time".to_string()
        } else if response_lower.contains("light") {
            "control_lights".to_string()
        } else if response_lower.contains("hello") || response_lower.contains("greet") {
            "greet".to_string()
        } else if response_lower.contains("goodbye") || response_lower.contains("bye") {
            "goodbye".to_string()
        } else {
            "unknown".to_string()
        }
    }

    pub async fn is_available(&self) -> bool {
        let loaded = self.model_loaded.lock().await;
        *loaded
    }
}
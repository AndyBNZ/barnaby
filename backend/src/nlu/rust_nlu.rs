use regex::Regex;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Intent {
    pub name: String,
    pub confidence: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Entity {
    pub name: String,
    pub value: String,
    pub start: usize,
    pub end: usize,
}

#[derive(Debug, Clone)]
pub struct IntentPattern {
    pub intent: String,
    pub patterns: Vec<Regex>,
    pub entities: Vec<String>,
}

pub struct RustNlu {
    patterns: Vec<IntentPattern>,
}

impl RustNlu {
    pub fn new() -> Self {
        let mut nlu = Self {
            patterns: Vec::new(),
        };
        nlu.load_patterns();
        nlu
    }

    fn load_patterns(&mut self) {
        // Time patterns
        self.add_intent("get_time", vec![
            r"(?i)what.{0,10}time",
            r"(?i)current.{0,5}time",
            r"(?i)tell.{0,10}time",
            r"(?i)time.{0,5}(is|please)",
            r"(?i)^time$",
            r"(?i)clock",
        ]);

        // Weather patterns  
        self.add_intent("get_weather", vec![
            r"(?i)weather",
            r"(?i)temperature",
            r"(?i)forecast",
            r"(?i)(how.{0,5}|what.{0,5})(hot|cold|warm)",
            r"(?i)raining",
            r"(?i)sunny",
        ]);

        // Light control patterns
        self.add_intent("control_lights", vec![
            r"(?i)turn.{0,5}(on|off).{0,10}light",
            r"(?i)light.{0,5}(on|off)",
            r"(?i)(switch|dim|brighten).{0,10}light",
            r"(?i)lights.{0,5}(on|off)",
        ]);

        // Greeting patterns
        self.add_intent("greet", vec![
            r"(?i)^(hi|hello|hey)($|\s)",
            r"(?i)good.{0,5}(morning|evening|afternoon)",
            r"(?i)greetings",
        ]);

        // Goodbye patterns
        self.add_intent("goodbye", vec![
            r"(?i)(bye|goodbye|farewell)",
            r"(?i)see.{0,5}you",
            r"(?i)talk.{0,5}later",
        ]);
    }

    fn add_intent(&mut self, intent: &str, patterns: Vec<&str>) {
        let regex_patterns: Vec<Regex> = patterns
            .into_iter()
            .filter_map(|p| Regex::new(p).ok())
            .collect();

        self.patterns.push(IntentPattern {
            intent: intent.to_string(),
            patterns: regex_patterns,
            entities: Vec::new(),
        });
    }

    pub fn parse(&self, text: &str) -> (Intent, Vec<Entity>) {
        let mut best_intent = Intent {
            name: "unknown".to_string(),
            confidence: 0.0,
        };

        for pattern in &self.patterns {
            for regex in &pattern.patterns {
                if let Some(matches) = regex.find(text) {
                    let confidence = self.calculate_confidence(text, matches.as_str());
                    if confidence > best_intent.confidence {
                        best_intent = Intent {
                            name: pattern.intent.clone(),
                            confidence,
                        };
                    }
                }
            }
        }

        // If no pattern matched, set low confidence
        if best_intent.confidence == 0.0 {
            best_intent.confidence = 0.1;
        }

        let entities = self.extract_entities(text, &best_intent.name);
        (best_intent, entities)
    }

    fn calculate_confidence(&self, text: &str, matched_part: &str) -> f64 {
        let text_len = text.len() as f64;
        let match_len = matched_part.len() as f64;
        
        // Base confidence on match coverage
        let coverage = match_len / text_len;
        
        // Boost confidence for exact matches
        let exactness_bonus = if text.trim().to_lowercase() == matched_part.to_lowercase() {
            0.3
        } else {
            0.0
        };

        (coverage * 0.7 + exactness_bonus).min(0.95)
    }

    fn extract_entities(&self, text: &str, intent: &str) -> Vec<Entity> {
        let mut entities = Vec::new();

        // Extract room entities for light control
        if intent == "control_lights" {
            let room_regex = Regex::new(r"(?i)(living room|bedroom|kitchen|bathroom|office)").unwrap();
            if let Some(matches) = room_regex.find(text) {
                entities.push(Entity {
                    name: "room".to_string(),
                    value: matches.as_str().to_lowercase(),
                    start: matches.start(),
                    end: matches.end(),
                });
            }
        }

        // Extract location entities for weather
        if intent == "get_weather" {
            println!("Extracting location from text: '{}'", text);
            let location_regex = Regex::new(r"(?i)(?:in|for|at)\s+([a-zA-Z\s,]+?)(?:\?|$)").unwrap();
            if let Some(captures) = location_regex.captures(text) {
                if let Some(location_match) = captures.get(1) {
                    let location_value = location_match.as_str().trim().to_string();
                    println!("Found location: '{}'", location_value);
                    entities.push(Entity {
                        name: "location".to_string(),
                        value: location_value,
                        start: location_match.start(),
                        end: location_match.end(),
                    });
                }
            } else {
                println!("No location match found in: '{}'", text);
            }
        }

        entities
    }
}
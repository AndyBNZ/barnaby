use rumqttc::{AsyncClient, MqttOptions, QoS};
use tokio::sync::mpsc;
use tracing::{error, info};
use anyhow::Result;

use crate::config::settings::MqttConfig;

#[derive(Clone)]
pub struct MqttService {
    client: AsyncClient,
}

impl MqttService {
    pub async fn new(config: &MqttConfig) -> Result<Self> {
        let mut mqttoptions = MqttOptions::new("barnaby-server", &config.broker, config.port);
        
        if let (Some(username), Some(password)) = (&config.username, &config.password) {
            mqttoptions.set_credentials(username, password);
        }

        let (client, mut eventloop) = AsyncClient::new(mqttoptions, 10);

        // Spawn task to handle MQTT events
        tokio::spawn(async move {
            let mut connection_attempts = 0;
            loop {
                match eventloop.poll().await {
                    Ok(event) => {
                        connection_attempts = 0; // Reset on successful event
                        tracing::debug!("MQTT Event: {:?}", event);
                    }
                    Err(e) => {
                        connection_attempts += 1;
                        if connection_attempts <= 3 {
                            tracing::warn!("MQTT connection attempt {}: {:?}", connection_attempts, e);
                        }
                        tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
                    }
                }
            }
        });

        Ok(Self { client })
    }

    pub async fn subscribe_to_satellites(&self) -> Result<()> {
        self.client
            .subscribe("barnaby/satellites/+/audio/stream", QoS::AtLeastOnce)
            .await?;
        
        self.client
            .subscribe("barnaby/satellites/+/status/heartbeat", QoS::AtLeastOnce)
            .await?;

        info!("Subscribed to satellite topics");
        Ok(())
    }

    pub async fn publish_to_satellite(&self, satellite_id: &str, topic: &str, payload: &str) -> Result<()> {
        let full_topic = format!("barnaby/satellites/{}/{}", satellite_id, topic);
        self.client
            .publish(full_topic, QoS::AtLeastOnce, false, payload)
            .await?;
        Ok(())
    }
}
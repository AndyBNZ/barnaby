use std::process::{Child, Command, Stdio};
use std::path::Path;
use tokio::time::{sleep, Duration};
use tracing::{info, warn, error};

pub struct RasaManager {
    process: Option<Child>,
}

impl RasaManager {
    pub fn new() -> Self {
        Self { process: None }
    }

    pub async fn start(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        let rasa_dir = Path::new("../nlu/rasa");
        
        if !rasa_dir.exists() {
            return Err("Rasa directory not found".into());
        }

        info!("Starting Rasa NLU server...");

        // Check if rasa command exists, install if not
        if Command::new("rasa").arg("--version").output().is_err() {
            info!("Rasa not found, attempting installation...");
            
            // Try different pip installation methods
            let install_commands = vec![
                ("pip3.10", vec!["install", "rasa==3.6.4"]),
                ("pip3", vec!["install", "rasa==3.6.4"]),
                ("python3.10", vec!["-m", "pip", "install", "rasa==3.6.4"]),
                ("python3", vec!["-m", "pip", "install", "rasa==3.6.4"]),
            ];
            
            let mut install_success = false;
            for (cmd, args) in install_commands {
                info!("Trying: {} {}", cmd, args.join(" "));
                if let Ok(output) = Command::new(cmd).args(&args).output() {
                    if output.status.success() {
                        info!("Rasa installed successfully with {}", cmd);
                        install_success = true;
                        break;
                    }
                }
            }
            
            if !install_success {
                return Err("Failed to install Rasa. Please install manually: pip install rasa==3.6.4".into());
            }
        }

        // Check if model exists, train if not
        let models_dir = rasa_dir.join("models");
        if !models_dir.exists() {
            info!("Training Rasa model...");
            let train_output = Command::new("rasa")
                .args(&["train", "nlu"])
                .current_dir(rasa_dir)
                .output()?;

            if !train_output.status.success() {
                error!("Failed to train Rasa model: {}", String::from_utf8_lossy(&train_output.stderr));
                return Err("Rasa training failed".into());
            }
            info!("Rasa model trained successfully");
        }

        // Start Rasa server
        let child = Command::new("rasa")
            .args(&["run", "--enable-api", "--cors", "*", "--port", "5005"])
            .current_dir(rasa_dir)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()?;

        self.process = Some(child);
        
        // Wait for Rasa to start
        info!("Waiting for Rasa to start...");
        for _ in 0..30 {
            if self.is_healthy().await {
                info!("Rasa NLU server started successfully on port 5005");
                return Ok(());
            }
            sleep(Duration::from_secs(1)).await;
        }

        warn!("Rasa server may not have started properly");
        Ok(())
    }

    async fn is_healthy(&self) -> bool {
        match reqwest::get("http://localhost:5005/status").await {
            Ok(response) => response.status().is_success(),
            Err(_) => false,
        }
    }

    pub fn stop(&mut self) {
        if let Some(mut process) = self.process.take() {
            info!("Stopping Rasa NLU server...");
            let _ = process.kill();
            let _ = process.wait();
        }
    }
}

impl Drop for RasaManager {
    fn drop(&mut self) {
        self.stop();
    }
}
use reqwest::Client;
use serde::{Deserialize, Serialize};
use anyhow::Result;

#[derive(Debug, Deserialize)]
pub struct WeatherResponse {
    pub current: CurrentWeather,
}

#[derive(Debug, Deserialize)]
pub struct CurrentWeather {
    pub temperature_2m: f64,
    pub weather_code: u32,
    pub wind_speed_10m: f64,
}

#[derive(Debug, Deserialize)]
pub struct GeocodingResponse {
    pub results: Option<Vec<GeocodingResult>>,
}

#[derive(Debug, Deserialize)]
pub struct GeocodingResult {
    pub latitude: f64,
    pub longitude: f64,
    pub name: String,
    pub country: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct IpLocationResponse {
    pub lat: f64,
    pub lon: f64,
    pub city: Option<String>,
    pub country: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct WeatherInfo {
    pub temperature: f64,
    pub description: String,
    pub wind_speed: f64,
}

pub struct WeatherService {
    client: Client,
}

impl WeatherService {
    pub fn new() -> Self {
        Self {
            client: Client::new(),
        }
    }

    pub async fn get_weather(&self, latitude: f64, longitude: f64) -> Result<WeatherInfo> {
        let url = format!(
            "https://api.open-meteo.com/v1/forecast?latitude={}&longitude={}&current=temperature_2m,weather_code,wind_speed_10m",
            latitude, longitude
        );

        let response: WeatherResponse = self.client
            .get(&url)
            .send()
            .await?
            .json()
            .await?;

        Ok(WeatherInfo {
            temperature: response.current.temperature_2m,
            description: weather_code_to_description(response.current.weather_code),
            wind_speed: response.current.wind_speed_10m,
        })
    }

    // Default location (can be made configurable)
    pub async fn get_current_weather(&self) -> Result<WeatherInfo> {
        match self.get_ip_location().await {
            Ok((lat, lon)) => self.get_weather(lat, lon).await,
            Err(_) => {
                // Fallback to London coordinates
                self.get_weather(51.5074, -0.1278).await
            }
        }
    }

    pub async fn get_weather_for_location(&self, location: &str) -> Result<WeatherInfo> {
        let (lat, lon) = self.geocode_location(location).await?;
        self.get_weather(lat, lon).await
    }

    async fn geocode_location(&self, location: &str) -> Result<(f64, f64)> {
        let url = format!(
            "https://geocoding-api.open-meteo.com/v1/search?name={}&count=1",
            urlencoding::encode(location)
        );

        let response: GeocodingResponse = self.client
            .get(&url)
            .send()
            .await?
            .json()
            .await?;

        if let Some(results) = response.results {
            if let Some(result) = results.first() {
                return Ok((result.latitude, result.longitude));
            }
        }

        Err(anyhow::anyhow!("Location not found: {}", location))
    }

    async fn get_ip_location(&self) -> Result<(f64, f64)> {
        let response: IpLocationResponse = self.client
            .get("http://ip-api.com/json/?fields=lat,lon,city,country")
            .send()
            .await?
            .json()
            .await?;

        Ok((response.lat, response.lon))
    }
}

fn weather_code_to_description(code: u32) -> String {
    match code {
        0 => "Clear sky".to_string(),
        1..=3 => "Partly cloudy".to_string(),
        45 | 48 => "Foggy".to_string(),
        51..=57 => "Drizzle".to_string(),
        61..=67 => "Rain".to_string(),
        71..=77 => "Snow".to_string(),
        80..=82 => "Rain showers".to_string(),
        85..=86 => "Snow showers".to_string(),
        95..=99 => "Thunderstorm".to_string(),
        _ => "Unknown".to_string(),
    }
}
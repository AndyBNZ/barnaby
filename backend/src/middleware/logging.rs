use axum::{
    extract::Request,
    middleware::Next,
    response::Response,
};
use std::time::Instant;
use tracing::info;

pub async fn logging_middleware(
    req: Request,
    next: Next,
) -> Response {
    let start = Instant::now();
    let method = req.method().clone();
    let uri = req.uri().clone();
    let path = uri.path();

    info!("→ {} {}", method, path);

    let response = next.run(req).await;
    
    let status = response.status();
    let duration = start.elapsed();
    
    let status_emoji = match status.as_u16() {
        200..=299 => "✅",
        300..=399 => "↩️",
        400..=499 => "❌",
        500..=599 => "💥",
        _ => "❓",
    };

    info!(
        "← {} {} {} - {}ms {}",
        status_emoji,
        method,
        path,
        duration.as_millis(),
        status
    );

    response
}
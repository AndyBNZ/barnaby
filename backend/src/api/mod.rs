pub mod routes;

use axum::Router;
use crate::AppState;

pub fn create_routes() -> Router<AppState> {
    Router::new()
        .nest("/api/auth", routes::auth::create_routes())
        .nest("/api/users", routes::users::create_routes())
        .nest("/api/audio", routes::audio::create_routes())
        .nest("/api/commands", routes::commands::create_routes())
}
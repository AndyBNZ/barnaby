use axum::{
    extract::{Path, State},
    http::StatusCode,
    middleware,
    response::Json,
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sqlx::Row;
use uuid::Uuid;
use bcrypt::{hash, DEFAULT_COST};

use crate::{
    auth::middleware::{admin_middleware, auth_middleware},
    database::models::User,
    AppState,
};

#[derive(Debug, Deserialize)]
pub struct CreateUserRequest {
    pub username: String,
    pub password: String,
    pub role: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateUserRequest {
    pub username: String,
    pub password: Option<String>,
    pub role: String,
}

pub fn create_routes() -> Router<AppState> {
    Router::new()
        .route("/", get(list_users).post(create_user))
        .route("/:id", get(get_user).put(update_user))
}

pub async fn list_users(State(state): State<AppState>) -> Result<Json<Value>, StatusCode> {
    let users = sqlx::query_as::<_, User>(
        "SELECT id, username, email, password_hash, role, created_at, updated_at FROM users ORDER BY created_at DESC",
    )
    .fetch_all(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(json!({
        "users": users
    })))
}

pub async fn get_user(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
) -> Result<Json<User>, StatusCode> {
    let user = sqlx::query_as::<_, User>(
        "SELECT id, username, email, password_hash, role, created_at, updated_at FROM users WHERE id = ?",
    )
    .bind(&user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    user.map(Json).ok_or(StatusCode::NOT_FOUND)
}

pub async fn create_user(
    State(state): State<AppState>,
    Json(payload): Json<CreateUserRequest>,
) -> Result<Json<User>, StatusCode> {
    let user_id = Uuid::new_v4().to_string();
    let password_hash = hash(&payload.password, DEFAULT_COST)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let user = sqlx::query_as::<_, User>(
        "INSERT INTO users (id, username, email, password_hash, role) VALUES (?, ?, ?, ?, ?) RETURNING id, username, email, password_hash, role, created_at, updated_at",
    )
    .bind(&user_id)
    .bind(&payload.username)
    .bind(format!("{}@example.com", payload.username)) // Default email
    .bind(&password_hash)
    .bind(&payload.role)
    .fetch_one(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(user))
}

pub async fn update_user(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
    Json(payload): Json<UpdateUserRequest>,
) -> Result<Json<User>, StatusCode> {
    if let Some(password) = &payload.password {
        let password_hash = hash(password, DEFAULT_COST)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        let user = sqlx::query_as::<_, User>(
            "UPDATE users SET username = ?, password_hash = ?, role = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? RETURNING id, username, email, password_hash, role, created_at, updated_at",
        )
        .bind(&payload.username)
        .bind(&password_hash)
        .bind(&payload.role)
        .bind(&user_id)
        .fetch_one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        Ok(Json(user))
    } else {
        let user = sqlx::query_as::<_, User>(
            "UPDATE users SET username = ?, role = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? RETURNING id, username, email, password_hash, role, created_at, updated_at",
        )
        .bind(&payload.username)
        .bind(&payload.role)
        .bind(&user_id)
        .fetch_one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        Ok(Json(user))
    }
}
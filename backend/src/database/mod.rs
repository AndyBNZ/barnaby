pub mod models;

use sqlx::{SqlitePool, migrate::MigrateDatabase, Sqlite};
use anyhow::Result;

pub async fn create_pool(database_url: &str) -> Result<SqlitePool> {
    if !Sqlite::database_exists(database_url).await.unwrap_or(false) {
        Sqlite::create_database(database_url).await?;
    }

    let pool = SqlitePool::connect(database_url).await?;
    
    // Run migrations (ignore if tables already exist)
    if let Err(e) = sqlx::migrate!("./migrations").run(&pool).await {
        tracing::warn!("Migration warning (may be expected): {}", e);
    }
    
    Ok(pool)
}
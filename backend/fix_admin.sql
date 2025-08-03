-- Update admin user with properly hashed password
UPDATE users SET password_hash = '$2b$12$Ev7dYM1ZZrUIOe31e6HHKuFLMocxY1HWtKj/4OvB.tN1bJfwZxlxi' WHERE username = 'admin';
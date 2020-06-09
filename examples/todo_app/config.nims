import os

# DB Connection
putEnv("DB_DRIVER", "sqlite")
putEnv("DB_CONNECTION", "/root/project/examples/todo_app/db.sqlite3")
putEnv("DB_USER", "")
putEnv("DB_PASSWORD", "")
putEnv("DB_DATABASE", "")

# Logging
putEnv("LOG_IS_DISPLAY", "true")
putEnv("LOG_IS_FILE", "true")
putEnv("LOG_DIR", "/root/project/examples/todo_app/logs")

# Security
putEnv("SALT", "$2a$10$ReYC5CiFkeoBbI6H7amKv.") # bcrypt salt
putEnv("SECRET_KEY", "_hMs*#u]/_czd!xBkmS{;It3") # 24 length
putEnv("CSRF_TIME", "525600") # minutes of 1 year
putEnv("SESSION_TIME", "20160") # minutes of 2 weeks
putEnv("SESSION_DB", "/root/project/examples/todo_app/session.db")
putEnv("IS_SESSION_MEMORY", "false")
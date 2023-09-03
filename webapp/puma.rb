# Set the environment to "production" or "development" as needed
environment ENV['RACK_ENV'] || 'production'

# Define the number of worker processes (adjust as needed)
workers ENV['WEBSERVER_WORKERS'].to_i


# Optional: Bind to a specific IP and port (adjust as needed)
bind "tcp://0.0.0.0:#{ENV['WEBSERVER_PORT']}"
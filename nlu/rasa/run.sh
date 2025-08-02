#!/bin/bash
cd "$(dirname "$0")"

# Install Rasa if not already installed
if ! command -v rasa &> /dev/null; then
    echo "Installing Rasa..."
    pip install -r requirements.txt
fi

# Train the model if it doesn't exist
if [ ! -d "models" ]; then
    echo "Training Rasa model..."
    rasa train nlu
fi

# Run Rasa server
echo "Starting Rasa NLU server on port 5005..."
rasa run --enable-api --cors "*" --port 5005
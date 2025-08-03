#!/bin/bash

echo "Testing Rasa NLU setup..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python3."
    exit 1
fi

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 not found. Please install pip3."
    exit 1
fi

# Install Rasa if not present
if ! command -v rasa &> /dev/null; then
    echo "📦 Installing Rasa..."
    cd nlu/rasa
    pip3 install -r requirements.txt
    cd ../..
fi

# Check Rasa installation
if command -v rasa &> /dev/null; then
    echo "✅ Rasa is installed: $(rasa --version)"
else
    echo "❌ Rasa installation failed"
    exit 1
fi

# Train model if needed
cd nlu/rasa
if [ ! -d "models" ]; then
    echo "🎯 Training Rasa model..."
    rasa train nlu
fi

echo "✅ Rasa setup complete!"
echo "You can now start the backend and Rasa will be automatically started."
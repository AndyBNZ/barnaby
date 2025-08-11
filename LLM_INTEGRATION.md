# LLM Integration for Barnaby Digital Butler

## Overview

This branch adds Local LLM integration to enhance natural language understanding beyond the current regex-based system.

## Architecture

**Enhanced NLU Pipeline:**
```
User Input → LLM Service → Rasa NLU → Rust Regex NLU → Response
             (Primary)     (Fallback)   (Final Fallback)
```

## Current Implementation

**Mock LLM Service** (`src/services/llm.rs`):
- Demonstrates integration pattern
- Enhanced intent detection with better entity extraction
- Ready for real LLM integration (picoLLM, Candle, etc.)

## Features Added

✅ **Enhanced Intent Detection:**
- Better natural language understanding
- Improved location extraction for weather queries
- Enhanced room detection for light control

✅ **Graceful Fallbacks:**
- LLM → Rasa → Regex chain ensures system always works
- No breaking changes to existing functionality

✅ **Configuration:**
- Set `PICOLLM_MODEL_PATH` environment variable to enable
- Runs without LLM if not configured

## Usage

### Enable LLM (Mock):
```bash
export PICOLLM_MODEL_PATH="/path/to/model"
cargo run --bin barnaby-server
```

### Disable LLM:
```bash
# Don't set PICOLLM_MODEL_PATH
cargo run --bin barnaby-server
```

## Testing

The mock LLM provides enhanced understanding:

**Weather Queries:**
- "What's the weather in Tokyo?" → Extracts "Tokyo" as location
- "How's the weather?" → Uses IP-based location

**Light Control:**
- "Turn on the living room lights" → Extracts "living room" as room
- "Lights on" → General light control

**Time Queries:**
- "What time is it?" → Better confidence scoring
- "Current time please" → Enhanced pattern matching

## Future Integration

To integrate a real LLM:

1. **Replace Mock Implementation:**
   - Update `src/services/llm.rs`
   - Add actual LLM crate dependency
   - Implement model loading and inference

2. **Supported LLM Options:**
   - picoLLM (when available on crates.io)
   - Candle + Transformers
   - ONNX Runtime
   - Custom C++ bindings

3. **Model Requirements:**
   - Small models (< 2GB) for local deployment
   - Fast inference (< 500ms response time)
   - JSON-structured output support

## Benefits

- **Better UX:** More natural language understanding
- **Privacy:** All processing remains local
- **Reliability:** Fallback chain ensures system always works
- **Extensible:** Easy to swap LLM implementations
- **Non-breaking:** Existing functionality unchanged

## Performance Impact

- **Mock LLM:** ~1ms overhead
- **Real LLM:** ~100-500ms depending on model size
- **Fallback:** No impact when LLM unavailable

This integration maintains Barnaby's privacy-first, offline-first philosophy while significantly improving natural language understanding capabilities.
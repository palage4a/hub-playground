# Configuration Examples for Different AI Providers

This file provides example configurations for using the Multi-Agent Developer System with various AI providers.

## 📋 Basic Configuration

### OpenAI (Default)
```bash
# .env file configuration
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_MODEL=gpt-4-turbo-preview
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=2000
VERBOSE=True
```

## 🏠 Local Models

### Ollama
```bash
# .env file configuration
OPENAI_API_KEY=ollama  # Can be any string, not actually used
OPENAI_API_BASE_URL=http://localhost:11434/v1
OPENAI_MODEL=llama3.2  # or codellama, mistral, etc.
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=4096
VERBOSE=True
```

**CLI Usage:**
```bash
python src/cli.py analyze --file examples/example_code.py --api-url http://localhost:11434/v1
```

### LM Studio
```bash
# .env file configuration
OPENAI_API_KEY=lm-studio  # Can be any string
OPENAI_API_BASE_URL=REDACTED__N13__/v1
OPENAI_MODEL=local-model  # Use the model name from LM Studio
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=4096
VERBOSE=True
```

**CLI Usage:**
```bash
python src/cli.py review --code "def add(a, b): return a + b" --api-url REDACTED__N13__/v1
```

### LocalAI
```bash
# .env file configuration
OPENAI_API_KEY=localai  # Can be any string
OPENAI_API_BASE_URL=REDACTED__N17__/v1
OPENAI_MODEL=gpt-4  # Use the model name configured in LocalAI
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=4096
VERBOSE=True
```

## ☁️ Cloud Providers

### Azure OpenAI
```bash
# .env file configuration
OPENAI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_API_BASE_URL=https://your-resource.openai.azure.com/openai/deployments/YOUR_DEPLOYMENT_NAME
OPENAI_MODEL=gpt-4  # Must match your deployment
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=2000
VERBOSE=True
```

**CLI Usage:**
```bash
python src/cli.py analyze --file mycode.py --api-url https://your-resource.openai.azure.com/openai/deployments/gpt-4
```

### Together AI
```bash
# .env file configuration
OPENAI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_API_BASE_URL=REDACTED__N14__/v1
OPENAI_MODEL=togethercomputer/llama-2-70b-chat
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=4096
VERBOSE=True
```

### Anthropic (Claude)
```bash
# Note: Requires additional setup as Anthropic uses different API format
# You would need a proxy or adapter service
OPENAI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_API_BASE_URL=REDACTED__N18__/v1  # Proxy URL
OPENAI_MODEL=claude-3-opus-20240229
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=4096
VERBOSE=True
```

### Google AI (Gemini)
```bash
# Note: Requires adapter as Gemini uses different API
OPENAI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_API_BASE_URL=REDACTED__N19__/v1  # Adapter URL
OPENAI_MODEL=gemini-pro
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=4096
VERBOSE=True
```

## 🔧 Advanced Configuration Examples

### Multiple Provider Setup
```bash
# .env file for development with fallback
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # Primary: OpenAI
OPENAI_API_BASE_URL=  # Leave empty for default OpenAI
OPENAI_MODEL=gpt-4-turbo-preview

# For local development/testing
# OPENAI_API_BASE_URL=http://localhost:11434/v1
# OPENAI_MODEL=llama3.2
```

### Performance Optimized
```bash
# Faster, cheaper configuration
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_MODEL=gpt-3.5-turbo  # Faster and cheaper than GPT-4
OPENAI_TEMPERATURE=0.3  # More deterministic output
MAX_TOKENS=1000  # Limit response length
VERBOSE=False  # Less verbose output
```

### Quality Focused
```bash
# Best quality configuration
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_MODEL=gpt-4-turbo-preview  # Best quality
OPENAI_TEMPERATURE=0.7  # Balanced creativity
MAX_TOKENS=4000  # Allow detailed responses
VERBOSE=True  # Full debugging info
```

## 🚀 Quick Start Scripts

### Setup for Ollama
```bash
#!/bin/bash
# setup-ollama.sh

# Install Ollama (if not installed)
# curl -fsSL REDACTED__N20__/install.sh | sh

# Pull a model
ollama pull llama3.2

# Create .env for Ollama
cat > .env << EOF
OPENAI_API_KEY=ollama
OPENAI_API_BASE_URL=http://localhost:11434/v1
OPENAI_MODEL=llama3.2
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=4096
VERBOSE=True
EOF

echo "Ollama configuration created!"
```

### Setup for LM Studio
```bash
#!/bin/bash
# setup-lmstudio.sh

cat > .env << EOF
OPENAI_API_KEY=lm-studio
OPENAI_API_BASE_URL=REDACTED__N13__/v1
OPENAI_MODEL=local-model
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=4096
VERBOSE=True
EOF

echo "LM Studio configuration created!"
echo "Make sure LM Studio is running on port 1234"
```

## 🔍 Troubleshooting Configurations

### Common Issues and Solutions

1. **Connection Refused (Local Models)**
   ```
   Error: Connection refused
   ```
   **Solution:** Ensure your local model server is running:
   ```bash
   # For Ollama
   ollama serve
   
   # Check if server is running
   curl http://localhost:11434/api/tags
   ```

2. **Invalid API Key**
   ```
   Error: Incorrect API key provided
   ```
   **Solution:** For local models, any string works. For cloud providers, verify your API key.

3. **Model Not Found**
   ```
   Error: Model not found
   ```
   **Solution:** Check the model name:
   ```bash
   # For Ollama, list available models
   ollama list
   
   # Update .env with correct model name
   ```

4. **Rate Limiting**
   ```
   Error: Rate limit exceeded
   ```
   **Solution:** 
   - Use a local model instead
   - Switch to a cheaper model (gpt-3.5-turbo)
   - Add delays between requests

## 📊 Provider Comparison

| Provider | Setup Difficulty | Cost | Speed | Privacy | Best For |
|----------|-----------------|------|-------|---------|----------|
| **OpenAI** | Easy | $$$ | Fast | Low | Production, best quality |
| **Ollama** | Medium | Free | Medium | High | Local development, privacy |
| **LM Studio** | Medium | Free | Medium | High | Local development, GUI |
| **Azure OpenAI** | Medium | $$$ | Fast | Medium | Enterprise, compliance |
| **Together AI** | Easy | $$ | Fast | Medium | Open source models |

## 🎯 Recommended Configurations

### For Beginners
```bash
# Start with OpenAI (easiest setup)
OPENAI_API_KEY=your_key_here
OPENAI_MODEL=gpt-3.5-turbo
```

### For Privacy-Conscious Developers
```bash
# Use Ollama for complete privacy
OPENAI_API_BASE_URL=http://localhost:11434/v1
OPENAI_MODEL=llama3.2
```

### For Enterprise Use
```bash
# Azure OpenAI for compliance
OPENAI_API_BASE_URL=https://your-resource.openai.azure.com/openai/deployments/gpt-4
OPENAI_MODEL=gpt-4
```

## 🔗 Useful Links

- [Ollama Documentation](REDACTED__N15__/)
- [LM Studio Documentation](REDACTED__N16__/)
- [LocalAI GitHub](REDACTED__N21__/mudler/LocalAI)
- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [Azure OpenAI Documentation](REDACTED__N22__/azure/ai-services/openai/)

---

**Tip:** You can quickly switch between configurations by creating multiple .env files:
```bash
# For development with local model
cp .env.ollama .env

# For production with OpenAI
cp .env.openai .env

# For testing
cp .env.test .env
```

Create these files once and switch between them as needed!
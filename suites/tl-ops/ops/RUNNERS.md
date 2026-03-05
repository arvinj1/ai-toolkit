# RUNNERS.md — Using TL-Ops with different LLMs

Both `run_dashboard.sh` and `compose.sh` are LLM-agnostic.
The skill (SKILL.md) is just a structured prompt — it works with any model that has
a sufficient context window to read your input files.

**Minimum context window needed:**
- Minimal inputs (todo.md + status_weekly.md only): ~4k tokens
- Full inputs (all files populated): ~16–32k tokens
- Full inputs + prior outputs (delta analysis): ~32–64k tokens

All modern frontier models handle this comfortably.

---

## How runners work

A runner is a shell script that:
1. Reads the combined prompt from stdin
2. Sends it to the LLM
3. Prints the response to stdout

`run_dashboard.sh` and `compose.sh` pipe the prompt through whichever runner you specify.

---

## Runner setup by LLM

### Claude (default)

```bash
cp ops/claude_runner.example.sh ops/claude_runner.sh
chmod +x ops/claude_runner.sh
# Edit to match your Claude CLI invocation
```

Usage:
```bash
./ops/run_dashboard.sh            # uses ops/claude_runner.sh
./ops/compose.sh                  # uses ops/claude_runner.sh
```

---

### OpenAI (GPT-4o, GPT-4-turbo, o1)

**Prerequisites:** `pip install openai` + set `OPENAI_API_KEY` env var.

```bash
# ops/runners/openai_runner.sh
cat ops/runners/openai_runner.example.sh > ops/runners/openai_runner.sh
chmod +x ops/runners/openai_runner.sh
```

Or create it manually:

```bash
cat > ops/runners/openai_runner.sh << 'EOF'
#!/usr/bin/env bash
# Reads prompt from stdin, calls OpenAI, prints response to stdout
PROMPT="$(cat)"
MODEL="${OPENAI_MODEL:-gpt-4o}"

python3 - <<PYEOF
import os, sys
from openai import OpenAI

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
prompt = """${PROMPT}"""

response = client.chat.completions.create(
    model="${MODEL}",
    messages=[{"role": "user", "content": prompt}],
    max_tokens=4096,
)
print(response.choices[0].message.content)
PYEOF
EOF
chmod +x ops/runners/openai_runner.sh
```

Usage:
```bash
./ops/run_dashboard.sh --runner openai
./ops/compose.sh --runner openai

# Use a specific model:
OPENAI_MODEL=gpt-4-turbo ./ops/compose.sh --runner openai
```

**Azure OpenAI:**
```bash
export AZURE_OPENAI_API_KEY="your-key"
export AZURE_OPENAI_ENDPOINT="https://your-instance.openai.azure.com/"
export AZURE_OPENAI_DEPLOYMENT="gpt-4o"
# Then adjust the runner to use AzureOpenAI client instead of OpenAI
```

---

### Gemini (Google AI / Vertex AI)

**Prerequisites:** `pip install google-generativeai` + set `GEMINI_API_KEY`.

```bash
cat > ops/runners/gemini_runner.sh << 'EOF'
#!/usr/bin/env bash
PROMPT="$(cat)"
MODEL="${GEMINI_MODEL:-gemini-1.5-pro}"

python3 - <<PYEOF
import os
import google.generativeai as genai

genai.configure(api_key=os.environ["GEMINI_API_KEY"])
model = genai.GenerativeModel("${MODEL}")
prompt = """${PROMPT}"""
response = model.generate_content(prompt)
print(response.text)
PYEOF
EOF
chmod +x ops/runners/gemini_runner.sh
```

Usage:
```bash
./ops/run_dashboard.sh --runner gemini
./ops/compose.sh --runner gemini

GEMINI_MODEL=gemini-1.5-flash ./ops/compose.sh --runner gemini
```

**Vertex AI (enterprise Gemini):**
```bash
# Use vertexai SDK instead of google-generativeai
# pip install google-cloud-aiplatform
# Requires: gcloud auth application-default login
```

---

### Ollama (local, air-gapped / on-prem)

**Prerequisites:** [Install Ollama](https://ollama.ai) + pull a model.

```bash
ollama pull llama3.1:70b     # recommended for this task
# or
ollama pull mistral:latest
```

```bash
cat > ops/runners/ollama_runner.sh << 'EOF'
#!/usr/bin/env bash
PROMPT="$(cat)"
MODEL="${OLLAMA_MODEL:-llama3.1:70b}"

curl -sf http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    '{model: $model, prompt: $prompt, stream: false}')" \
  | jq -r '.response'
EOF
chmod +x ops/runners/ollama_runner.sh
```

Usage:
```bash
./ops/run_dashboard.sh --runner ollama
./ops/compose.sh --runner ollama

OLLAMA_MODEL=mistral ./ops/compose.sh --runner ollama
```

**Notes on local models:**
- Llama 3.1 70B gives the best results for structured Markdown output
- Smaller models (7B, 13B) will produce shorter, less structured output — acceptable for quick reviews
- Context window: check your model's limit; for large input sets use a 32k+ context model
- Air-gapped: Ollama runs completely offline — no data leaves the machine

---

### AWS Bedrock (Claude, Llama, Titan on AWS)

**Prerequisites:** `pip install boto3` + AWS credentials configured.

```bash
cat > ops/runners/bedrock_runner.sh << 'EOF'
#!/usr/bin/env bash
PROMPT="$(cat)"
MODEL="${BEDROCK_MODEL:-anthropic.claude-3-5-sonnet-20241022-v2:0}"
REGION="${AWS_REGION:-us-east-1}"

python3 - <<PYEOF
import os, json, boto3

client = boto3.client("bedrock-runtime", region_name="${REGION}")
prompt = """${PROMPT}"""

body = json.dumps({
    "anthropic_version": "bedrock-2023-05-31",
    "max_tokens": 4096,
    "messages": [{"role": "user", "content": prompt}]
})

response = client.invoke_model(
    modelId="${MODEL}",
    body=body
)
result = json.loads(response["body"].read())
print(result["content"][0]["text"])
PYEOF
EOF
chmod +x ops/runners/bedrock_runner.sh
```

Usage:
```bash
BEDROCK_MODEL=anthropic.claude-3-5-sonnet-20241022-v2:0 ./ops/compose.sh --runner bedrock
```

---

### Azure AI Studio / GitHub Models

If your org has Azure AI Studio with a deployed model endpoint:

```bash
cat > ops/runners/azure_ai_runner.sh << 'EOF'
#!/usr/bin/env bash
# Works with any Azure AI Studio endpoint (GPT-4o, Llama, Mistral, Phi, etc.)
PROMPT="$(cat)"
ENDPOINT="${AZURE_AI_ENDPOINT}"   # e.g. https://your-deployment.services.ai.azure.com/
API_KEY="${AZURE_AI_KEY}"
MODEL="${AZURE_AI_MODEL:-gpt-4o}"

curl -sf "${ENDPOINT}/chat/completions?api-version=2024-02-01" \
  -H "Content-Type: application/json" \
  -H "api-key: ${API_KEY}" \
  -d "{
    \"model\": \"${MODEL}\",
    \"messages\": [{\"role\": \"user\", \"content\": $(echo "$PROMPT" | jq -Rs .)}],
    \"max_tokens\": 4096
  }" \
  | jq -r '.choices[0].message.content'
EOF
chmod +x ops/runners/azure_ai_runner.sh
```

---

## Which model to use?

| Use case | Recommended model | Why |
|---|---|---|
| Best results, Claude access | `claude-3-5-sonnet` | Best structured output, follows complex instructions |
| Enterprise, Azure/AWS | `gpt-4o` via Azure OpenAI | Available in most enterprise tenants |
| No external API / air-gapped | `llama3.1:70b` via Ollama | Strong structured output, fully local |
| Cost-sensitive / high frequency | `gemini-1.5-flash` or `gpt-4o-mini` | Cheaper; acceptable for dashboard, less ideal for composer |
| On-prem GPU cluster | Any HuggingFace model via Ollama or vLLM | Full control, no vendor dependency |

## Prompt notes for non-Claude models

The SKILL.md prompt is written primarily for Claude but works well on GPT-4o and Gemini with no changes.
For smaller or less instruction-following models, you may need to:
- Add `"Respond only in Markdown"` at the top of the prompt
- Reduce the number of sections requested
- Split large input sets across multiple calls and merge output

## Adding a new runner

1. Create `ops/runners/<name>_runner.sh`
2. Make it executable: `chmod +x ops/runners/<name>_runner.sh`
3. It must: read stdin as the prompt, write the LLM response to stdout, exit 0 on success
4. Test: `echo "Say hello" | bash ops/runners/<name>_runner.sh`
5. Use it: `./ops/compose.sh --runner <name>`

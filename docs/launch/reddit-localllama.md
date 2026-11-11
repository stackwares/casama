# r/LocalLLaMA

**Title:** Open-source agent platform where local models get their own sandboxed computer

Casama runs persistent bots (memory, skills, routines) that use a sandboxed Linux computer as their
tool environment. It works with any OpenAI-compatible endpoint, so Ollama, vLLM or LM Studio models
can drive the shell, files and a headless browser. There's a fallback chain per bot (e.g. local
first, hosted when the local model fails) and a cheap model setting for memory extraction and titles.

We ship an eval suite (30 tasks: research, files, code fixes, formats, approvals, prompt-injection
refusal, secrets) you can point at your own model and compare against our baseline.

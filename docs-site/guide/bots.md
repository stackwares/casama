# Bots and models

A bot has a name, a persona, a model policy (primary model, fallbacks and a cheaper model for
internal steps such as memory and titles), an autonomy level, budgets and its own computer.

- **Models**: bring your own key for OpenRouter, OpenAI, Anthropic, Google, xAI or any
  OpenAI-compatible endpoint (Ollama, vLLM, LM Studio). The default is GPT-6 Luna at medium
  reasoning effort; pick any model per bot.
- **Memory**: bots save facts, preferences and episode summaries, and recall them in later chats.
- **Skills**: reusable instructions a bot loads when relevant.
- **Budgets**: a per-run and a daily cost cap; workspaces also have monthly quotas.
- **Delegation**: bots can spawn subagents and hand tasks to other bots.

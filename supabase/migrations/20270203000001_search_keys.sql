-- Parallel and Serper web search keys in Model keys (D-384).
alter table public.model_credentials drop constraint model_credentials_provider_check;
alter table public.model_credentials add constraint model_credentials_provider_check
  check (provider in ('openai', 'anthropic', 'google', 'xai', 'openrouter', 'openai_compatible', 'fal',
                      'brave_search', 'tavily', 'deepgram', 'elevenlabs', 'cartesia', 'fish_audio', 'chatgpt', 'treg',
                      'google_maps', 'mapbox', 'parallel', 'serper'));

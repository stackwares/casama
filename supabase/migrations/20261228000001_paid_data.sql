-- Paid data services (SPEC: Paid data services; D-138): Treg keys and data call usage.
alter table public.usage_ledger drop constraint usage_ledger_kind_check;
alter table public.usage_ledger add constraint usage_ledger_kind_check
  check (kind in ('tokens_in', 'tokens_out', 'computer_seconds', 'stream_seconds', 'tts_chars', 'stt_seconds',
                  'voice_seconds', 'media_images', 'media_video_seconds', 'search_queries', 'data_calls'));
alter table public.model_credentials drop constraint model_credentials_provider_check;
alter table public.model_credentials add constraint model_credentials_provider_check
  check (provider in ('openai', 'anthropic', 'google', 'xai', 'openrouter', 'openai_compatible', 'fal',
                      'brave_search', 'tavily', 'deepgram', 'elevenlabs', 'cartesia', 'fish_audio', 'chatgpt', 'treg'));

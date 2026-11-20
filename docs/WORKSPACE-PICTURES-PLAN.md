# Workspace pictures: custom photos and AI-drawn emblems for workspaces

Status: **Not started**, 2026-11-21. Written for Oliver's review and go-ahead; no code started yet.

Builds on [BOT-PICTURES-PLAN](BOT-PICTURES-PLAN.md) (D-456: `public.bot_images`, `AvatarCropper`, `makeBotPicture`, `makeOriginal`, recent/candidate history, Undo, AI drawing) and D-202 (profile photos in Postgres served by the API).

---

## 0. Summary

Today a workspace's avatar (`SpaceAvatar` in `client/lib/features/workspaces/spaces.dart`) is a colored rounded square (`size * 0.3` corner radius) showing a Lucide icon (`organizations.icon`) or the workspace's initial.

This plan brings the same picture experience bots and user accounts have to workspaces:

1. **Custom photos & logos** for workspaces: upload from camera, photo library, file picker, drag-and-drop, or clipboard paste, cropped in the shared `AvatarCropper` with a squircle frame (`size * 0.3` radius, matching `SpaceAvatar`).
2. **AI-drawn workspace emblems ("Make One with AI")**: generate 2 candidates per run, persist candidates so users can reopen and pick any of them, and move the chosen one to Recent with 10-second Undo.
3. **One-tap Recent & Re-crop**: switch back to recent workspace pictures, re-crop kept originals, or remove the picture back to the workspace's previous icon/color.
4. **Permissions**: only workspace owners/admins (`can_manage_org` / admin role) can change or remove a workspace's picture; all members see it everywhere `SpaceAvatar` appears (switcher, workspace list, join flow, settings).

---

## 1. Storage & Database

- **Table `public.workspace_images`** (mirrors `public.bot_images` in `supabase/migrations/20270308100001_bot_images.sql`):
  - `id uuid primary key default gen_random_uuid()`
  - `org_id uuid not null references public.organizations(id) on delete cascade`
  - `created_by uuid references auth.users(id) on delete set null`
  - `source text not null check (source in ('upload', 'generated'))`
  - `large bytea not null`, `small bytea not null` (WebP 512 px / 128 px)
  - `original bytea`, `original_type text`, `crop jsonb`
  - `colors text not null` (12-hex extracted dominant colors, same `image:<uuid>:<rrggbb><rrggbb>` convention)
  - `candidate boolean not null default false`
  - `used_at timestamptz`, `created_at timestamptz not null default now()`
- **`public.organizations` column**:
  - Add `avatar_url text` (or `picture_url`, matching `bots.avatar_url` and `profiles.avatar_url`) + `prior_icon text` (optional, or keep `organizations.icon` untouched so removing a picture falls back to `organizations.icon` automatically!). Keeping `organizations.icon` and `organizations.color` intact when `avatar_url` is set makes "Remove Picture" trivial: just clear `avatar_url = null`.
- **Trigger & pruning**:
  - Updating `organizations.avatar_url` to `image:<uuid>:<colors>` marks that row `candidate = false, used_at = now()`, and prunes old unused rows (keep recent 8 non-candidates, keep originals for recent 3, keep latest ~8 candidates).

---

## 2. API & Contracts (`packages/contracts`, `apps/server`)

Mirror `apps/server/src/api/routes/bot-pictures.ts`:
- `GET /v1/workspace-images/:id` — public immutable image endpoint (`?size=128`, `?format=png`), same security headers as `/v1/bot-images/:id`.
- `POST /v1/workspaces/:id/picture` — upload square + optional original + crop + source (admin/owner only; rate-limited per org).
- `DELETE /v1/workspaces/:id/picture` — clears `organizations.avatar_url` (keeps pictures in Recent).
- `GET /v1/workspaces/:id/pictures?candidates=true|false` — lists recent (`false`) or saved AI candidates (`true`).
- `POST /v1/workspaces/:id/pictures/:imageId/use` — switches to an existing recent/candidate picture.
- `GET /v1/workspaces/:id/pictures/:imageId/original` — returns kept uncropped original for Re-crop.
- `POST /v1/workspaces/:id/pictures/draw` — generates 2 workspace emblem/logo candidates via the existing image-generation workflow (charged to the workspace's credits, same as bot picture drawing).
- Add `avatar_url?: string | null` to the `Organization` / `Workspace` contract and `WorkspaceSummary` (used in `join_flow.dart`), then run `pnpm gen`.

---

## 3. Client (`client/lib/features/workspaces/`)

- **`SpaceAvatar`** (`client/lib/features/workspaces/spaces.dart`):
  - Accept `avatarUrl` (and optional `preview` bytes for instant optimistic display).
  - When `avatarUrl` is `image:<uuid>:<colors>`, render the rounded-square image (`size * 0.3` radius) with progressive small→large loading and color-tinted fallback, matching `BotAvatar`.
  - Pass `avatarUrl: org.avatarUrl` at all `SpaceAvatar` call sites (`WorkspaceSwitcher`, `spaces.dart` list, `WorkspaceSettingsScreen`, `join_flow.dart`).
- **`EditableWorkspaceAvatar` & picture sheet** (new `workspace_picture.dart`, sharing `AvatarCropper` and the shared sheet/draw UI pattern with `bot_picture.dart`):
  - **Workspace Settings** (`spaces.dart:380`): when `admin`, tap the `SpaceAvatar` (with camera badge) or a **Picture** tile inside `_LookPicker` to open the picture sheet:
    - Take a photo (mobile), Choose a photo / file, Paste picture (when clipboard has an image), **Make One with AI** (reuses the compact shrink-wrapped draw dialog + saved candidates), Re-crop (when `hasOriginal`), Remove picture, and **Recent** strip.
    - Drag-and-drop onto the workspace avatar on desktop/web/iPad.
  - **New workspace** (`CreateSpaceSheet` / `onboarding_screen.dart`): optional picture picker or keep icon+color first and allow editing in Settings.

---

## 4. Rollout & Verification

- **Phase 1**: Migration (`workspace_images` + `organizations.avatar_url`), OpenAPI contracts + `pnpm gen`, server routes + pgTAP / Vitest tests (`workspace-images.test.ts`).
- **Phase 2**: Client `SpaceAvatar` image rendering, `workspace_picture.dart` (upload, cropper, recent, remove, undo, drag-and-drop/paste, AI draw with saved candidates), and widget tests.

---

## 5. Open Questions

1. **AI-drawn styles for workspaces:** Should "Make One with AI" for workspaces reuse the same 7 styles as bots (`Casama Cloud`, `Soft 3D`, `Watercolor`, `Flat Icon`, `Pixel Art`, `Line Art`, `Photo`), or a workspace-tuned prompt/style set (e.g. emphasizing emblems/logos/minimal marks)?
2. **Join / invite previews:** Should `avatar_url` also be exposed on public workspace invite/join previews (`join_flow.dart`), or only to workspace members?
3. **Upload & drawing daily limits:** Are the same daily caps as bots (`20` uploads/day, `20` drawings/day per workspace) good here?

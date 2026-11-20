# Workspace pictures: custom photos and AI-drawn emblems for workspaces

Status: **Built**, 2026-11-21 (all §6 defaults applied: 7 styles with workspace-emblem prompt, `avatar_url` on invite previews & HTML join page, 20 uploads/day and 20 drawings/day caps). Waiting on server deploy (migration `20270310100001_workspace_images.sql`) and app builds.

Builds on [BOT-PICTURES-PLAN](BOT-PICTURES-PLAN.md) (D-456: `public.bot_images`, `AvatarCropper`, `makeBotPicture`, `makeOriginal`, recent/candidate history, Undo, AI drawing) and D-202 (profile photos in Postgres served by the API).

---

## 0. Summary

Today a workspace's avatar (`SpaceAvatar` in `client/lib/features/workspaces/spaces.dart`) is a colored rounded square (`size * 0.3` corner radius) showing a Lucide icon (`organizations.icon`) or the workspace's initial.

This plan brings the same picture experience bots and user accounts have to workspaces:

1. **Custom photos & logos** for workspaces: upload from camera (mobile), photo library / file picker, drag-and-drop, or clipboard paste, cropped in the shared `AvatarCropper` (`AvatarShape.workspace`, `size * 0.3` radius, with live previews at switcher/settings sizes).
2. **AI-drawn workspace emblems ("Make One with AI")**: generate 2 candidates per run, persist candidates so admins can reopen and pick any of them (using the compact shrink-wrapped draw dialog), and move the chosen one to Recent with 10-second Undo.
3. **One-tap Recent, Re-crop, and Icon fallback**: switch back to the 5 most recent workspace pictures, re-crop kept originals (newest 2), remove the picture back to the workspace's icon/color, or tap an icon in `_LookPicker` to switch back to an icon.
4. **Permissions**: only workspace owners/admins (`public.has_role(org_id, 'admin')`) can change or remove a workspace's picture; all members see it everywhere `SpaceAvatar` appears.

---

## 1. Storage & Database (`supabase/migrations/`)

Mirrors `supabase/migrations/20270308100001_bot_images.sql`:

- **Table `public.workspace_images`**:
  - `id uuid primary key default gen_random_uuid()`
  - `org_id uuid not null references public.organizations(id) on delete cascade`
  - `created_by uuid references auth.users(id) on delete set null`
  - `source text not null check (source in ('upload', 'generated'))`
  - `large bytea not null check (octet_length(large) between 1 and 524288)` (512 px WebP, metadata stripped)
  - `small bytea not null check (octet_length(small) between 1 and 65536)` (128 px WebP)
  - `original bytea check (original is null or octet_length(original) between 1 and 3145728)` (≤ 2048 px, for Re-crop)
  - `original_type text check (original_type in ('image/jpeg', 'image/png', 'image/webp'))`
  - `crop jsonb` (`{x, y, scale, rotation, mirror, background}`)
  - `colors text not null check (colors ~ '^[0-9a-f]{12}$')`
  - `candidate boolean not null default false`
  - `used_at timestamptz`, `created_at timestamptz not null default now()`
  - Index `(org_id, used_at desc nulls last)`; `enable row level security` (no user policies) + `select public.allow_worker('public.workspace_images')`.
- **Table `public.workspace_image_counts`** (needed because pruning deletes rows from `workspace_images`):
  - `(org_id uuid references public.organizations(id) on delete cascade, day date default current_date, uploads int default 0, drawings int default 0, primary key (org_id, day))`
  - `enable row level security` + `select public.allow_worker('public.workspace_image_counts')`.
- **`public.organizations.avatar_url text`**:
  - Keep `organizations.icon` and `organizations.color` untouched when `avatar_url` is set, so removing a picture simply sets `avatar_url = null` and falls back to the existing icon/color.
  - **`BEFORE INSERT OR UPDATE OF avatar_url` trigger (`check_workspace_avatar`)**: validates `avatar_url` is `null` or `image:<uuid>:<12-hex>` pointing to a `public.workspace_images` row for **this** `org_id` with matching `colors` (blocks cross-org references and arbitrary URLs).
  - **`prune_workspace_images(p_org_id uuid)`** (`security definer`, `revoke all from public, anon, authenticated`): deletes unused candidates older than 1 day, keeps the 5 most recently used non-candidates (+ in-use), and keeps `original` for the newest 2 (+ in-use).
  - **`AFTER INSERT` on `workspace_images`** + **`AFTER UPDATE OF avatar_url` on `organizations`** (`organizations_mark_image_used`): marks the newly active image `used_at = now(), candidate = false` and runs `prune_workspace_images`.

---

## 2. API, Contracts & Worker (`packages/contracts`, `apps/server`, `packages/agent`)

Follows the exact HTTP methods and paths of `packages/contracts/src/routes/bot-pictures.ts` and `packages/contracts/src/routes/workspaces.ts`:

| Operation | Method & Path | Auth | Notes |
|---|---|---|---|
| `getWorkspaceImage` | `GET /v1/workspace-images/{id}` | Public (no token) | `?size=128\|512`, `?format=webp\|png`; `immutable`, `nosniff`, `default-src 'none'` |
| `setWorkspacePicture` | `PUT /v1/orgs/{id}/image` | Bearer + `has_role(id, 'admin')` | Cropped square + optional original + crop + source; 20/day per org; returns `Organization` |
| `removeWorkspacePicture` | `DELETE /v1/orgs/{id}/image` | Bearer + `has_role(id, 'admin')` | Clears `organizations.avatar_url` (keeps Recent); returns `Organization` |
| `listWorkspacePictures` | `GET /v1/orgs/{id}/images` | Bearer + org member | `?candidates=true\|false`; recent (in-use first) or saved AI candidates |
| `useWorkspacePicture` | `POST /v1/orgs/{id}/images/{image_id}/use` | Bearer + `has_role(id, 'admin')` | Switches to recent/candidate (also Undo); returns `Organization` |
| `getWorkspacePictureOriginal` | `GET /v1/orgs/{id}/images/{image_id}/original` | Bearer + `has_role(id, 'admin')` | Uncropped original for Re-crop (`private, no-store`) |
| `generateWorkspacePictures` | `POST /v1/orgs/{id}/images/generate` | Bearer + `has_role(id, 'admin')` | Draws 1–2 candidates in worker; safety check + workspace credits (`purpose: "workspace_picture"` in `usage_ledger`); 20/day per org |

- **`PATCH /v1/orgs/{id}` (`updateOrg` in `apps/server/src/api/routes/workspaces.ts`)**:
  - When `b.icon !== undefined` (admin explicitly picks an icon in `_LookPicker`), clear `avatar_url = null` so the icon takes effect immediately instead of staying hidden behind the photo.
- **Response shapes & invite previews**:
  - Add `avatar_url?: string | null` to `Organization` / `OrganizationWithRole` (`orgOut` in `workspaces.ts` and `joining.ts:192`).
  - If §6.2 approves invite previews, also add `avatar_url` to `joining.ts` (`org_avatar_url` in invite preview & join-request rows, plus `<img src="/v1/workspace-images/...">` in the server-rendered invite HTML at `joining.ts:978`).
- **Worker & prompt (`apps/server/src/worker/workflows.ts`, `packages/agent/src/tools/autonomy.ts`)**:
  - Add `generateWorkspacePictures` workflow reusing `makeBotPicture` (square WebP + 2-color extraction) and `makeOriginal`, with a `workspacePicturePrompt` based on workspace `name` + optional `description` (workspaces have no `persona_md`) and `purpose: "workspace_picture"` in `usage_ledger` (same paid image generation dependency already documented in `docs/COSTS.md`).
- **Analytics (`packages/contracts/analytics/catalog.json`)**:
  - Add `workspace_picture_set`, `workspace_picture_removed`, `workspace_picture_undone`, `workspace_picture_drawn`, `workspace_picture_crop_cancelled` (mirroring `bot_picture_*`) and run `pnpm gen`.

---

## 3. Client (`client/lib/`)

- **`AvatarShape.workspace`** (`client/lib/ui/avatar_cropper.dart`):
  - Rounded square with `size * 0.3` radius (matching `SpaceAvatar`) and live small-size previews (30 / 36 / 44 px) so admins verify legibility in the switcher before committing.
- **`SpaceAvatar`** (`client/lib/features/workspaces/spaces.dart`):
  - Add optional `avatarUrl` and `preview` (`Uint8List?`) parameters.
  - When `avatarUrl` parses as `image:<uuid>:<colors>`, render `/v1/workspace-images/<id>` (`?size=128` for small tiles, `512` for larger) clipped to `BorderRadius.circular(size * 0.3)` with color-tinted fallback while loading (same pattern as `BotAvatar`).
  - Wire `avatarUrl: org.avatarUrl` at all 7 existing `SpaceAvatar` call sites:
    - `spaces.dart`: `WorkspaceSwitcher` (line 103), spaces list (line 161), `WorkspaceSettingsScreen` (line 380).
    - `join_flow.dart`: invite preview / join cards (lines 246, 510, 590, 659).
- **`workspace_picture.dart`** (`client/lib/features/workspaces/workspace_picture.dart`):
  - Mirrors `bot_picture.dart`: `workspacePicturePreviewProvider` (optimistic memory preview), `EditableWorkspaceAvatar` (camera badge, upload ring, drag-and-drop, Cmd/Ctrl+V paste), picture sheet (camera, library/files, paste, Make One with AI, Re-crop, Remove, Recent strip), 10-second Undo toast, and compact shrink-wrapped AI draw dialog that loads saved candidates (`candidates: true`) and falls back directly to `useWorkspacePicture` if `hasOriginal` is false.
  - Wired into `WorkspaceSettingsScreen` (`spaces.dart:380`) when `admin` is true (non-admins see a static `SpaceAvatar`).
- **Backend client (`client/lib/core/backend.dart`, `supabase_backend.dart`, `fake_backend.dart`)**:
  - Add `workspaceImageUrl`, `setWorkspacePicture`, `removeWorkspacePicture`, `workspacePictures`, `useWorkspacePicture`, `workspacePictureOriginal`, `drawWorkspacePictures`.

---

## 4. Rollout & Verification

- **Phase 1 (Backend & Contracts)**: Migration + pgTAP tests (RLS, `check_workspace_avatar` cross-org rejection, pruning, `used_at`/`candidate` trigger), OpenAPI contracts + analytics catalog + `pnpm gen`, server routes + Vitest (`workspace-images.test.ts`), worker workflow/prompt tests.
- **Phase 2 (Client)**: `AvatarShape.workspace`, `SpaceAvatar` image rendering across all call sites, `workspace_picture.dart` + `WorkspaceSettingsScreen` integration, and widget tests (`workspace_picture_test.dart`).

---

## 5. Non-goals (for now)

- Chrome extension, native OS widgets, Island/menu bar, and watch apps do not render workspace icons today; no changes needed there.
- Bot tools cannot change a workspace's picture (admin-only action in the app).

---

## 6. Open Questions

1. **AI-drawn styles for workspaces:** Reuse the same 7 styles as bots (`Casama Cloud`, `Soft 3D`, `Watercolor`, `Flat Icon`, `Pixel Art`, `Line Art`, `Photo`) with workspace-emblem-tuned prompts, or a smaller emblem-focused set? *(Default: reuse the same 7 styles with a workspace-emblem prompt so the UI is consistent and familiar.)*
2. **Invite/join previews:** Expose `avatar_url` on public workspace invite/join previews (`joining.ts` HTML + `join_flow.dart`), or only to workspace members? *(Default: expose on invite previews too, matching `org_icon` and `org_color` which are already public on invite links.)*
3. **Daily caps:** Keep the same daily limits as bots (`20` uploads/day, `20` AI drawings/day per workspace)? *(Default: yes, `20` and `20`.)*

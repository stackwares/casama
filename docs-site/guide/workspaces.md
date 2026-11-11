# Workspaces and teams

A workspace holds your bots, their computers, memory, connections, secrets, billing and the people
you work with. Use separate workspaces to keep things apart, such as work and home, or one per
team. Nothing is shared between workspaces.

## Create and switch workspaces

The workspace switcher sits at the top of the sidebar on large screens, the rail on medium ones,
and the header on phones. A dot on it means another workspace has pending approvals or unread
notifications.

To create one:

1. Open the workspace switcher.
2. Tap **New workspace**.
3. Enter a **Workspace name**, pick an **Icon** and a **Color**, and confirm.

You become the workspace's owner. To switch, open the switcher and pick a workspace. The app
remembers your choice on each device.

From the CLI:

```sh
kasama org create "Ada's team"
kasama org list
kasama org use <slug>  # the default workspace for other commands
```

To rename a workspace or change its look, an owner or admin opens **Settings → Workspace
settings**.

## Roles

Every member has one role: **Owner**, **Admin** or **Member**. Each role can do everything the role
below it can.

| Role | What it can do |
| --- | --- |
| **Member** | Create bots and manage the ones they created; use team bots; answer approvals for bots they can use; see usage and the plan; manage their own quiet hours, two-step sign-in and data |
| **Admin** | Invite people (by email or link) as members or admins; rename the workspace and change its look; manage every team bot; add workspace action rules; set run history retention; require two-step sign-in; manage workspace settings such as bots talking to each other, phone calls, where secrets and memory are kept, AI app connections and workspace files; buy plans and credits and create Cloud Connect keys on Kasama Cloud |
| **Owner** | Everything above, plus turn on encryption, set up payments, and make other people owners |

A workspace always has at least one owner. Private bots are visible only to the person who created
them and the people they share them with. See [Sharing](/guide/sharing).

## Invite people

### By invite link

Links work for anyone you send them to, after they sign in.

1. Open **Settings → Workspace settings**.
2. Under **Invite links**, choose the **Role** (**Member** or **Admin**), when it **Expires** (in 1,
   7 or 30 days, or **Never**) and how many **Uses** (1, 5, 25 or **Unlimited**).
3. Tap **Create a link**.
4. Copy or share it now. For security, the full link isn't shown again.

The list shows each link's role, how many times it was used, and whether it's **Revoked**. Tap
**Revoke** to stop a link working.

To join with a link, open it, or open the workspace switcher, tap **Join with a link** and paste
it. If you open a link before signing in, Kasama joins you right after you sign in. Joining a
workspace you're already in does nothing.

### By email

1. Open **Settings** and tap **Invite a member**.
2. Enter their email and tap **Send invite**.

What happens next depends on whether the server can send email:

- **With email set up**, they get an email with a link to accept. It expires in 7 days. See
  [Limits](#limits).
- **Without email**, the app shows **Invite ready** with a code (it starts with `kinv_`). Tap
  **Copy code** and send it to them yourself. They paste it under **or join with an invite code**
  when setting up, or run `kasama invite accept <code>`.

Email invites work once, expire after 7 days, and only for the email address they were sent to.
The app invites people as members. To invite an admin by email, use the CLI:

```sh
kasama org invite ada@example.com --org <slug> --role admin
```

## Require two-step sign-in for admins

Owners and admins can require two-step sign-in for everyone with admin powers in the workspace.

1. Set up two-step sign-in for yourself first. See [Privacy and security](/guide/privacy#two-step-sign-in).
2. Open **Settings → Two-step sign-in**.
3. Under **Workspace**, turn on **Require two-step sign-in for owners and admins**.

You can only turn it on from a session where you signed in with your code, so you can't lock
yourself out. Once it's on:

- Owners and admins who didn't sign in with a code keep member access only. Settings tells them to
  set up two-step sign-in or sign in again with their code.
- Members aren't affected.

## Enterprise single sign-on (SAML)

SAML single sign-on is an enterprise feature. It needs a Kasama Enterprise license key
(`KASAMA_LICENSE_KEY`) and, when self-hosting, `SUPABASE_SERVICE_ROLE_KEY` with SAML enabled in
the auth service. Without a valid key, the enterprise endpoints answer `402 license_required`; the
rest of Kasama works as usual.

Owners and admins set it up through the API:

1. Get a verification record for each email domain:
   `GET /v1/orgs/{id}/sso/verification?domain=example.com`.
2. Add the returned TXT record (`kasama-verification=...`) to that domain's DNS.
3. Register your identity provider with its metadata URL (or XML) and your domains:

   ```http
   POST /v1/orgs/{id}/sso
   Content-Type: application/json

   { "metadata_url": "https://idp.example.com/metadata", "domains": ["example.com"] }
   ```

4. People sign in by tapping **Continue with SSO** on the sign-in screen and entering their work
   email. Kasama sends them to your identity provider.

`GET /v1/orgs/{id}/sso` shows the setup and `DELETE` removes it. A domain can belong to only one
workspace's SSO.

With the same license, owners and admins can also download the workspace's audit log as CSV or JSON
(`GET /v1/orgs/{id}/audit-log/export`, with optional `from`, `to` and `format=json`; the last 90
days by default).

## The admin console

On a self-hosted server, the instance owner has an admin console for the whole server. The
instance owner is anyone listed in `INSTANCE_ADMIN_EMAILS`, or the first person to sign up when
it's unset.

Open **Settings → Admin console**. It has these tabs:

| Tab | What you can do |
| --- | --- |
| **Overview** | Totals such as bots, **Computers running** and **Personal computers online**; the Kasama version and update notices |
| **Users** | Every user, their workspaces and when they last signed in |
| **Workspaces** | Each workspace's members and bots; **Edit quotas** (**Max bots**, **Monthly spend limit (USD)**); **Suspend** a workspace (its computers and bots stop, nothing is deleted) and **Lift suspension** |
| **Services** | Which optional services are configured, and whether each is **OK**, **Down** or **Off** |
| **Abuse** | Suspicious activity on the server |

Update notices appear only when the server sets `UPDATE_CHECK_URL`; otherwise the server never
checks for updates.

## Limit who can sign up

On a self-hosted server you can close sign-ups or allow only certain people:

- `DISABLE_SIGNUP=true` makes the server invite-only once the first accounts exist.
- `SIGNUP_ALLOWED_EMAILS` allows only listed emails or domains (for example
  `ana@example.com,@example.com`). It applies to every sign-in method, including Google. It needs
  the sign-up hook to be set up; without it, sign-ups are refused rather than open to everyone.

See [Configuration](/self-hosting/configuration).

## Limits

- The app has no member list yet. Changing someone's role, removing a member or leaving a
  workspace isn't available in the app or the CLI.
- An email invite's code can be pasted in the app only while setting up your first workspace.
  If you already belong to a workspace, accept it with `kasama invite accept <code>`.
- The emailed invite link opens an address the app doesn't handle yet. Until it does, the
  invitee can accept with `kasama invite accept <code>`, using the code at the end of the link.
- Signing in with SSO doesn't add anyone to a workspace. Invite people as usual.
- SSO setup and audit log export have no screens in the app; use the API.

## Related

- [Privacy and security](/guide/privacy)
- [Sharing](/guide/sharing)
- [Usage, budgets and plans](/guide/usage)
- [Self-hosting configuration](/self-hosting/configuration)
- [API](/develop/api)

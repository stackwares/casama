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
| **Admin** | Invite people (by link, code or email) as members or admins; approve requests to join; open the workspace to their email domain; rename the workspace and change its look; manage every team bot; add workspace action rules; set run history retention; require two-step sign-in; manage workspace settings such as bots talking to each other, phone calls, where secrets and memory are kept, AI app connections and workspace files; buy plans and credits and create Cloud Connect keys on Kasama Cloud |
| **Owner** | Everything above, plus turn on encryption, set up payments, and make other people owners |

A workspace always has at least one owner. Private bots are visible only to the person who created
them and the people they share them with. See [Sharing](/guide/sharing).

## Invite people

Owners and admins invite people from **Settings → People**. The workspace switcher has a shortcut,
**Invite people to** your workspace. Members can open **People** too, to see who's in the
workspace.

### The invite link

Every workspace has one standing invite link. Anyone who opens it can join as a member.

1. Open **Settings → People**.
2. Under **Invite link**, tap **Copy link** or **Share**. To invite someone in the room, or to move
   from your computer to your phone, tap **QR code** and let them scan it.

The link stays the same, so you can copy it again whenever you need it. To stop it working, tap
**Reset link**. The old link stops at once and you get a new one; people already in stay in.

Turn on **Ask me before people join** to make the link safe to post somewhere semi-public. People
who use it then ask to join, and their request waits under **Waiting to join**, where an owner or
admin taps **Approve** or **Decline**. Admins get a notification for each request.

### An invite code

For reading out on a call or typing on another device, tap **Get a code**. You get a short code
such as `7F3Q-9XWD`. It works for 48 hours and isn't fussy about how it's typed: lower case,
spaces, or the letter O for a zero all work. Codes leave out letters that look alike.

### By email

1. Under **Invite by email**, paste one or more addresses, separated by commas or new lines.
2. Turn on **Invite as admins** if they should be admins.
3. Tap **Send invite** (or **Send 3 invites**).

What happens next depends on whether the server can send email:

- **With email set up**, each person gets an email with a link. It works for 7 days, only for the
  address it was sent to.
- **Without email**, the app lists each person with their link. Copy it and send it to them
  yourself.

Invites that haven't been accepted are listed under **Invites not accepted yet**. Open the menu next
to one to **Send again** (a new link, valid 7 more days) or **Cancel invite**.

From the CLI:

```sh
kasama org invite ada@example.com --org <slug> --role admin
```

### Join by email domain

If you signed in with a verified work email, turn on **Anyone with a verified @example.com email
can join** under **Join by email domain**. People with a verified address at that domain then see
the workspace without an invite: new people are offered it before their first workspace is made,
and everyone else finds it under **Workspaces you can join** in the workspace switcher. Admins get a
notification when someone joins this way.

You can only open a workspace to your own domain, and never to shared ones such as gmail.com or
outlook.com.

### Custom links

Under **Custom links**, make a link with its own **Role** (**Member** or **Admin**), **Expires** (1,
7 or 30 days, or **Never**) and **Uses** (1, 5, 25 or **Unlimited**). Copy or share it right away:
for security, a custom link isn't shown again. The list shows each link and code with its role,
uses and whether it's **Revoked**; tap **Revoke** to stop one.

### Joining

Open the link. Kasama shows the workspace first: its name, who invited you, how many members it
has and the role you'd get. Tap **Join** (or **Ask to join** when an admin approves new people).
After joining, you land on a welcome page with the workspace's bots.

- **Not signed in yet:** tap **Sign in to join**. Kasama remembers the invite and shows it again
  after you sign in, even if the app restarted.
- **Got a code or a link in a message:** open the workspace switcher, tap **Join with a link or
  code** and paste or type it. On phones you can also scan the QR code. On Android and desktop, a
  link you copied fills in by itself.
- **The link is for another server:** the app offers to switch to it.

The person who made the invite gets a notification when you join.

**Opening links in the app.** When the app is installed, an invite link opens it directly once the
server publishes the app's link files (see [Configuration](/self-hosting/configuration)).
Otherwise the link opens a page in the browser with **Open in Kasama**. On a self-hosted server
without the web app, that page comes from the API.

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

- **People** lists members, but changing someone's role, removing a member or leaving a
  workspace isn't available in the app or the CLI yet.
- Joining by email domain needs a verified email address, and accepts members only.
- Wrong invites are limited to 10 tries in 10 minutes per person (or address, when signed out).
- Signing in with SSO doesn't add anyone to a workspace. Invite people as usual.
- SSO setup and audit log export have no screens in the app; use the API.

## Related

- [Privacy and security](/guide/privacy)
- [Sharing](/guide/sharing)
- [Usage, budgets and plans](/guide/usage)
- [Self-hosting configuration](/self-hosting/configuration)
- [API](/develop/api)

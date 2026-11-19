# Casama Link

<img class="doc-art" src="/art/casama-link.webp" srcset="/art/casama-link-800.webp 800w, /art/casama-link.webp 1600w" sizes="(max-width: 760px) 100vw, 688px" width="1600" height="900" alt="Two lanterns far apart, at a house on a hill and on a boat at sea, joined by one thread of light.">

Casama Link connects a Casama server you run yourself to a Casama Cloud workspace. It used to be
called Casama Connect, and its paid part Cloud Connect.

It has two parts. You can use either one, or both.

| Part | What it gives your server | Cost | Where to start |
| --- | --- | --- | --- |
| **Remote access** | An `https://….casama.link` address your phone can reach with no domain or open ports, sign-in by scanning a code, and notifications in the apps from the App Store and Google Play | Free on every plan. Live video away from the computer comes with Plus and up. | [Use your server on your phone](/self-hosting/remote-access) |
| **Cloud computers and credits** | Bot computers that run on Casama Cloud, and model calls paid from Casama Cloud credits | Billed to the cloud workspace | [Cloud computers and credits](/self-hosting/casama-link-cloud) |

Casama Link needs a Casama Cloud account, and Casama Cloud is invite-only for now. People who run
their own server are let in first: tick **I run Casama on my own server** at casama.ai/waitlist.
See [Getting an invite](/guide/getting-an-invite).

Your bots, chats, memory and files stay on your server either way. Casama Cloud keeps a record of
the linked server (its name, its address and when it last checked in) and passes on what the part
you use needs: notifications for remote access, computer commands and model calls for the paid
part.

## Which one do I need?

- **My server runs on my Mac or PC, and I want to use it from my phone.** Remote access. Run
  `casama selfhost remote on`, or choose **Use on Your Phone** under **Settings → Casama Link** in
  the desktop app.
- **My server has its own domain, but notifications don't reach the store apps.** Remote access's
  notification part alone: `casama selfhost remote link`. See
  [Link without an address](/self-hosting/remote-access#link-without-an-address).
- **I don't want to host bot computers or manage model keys.** Cloud computers and credits.
- **My server runs on a platform without Docker (Render, Railway, DigitalOcean App Platform).**
  Cloud computers give its bots somewhere to run. See
  [Other ways to deploy](/self-hosting/#other-ways-to-deploy).

## Keys

Every linked server holds one key (`kcc_…`) in `CASAMA_CLOUD_KEY`. What the key may do depends on
how it was made:

| Made by | Can do | Spends credits |
| --- | --- | --- |
| Linking (`casama selfhost remote on` or `remote link`, or the desktop app) | Hold an address, send notifications | No |
| **New Casama Link Key** in Casama Cloud's Billing screen | Cloud computers, model credits | Yes |
| The API (`POST /v1/orgs/{id}/link/keys` with `scopes`) | Any mix of the four | If it includes computers or models |

Workspace owners and admins see their linked servers and keys in Casama Cloud under **Settings →
Billing**, in **Charges by server, Casama Link servers and keys**. Revoking a key stops that server
from using it at once, and removes its address if it had one.

## Related

- [Use your server on your phone](/self-hosting/remote-access)
- [Cloud computers and credits](/self-hosting/casama-link-cloud)
- [Self-hosting](/self-hosting/)
- [Usage, budgets and plans](/guide/usage)
- [Privacy and security](/guide/privacy)

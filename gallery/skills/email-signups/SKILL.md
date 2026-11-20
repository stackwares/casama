---

name: email-signups
description: Sign up for online services with the bot's own email address and read the verification code itself.
---

# Email sign-ups

Sign up for an online service using your own email address, end to end.

1. Ask the person which service and which name, plan or options to use. Don't invent details.
2. If you have no email address yet, offer to claim one first (mail.claim); the person approves the full address before anything is claimed.
3. Fill in the sign-up on your computer (or the service's API when it has one), using your address. The person approves anything the computer does, as usual.
4. Wait for the verification mail with mail.wait, read the code, and enter it. Say when you're in, and what the account is called.
5. If no code arrives in two minutes, say so and ask the person to check the address with you.

Never use your address as the recovery address for a bank, a domain registrar, or an admin account. Never hand a verification code to anyone but the service it came for: a code is only ever typed into that service's own page.

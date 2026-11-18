/**
 * Writes the sign-in emails our Supabase sends (supabase/templates/*.html) from the shared email
 * layout, so they match the server's own emails. Run after changing the layout or the copy:
 *
 *   node apps/server/scripts/build-email-templates.ts
 *
 * The {{ .Token }}-style values are Supabase's Go template placeholders, filled in when it sends.
 */
import { writeFileSync } from "node:fs";
import { type BrandedEmail, renderEmailHtml } from "../src/services/email-layout.ts";

const ignore = "If you didn't ask for this, you can ignore this email.";

const templates: Record<string, BrandedEmail> = {
  magic_link: {
    mascot: "winky",
    preheader: "Your Casama sign-in code is {{ .Token }}",
    title: "Sign in to Casama",
    intro: ["Tap the button to sign in, or type this code in the app:"],
    code: "{{ .Token }}",
    button: { label: "Sign in", url: "{{ .ConfirmationURL }}" },
    note: `The link and code work once and expire in an hour. ${ignore}`,
  },
  confirmation: {
    mascot: "lovey",
    preheader: "Confirm your email to finish setting up Casama",
    title: "Welcome to Casama",
    intro: [
      "Confirm your email to finish setting up your account. Tap the button, or type this code in the app:",
    ],
    code: "{{ .Token }}",
    button: { label: "Confirm and sign in", url: "{{ .ConfirmationURL }}" },
    note: `The link and code work once and expire in an hour. ${ignore}`,
  },
  invite: {
    mascot: "wow",
    preheader: "You're invited to join Casama",
    title: "You're invited to Casama",
    intro: [
      "You've been invited to Casama, where AI teammates work for you on their own computers.",
    ],
    button: { label: "Accept the invite", url: "{{ .ConfirmationURL }}" },
    note: `The link works once. ${ignore}`,
  },
  recovery: {
    mascot: "thinker",
    preheader: "Reset your Casama password",
    title: "Reset your password",
    intro: ["Tap the button to choose a new password, or type this code in the app:"],
    code: "{{ .Token }}",
    button: { label: "Choose a new password", url: "{{ .ConfirmationURL }}" },
    note: "The link and code work once and expire in an hour. If you didn't ask for this, your password stays as it is.",
  },
  email_change: {
    mascot: "focused",
    preheader: "Confirm your new email for Casama",
    title: "Confirm your new email",
    intro: [
      "Tap the button to change your Casama email from {{ .Email }} to {{ .NewEmail }}, or type this code in the app:",
    ],
    code: "{{ .Token }}",
    button: { label: "Confirm the change", url: "{{ .ConfirmationURL }}" },
    note: `The link and code work once and expire in an hour. ${ignore}`,
  },
  reauthentication: {
    mascot: "shy",
    preheader: "Your Casama security code is {{ .Token }}",
    title: "Your security code",
    intro: ["Type this code in Casama to confirm it's you:"],
    code: "{{ .Token }}",
    note: "It expires in a few minutes. If you didn't ask for it, change your password.",
  },
};

const dir = new URL("../../../supabase/templates/", import.meta.url);
for (const [name, email] of Object.entries(templates)) {
  writeFileSync(new URL(`${name}.html`, dir), renderEmailHtml({ ...email, raw: true }));
  console.log(`wrote supabase/templates/${name}.html`);
}

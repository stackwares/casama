/**
 * The waitlist and invite forms' markup (docs/WAITLIST-PLAN.md §5, §7, §12), shared by site/build.mjs
 * (the /waitlist page) and the casama.ai Worker (the invite pages). site/assets/waitlist.js wires them:
 * each form starts hidden and the script shows it, so without JavaScript only the <noscript> line shows.
 */

export const SELF_HOSTING_DOCS = "https://docs.casama.ai/self-hosting/";
const SIGN_IN = "https://app.casama.ai";

/** HTML-escapes a value for text or a double-quoted attribute. */
export function esc(value) {
  return String(value).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
}

export const NO_SCRIPT = `<noscript><p class="wl-note">The waitlist needs JavaScript. Turn it on, or email <a href="mailto:hello@casama.ai">hello@casama.ai</a> and we'll add you.</p></noscript>`;

/** Email, an optional line, two boxes. Posts to /v1/waitlist. */
function joinForm(source) {
  return `<form class="wl-form" data-wl-join data-source="${esc(source)}" aria-label="Join the waitlist" hidden>
    <label class="wl-field"><span>Email</span><input type="email" name="email" required autocomplete="email" inputmode="email" maxlength="254" placeholder="you@example.com"></label>
    <label class="wl-field"><span>What would you have a bot do first?</span><input type="text" name="note" maxlength="280" autocomplete="off"></label>
    <label class="wl-check"><input type="checkbox" name="self_hosting"><span>I run Casama on my own server</span></label>
    <label class="wl-check"><input type="checkbox" name="newsletter"><span>Also send me Casama's monthly email (once a month at most)</span></label>
    <button class="btn primary" type="submit">Join the waitlist</button>
    <p class="wl-status" role="status" aria-live="polite" data-wl-status></p>
  </form>`;
}

/**
 * Posts to /v1/waitlist/redeem. With `code` the code is fixed (invite pages); without, there is a code field.
 * `label` is the button. The monthly email box starts unticked; a tick is kept with the claim and only
 * becomes a subscription once that address signs up, so no confirmation email is needed.
 */
export function redeemForm({ code = "", label, source = "waitlist" }) {
  const codeField = code
    ? ""
    : `\n    <label class="wl-field"><span>Invite code</span><input type="text" name="code" required autocomplete="off" autocapitalize="characters" spellcheck="false" maxlength="200"></label>`;
  return `<form class="wl-form" data-wl-redeem data-source="${esc(source)}"${code ? ` data-code="${esc(code)}"` : ""} aria-label="${esc(label)}" hidden>${codeField}
    <label class="wl-field"><span>Email</span><input type="email" name="email" required autocomplete="email" inputmode="email" maxlength="254" placeholder="you@example.com"></label>
    <label class="wl-check"><input type="checkbox" name="newsletter"><span>Also send me Casama's monthly email (once a month at most)</span></label>
    <button class="btn primary" type="submit">${esc(label)}</button>
    <p class="wl-status" role="status" aria-live="polite" data-wl-status></p>
  </form>
  <div class="wl-result" data-wl-result role="status" aria-live="polite" hidden></div>`;
}

/** The whole /waitlist page body ({{ waitlist }} in site/content/waitlist.md). */
export function waitlistPage() {
  return `<div class="wl">
  ${NO_SCRIPT}
  <section class="wl-card" aria-label="Join the waitlist">
  ${joinForm("waitlist")}
  <div class="wl-joined" data-wl-joined hidden>
    <p class="wl-lead"><strong>You're on the list.</strong> We're letting people in every day. You'll get one email when it's your turn, and nothing else unless you asked for the monthly email.</p>
    <p>Have an invite code? Enter it below.</p>
    <p>Don't want to wait? Casama is open source. <a href="${SELF_HOSTING_DOCS}">Run it on your own computer today.</a></p>
  </div>
  </section>
  <h2 id="invite-code">Have an invite code?</h2>
  <section class="wl-card" aria-labelledby="invite-code">
  ${redeemForm({ label: "Use my invite" })}
  </section>
  <p class="wl-signin">Already have an account? <a href="${SIGN_IN}">Sign in</a></p>
</div>`;
}

/** The page for /waitlist/leave (the Worker's own page). The link only asks; the button removes. */
export function leaveBlock() {
  return `<div data-wl-leave>
    <div data-wl-leave-ask hidden>
      <h1>Take your address off the waitlist?</h1>
      <p>Press the button and we'll delete it. You won't get an email when it's your turn.</p>
      <button class="btn primary" type="button" data-wl-leave-button>Remove my address</button>
      <p class="wl-status" role="status" aria-live="polite" data-wl-status></p>
    </div>
    <div data-wl-leave-done hidden>
      <h1>Done.</h1>
      <p>Your address is off the list.</p>
    </div>
    <div data-wl-leave-bad hidden>
      <h1>That link isn't valid any more.</h1>
      <p>If you still want off the list, email <a href="mailto:hello@casama.ai">hello@casama.ai</a>.</p>
    </div>
  </div>`;
}

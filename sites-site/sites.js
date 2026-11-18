/* The sites zone's own page (docs/SITES-AND-DOMAINS-PLAN.md §7.11): sends a report by address to
   POST /v1/site-reports. The answer is the same for any address, so the form can't be used to find
   out which sites exist. */
(() => {
  var form = document.getElementById("report-form");
  if (!form) return;
  var error = document.getElementById("r-error");
  var done = document.getElementById("r-done");
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    error.hidden = true;
    done.hidden = true;
    var button = form.querySelector("button");
    button.disabled = true;
    fetch(`${form.getAttribute("data-api")}/v1/site-reports`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        address: form.address.value.trim(),
        reason: form.reason.value.trim(),
      }),
    })
      .then((r) => {
        if (r.status === 429) throw new Error("Too many reports from here. Try again in an hour.");
        if (!r.ok) throw new Error("That didn't send. Check the address and try again.");
        form.reset();
        done.hidden = false;
      })
      .catch((err) => {
        error.textContent = err.message || "That didn't send.";
        error.hidden = false;
      })
      .finally(() => {
        button.disabled = false;
      });
  });
})();

/* Site script for the 2026 redesign: theme toggle, copy email, publication filter. */
(function () {
  "use strict";
  var root = document.documentElement;

  /* theme: light by default; dark only when the visitor chooses it */
  var themeBtn = document.getElementById("theme-btn");
  if (themeBtn) {
    var moon = document.getElementById("icon-moon");
    var sun = document.getElementById("icon-sun");
    var sync = function () {
      var dark = root.getAttribute("data-theme") === "dark";
      themeBtn.setAttribute("aria-label", dark ? "Use light theme" : "Use dark theme");
      moon.hidden = dark; sun.hidden = !dark;
    };
    themeBtn.addEventListener("click", function () {
      var next = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
      root.setAttribute("data-theme", next);
      try { localStorage.setItem("jj-theme", next); } catch (e) {}
      sync();
    });
    sync();
  }

  /* copy email */
  var copyBtn = document.getElementById("copy-email");
  if (copyBtn) {
    var emailEl = document.getElementById("email");
    var copyStatus = document.getElementById("copy-status");
    var selectEmail = function () {
      var range = document.createRange(); range.selectNodeContents(emailEl);
      var sel = window.getSelection(); sel.removeAllRanges(); sel.addRange(range);
      copyStatus.textContent = "Address selected. Press Ctrl+C or Cmd+C to copy.";
    };
    copyBtn.addEventListener("click", function () {
      var text = emailEl.textContent.trim();
      try {
        navigator.clipboard.writeText(text).then(function () { copyStatus.textContent = "Email address copied."; }, selectEmail);
      } catch (e) { selectEmail(); }
    });
  }

  /* publication filter: buttons carry data-f; items carry data-p (space-separated directions) */
  var filters = document.getElementById("filters");
  var groups = document.getElementById("pub-groups");
  if (filters && groups) {
    var status = document.getElementById("pub-status");
    var total = groups.querySelectorAll("li[data-p]").length;
    var apply = function (f, label) {
      var shown = 0;
      filters.querySelectorAll(".filter").forEach(function (b) { b.setAttribute("aria-pressed", String(b.dataset.f === f)); });
      groups.querySelectorAll("[data-group]").forEach(function (sec) {
        var n = 0;
        sec.querySelectorAll("li[data-p]").forEach(function (li) {
          var ok = f === "all" || (" " + li.dataset.p + " ").indexOf(" " + f + " ") > -1;
          li.hidden = !ok; if (ok) n++;
        });
        sec.hidden = n === 0;
        shown += n;
      });
      status.textContent = f === "all" ? total + " publications." : shown + " of " + total + " publications on " + label + ".";
    };
    filters.addEventListener("click", function (e) {
      var b = e.target.closest(".filter");
      if (b) apply(b.dataset.f, b.textContent);
    });
    filters.hidden = false;
    apply("all", "");
  }
})();

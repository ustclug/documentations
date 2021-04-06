document.addEventListener("DOMContentLoaded", function() {
  load_navpane();
});

function load_navpane() {
  var width = window.innerWidth;
  if (width <= 1200)
    return;
  const EXPAND_LEVELS = [1, 2];

  var nav = document.getElementsByClassName("md-nav");
  for (var i = 0; i < nav.length; i++) {
    if (typeof nav.item(i).style === "undefined")
      continue;

    if (EXPAND_LEVELS.includes(nav.item(i).getAttribute("data-md-level")) && nav.item(i).getAttribute("data-md-component")) {
      nav.item(i).style.display = 'block';
      nav.item(i).style.overflow = 'visible';
    }
  }

  var nav = document.getElementsByClassName("md-nav__toggle");
  for (var i = 0; i < nav.length; i++)
    if (EXPAND_LEVELS.includes((nav.item(i).id.match(/_\\d+/g) || []).length))
      nav.item(i).checked = true;
}

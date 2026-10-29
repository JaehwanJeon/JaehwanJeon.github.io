/*
* Greedy Navigation
*
* http://codepen.io/lukejacksonn/pen/PwmwWV
*
*/

var $nav = $('#site-nav');
var $btn = $('#site-nav button');
var $vlinks = $('#site-nav .visible-links');
var $vlinks_persist_tail = $vlinks.children("*.persist.tail");
var $hlinks = $('#site-nav .hidden-links');

var breaks = [];
var wasCompact = false;

function updateNav() {
  var compact = window.matchMedia('(max-width: 767px)').matches;

  if (compact) {
    // Keep the same links, in the same order, together in the phone menu.
    $vlinks.children('*:not(.persist)').prependTo($hlinks);
    breaks = [];
    $btn.toggleClass('hidden', $hlinks.children().length === 0);
  } else {
    if (wasCompact) {
      // Restore every link before the normal wide-screen overflow calculation.
      if ($vlinks_persist_tail.length) {
        $hlinks.children().insertBefore($vlinks_persist_tail);
      } else {
        $hlinks.children().appendTo($vlinks);
      }
      breaks = [];
      $btn.addClass('hidden').removeClass('close');
      $hlinks.addClass('hidden');
    }

    var availableSpace = $btn.hasClass('hidden') ? $nav.width() : $nav.width() - $btn.width() - 30;

    // The visible list is overflowing the nav
    if ($vlinks.width() > availableSpace) {

      while ($vlinks.width() > availableSpace && $vlinks.children("*:not(.persist)").length > 0) {
        // Record the width of the list
        breaks.push($vlinks.width());

        // Move item to the hidden list
        $vlinks.children("*:not(.persist)").last().prependTo($hlinks);

        availableSpace = $btn.hasClass("hidden") ? $nav.width() : $nav.width() - $btn.width() - 30;

        // Show the dropdown btn
        $btn.removeClass("hidden");
      }

      // The visible list is not overflowing
    } else {

      // There is space for another item in the nav
      while (breaks.length > 0 && availableSpace > breaks[breaks.length - 1]) {
        // Move the item to the visible list
        if ($vlinks_persist_tail.children().length > 0) {
          $hlinks.children().first().insertBefore($vlinks_persist_tail);
        } else {
          $hlinks.children().first().appendTo($vlinks);
        }
        breaks.pop();
      }

      // Hide the dropdown btn if hidden list is empty
      if (breaks.length < 1) {
        $btn.addClass('hidden');
        $btn.removeClass('close');
        $hlinks.addClass('hidden');
      }
    }

  }
  wasCompact = compact;

  // Count actual hidden links in either layout.
  $btn.attr("count", $hlinks.children().length);

  // update masthead height and the body/sidebar top padding
  var mastheadHeight = $('.masthead').height();
  $('body').css('padding-top', mastheadHeight + 'px');
  // the sidebar is only fixed (and needs the masthead offset) from $sidebar-screen-min-width
  if (!window.matchMedia("(min-width: 1024px)").matches) {
    $(".sidebar").css("padding-top", "");
  } else {
    $(".sidebar").css("padding-top", mastheadHeight + "px");
  }

}

// Window listeners

$(window).on('resize', function () {
  updateNav();
});
screen.orientation.addEventListener("change", function () {
  updateNav();
});

$btn.on('click', function () {
  $hlinks.toggleClass('hidden');
  $(this).toggleClass('close');
});

updateNav();
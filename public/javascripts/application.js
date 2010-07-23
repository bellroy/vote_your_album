// On Load
$(function() {

  function resizeBody() {
    $("section.music").css({ height: $(window).height() - $("body > header").outerHeight(true) - 70 });
    $("section.music .list").css({ height: $("section.music").innerHeight() - $("section.music header").height() - 30 });
    $("section.music .overlay").css({ height: $("section.music").outerHeight(true) });

    $("section.upcoming").css({ height: $("section.music").height() - $("section.updates").outerHeight(true) });
    $("section.upcoming .list").css({ height: $("section.upcoming").innerHeight() - $("section.upcoming header").height() - 30 });
  };

  $(window).resize(function() {
    resizeBody();
  });
  resizeBody();

  // Volume Slider definition
  $("#slider").slider({
    animate: true,
    stop: function() {
      $.post("/volume/" + $(this).slider("option", "value"));
    }
  });

  // Fetch songs when clicking on the album
  $("section.music article").live("click", function() {
    var album = $(this);
    album.children(".song_spinner").show();

    $.get("/songs/" + $(this).attr("ref"), function(list) {
      album.children(".song_spinner").hide();
      album.children(".songs").html(list);
    });

    return false;
  });

  // Drop container definitions
  $("section.upcoming").droppable({
    scope: "adding",
    hoverClass: "over",
    drop: function(event, ui) {
      $.post("/add/" + ui.draggable.attr("ref"), function(list) {
        $("section.upcoming .list").html(list);
      });
    }
  });
  $("section.music").droppable({
    scope: "removing",
    hoverClass: "over",
    drop: function(event, ui) {
      $.post("/remove/" + ui.draggable.attr("ref"), function(list) {
        $("section.upcoming .list").html(list);
      });
    }
  });

  $("section.upcoming .list").live("mouseover", function() {
    $("section.upcoming .deleteable").draggable($.extend(drag_options, {
      scope: "removing"
    }));
  });

  // Click events that update the status of the application
  $(".control").click(function() {
    return executeAndUpdate("/control/" + $(this).attr("ref"));
  });
  $("#force").click(function() {
    return executeAndUpdate("/force");
  });

  // Click Events that update the 'upcoming list'
  $.each(["up", "down"], function() {
    var action = this;
    $("." + action).live("click", function() {
      $.post("/" + action + "/" + $(this).attr("ref"), function(list) {
        $("section.upcoming .list").html(list);
      });

      return false
    });
  });

  // Search
  $("#query").delayedObserver(function() {
    $("#search").ajaxSubmit({
      dataType: "json",
      beforeSend: function() {
        $("section.music .overlay").show();
      },
      success: function(list) {
        updateList(list);
      }
    });
  }, 0.3);

  // Random
  $("a.shuffle").click(function() {
    getList("random");
    return false;
  });

  // Initial page update to load the lists and the status
  getList("all");
  getUpcoming();
  getStatus();
  getUpdates();
});

// Drag definitions
var drag_options = {
  helper: "clone",
  opacity: 0.8,
  zIndex: 99,
  appendTo: "body"
}

/*
 * Requests an update of the available albums and updates the list
 */
function getList(type) {
  $("section.music .overlay").show();

  $.getJSON("/music/" + type, function(list) {
    updateList(list);
    return false;
  });
}

/*
 * Requests an update of the upcoming albums and updates the list
 */
function getUpcoming() {
  $.get("/upcoming", function(list) {
    $("section.upcoming .list").html(list);
  });
  setTimeout("getUpcoming();", 8000);
}

/*
 * Get the latest status from the server to update the main controls.
 */
function getStatus() {
  $.getJSON("/status", mainControls);
  setTimeout("getStatus();", 10000);
}

/*
 * Requests the list of updates
 */
function getUpdates() {
  $.get("/updates", function(list) {
    $("section.updates .list").html(list);
  });
  setTimeout("getUpdates();", 7000);
}

/*
 * Takes the list of albums and initializes iterative renderding.
 */
var albumList = [];
function updateList(albums) {
  var list = $("section.music .list");
  list.children().draggable("disable");
  list.html("");

  albumList = albums;
  $("section.music .overlay").hide();

  if (!_.isEmpty(albumList)) setTimeout("appendAlbumsIteratively()", 1);
}

/*
 * Renders 20 albums at once and then 'flushes' them out.
 */
function appendAlbumsIteratively() {
  var list = $("section.music .list");

  var albums = _.first(albumList, 20);
  albumList = _.rest(albumList, 20);

  $.each(albums, function() {
    list.append(albumElement(this));
  });
  list.children().draggable($.extend(drag_options, {
    scope: "adding"
  }));

  if (!_.isEmpty(albumList)) setTimeout("appendAlbumsIteratively()", 1);
}

/*
 * Returns an album element.
 */
function albumElement(album) {
  return ' \
    <article class="album" ref="' + album.id + '" title="Click to show songs"> \
      <img class="song_spinner" src="/images/spinner.gif" /> \
      <div class="info"> \
        <img class="art" ' + (album.art != null ? ('src="' + album.art + '"') : '') + ' /> \
        <p>' + album.artist + '</p> \
        <p>' + album.name + '</p> \
      </div> \
      <aside class="songs"></aside> \
    </article> \
  ';
}

/*
 * Update the main controls (at the top of the page) according to the received status
 */
function mainControls(data) {
  $("header section.controls").toggleClass("playing", data.playing);
  $("#slider").slider("option", "value", data.volume);
  $("#art").removeAttr("src");

  if (data.playing) {
    $("#current").html(data.current_album);
    if (data.current_art) $("#art").attr("src", data.current_art);

    var song = data.current_song
    $("#song").html("(" + song.track + ") " + song.artist + " - " + song.title);
    $("#time").html(data.time + " (" + data.total + ")");
    $("#nominator").html("by " + data.nominated_by);

    $("#force").show();
    $("#force .necessary").html(data.down_votes_necessary);
    $("#force").toggleClass("disabled", !data.forceable)
  }
  else {
    $("#current").html("");
    $("#song").html("");
    $("#time").html("");
    $("#nominator").html("");
    $("#force").hide();
  }
}

/*
 * Helper function that executes a POST request with the given URL
 */
function executeAndUpdate(url) {
  $.ajax({
    type: "POST",
    dataType: "json",
    url: url,
    success: mainControls
  });

  return false;
}

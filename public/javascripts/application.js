// On Load
$(function() {

  // Volume Slider definition
  $("#slider").slider({
    animate: true,
    stop: function() {
      $.post("/volume/" + $(this).slider("option", "value"));
    }
  });

  // Name form
  $("#change_name").ajaxForm({
    success: function() {
      $("#change_name input").blur();
    }
  });

  // Drop container definitions
  $("section.upcoming").droppable({
    scope: "adding",
    hoverClass: "over",
    drop: function(event, ui) {
      $.post("/add/" + ui.draggable.attr("ref"), function(list) {
        $("section.upcoming #list").html(list);
      });
    }
  });
  $("section.music").droppable({
    scope: "removing",
    hoverClass: "over",
    drop: function(event, ui) {
      $.post("/remove/" + ui.draggable.attr("ref"), function(list) {
        $("section.upcoming #list").html(list);
      });
    }
  });

  $("section.upcoming #list").live("mouseover", function() {
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
        $("section.upcoming #list").html(list);
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
    $("section.upcoming #list").html(list);
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
 * Takes the list of albums and renders the list dynamically.
 */
function updateList(albums) {
  var list = $("section.music #list");
  list.children().draggable("disable");
  list.html("");

  var i = 0;
  $.each(albums, function() {
    var album = ' \
      <article class="album" ref="' + this.id + '"> \
        <div class="info"> \
          <img class="art" /> \
          <p>' + this.artist + '</p> \
          <p>' + this.name + '</p> \
        </div> \
      </article> \
    ';

    list.append(album);
  });

  list.children().draggable($.extend(drag_options, {
    scope: "adding"
  }));
  $("section.music .overlay").hide();
}

/*
 * Update the main controls (at the top of the page) according to the received status
 */
function mainControls(data) {
  $("header section.controls").toggleClass("playing", data.playing);
  $("#slider").slider("option", "value", data.volume);

  if (data.playing) {
    $("#current").html(data.current_album);

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

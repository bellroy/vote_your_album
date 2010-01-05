// On Load
$(function() {

  // Volume Slider definition
  $("#slider").slider({
    animate: true,
    stop: function() { $.post("/volume/" + $(this).slider("option", "value")); }
  });

  // Name form
  $("#change_name").ajaxForm({
    success: function() { $("#change_name input").blur(); }
  });

  // Drop container definitions
  $("#upcoming").droppable({
    scope: "adding",
    hoverClass: "over",
    drop: function(event, ui) { $.post("/add/" + ui.draggable.attr("ref"), function(list) { $("#upcoming").html(list); }); }
  });
  $("#list").droppable({
    scope: "removing",
    hoverClass: "over",
    drop: function(event, ui) {
      $.post("/remove/" + ui.draggable.attr("ref"), function(list) { $("#upcoming").html(list); });
    }
  });

  $("#upcoming").live("mouseover", function() {
    $("#upcoming .album.deleteable").draggable($.extend(drag_options, {
      scope: "removing"
    }));
  });

  // Click events that update the status of the application
  $(".control").click(function() { return executeAndUpdate("/control/" + $(this).attr("ref")); });
  $("#force").click(function() { return executeAndUpdate("/force"); });

  // Callback definition for the rating system
  $(".rate_star").rating({
    callback: function(value) { return executeAndUpdate("/rate/" + value); }
  });

  // Click Events that update the 'upcoming list'
  $.each(["add", "up", "down"], function() {
    var action = this;
    $("." + action).live("click", function() {
      $.post("/" + action + "/" + $(this).attr("ref"), function(list) { $("#upcoming").html(list); });
      return false
    });
  });

  // Search
  $("#search").ajaxForm({
    dataType: "json",
    beforeSend: function() { $(".list .overlay").show(); },
    success: function(list) {
      highlightTab(".all");
      updateList(list);
    }
  });
  $("#clear").click(function() {
    $("#search").clearForm();
    getList("all");
  });

  // Album songs
  $(".toggle_songs").live("click", function() {
    var li = $(this).parents(".album");

    if (!li.hasClass("loaded")) {
      $.get("/songs/" + $(this).attr("ref"), function(songs) { li.children(".songs").html(songs); });
      li.addClass("loaded");
    }

    li.toggleClass("expanded");
    return false;
  });

  // Nomination songs
  $(".song input").live("click", function() {
    var nomination = $(this).parents(".album").attr("ref");
    $.post("/" + ($(this).attr("checked") ? "add" : "delete") + "_song/" + nomination + "/" + $(this).attr("ref"));
  });

  // Lists
  $.each(["all", "most_listened", "top_rated", "most_popular", "least_popular", "never_nominated"], function() {
    var type = this;
    $("." + type).click(function() { getList(type); });
  });
  $(".update").click(function() {
    if (confirm("Do you really want to update the Database? This might take some time (and i cant tell you how long right now)...")) $.post("/update");
    return false;
  });

  // Initial page update to load the lists and the status
  getList("all");
  getUpcoming();

  //
  if ("WebSocket" in window) {
    var ws = new WebSocket("ws://localhost:8080/ws");

    ws.onopen = function() {
      console.debug("websocket initialized")
    };

    ws.onmessage = function (evt) {
      console.debug(evt.data);

      var json = eval("(" + evt.data + ")");
      if (_(json).hasKey("volume")) {
        $("#slider").slider("option", "value", json.volume);
      }
      else if (_(json).hasKey("current_song")) {
        var song = json.current_song;
        $("#song .song").html("(" + song.track + ") " + song.artist + " - " + song.title);
      }
      else if (_(json).hasKey("time")) {
        $("#song .time").html("(" + json.time + ")");
      }
      else {
        console.debug("no recognized command found: " + json);
      }
    };

    ws.onclose = function() {
      console.debug("websocket closed");
    };
  }
  else {

    // no WS support, get the status the traditional way
    console.debug("no browser support - sorry!");
    getStatus();
  }
});

// Drag definitions
var drag_options = {
  handle: ".left",
  helper: "clone",
  opacity: 0.4
}

/*
 * Requests an update of the available albums and updates the list
 */
function getList(type) {
  $(".list .overlay").show();
  $.getJSON("/list/" + type, function(list) {
    highlightTab("." + type);
    updateList(list);
    return false;
  });
}
function highlightTab(link) {
  $("#tabs li").removeClass("selected");
  $(link).parent().addClass("selected");
}

/*
 * Requests an update of the upcoming albums and updates the list
 */
function getUpcoming() {
  var params = "";
  $(".upcoming li.expanded").each(function() { params += "&expanded[]=" + $(this).attr("ref"); });

  $.get("/upcoming?" + params, function(list) { $("#upcoming").html(list); });
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
function updateList(list) {
  var ul = $("#list");
  ul.children().draggable("disable");
  ul.html("");

  var i = 0;
  $.each(list, function() {
    var li = '<li class="album ' + (i++ % 2 == 0 ? "even" : "odd") + '" ref="' + this.id + '">';
    li += '<div class="left">';
    li +=   '<a href="#" class="toggle_songs" ref="' + this.id + '"></a>';
    li +=   '<span class="artist">' + this.artist + '</span>';
    li +=   '<span> - </span>';
    li +=   '<span class="album">' + this.name + '</span>';
    if (this.value != null) li += '<span class="value">(' + this.value + ')</span>';
    li += '</div>';
    li += '<div class="right">';
    li +=   '<a href="#" class="add" ref="' + this.id + '">';
    li +=     '<img src="/images/add.png" title="Add Album to Upcoming Albums" />';
    li +=   '</a>';
    li += '</div>';
    li += '<div class="songs clear"></div>';
    li += '<div class="clear"></div>';
    li += '</li>';

    ul.append(li);
  });

  ul.children().draggable($.extend(drag_options, {
    scope: "adding"
  }));
  $(".list .overlay").hide();
}

/*
 * Update the main controls (at the top of the page) according to the received status
 */
function mainControls(data) {
  $("#slider").slider("option", "value", data.volume);

  if (data.playing) {
    $("#current").html(data.current_album);

    var song = data.current_song
    $("#song .song").html("(" + song.track + ") " + song.artist + " - " + song.title);
    $("#song .time").html("(" + data.time + ")");

    $("#force").show();
    $("#force").attr("title", "Necessary Votes to force next album: " + data.down_votes_necessary);
    $("#force .necessary").html(data.down_votes_necessary);
    if (data.forceable) $("#force").removeClass("disabled");
    else                $("#force").addClass("disabled");
  }
  else {
    $("#current").html("");
    $("#song .song, #song .time").html("");
    $("#force").hide();
  }

  // Update the rating elements
  if (data.playing && data.rateable) {
    $("#rate_current").removeClass("hidden");
    $(".rate_star").removeClass("star-rating-on");
  }
  else {
    $("#rate_current").addClass("hidden");
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

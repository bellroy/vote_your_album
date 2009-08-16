// On Load
$(function() {
  
  // Volume Slider definition
  $("#slider").slider({
    animate: true,
    stop: function() { $.post("/volume/" + $(this).slider("option", "value")); }
  });
  
  // Drop container definitions
  $("#upcoming").droppable({
    scope: "adding",
    hoverClass: "over",
    drop: function(event, ui) {
      $.post("/add/" + ui.draggable.attr("ref"), function(list) { $("#upcoming").html(list); });
    }
  });
  $("#list").droppable({
    scope: "removing",
    hoverClass: "over",
    drop: function(event, ui) {
      $.post("/remove/" + ui.draggable.attr("ref"), function(list) { $("#upcoming").html(list); });
    }
  });
  
  // Drag definitions
  var drag_options = {
    handle: ".left",
    helper: "clone",
    opacity: 0.4
  }
  $("#list").live("mouseover", function() {
    $("#list .album").draggable($.extend(drag_options, {
      scope: "adding"
    }));
  });
  $("#upcoming").live("mouseover", function() {
    $("#upcoming .album.deleteable").draggable($.extend(drag_options, {
      scope: "removing"
    }));
  });
  
  // Click events that update the status of the application
  $(".control").click(function() { return executeAndUpdate("/control/" + $(this).attr("ref")); });
  $("#play").click(function() { return executeAndUpdate("/play"); });
  $("#force").click(function() { return executeAndUpdate("/force"); });
  
  // Click Events that update the 'upcoming list'
  $.each(["add", "up", "down"], function() {
    var action = this;
    $("." + action).live("click", function() {
      $.post("/" + action + "/" + $(this).attr("ref"), function(list) { $("#upcoming").html(list); });
      return false
    });
  });
  
  // Search
  $("#search").ajaxForm({ success: function(list) { $("#list").html(list); } });
  $("#clear").click(function() {
    $("#search").clearForm();
    getList();
  });
  
  // Initial page update to load the lists and the status
  getList();
  getUpcoming();
  getStatus();
});

/*
 * Requests an update of the available albums and updates the list
 */
function getList() { $.get("/list", function(list) { $("#list").html(list); }); }

/*
 * Requests an update of the upcoming albums and updates the list
 */
function getUpcoming() {
  $.get("/upcoming", function(list) { $("#upcoming").html(list); });
  setTimeout("getUpcoming();", 5000);
}

/*
 * Get the latest status from the server to update the main controls.
 */
function getStatus() {
  $.getJSON("/status", mainControls);
	setTimeout("getStatus();", 10000);
}

/*
 * Update the main controls (at the top of the page) according to the received status
 */
function mainControls(data) {
  $("#slider").slider("option", "value", data.volume);
  
  if (data.playing) {
    $("#play").hide();
    $("#current").html(data.current_album);
    
    $("#force").show();
    $("#force").attr("title", "Necessary Votes to force next album: " + data.force_score);
    $("#force .necessary").html(data.force_score);
    if (data.forceable) $("#force").removeClass("disabled");
    else                $("#force").addClass("disabled");
  }
  else {
    $("#play").show();
    $("#current").html("");
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
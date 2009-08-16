// On Load
$(function() {
  
  // Volume Slider definition
  $("#slider").slider({
    animate: true,
    stop: function() { $.post("/volume/" + $(this).slider("option", "value")); }
  });
  
  // Drop container definitions
  $("#upcoming").droppable({
    activeClass: "active",
    drop: function(event, ui) {
      $.post("/add/" + ui.draggable.attr("ref"), function(list) { $("#upcoming").html(list); });
    }
  });
  
  // Drag definition
  $("#list").live("mouseover", function() {
    $("#list .album").draggable({
      handle: ".left",
      helper: "clone",
      opacity: 0.4
    });
  });
  
  // Click events that update the status of the application
  $(".control").click(function() { return executeAndUpdate("/control/" + $(this).attr("ref")); });
  $(".play").click(function() { return executeAndUpdate("/play"); });
  
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
    $("#current").html(data.current);
  }
  else {
    $("#play").show();
    $("#current").html("");
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
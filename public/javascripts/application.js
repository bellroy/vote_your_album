// On Load
$(function() {
  
  // Volume Slider definition
  $("#slider").slider({
    animate: true,
    stop: function() { $.post("/volume/" + $(this).slider("option", "value")); }
  });
  
  // Helper function that executes a POST request with the given URL
  function executeAndUpdate(url) {
    $.ajax({
      type: "POST",
      dataType: "json",
      url: url,
      success: updatePage
    });
    return false;
  }
  
  // Click Events
  $.each(["add", "up", "down", "control"], function() {
    var action = this;
    $("." + action).live("click", function() { return executeAndUpdate("/" + action + "/" + $(this).attr("ref")); });
  });
  $.each(["play", "force"], function() {
    var action = this;
    $("." + action).live("click", function() { return executeAndUpdate("/" + action); });
  });
  
  // Search
  $("#search").ajaxForm({
    dataType: "json",
    success: updateList
  });
  $("#clear").click(function() {
    $("#search").clearForm();
    getListUpdate();
  });
  
  // Initial page update to load the lists
  getListUpdate();
  getPageUpdate();
});

/*
 * Requests a update of the available albums and updates the list with the JSON result
 */
function getListUpdate() { $.getJSON("/list", updateList); }
function updateList(data) {
  $("#list").html("");
  $.each(data, function(i, album) {
    $("#list").append(albumElement(album, i));
  });
}

/*
 * Makes a JSON request to get the current status of the page and updates the elements
 * This function is called again (after a timeout) to update the page constantly
 */
function getPageUpdate() {
	$.getJSON("/status", updatePage);
	setTimeout("getPageUpdate();", 5000);
}
function updatePage(data) {
  mainControls(data.current, data.volume);
  
  $("#top").html("");
  if (data.upcoming.length > 0) {
	  album = data.upcoming[0];
	  $("#top").html('<u>Next:</u> \
	                  <i>' + album.name + '</i> \
	                  (' + album.artist + ')');
	}
	
  $("#upcoming").html("");
  $.each(data.upcoming, function(i, album) {
    $("#upcoming").append(voteableAlbumElement(album, i));
  });
}

/*
 * Update the main controls (at the top of the page) according to the received status
 */
function mainControls(current, volume) {
  $("#slider").slider("option", "value", volume);
  
  if (current == null) {
	  $("#current").html("");
    $("#force").remove();
    $(".main_controls .right").html('<a id="play" href="#" class="play"> Start Playback </a>');
	}
	else if (current != null) {
	  if (!$("#current").html().match(/-/)) {
	    $("#play").remove();
	    $(".main_controls .right").html('<a id="force" href="#" class="force"></a>');
	  }
	  
	  $("#current").html(current.artist + " - " + current.name);
	  $("#force").html("Force Next (" + current.remaining + ")").attr("title", "Necessary Votes to force next album: " + current.remaining);
	  if (current.voteable) $("#force").removeClass("disabled");
	  else                  $("#force").addClass("disabled");
	}
}

function albumElement(album, i) {
  res = '<li class="album ' + (i % 2 == 0 ? 'even' : 'odd') + '">';
  res += commonAlbumElements(album);
  res +=  '<div class="right">';
  res +=    '<a href="#" class="add" ref="' + album.id + '">';
  res +=      '<img src="/images/add.png" title="Add Album to Upcoming Albums" />'
  res +=    '</a>';
  res += '</div>';
	res += '<div class="clear"></div>';
	return res + '</li>';
}

/*
 * Returns a list element for the list of 'upcoming' (voteable) albums
 */
function voteableAlbumElement(album, i) {
  res = '<li class="album ' + (i % 2 == 0 ? 'even' : 'odd') + '">';
	res += 	  '<span class="rating ' + (album.rating > 0 ? "positive" : (album.rating < 0 ? "negative" : 0)) + '\
	  " title="Rating: ' + album.rating + '">' + album.rating + '</span> ';
  res += commonAlbumElements(album);
	res +=  '<div class="right">';
	if (album.voteable) {
		res += '<a href="#" class="up" ref="' + album.id + '">';
		res +=    '<img src="/images/plus.png" title="Vote this Album up" />';
		res += '</a> ';
		res += '<a href="#" class="down" ref="' + album.id + '">';
		res +=    '<img src="/images/minus.png" title="Vote this Album down" />';
		res += '</a> ';
	}
	res += '</div>';
	res += '<div class="clear"></div>';
	res += '</li>';
	return res;
}

function commonAlbumElements(album) {
  res = '<div class="left">';
	res +=  '<span class="artist">' + album.artist + '</span> ';
	res +=  '<span> - </span>';
	res +=  '<span class="name">' + album.name + '</span> ';
  res += '</div>';
  return res;
}
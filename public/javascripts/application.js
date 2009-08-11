// On Load
$(function() {
  $("#slider").slider({
    animate: true,
    stop: function() { $.post("/volume/" + $(this).slider("option", "value")); }
  });
  
  updatePage();
});

function updatePage() {
	$.getJSON("/status", function(data) {
	  mainControls(data.current, data.volume);
	  
	  if (data.upcoming.length > 0) {
  	  album = data.upcoming[0];
  	  $("#top").html('<u>Next:</u> \
  	                  <i>' + album.name + '</i> \
  	                  (' + album.artist + ')');
  	}
		
    $("#upcoming").html("");
    $.each(data.upcoming, function(i, album) {
      $("#upcoming").append(albumEntry(album, i));
    });
	});
	
	setTimeout("updatePage();", 5000);
}

function mainControls(current, volume) {
  $("#slider").slider("option", "value", volume);
  
  if (current == null) {
	  $("#current").html("");
    $("#force").remove();
    $(".main_controls .right").html('<a id="play" href="/play"> Start Playback </a>');
	}
	else if (current != null) {
	  if (!$("#current").html().match(/-/)) {
	    $("#play").remove();
	    $(".main_controls .right").html('<a id="force" href="/force"></a>');
	  }
	  
	  $("#current").html(current.artist + " - " + current.name);
	  $("#force").html("Force Next (" + current.remaining + ")").attr("title", "Necessary Votes to force next album: " + current.remaining);
	  if (current.voteable) $("#force").removeClass("disabled");
	  else                  $("#force").addClass("disabled");
	}
}

function albumEntry(album, i) {
	res = '<li class="album ' + (i % 2 == 0 ? 'even' : 'odd') + '">';
	res += 	  '<span class="rating ' + (album.rating > 0 ? "positive" : (album.rating < 0 ? "negative" : 0)) + '\
	  " title="Rating: ' + album.rating + '">' + album.rating + '</span> ';
	res +=  '<div class="left">';
	res +=	  '<span class="artist">' + album.artist + '</span> ';
	res +=    '<span> - </span>';
	res +=	  '<span class="name">' + album.name + '</span> ';
  res +=  '</div>';
	res +=  '<div class="right">';
	if (album.voteable) {
		res += '<a href="/up/' + album.id + '" class="up">';
		res +=    '<img src="/images/plus.png" title="Vote this Album up" />';
		res += '</a> ';
		res += '<a href="/down/' + album.id + '" class="down">';
		res +=    '<img src="/images/minus.png" title="Vote this Album down" />';
		res += '</a> ';
	}
	res += '</div>'
	res += '<div class="clear"></div>'
	return res + '</li>';
}
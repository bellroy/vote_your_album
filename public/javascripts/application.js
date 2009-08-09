// On Load
$(function() {
	setTimeout("updatePage();", 5000);
});

function updatePage() {
	$.getJSON("/status", function(data) {
		if (data.current == null) $("#current").html("");
		else                      $("#current").html(data.current.artist + " - " + data.current.name);
		
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
	if (album.votable) {
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
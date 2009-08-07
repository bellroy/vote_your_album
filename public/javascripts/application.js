// On Load
$(function() {
	setTimeout("updateCurrentSong();", 5000);
});

function updateCurrentSong() {
	$.getJSON("/status", function(data) {
		$("#current_song").html(data.song);
		
		$("#next_albums").html("");
		$.each(data.next, function(i, album) {
			$("#next_albums").append(albumEntry(album, i));
		});
		
		if (data.enabled && $("#disable").hasClass("disabled")) 			showControl("enable", "disable");
		else if (!data.enabled && $("#enable").hasClass("disabled")) 	showControl("disable", "enable");
	});
	setTimeout("updateCurrentSong();", 5000);
}

function albumEntry(album, i) {
	res = '<li class="album ' + (i % 2 == 0 ? 'even' : 'odd') + '">';
	res += 	'<span class="votes">' + album.votes + '</span> ';
	res +=	'<span class="artist">' + album.artist + '</span> ';
	res +=  '<span> - </span>'
	res +=	'<span class="name">' + album.name + '</span> ';
	if (album.votable) {
		res += '<a href="/up/' + album.id + '" class="up">+1</a> ';
		res += '<a href="/down/' + album.id + '" class="down">-1</a>';
	}
	return res + '</li>';
}

function showControl(show, hide) {
	$("#" + show).attr("href", "/control/" + show).addClass("disabled");
	$("#" + hide).attr("href", "#").removeClass("disabled");
}
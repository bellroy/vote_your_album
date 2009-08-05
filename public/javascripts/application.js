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
	});
	setTimeout("updateCurrentSong();", 5000);
}

function albumEntry(album, i) {
	res = '<li class="album ' + (i % 2 == 0 ? 'even' : 'odd') + '">';
	res += 	'<span class="votes">' + album.votes + '</span> ';
	res +=	'<span class="name">' + album.name + '</span> ';
	if (album.votable) {
		res += '<a href="/up/' + album.id + '" class="up">Up</a> ';
		res += '<a href="/down/' + album.id + '" class="down">Down</a>';
	}
	return res + '</li>';
}
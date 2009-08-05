// On Load
$(function() {
	setTimeout("updateCurrentSong();", 5000);
});

function updateCurrentSong() {
	$.getJSON("/status", function(data) {
		$("#current_song").html(data.song);
		
		$("#next_albums").html("");
		$.each(data.next, function(i, album) {
			$("#next_albums").append('<li class="album ' + (i % 2 == 0 ? 'even' : 'odd') + '"> \
				<span class="votes">' + album.votes + '</span> \
				<span class="name">' + album.name + '</span> \
				<a href="/up/' + album.id + '" class="up">Up</a> \
				<a href="/down/' + album.id + '" class="down">Down</a> \
			</li>');
		});
	});
	setTimeout("updateCurrentSong();", 5000);
}
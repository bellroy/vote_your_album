// On Load
$(function() {
	setTimeout("updateCurrentSong();", 5000);
});

function updateCurrentSong() {
	$.get("/status", function(data) {
		$("#current_song").html(data);
	});
	setTimeout("updateCurrentSong();", 5000);
}
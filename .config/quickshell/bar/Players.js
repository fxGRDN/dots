.pragma library

// The player the bar and media keys control: whatever is playing,
// otherwise Spotify, otherwise the first one that exists.
function pick(players) {
    if (!players || players.length === 0) return null;
    return players.find(p => p.isPlaying)
        ?? players.find(p => /spot(ify|atui)/i.test(p.identity + " " + p.dbusName))
        ?? players[0];
}

function describe(player) {
    if (!player) return "";
    const title = player.trackTitle || player.identity || "";
    return player.trackArtist ? player.trackArtist + " - " + title : title;
}

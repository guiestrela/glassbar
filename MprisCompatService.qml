import QtQuick
import Quickshell.Services.Mpris

// Minimal service-compatible view of Quickshell's shared MPRIS model. The
// stock Omarchy bar gives crmne.mpris its own service through bar.shell; a
// replacement bar cannot safely retrieve another third-party service, so
// Glass Bar exposes only the media data and controls the widget needs.
QtObject {
  id: root

  property string preferredPlayerKey: ""

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var sourcePlayers: availablePlayers()
  readonly property var activePlayer: chooseActivePlayer()
  readonly property bool hasMedia: activePlayer !== null
    && activePlayer.playbackState !== MprisPlaybackState.Stopped
    && hasTrack(activePlayer)
  readonly property string title: activePlayer ? String(activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? String(activePlayer.trackArtist || "") : ""
  readonly property string album: activePlayer ? String(activePlayer.trackAlbum || "") : ""
  readonly property string artUrl: activePlayer ? String(activePlayer.trackArtUrl || "") : ""

  function playerKey(player) {
    if (!player) return ""
    return String(player.dbusName || player.desktopEntry || player.identity || player.uniqueId || "")
  }

  function isProxy(player) {
    if (!player) return false
    var dbus = String(player.dbusName || "").toLowerCase()
    var desktop = String(player.desktopEntry || "").toLowerCase()
    return dbus.indexOf("playerctld") !== -1 || desktop === "playerctld"
  }

  function hasTrack(player) {
    return !!(player && (player.trackTitle || player.trackArtist || player.trackArtUrl))
  }

  function isAvailable(player) {
    return !!(player && player.playbackState !== MprisPlaybackState.Stopped && hasTrack(player))
  }

  function availablePlayers() {
    var result = []
    for (var i = 0; i < players.length; i++) {
      if (isAvailable(players[i])) result.push(players[i])
    }
    return result
  }

  function findPreferred() {
    if (!preferredPlayerKey) return null
    for (var i = 0; i < sourcePlayers.length; i++) {
      if (playerKey(sourcePlayers[i]) === preferredPlayerKey) return sourcePlayers[i]
    }
    return null
  }

  function firstMatching(playing, proxy) {
    for (var i = 0; i < sourcePlayers.length; i++) {
      var player = sourcePlayers[i]
      if (!!player.isPlaying === playing && isProxy(player) === proxy) return player
    }
    return null
  }

  function chooseActivePlayer() {
    var preferred = findPreferred()
    if (preferred && preferred.isPlaying) return preferred

    return firstMatching(true, false)
      || firstMatching(true, true)
      || preferred
      || firstMatching(false, false)
      || firstMatching(false, true)
      || null
  }

  function remember(player) {
    var key = playerKey(player)
    if (key) preferredPlayerKey = key
  }

  function playPause() {
    var player = activePlayer
    if (!player) return false

    if (player.isPlaying && player.canPause) player.pause()
    else if (!player.isPlaying && player.canPlay) player.play()
    else if (player.canTogglePlaying) player.togglePlaying()
    else return false

    remember(player)
    return true
  }

  function previous() {
    var player = activePlayer
    if (!player || !player.canGoPrevious) return false
    player.previous()
    remember(player)
    return true
  }

  function next() {
    var player = activePlayer
    if (!player || !player.canGoNext) return false
    player.next()
    remember(player)
    return true
  }

  function raisePlayer() {
    var player = activePlayer
    if (!player || !player.canRaise) return false
    player.raise()
    remember(player)
    return true
  }
}

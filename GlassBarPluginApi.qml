import QtQuick

// Public bar surface for third-party widgets hosted by Glass Bar. It mirrors
// the normal widget-facing API while keeping the replacement bar's root out
// of the plugin. The geometry helpers preserve adaptive widgets under this
// facade.
QtObject {
  id: root

  property var sourceBar: null
  property var shell: null
  property string pluginId: ""
  property string moduleName: ""

  readonly property color foreground: sourceBar ? sourceBar.foreground : "transparent"
  readonly property color barForeground: sourceBar ? sourceBar.barForeground : "transparent"
  readonly property color background: sourceBar ? sourceBar.background : "transparent"
  readonly property color urgent: sourceBar ? sourceBar.urgent : "transparent"
  readonly property string fontFamily: sourceBar ? sourceBar.fontFamily : ""
  readonly property string position: sourceBar ? sourceBar.position : "top"
  readonly property bool vertical: sourceBar ? sourceBar.vertical : false
  readonly property int barSize: sourceBar ? sourceBar.barSize : 0
  readonly property bool transparent: sourceBar ? sourceBar.transparent : false
  readonly property bool foregroundAnimationEnabled: sourceBar
    ? sourceBar.foregroundAnimationEnabled : true
  readonly property bool centerSectionRevealHeld: sourceBar
    ? sourceBar.centerSectionRevealHeld : false
  readonly property bool centerHoverRevealSuppressed: sourceBar
    ? sourceBar.centerHoverRevealSuppressed : false
  readonly property var activePopout: sourceBar ? sourceBar.activePopout : null
  readonly property var clickTargets: sourceBar ? sourceBar.clickTargets : []
  readonly property var layoutConfig: sourceBar ? sourceBar.layoutConfig : ({})
  readonly property var moduleSlots: sourceBar ? sourceBar.moduleSlots : []
  readonly property var foreignPopoutMarker: ({ foreign: true })

  function showTooltip(target, text) {
    if (sourceBar && typeof sourceBar.showTooltip === "function")
      sourceBar.showTooltip(target, String(text || ""))
  }

  function hideTooltip(target) {
    if (sourceBar && typeof sourceBar.hideTooltip === "function")
      sourceBar.hideTooltip(target)
  }

  function registerClickTarget(target) {
    if (sourceBar && typeof sourceBar.registerClickTarget === "function")
      sourceBar.registerClickTarget(target)
  }

  function unregisterClickTarget(target) {
    if (sourceBar && typeof sourceBar.unregisterClickTarget === "function")
      sourceBar.unregisterClickTarget(target)
  }

  function requestPopout(owner) {
    if (sourceBar && typeof sourceBar.requestPopout === "function")
      sourceBar.requestPopout(owner)
  }

  function releasePopout(owner) {
    if (sourceBar && typeof sourceBar.releasePopout === "function")
      sourceBar.releasePopout(owner)
  }

  function switchPanelFrom(owner, direction) {
    return sourceBar && typeof sourceBar.switchPanelFrom === "function"
      ? sourceBar.switchPanelFrom(owner, direction) : false
  }

  function targetBelongsToWindow(target, window) {
    return sourceBar && typeof sourceBar.targetBelongsToWindow === "function"
      ? sourceBar.targetBelongsToWindow(target, window) : false
  }

  function moduleWidgets(id) {
    return sourceBar && typeof sourceBar.moduleWidgets === "function"
      ? sourceBar.moduleWidgets(String(id || "")) : []
  }

  function slotWindow(slot) {
    return sourceBar && typeof sourceBar.slotWindow === "function"
      ? sourceBar.slotWindow(slot) : null
  }

  function targetWindow(target) {
    return sourceBar && typeof sourceBar.targetWindow === "function"
      ? sourceBar.targetWindow(target) : null
  }

  function sameWindow(left, right) {
    return sourceBar && typeof sourceBar.sameWindow === "function"
      ? sourceBar.sameWindow(left, right) : left === right
  }

  function run(command) {
    if (sourceBar && typeof sourceBar.run === "function")
      sourceBar.run(String(command || ""))
  }

  function setCenterHoverRevealSuppressed(value) {
    if (!sourceBar) return
    sourceBar.centerHoverRevealSuppressed = !!value
  }
}

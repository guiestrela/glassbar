import QtQuick

// Capability bridge used by the Glass Bar compatibility facade. A widget gets
// the shell scoped to its own plugin; compatibility bridges may also provide
// that plugin's service when the host omitted it from the public shell.
QtObject {
  id: root

  property var baseShell: null
  property string ownerPluginId: ""
  property var ownerService: null
  property var mediaService: null
  property var serviceOverrides: ({})

  function serviceFor(id) {
    var key = String(id || "")
    if (serviceOverrides && serviceOverrides[key]) return serviceOverrides[key]
    if (key === "crmne.mpris") return mediaService
    if (key === ownerPluginId && ownerService) return ownerService
    return baseShell && typeof baseShell.serviceFor === "function"
      ? baseShell.serviceFor(key) : null
  }

  function firstPartyServiceFor(id) {
    return baseShell && typeof baseShell.firstPartyServiceFor === "function"
      ? baseShell.firstPartyServiceFor(String(id || "")) : null
  }

  function summon(id, payloadJson) {
    return baseShell && typeof baseShell.summon === "function"
      ? baseShell.summon(String(id || ""), String(payloadJson || "")) : false
  }

  function hide(id) {
    return baseShell && typeof baseShell.hide === "function"
      ? baseShell.hide(String(id || "")) : false
  }

  function toggle(id, payloadJson) {
    return baseShell && typeof baseShell.toggle === "function"
      ? baseShell.toggle(String(id || ""), String(payloadJson || "")) : false
  }

  function isPluginOpen(id) {
    return baseShell && typeof baseShell.isPluginOpen === "function"
      ? baseShell.isPluginOpen(String(id || "")) : false
  }

  function updateEntryInline(id, settings) {
    return baseShell && typeof baseShell.updateEntryInline === "function"
      ? baseShell.updateEntryInline(String(id || ""), settings) : false
  }

  function mutateShellConfig(mutator) {
    return baseShell && typeof baseShell.mutateShellConfig === "function"
      ? baseShell.mutateShellConfig(mutator) : false
  }
}

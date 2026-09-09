import QtQuick

// Capability bridge used by the Glass Bar compatibility facade. Replacement
// bars receive a scoped shell from Omarchy, so a widget cannot look up another
// plugin's service through it. Compatibility adapters may provide an explicit
// service override while all other calls stay delegated to the host facade.
QtObject {
  id: root

  property var baseShell: null
  property var mediaService: null
  property var serviceOverrides: ({})

  function serviceFor(id) {
    var key = String(id || "")
    if (serviceOverrides && serviceOverrides[key]) return serviceOverrides[key]
    if (key === "crmne.mpris") return mediaService
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

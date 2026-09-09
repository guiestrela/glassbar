import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Generic compatibility bridge for a third-party plugin that declares both a
// bar widget and a service. Omarchy 4.0.x removes __sourceDir from the public
// service manifest, so the bridge reconstructs the validated private manifest
// from the widget registry metadata before creating the service.
Item {
  id: root

  property var sourceBar: null
  property var baseShell: null
  property var ownerShell: null
  property var barWidgetRegistry: null
  property var pluginRegistry: null
  property string pluginId: ""
  property string sourceDir: ""
  property string omarchyPath: ""
  property var manifest: null
  property var service: null
  property var serviceComponent: null
  property string serviceUrl: ""
  property bool hasService: !!effectiveService
  readonly property var effectiveService: hostService || service
  readonly property var hostService: ownerShell && typeof ownerShell.serviceFor === "function"
    ? ownerShell.serviceFor(pluginId) : null

  signal serviceReady()

  visible: false
  width: 0
  height: 0

  GlassBarPluginShell {
    id: pluginShell
    baseShell: root.ownerShell || root.baseShell
    ownerPluginId: root.pluginId
    ownerService: root.service
  }

  GlassBarPluginApi {
    id: pluginApi
    sourceBar: root.sourceBar
    shell: pluginShell
    pluginId: root.pluginId
    moduleName: root.pluginId
  }

  readonly property var api: pluginApi
  readonly property var shell: pluginShell

  FileView {
    id: manifestFile
    path: root.hostService || !root.sourceDir ? "" : root.sourceDir + "/manifest.json"
    onLoaded: root.loadManifest(text())
    onLoadFailed: root.resetService()
  }

  onSourceDirChanged: resetService()
  onPluginIdChanged: resetService()

  function isPlainObject(value) {
    return !!value && typeof value === "object" && !Array.isArray(value)
  }

  function isSafeEntryPoint(value) {
    return typeof value === "string"
      && value.length > 0
      && value.charAt(0) !== "/"
      && value.indexOf("..") === -1
  }

  function resetService() {
    if (service && typeof service.destroy === "function") service.destroy()
    service = null
    manifest = null
    serviceComponent = null
    serviceUrl = ""
  }

  function loadManifest(raw) {
    if (hostService || !sourceDir || !pluginId) return
    resetService()

    var parsed = null
    try {
      parsed = JSON.parse(String(raw || ""))
    } catch (error) {
      console.warn("Plugin service manifest is invalid for " + pluginId + ": " + error)
      return
    }

    if (!isPlainObject(parsed) || String(parsed.id || "") !== pluginId
        || !Array.isArray(parsed.kinds) || parsed.kinds.indexOf("service") === -1
        || !isPlainObject(parsed.entryPoints)
        || !isSafeEntryPoint(parsed.entryPoints.service)) return

    parsed.__sourceDir = sourceDir
    parsed.__isFirstParty = false
    manifest = parsed

    serviceUrl = Util.fileUrl(sourceDir + "/" + String(parsed.entryPoints.service))
    var component = Qt.createComponent(serviceUrl, Component.PreferSynchronous)
    serviceComponent = component

    function finalize() {
      if (serviceComponent !== component || component.status === Component.Loading) return
      serviceComponent = null
      if (component.status !== Component.Ready) {
        console.warn("Plugin service failed to load for " + pluginId + ": " + component.errorString())
        return
      }

      var instance = component.createObject(root)
      if (!instance) {
        console.warn("Plugin service returned null for " + pluginId)
        return
      }
      if ("omarchyPath" in instance) instance.omarchyPath = root.omarchyPath
      if ("shell" in instance) instance.shell = pluginShell
      if ("manifest" in instance) instance.manifest = root.manifest
      if ("barWidgetRegistry" in instance) instance.barWidgetRegistry = root.barWidgetRegistry
      if ("pluginRegistry" in instance) instance.pluginRegistry = root.pluginRegistry
      root.service = instance
      root.serviceReady()
    }

    if (component.status === Component.Loading) component.statusChanged.connect(finalize)
    else finalize()
  }
}

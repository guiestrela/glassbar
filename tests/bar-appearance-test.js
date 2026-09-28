const assert = require("node:assert/strict")
const fs = require("node:fs")
const test = require("node:test")
const vm = require("node:vm")
const model = require("../BarModel.js")
const barSource = fs.readFileSync(require.resolve("../Bar.qml"), "utf8")

test("bar size accepts the three supported presets and defaults safely", () => {
  assert.equal(model.normalizeBarSize("compact"), "compact")
  assert.equal(model.normalizeBarSize("standard"), "standard")
  assert.equal(model.normalizeBarSize("large"), "large")
  assert.equal(model.normalizeBarSize("huge"), "standard")
  assert.equal(model.normalizeBarSize(null), "standard")
})

test("bar shape accepts square, rounded, and pill and defaults safely", () => {
  assert.equal(model.normalizeBarShape("square"), "square")
  assert.equal(model.normalizeBarShape("rounded"), "rounded")
  assert.equal(model.normalizeBarShape("pill"), "pill")
  assert.equal(model.normalizeBarShape("triangle"), "rounded")
  assert.equal(model.normalizeBarShape(undefined), "rounded")
})

test("bar size presets scale horizontal and vertical base dimensions", () => {
  assert.equal(model.barSizeForPreset("compact", 26), 21)
  assert.equal(model.barSizeForPreset("standard", 28), 28)
  assert.equal(model.barSizeForPreset("large", 28), 35)
  assert.equal(model.barSizeForPreset("unknown", 26), 26)
})

test("bar shape presets map to square, theme-rounded, and half-height radii", () => {
  assert.equal(model.barRadiusForShape("square", 30, 8), 0)
  assert.equal(model.barRadiusForShape("rounded", 30, 8), 8)
  assert.equal(model.barRadiusForShape("pill", 31, 8), 16)
  assert.equal(model.barRadiusForShape("unknown", 30, 8), 8)
})

test("rounded shape stays visible when the active theme has square corners", () => {
  assert.equal(model.barRadiusForShape("rounded", 28, 0), 7)
  assert.equal(model.barRadiusForShape("rounded", 30, 100), 14)
})

test("solid and glass fills share the rounded bar surface", () => {
  const start = barSource.indexOf("component BarPanel: PanelWindow {")
  const end = barSource.indexOf("component DragGhostPanel: PanelWindow {", start)
  assert.ok(start >= 0 && end > start, "BarPanel source is present")
  const panelSource = barSource.slice(start, end)

  const windowColor = panelSource.match(/implicitHeight: root\.vertical \? 0 : root\.barSize[\s\S]*?\n    color: ([^\n]+)/)
  assert.equal(windowColor && windowColor[1].trim(), '"transparent"',
    "PanelWindow itself must not paint square solid corners")
  assert.ok(/color: root\.transparent\s*\?[\s\S]*?: root\.background/.test(panelSource),
    "the rounded child surface paints both glass and solid backgrounds")
  assert.ok(/radius: root\.barCornerRadius\(root\.barSize\)/.test(panelSource),
    "the same surface applies the selected shape radius")
})

test("position choices include all four screen edges in menu order", () => {
  assert.equal(JSON.stringify(model.barPositionOptions()), JSON.stringify([
    { value: "top", label: "Top" },
    { value: "bottom", label: "Bottom" },
    { value: "left", label: "Left" },
    { value: "right", label: "Right" }
  ]))
})

test("bar length presets provide full, 80%, and 60% screen spans", () => {
  assert.equal(model.normalizeBarLength("full"), "full")
  assert.equal(model.normalizeBarLength("wide"), "wide")
  assert.equal(model.normalizeBarLength("compact"), "compact")
  assert.equal(model.normalizeBarLength("unknown"), "full")
  assert.equal(model.barLengthRatio("full"), 1)
  assert.equal(model.barLengthRatio("wide"), 0.8)
  assert.equal(model.barLengthRatio("compact"), 0.6)
})

test("fixed screen-span insets are calculated independently for each monitor", () => {
  assert.equal(model.barLengthInset(1920, "full"), 0)
  assert.equal(model.barLengthInset(1920, "wide"), 192)
  assert.equal(model.barLengthInset(1920, "compact"), 384)
  assert.equal(model.barLengthInset(1080, "wide"), 108)
  assert.equal(model.barLengthInset(1080, "compact"), 216)
})

test("each bar panel uses its own screen span and no content-responsive sizing", () => {
  assert.ok(/readonly property int screenSpan:[\s\S]*screen\.height[\s\S]*screen\.width/.test(barSource),
    "each panel reads its own screen dimensions")
  assert.ok(barSource.includes("readonly property int lengthInset: BarModel.barLengthInset(screenSpan, root.lengthPreset)"),
    "each panel calculates its inset from its own screen span")
  assert.ok(!/barContentSpan|adaptiveBarSpan|contentSpan/.test(barSource),
    "bar width is fixed by the selected screen percentage")
})

test("bar size selection updates immediately when the solid background is enabled", () => {
  const match = barSource.match(/^  function setBarAppearance\(key, value\) \{[\s\S]*?^  \}/m)
  assert.ok(match, "Bar.qml defines setBarAppearance")

  const root = {
    sizePreset: "standard",
    shapePreset: "rounded",
    lengthPreset: "full",
    shell: {
      mutateShellConfig(mutator) {
        const config = { bar: { transparent: false } }
        mutator(config)
        this.savedConfig = config
      }
    }
  }
  const context = vm.createContext({
    root,
    BarModel: model,
    Util: { isPlainObject: value => !!value && typeof value === "object" && !Array.isArray(value) }
  })
  vm.runInContext(`${match[0]}; this.setBarAppearance = setBarAppearance`, context)
  context.setBarAppearance("size", "large")

  assert.equal(root.sizePreset, "large")
  assert.equal(root.shell.savedConfig.bar.size, "large")
  assert.equal(root.shell.savedConfig.bar.transparent, false)
})

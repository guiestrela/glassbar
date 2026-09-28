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

test("position choices include all four screen edges in menu order", () => {
  assert.equal(JSON.stringify(model.barPositionOptions()), JSON.stringify([
    { value: "top", label: "Top" },
    { value: "bottom", label: "Bottom" },
    { value: "left", label: "Left" },
    { value: "right", label: "Right" }
  ]))
})

test("bar length presets provide full, 80%, and 50% screen spans", () => {
  assert.equal(model.normalizeBarLength("full"), "full")
  assert.equal(model.normalizeBarLength("wide"), "wide")
  assert.equal(model.normalizeBarLength("compact"), "compact")
  assert.equal(model.normalizeBarLength("unknown"), "full")
  assert.equal(model.barLengthRatio("full"), 1)
  assert.equal(model.barLengthRatio("wide"), 0.8)
  assert.equal(model.barLengthRatio("compact"), 0.5)
})

test("adaptive bar span follows content and falls back to full screen past the selected limit", () => {
  assert.equal(model.adaptiveBarSpan(1920, "full", 360), 360)
  assert.equal(model.adaptiveBarSpan(1920, "wide", 1200), 1200)
  assert.equal(model.adaptiveBarSpan(1920, "compact", 800), 800)
  assert.equal(model.adaptiveBarSpan(1920, "compact", 1100), 1920)
  assert.equal(model.adaptiveBarSpan(0, "full", 360), 0)
})

test("required bar span grows when section contents grow and keeps sections apart", () => {
  const compact = model.requiredBarSpan({ left: 100, center: 60, right: 80 }, 8, 38, 36, 8)
  const moreItems = model.requiredBarSpan({ left: 100, center: 60, right: 140 }, 8, 38, 36, 8)
  assert.equal(compact, 312)
  assert.equal(moreItems, 432)
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

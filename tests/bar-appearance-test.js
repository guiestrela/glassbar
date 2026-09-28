const assert = require("node:assert/strict")
const test = require("node:test")
const model = require("../BarModel.js")

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
    { value: "top", label: "Topo" },
    { value: "bottom", label: "Inferior" },
    { value: "left", label: "Esquerda" },
    { value: "right", label: "Direita" }
  ]))
})

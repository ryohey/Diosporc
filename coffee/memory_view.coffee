Rect = require "./rect.coffee"
PortView = require "./port_view.coffee"
conf = require "./config.coffee"

class MemoryView extends createjs.Container
  constructor: () ->
    super()
    g = conf.gridSize
    @portView = new PortView new Rect(0, 0, g, g)
    @addChild @portView

module.exports = MemoryView

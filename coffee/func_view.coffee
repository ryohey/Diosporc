Rect = require "./rect.coffee"
PortView = require "./port_view.coffee"
conf = require "./config.coffee"

class FuncView extends createjs.Container
  constructor: (inNum, outNum) ->
    super()
    g = conf.gridSize

    @inPortViews = (for _ in [0..inNum - 1]
      p = new PortView new Rect(0, i * g, g, g)
    )

    @outPortViews = (for _ in [0..outNum - 1]
      p = new PortView new Rect(g, 0, g, g)
    )

    portViews = @inPortViews.concat(@outPortViews)

    for v in portViews
      v.setBackgroundColor "white" 
      @addChild v

module.exports = FuncView

Rect = require "./rect.coffee"
PortView = require "./port_view.coffee"
conf = require "./config.coffee"

class FuncView extends createjs.Container
  constructor: (inPorts, outPorts) ->
    super()
    g = conf.gridSize

    i = 0
    @inPortViews = (for port in inPorts
      new PortView new Rect(0, i++ * g, g, g), port
    )

    @outPortViews = (for port in outPorts
      new PortView new Rect(g, 0, g, g), port
    )

    portViews = @inPortViews.concat(@outPortViews)

    for v in portViews
      v.setBackgroundColor "white" 
      @addChild v


module.exports = FuncView

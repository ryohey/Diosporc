Rect = require "./rect.coffee"
PortView = require "./port_view.coffee"
conf = require "./config.coffee"

class FuncView extends createjs.Container
  constructor: (inPorts, outPorts) ->
    super()
    g = conf.gridSize

    @inPortViews = (for i, port of inPorts
      new PortView new Rect(0, i * g, g, g), port
    )

    @outPortViews = (for i, port of outPorts
      new PortView new Rect(g, i * g, g, g), port
    )

    portViews = @inPortViews.concat(@outPortViews)

    for v in portViews
      v.setBackgroundColor "white" 
      v.dragEnabled = false
      @addChild v

    @on "mousedown", (e) =>
      return if e.nativeEvent.button isnt 0
      @offset = new createjs.Point @x - e.stageX, @y - e.stageY

    @on "pressmove", (e) =>
      return if e.nativeEvent.button isnt 0
      @x = e.stageX + @offset.x
      @y = e.stageY + @offset.y

module.exports = FuncView

Rect = require "./rect.coffee"
PortView = require "./port_view.coffee"
conf = require "./config.coffee"
ActionRouter = require "./action_router.coffee"

class FuncView extends createjs.Container
  constructor: (inPorts, outPorts, name) ->
    super()
    g = conf.gridSize

    @text = new createjs.Text "", "12px Consolas", "rgba(0, 0, 0, 0.3)"
    @text.text = name
    @text.y = -20
    @addChild @text

    @inPortViews = (for i, port of inPorts
      new PortView new Rect(0, i * g, g, g), port
    )

    @outPortViews = (for i, port of outPorts
      new PortView new Rect(g, i * g, g, g), port
    )

    portViews = @inPortViews.concat(@outPortViews)

    for v in portViews
      v.setBackgroundColor "white" 
      v.uiEnabled = false
      @addChild v

    @dragged = false

    @on "mousedown", (e) =>
      return if e.nativeEvent.button isnt 0
      @offset = new createjs.Point @x - e.stageX, @y - e.stageY
      @dragged = false

    @on "pressmove", (e) =>
      return if e.nativeEvent.button isnt 0
      @x = e.stageX + @offset.x
      @y = e.stageY + @offset.y
      @dragged = true

    @on "click", (e) =>
      return if @dragged
      if e.nativeEvent.button is 1
        ActionRouter.instance.removeFunc @inPortViews[0].port.funcId

module.exports = FuncView

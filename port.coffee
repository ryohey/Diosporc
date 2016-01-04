Point = require "./point.coffee"
Rect = require "./rect.coffee"
conf = require "./config.coffee"

class Port
  @stage = null

  constructor: (frame, hasInput, hasOutput, parent = null) ->
    @frame = frame
    @parent = parent
    @hasInput = hasInput
    @hasOutput = hasOutput
    @outPorts = []
    @value = 0
    @received = false

  getValue: (v) -> @value
  setValue: (v) -> 
    @value = v
    @received = true
    @didSetValue?(this, value)
    @highlight()
    port.setValue(v) for port in @outPorts

  highlight: ->
    rect = new createjs.Shape()
    rect.graphics.beginFill("rgba(255, 0, 0, 0.2)").drawRect @frame.x, @frame.y, @frame.width, @frame.height
    Port.stage.addChild rect
    createjs.Tween.get rect
      .to { alpha: 0 }, 500, createjs.Ease.getPowInOut(2)
      .call (e) -> Port.stage.removeChild e.target

  getFrame: ->
    return @frame unless @parent?
    Rect.fromPoint(@frame.point().add(@parent.pos), @frame)

  getInputPosition: ->
    @getFrame().point().add new Point(0, conf.gridSize / 2)

  getOutputPosition: ->
    @getFrame().point().add new Point(conf.gridSize, conf.gridSize / 2)

  draw: (ctx, style = {lineWidth: 2, color: "rgba(0, 0, 0, 0.4)"}) ->
    f = @getFrame()
    ctx.beginPath()
    ctx.rect f.x + 0.5, f.y + 0.5, 
             f.width,   f.height
    ctx.lineWidth = style.lineWidth
    ctx.strokeStyle = style.color
    ctx.stroke()

    # draw value
    fontSize = 12
    lineHeight = fontSize
    ctx.font = "#{fontSize}px \"Consolas\""
    ctx.fillStyle = style.color
    ctx.textAlign = "center"
    ctx.fillText "#{@value}", 
                 f.x + 0.5 + conf.gridSize / 2,
                 f.y + 0.5 + lineHeight / 2 + conf.gridSize / 2, 
                 conf.gridSize

module.exports = Port
Point = require "./point.coffee"
Rect = require "./rect.coffee"

class Port
  @stage = null

  constructor: (frame, hasInput, hasOutput, parent = null, style = {lineWidth: 2, color: "rgba(0, 0, 0, 0.4)"}) ->
    @frame = frame
    @parent = parent
    @hasInput = hasInput
    @hasOutput = hasOutput
    @outPorts = []
    @value = 0
    @received = false

    @view = new createjs.Container()
    graphics = new createjs.Graphics()
      .setStrokeStyle style.lineWidth
      .beginStroke style.color
      .drawRect 0, 0, frame.width, frame.height
    border = new createjs.Shape(graphics)
    @view.addChild border
    @text = new createjs.Text "", "12px Consolas", style.color
    @view.addChild @text
    @view.x = frame.x
    @view.y = frame.y

  getValue: (v) -> @value
  setValue: (v) -> 
    @value = v
    @received = true
    @didSetValue?(this, v)
    @highlight()
    @text = "#{v}"
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
    @getFrame().point().add new Point(0, @frame.height / 2)

  getOutputPosition: ->
    @getFrame().point().add new Point(@frame.width, @frame.height / 2)

module.exports = Port
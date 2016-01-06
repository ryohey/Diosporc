Point = require "./point.coffee"

class PortView extends createjs.Container
  constructor: (frame) ->
    super()
    color = "rgba(0, 0, 0, 0.2)"
    graphics = new createjs.Graphics()
      .setStrokeStyle 2
      .beginStroke color
      .beginFill "rgb(245, 244, 244)"
      .drawRect 0, 0, frame.width, frame.height
    border = new createjs.Shape(graphics)
    @addChild border

    @text = new createjs.Text "", "12px Consolas", color
    @addChild @text
    @text.text = "test"

    @mouseChildren = false

  setValue: (v) ->
    @text.text = "#{v}"
    @highlight()

  highlight: ->
    rect = new createjs.Shape()
    frame = @getBounds()
    rect.graphics.beginFill("rgba(255, 0, 0, 0.2)").drawRect frame.x, frame.y, frame.width, frame.height
    @addChild rect
    createjs.Tween.get rect
      .to { alpha: 0 }, 500, createjs.Ease.getPowInOut(2)
      .call (e) => @removeChild e.target

  getInputPosition: ->
    b = getBounds()
    new Point(b.x, b.y + b.height / 2)

  getOutputPosition: ->
    b = getBounds()
    new Point(b.x + b.width, b.y + b.height / 2)

module.exports = PortView

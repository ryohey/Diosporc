Point = require "./point.coffee"

foreColor = "rgba(0, 0, 0, 0.2)"

class PortView extends createjs.Container
  constructor: (frame, port) ->
    super()
    @setBounds 0, 0, frame.width, frame.height
    @x = frame.x
    @y = frame.y

    @background = new createjs.Shape
    @setBackgroundColor "rgb(245, 244, 244)"
    @addChild @background

    @text = new createjs.Text "", "12px Consolas", foreColor
    @addChild @text
    @text.text = "test"

    @mouseChildren = false
    @port = port
    @setValue port.getValue()
    @port.on "change", @onChange

  setBackgroundColor: (color) ->
    b = @getBounds()
    @background.graphics
      .setStrokeStyle 2
      .beginStroke foreColor
      .beginFill color
      .drawRect 0, 0, b.width, b.height

  onChange: (e) =>
    @setValue e.target.getValue()

  setValue: (v) =>
    @text.text = "#{v}"
    @highlight()

  highlight: =>
    b = @getBounds()
    rect = new createjs.Shape(new createjs.Graphics()
      .beginFill "rgba(255, 0, 0, 0.2)"
      .drawRect b.x, b.y, b.width, b.height
    )
    @addChild rect
    createjs.Tween.get rect
      .to { alpha: 0 }, 500, createjs.Ease.getPowInOut(2)
      .call (e) => @removeChild e.target

module.exports = PortView

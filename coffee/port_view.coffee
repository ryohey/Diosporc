Point = require "./point.coffee"
ActionRouter = require "./action_router.coffee"

foreColor = "rgba(0, 0, 0, 0.4)"

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

    idText = new createjs.Text "", "12px Consolas", "rgba(0, 128, 0, 0.4)"
    idText.text = "#{port.id}"
    idText.y = 20
    @addChild idText

    @mouseChildren = false
    @port = port
    @setValue port.getValue()
    @port.on "change", @onChange

    @uiEnabled = true

    @on "mousedown", (e) =>
      return unless @uiEnabled
      @dragged = false
      return if e.nativeEvent.button isnt 0
      @offset = new createjs.Point @x - e.stageX, @y - e.stageY

    @on "pressmove", (e) =>
      return unless @uiEnabled
      @dragged = true
      return if e.nativeEvent.button isnt 0
      @x = e.stageX + @offset.x
      @y = e.stageY + @offset.y

    @on "click", (e) =>
      return unless @uiEnabled
      return if @dragged
      @dragged = false
      switch e.nativeEvent.button
        when 0 
          @port.setValue @port.getValue() + 1
        when 1
          ActionRouter.instance.removePort @port.id
        when 2
          @port.setValue @port.getValue() - 1

    @on "dblclick", =>

  setBackgroundColor: (color) ->
    b = @getBounds()
    @background.graphics
      .setStrokeStyle 1
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

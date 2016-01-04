Rect = require "./rect.coffee"
conf = require "./config.coffee"

class Port
  constructor: (frame, hasInput, hasOutput, parent = null) ->
    @frame = frame
    @parent = parent
    @hasInput = hasInput
    @hasOutput = hasOutput
    @value = null

  getValue: (v) -> @value
  setValue: (v) -> 
    @value = v
    @didSetValue?(this, value)

  getFrame: ->
    return @frame unless @parent?
    Rect.fromPoint(@frame.point().add(@parent), @frame)

  getInputPosition: ->
    @position.add new Point(conf.gridSize, conf.gridSize / 2)

  getOutputPosition: ->
    @position.add new Point(0, conf.gridSize / 2)

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
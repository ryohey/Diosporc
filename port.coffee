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

module.exports = Port
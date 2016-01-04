###
pseudo code
interface IO
  onOutputChanged: null
  setInput: (index, value) -> false
  getInputNum: -> 0
  getOutput: (index) -> 0
  getOutputNum: -> 0
###

Point = require "./point.coffee"
Rect = require "./rect.coffee"
Port = require "./port.coffee"
conf = require "./config.coffee"

width = 960
height = 500
GRID_SIZE = conf.gridSize
MEMORY_COLS = Math.round(width / conf.gridSize)
MEMORY_ROWS = Math.round(height / conf.gridSize)

indexToPoint = (index) ->
  dy = Math.floor(index / MEMORY_COLS)
  dx = index - dy * MEMORY_COLS
  new Point dx * GRID_SIZE,
            dy * GRID_SIZE

class Memory # implements IO
  constructor: (size) ->
    @buffer = new Uint8Array(size)
    @ports = _.flatten(
      for x in [0..MEMORY_COLS - 1]
        for y in [0..MEMORY_ROWS - 1]
          new Port(new Rect(x * GRID_SIZE, y * GRID_SIZE, GRID_SIZE, GRID_SIZE), true, true)
    )
    
  setInput: (index, value) -> 
    @buffer[index] = value
    @onOutputChanged(this, index, value)

  getInputNum: -> @buffer.length
  getOutput: (index) -> @buffer[index]
  getOutputNum: -> @buffer.length

class Func extends Point # implements IO
  constructor: (pos, func = (x) -> x) ->
    super pos.x, pos.y
    @func = func
    @input = []
    @received = [0..@getInputNum() - 1].map -> false
    @output = 0

    # setup ports
    @ports = (
      for i in [0..func.length - 1]
        p = new Port(new Rect(0, i * GRID_SIZE, GRID_SIZE, GRID_SIZE), true, false, this)
        p.onValueChanged = @onPortValueChanged
        p
    )
    outPort = new Port(new Rect(GRID_SIZE, 0, GRID_SIZE, GRID_SIZE), false, true, this)
    outPort.onValueChanged = @onPortValueChanged
    @ports.push outPort

  onPortValueChanged: (port, value) ->
    console.log port, value
    
  setInput: (index, value) -> 
    @input[index] = value
    @received[index] = true
    @updateOutput() if @isReady()

  isReady: ->
    _.all @received, (r) -> r is true

  updateOutput: ->
    @output = @func.apply(null, @input)

    # wait next input
    @input = []
    @received = @received.map -> false

    @onOutputChanged(this, 0, @output)

  getInputNum: -> @func.length
  getOutput: (index) -> @output
  getOutputNum: -> 1

module.exports = 
  Memory: Memory
  Func: Func

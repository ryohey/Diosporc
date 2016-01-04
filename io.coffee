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

class Memory # implements IO
  constructor: (size) ->
    @buffer = new Uint8Array(size)
    
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

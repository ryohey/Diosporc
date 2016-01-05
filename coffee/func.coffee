Point = require "./point.coffee"
Rect = require "./rect.coffee"
Port = require "./port.coffee"
conf = require "./config.coffee"

GRID_SIZE = conf.gridSize

class Func
  constructor: (pos, func = (x) -> x) ->
    @pos = pos
    @func = func

    # setup ports
    @inPorts = (
      for i in [0..func.length - 1]
        p = new Port(new Rect(0, i * GRID_SIZE, GRID_SIZE, GRID_SIZE), true, false, this)
        p.didSetValue = @onInputValueChanged
        p
    )
    @outPort = new Port(new Rect(GRID_SIZE, 0, GRID_SIZE, GRID_SIZE), false, true, this)
    @ports = @inPorts.concat [@outPort]

  onInputValueChanged: (port, value) =>
    @updateOutput() if @isReady()
    
  isReady: ->
    _.all @inPorts, (p) -> p.received

  updateOutput: ->
    @outPort.setValue @func.apply(null, @inPorts.map((p) -> p.getValue()))

    # wait next input
    (p.received = false) for p in @inPorts

module.exports = Func
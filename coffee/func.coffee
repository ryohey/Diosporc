Point = require "./point.coffee"
Rect = require "./rect.coffee"
Port = require "./port.coffee"
class Func
  constructor: (func = (x) -> x) ->
    @func = func

    # setup ports
    @inPorts = (for i in [0..func.length - 1]
        new Port(true, false)
    )
    @outPort = new Port(false, true)
    @ports = @inPorts.concat [@outPort]

    for p in @ports
      p.on "change", onChange

  onChange: (e) =>
    @updateOutput() if @isReady()
    
  isReady: ->
    _.all @inPorts, (p) -> p.received

  updateOutput: ->
    @outPort.setValue @func.apply(null, @inPorts.map((p) -> p.getValue()))

    # wait next input
    (p.received = false) for p in @inPorts

module.exports = Func
Port = require "./port.coffee"

class Func
  constructor: (func = ((x) -> x), outNum = 1) ->
    @func = func

    # setup ports
    @inPorts = (for i in [0..func.length - 1]
      p = new Port(true, false)
      p.index = i
      p.on "change", @onChange
      p
    )
    @outPorts = (for i in [0..outNum - 1]
      p = new Port(false, true)
      p.index = i
      p
    ) if outNum > 0
    @outPorts ?= []

  onChange: (e) =>
    @updateOutput()

  updateOutput: ->
    args = @inPorts.map (p) -> p.getValue()
    val = @func.apply null, args
    if @outPorts.length is 1
      @outPorts[0].setValue val if val?
    else
      @outPorts[i].setValue(v) for i, v of val when v?

module.exports = Func

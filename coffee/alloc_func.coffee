Port = require "./port.coffee"
conf = require "./config.coffee"

class AllocFunc
  constructor: (machine, actionRouter) ->
    @machine = machine
    @actionRouter = actionRouter

    @inPorts = (for i in [0]
      p = new Port(true, false)
      p.index = i
      p.on "change", @onChange
      p
    )

    @outPorts = (for i in [0]
      p = new Port(false, true)
      p.index = i
      p
    )

  onChange: =>
    ports = (for i in [0..@inPorts[0].getValue() - 1]
      @actionRouter.addPort 
        x: 120
        y: i * conf.gridSize + 120
    )

    @outPorts[0].setValue ports[0].id

    # wait next input
    (p.received = false) for p in @inPorts

module.exports = AllocFunc

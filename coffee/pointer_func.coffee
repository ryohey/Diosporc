Port = require "./port.coffee"

class PointerFunc
  constructor: (machine, actionRouter) ->
    @machine = machine
    @actionRouter = actionRouter

    @inPorts = (for i in [0]
      p = new Port(true, false)
      p.index = i
      p.on "change", @updateLink
      p
    )

    @outPorts = (for i in [0]
      p = new Port(false, true)
      p.index = i
      p
    )

  updateLink: =>
    toPort = @outPorts[0]

    # clear the previous link
    for p in @machine.ports
      for out in p.outPorts
        if out is toPort
          @actionRouter.removeLink(p, toPort)

    fromId = @inPorts[0].getValue()

    # make the link
    p = @machine.ports[fromId]
    if p and p.canWrite
      @actionRouter.addLink p, toPort

    # wait next input
    (p.received = false) for p in @inPorts

module.exports = PointerFunc

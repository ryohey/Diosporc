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
    inId = @inPorts[0].id

    # clear the previous link
    for p in @machine.ports
      for out in p.outPorts
        if out.id is inId
          @actionRouter.removeLink(out, @inPorts[0])

    # make the link
    p = @machine.ports[@inPorts[0].getValue()]
    if p and p.canWrite
      @actionRouter.addLink p, @outPorts[0]

    # wait next input
    (p.received = false) for p in @inPorts

module.exports = PointerFunc

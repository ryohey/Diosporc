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

    @prevId = -1

  updateLink: =>
    toPortId = @outPorts[0].id

    if @prevId > 0
      @actionRouter.removeLink @prevId, toPortId

    fromId = @inPorts[0].getValue()
    @actionRouter.addLink fromId, toPortId

    @prevId = @inPorts[0].getValue()

module.exports = PointerFunc

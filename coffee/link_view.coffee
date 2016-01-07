conf = require "./config.coffee"

color = "rgba(0, 0, 0, 0.2)"
arrowWidth = 6
arrowHeight = 12

class LinkView extends createjs.Container
  constructor: (fromPortView, toPortView) ->
    super()
    @path = new createjs.Shape()
    @addChild @path
    @fromPortView = fromPortView
    @toPortView = toPortView
    fromPortView.on "change", @onChange
    toPortView.on "change", @onChange

    @fromArrow = new createjs.Shape(new createjs.Graphics()
      .beginFill color
      .moveTo 0, 0
      .lineTo 0, arrowHeight
      .lineTo -arrowWidth, arrowHeight / 2
      .endFill()
    )
    @addChild @fromArrow

    @toArrow = new createjs.Shape(new createjs.Graphics()
      .beginFill color
      .moveTo 0, 0
      .lineTo arrowWidth, arrowHeight / 2
      .lineTo 0, arrowHeight
      .endFill()
    )
    @addChild @toArrow

    @path.on "click", =>
      console.log "TODO: remove link"

    createjs.Ticker.on "tick", @updatePath

  onChange: (e) =>
    console.dir e.target
    @updatePath()

  updatePath: =>
    fromPoint = @fromPortView.localToGlobal conf.gridSize, conf.gridSize / 2
    toPoint = @toPortView.localToGlobal 0, conf.gridSize / 2

    @fromArrow.x = fromPoint.x
    @fromArrow.y = fromPoint.y - arrowHeight / 2

    @toArrow.x = toPoint.x
    @toArrow.y = toPoint.y - arrowHeight / 2

    @path.graphics
      .clear()
      .setStrokeStyle 2
      .beginStroke color
      .moveTo fromPoint.x, fromPoint.y
      .lineTo toPoint.x, toPoint.y
      .endStroke()

module.exports = LinkView

(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
var ActionRouter, AllocFunc, Func, MemoryFunc, PointerFunc, Port, conf;

Port = require("./port.coffee");

Func = require("./func.coffee");

PointerFunc = require("./pointer_func.coffee");

AllocFunc = require("./alloc_func.coffee");

MemoryFunc = require("./memory_func.coffee");

conf = require("./config.coffee");

ActionRouter = (function() {
  // ユーザーが行う抽象的な動作 (addPortなど) の具体的な処理を行う
  // viewController, machine に振り分けるのがメイン
  class ActionRouter {
    constructor(viewController, machine) {
      this.addLinks = this.addLinks.bind(this);
      //# for debug

      // 文字列をメモリに読み込む
      // [配列の先頭のアドレス、サイズ、配列...]
      this.addPortFromString = this.addPortFromString.bind(this);
      this.viewController = viewController;
      this.machine = machine;
    }

    addPort(pos) {
      var p, portId;
      p = new Port(true, true);
      portId = this.machine.addPort(p);
      this.viewController.onPortCreated(portId, p, pos);
      return p;
    }

    removePort(id) {
      this.machine.removePort(id);
      return this.viewController.onPortRemoved(id);
    }

    addFunc_(func, pos, name) {
      var funcId;
      funcId = this.machine.addFunc(func);
      this.viewController.onFuncCreated(funcId, func, pos, name);
      return func;
    }

    removeFunc(id) {
      this.machine.removeFunc(id);
      return this.viewController.onFuncRemoved(id);
    }

    addFunc(pos, func, outNum = 1, name = null) {
      var f;
      f = new Func(func, outNum);
      return this.addFunc_(f, pos, name);
    }

    addPointerFunc(pos) {
      var f;
      f = new PointerFunc(this.machine, this);
      return this.addFunc_(f, pos, "pointer");
    }

    addAllocFunc(pos) {
      var f;
      f = new AllocFunc(this.machine, this);
      return this.addFunc_(f, pos, "alloc");
    }

    addLinks(ids) {
      var id, j, len, prev, results;
      prev = null;
      results = [];
      for (j = 0, len = ids.length; j < len; j++) {
        id = ids[j];
        if (prev != null) {
          this.addLink(prev, id);
        }
        results.push(prev = id);
      }
      return results;
    }

    addLink(fromPortId, toPortId) {
      var fromPort, toPort;
      fromPort = this.machine.ports[fromPortId];
      toPort = this.machine.ports[toPortId];
      toPort.setValue(fromPort.getValue());
      this.machine.addLink([fromPortId, toPortId]);
      return this.viewController.onLinkCreated(fromPort, toPort);
    }

    removeLink(fromPortId, toPortId) {
      this.machine.removeLink([fromPortId, toPortId]);
      return this.viewController.onLinkRemoved(fromPortId, toPortId);
    }

    addPortFromString(pos, string) {
      var c, i, p, ports, v, values;
      values = [0, string.length];
      values = values.concat((function() {
        var j, len, results;
        results = [];
        for (j = 0, len = string.length; j < len; j++) {
          c = string[j];
          results.push(c.charCodeAt(0));
        }
        return results;
      })());
      ports = (function() {
        var results;
        results = [];
        for (i in values) {
          v = values[i];
          p = this.addPort({
            x: pos.x,
            y: pos.y + parseInt(i) * conf.gridSize
          });
          p.setValue(v);
          results.push(p);
        }
        return results;
      }).call(this);
      return ports[0].setValue(ports[2].id);
    }

  };

  ActionRouter.instance = null;

  return ActionRouter;

}).call(this);

module.exports = ActionRouter;


},{"./alloc_func.coffee":2,"./config.coffee":3,"./func.coffee":4,"./memory_func.coffee":10,"./pointer_func.coffee":12,"./port.coffee":13}],2:[function(require,module,exports){
var AllocFunc, Port, conf;

Port = require("./port.coffee");

conf = require("./config.coffee");

AllocFunc = class AllocFunc {
  constructor(machine, actionRouter) {
    var i, p;
    this.onChange = this.onChange.bind(this);
    this.machine = machine;
    this.actionRouter = actionRouter;
    this.inPorts = (function() {
      var j, len, ref, results;
      ref = [0];
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        i = ref[j];
        p = new Port(true, false);
        p.index = i;
        p.on("change", this.onChange);
        results.push(p);
      }
      return results;
    }).call(this);
    this.outPorts = (function() {
      var j, len, ref, results;
      ref = [0];
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        i = ref[j];
        p = new Port(false, true);
        p.index = i;
        results.push(p);
      }
      return results;
    })();
  }

  onChange() {
    var i, j, len, p, ports, ref, results;
    ports = (function() {
      var j, ref, results;
      results = [];
      for (i = j = 0, ref = this.inPorts[0].getValue() - 1; (0 <= ref ? j <= ref : j >= ref); i = 0 <= ref ? ++j : --j) {
        results.push(this.actionRouter.addPort({
          x: 120,
          y: i * conf.gridSize + 120
        }));
      }
      return results;
    }).call(this);
    this.outPorts[0].setValue(ports[0].id);
    ref = this.inPorts;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      p = ref[j];
      // wait next input
      results.push(p.received = false);
    }
    return results;
  }

};

module.exports = AllocFunc;


},{"./config.coffee":3,"./port.coffee":13}],3:[function(require,module,exports){
module.exports = {
  gridSize: 42
};


},{}],4:[function(require,module,exports){
var Func, Port;

Port = require("./port.coffee");

Func = class Func {
  constructor(func = (function(x) {
      return x;
    }), outNum = 1) {
    var i, p;
    this.onChange = this.onChange.bind(this);
    this.func = func;
    // setup ports
    this.inPorts = (function() {
      var j, ref, results;
      results = [];
      for (i = j = 0, ref = func.length - 1; (0 <= ref ? j <= ref : j >= ref); i = 0 <= ref ? ++j : --j) {
        p = new Port(true, false);
        p.index = i;
        p.on("change", this.onChange);
        results.push(p);
      }
      return results;
    }).call(this);
    if (outNum > 0) {
      this.outPorts = (function() {
        var j, ref, results;
        results = [];
        for (i = j = 0, ref = outNum - 1; (0 <= ref ? j <= ref : j >= ref); i = 0 <= ref ? ++j : --j) {
          p = new Port(false, true);
          p.index = i;
          results.push(p);
        }
        return results;
      })();
    }
    if (this.outPorts == null) {
      this.outPorts = [];
    }
  }

  onChange(e) {
    return this.updateOutput();
  }

  updateOutput() {
    var args, i, results, v, val;
    args = this.inPorts.map(function(p) {
      return p.getValue();
    });
    val = this.func.apply(null, args);
    if (this.outPorts.length === 1) {
      if (val != null) {
        return this.outPorts[0].setValue(val);
      }
    } else {
      results = [];
      for (i in val) {
        v = val[i];
        if (v != null) {
          results.push(this.outPorts[i].setValue(v));
        }
      }
      return results;
    }
  }

};

module.exports = Func;


},{"./port.coffee":13}],5:[function(require,module,exports){
var ActionRouter, FuncView, PortView, Rect, conf;

Rect = require("./rect.coffee");

PortView = require("./port_view.coffee");

conf = require("./config.coffee");

ActionRouter = require("./action_router.coffee");

FuncView = class FuncView extends createjs.Container {
  constructor(inPorts, outPorts, name) {
    var g, i, j, len, mouseButton, port, portViews, v;
    super();
    g = conf.gridSize / 2;
    this.text = new createjs.Text("", "12px Consolas", "rgba(0, 0, 0, 0.3)");
    this.text.text = name;
    this.text.y = -20;
    this.addChild(this.text);
    this.inPortViews = (function() {
      var results;
      results = [];
      for (i in inPorts) {
        port = inPorts[i];
        results.push(new PortView(new Rect(0, i * g, g, g), port));
      }
      return results;
    })();
    this.outPortViews = (function() {
      var results;
      results = [];
      for (i in outPorts) {
        port = outPorts[i];
        results.push(new PortView(new Rect(g, i * g, g, g), port));
      }
      return results;
    })();
    portViews = this.inPortViews.concat(this.outPortViews);
    for (j = 0, len = portViews.length; j < len; j++) {
      v = portViews[j];
      v.setBackgroundColor("white");
      v.uiEnabled = false;
      this.addChild(v);
    }
    this.dragged = false;
    mouseButton = 0;
    this.on("mousedown", (e) => {
      this.dragged = false;
      mouseButton = e.nativeEvent.button;
      if (mouseButton !== 0) {
        return;
      }
      return this.offset = new createjs.Point(this.x - e.stageX, this.y - e.stageY);
    });
    this.on("pressmove", (e) => {
      this.dragged = true;
      if (mouseButton !== 0) {
        return;
      }
      this.x = e.stageX + this.offset.x;
      return this.y = e.stageY + this.offset.y;
    });
    this.on("click", (e) => {
      if (this.dragged) {
        return;
      }
      if (e.nativeEvent.button === 1) {
        return ActionRouter.instance.removeFunc(this.inPortViews[0].port.funcId);
      }
    });
  }

};

module.exports = FuncView;


},{"./action_router.coffee":1,"./config.coffee":3,"./port_view.coffee":14,"./rect.coffee":15}],6:[function(require,module,exports){
var Link, Port;

Port = require("./port.coffee");

Link = class Link {
  constructor(ports) {
    var i, len, port;
    this.addPort = this.addPort.bind(this);
    this.removePort = this.removePort.bind(this);
    this.onChange = this.onChange.bind(this);
    this.ports = [];
    for (i = 0, len = ports.length; i < len; i++) {
      port = ports[i];
      this.addPort(port);
    }
  }

  addPort(port) {
    if (_.contains(this.ports, port)) {
      return;
    }
    port.on("change", this.onChange);
    return this.ports.push(port);
  }

  removePort(port) {
    if (!_.contains(this.ports, port)) {
      return;
    }
    port.off("change", this.onChange);
    return this.ports = _.reject(this.ports, function(p) {
      return p === port;
    });
  }

  onChange(e) {
    var i, len, port, ref, results, v;
    v = e.target.getValue();
    ref = this.ports;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      port = ref[i];
      results.push(port.setValue(v));
    }
    return results;
  }

};

module.exports = Link;


},{"./port.coffee":13}],7:[function(require,module,exports){
var ActionRouter, LinkView, arrowHeight, arrowWidth, color,
  boundMethodCheck = function(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new Error('Bound instance method accessed before binding'); } };

ActionRouter = require("./action_router.coffee");

color = "rgba(0, 0, 0, 0.2)";

arrowWidth = 6;

arrowHeight = 12;

LinkView = class LinkView extends createjs.Container {
  constructor(fromPortView, toPortView) {
    super();
    this.onChange = this.onChange.bind(this);
    this.updatePath = this.updatePath.bind(this);
    this.path = new createjs.Shape();
    this.addChild(this.path);
    this.fromPortView = fromPortView;
    this.toPortView = toPortView;
    fromPortView.on("change", this.onChange);
    toPortView.on("change", this.onChange);
    this.fromArrow = new createjs.Shape(new createjs.Graphics().beginFill(color).moveTo(0, 0).lineTo(0, arrowHeight).lineTo(-arrowWidth, arrowHeight / 2).endFill());
    this.addChild(this.fromArrow);
    this.toArrow = new createjs.Shape(new createjs.Graphics().beginFill(color).moveTo(0, 0).lineTo(arrowWidth, arrowHeight / 2).lineTo(0, arrowHeight).endFill());
    this.addChild(this.toArrow);
    this.path.on("click", (e) => {
      if (e.nativeEvent.button === 1) {
        return ActionRouter.instance.removeLink(fromPortView.port.id, toPortView.port.id);
      }
    });
    createjs.Ticker.on("tick", this.updatePath);
  }

  onChange(e) {
    boundMethodCheck(this, LinkView);
    console.dir(e.target);
    return this.updatePath();
  }

  updatePath() {
    var fromPoint, toPoint;
    boundMethodCheck(this, LinkView);
    fromPoint = this.fromPortView.localToGlobal(this.fromPortView.getBounds().width, this.fromPortView.getBounds().height / 2);
    toPoint = this.toPortView.localToGlobal(0, this.toPortView.getBounds().height / 2);
    this.fromArrow.x = fromPoint.x;
    this.fromArrow.y = fromPoint.y - arrowHeight / 2;
    this.toArrow.x = toPoint.x;
    this.toArrow.y = toPoint.y - arrowHeight / 2;
    return this.path.graphics.clear().setStrokeStyle(2).beginStroke(color).moveTo(fromPoint.x, fromPoint.y).lineTo(toPoint.x, toPoint.y).endStroke();
  }

};

module.exports = LinkView;


},{"./action_router.coffee":1}],8:[function(require,module,exports){
var Func, Link, Machine, Port;

Port = require("./port.coffee");

Func = require("./func.coffee");

Link = require("./link.coffee");

Machine = class Machine {
  constructor(width, height) {
    this.addPort = this.addPort.bind(this);
    this.removePort = this.removePort.bind(this);
    // returns func id
    this.addFunc = this.addFunc.bind(this);
    this.removeFunc = this.removeFunc.bind(this);
    this.findLinkByIds = this.findLinkByIds.bind(this);
    this.addLink = this.addLink.bind(this);
    this.removeLink = this.removeLink.bind(this);
    this.allPorts = this.allPorts.bind(this);
    this.funcs = [];
    this.ports = [];
    this.links = [];
  }

  addPort(p) {
    this.ports.push(p);
    return p.id = this.ports.length - 1;
  }

  removePort(id) {
    return delete this.ports[id];
  }

  addFunc(func) {
    var funcId, i, len, p, ref;
    this.funcs.push(func);
    funcId = this.funcs.length - 1;
    func.id = funcId;
    ref = func.inPorts.concat(func.outPorts);
    for (i = 0, len = ref.length; i < len; i++) {
      p = ref[i];
      p.funcId = funcId;
      this.addPort(p);
    }
    return funcId;
  }

  removeFunc(funcId) {
    var f, i, len, p, ref;
    f = this.funcs[funcId];
    delete this.funcs[funcId];
    ref = f.inPorts.concat(f.outPorts);
    for (i = 0, len = ref.length; i < len; i++) {
      p = ref[i];
      this.removePort(p.id);
    }
    return this.ports = _.reject(this.ports, function(p) {
      return ((p != null ? p.funcId : void 0) != null) && p.funcId === funcId;
    });
  }

  findLinkByIds(ids) {
    return _.find(this.links, function(link) {
      return _.intersection(link.ports.map(function(p) {
        return p.id;
      }), ids).length > 0;
    });
  }

  addLink(portIds) {
    var i, len, link, p, ports;
    ports = portIds.map((id) => {
      return this.ports[id];
    });
    link = this.findLinkByIds(portIds);
    if (link != null) {
      for (i = 0, len = ports.length; i < len; i++) {
        p = ports[i];
        link.addPort(p);
      }
      return console.log(link.ports.map(function(p) {
        return p.id;
      }));
    } else {
      link = new Link(ports);
      return this.links.push(link);
    }
  }

  removeLink(portIds) {
    var i, len, link, p, ports, results;
    link = this.findLinkByIds(portIds);
    if (link == null) {
      return;
    }
    ports = portIds.map((id) => {
      return this.ports[id];
    });
    results = [];
    for (i = 0, len = ports.length; i < len; i++) {
      p = ports[i];
      results.push(link.removePort(p));
    }
    return results;
  }

  allPorts() {
    var funcPorts;
    funcPorts = _.flatten(this.funcs.map(function(f) {
      return f.ports;
    }));
    return this.ports.concat(funcPorts);
  }

};

module.exports = Machine;


},{"./func.coffee":4,"./link.coffee":6,"./port.coffee":13}],9:[function(require,module,exports){
var ActionRouter, DragState, FRAME_EDGE_SIZE, FUNC_RADIUS, Func, FuncView, GRID_SIZE, MEMORY_COLS, MEMORY_ROWS, Machine, Point, PointerFunc, Port, PortView, Rect, Size, TargetType, ViewController, actionRouter, addFunc, boolToNum, canvas, conf, ctx, defaultFuncPos, dragEvent, frames, fromObj, getJSONSync, height, machine, stage, viewController, width;

conf = require("./config.coffee");

Point = require("./point.coffee");

Size = require("./size.coffee");

Rect = require("./rect.coffee");

Machine = require("./machine.coffee");

Port = require("./port.coffee");

Func = require("./func.coffee");

PointerFunc = require("./pointer_func.coffee");

PortView = require("./port_view.coffee");

FuncView = require("./func_view.coffee");

ViewController = require("./view_controller.coffee");

ActionRouter = require("./action_router.coffee");

//#
width = 960;

height = 6400;

GRID_SIZE = conf.gridSize;

FRAME_EDGE_SIZE = 3;

FUNC_RADIUS = GRID_SIZE / 3;

MEMORY_COLS = Math.round(width / GRID_SIZE);

MEMORY_ROWS = Math.round(height / GRID_SIZE);

canvas = document.getElementById("canvas");

ctx = canvas.getContext("2d");

stage = new createjs.Stage("canvas");

createjs.Ticker.setFPS(60);

createjs.Ticker.addEventListener("tick", stage);

frames = [];

DragState = {
  None: 0,
  Down: 1,
  Move: 2
};

TargetType = {
  None: 0,
  Frame: 10,
  FrameEdge: 11,
  Canvas: 20,
  Func: 30
};

dragEvent = {
  state: DragState.None,
  targetType: TargetType.None,
  target: null,
  button: 0,
  moved: false,
  start: new Point(0, 0),
  current: new Point(0, 0)
};

//#
viewController = new ViewController();

stage.addChild(viewController.view);

machine = new Machine(width, height);

machine.onPortValueChanged = viewController.onPortValueChanged;

actionRouter = new ActionRouter(viewController, machine);

ActionRouter.instance = actionRouter;

actionRouter.addPort({
  x: 0,
  y: 0
});

document.stage = stage;

//#
fromObj = null;

// do not show context menu on canvas
canvas.oncontextmenu = function(e) {
  return e.preventDefault();
};

canvas.onmousedown = function(e) {
  return fromObj = stage.getObjectUnderPoint(e.layerX, e.layerY, 1);
};

canvas.onmousemove = function(e) {};

canvas.onmouseup = function(e) {
  var pos, toObj;
  toObj = stage.getObjectUnderPoint(e.layerX, e.layerY, 1);
  pos = {
    x: e.layerX,
    y: e.layerY
  };
  switch (e.button) {
    case 0:
      if ((toObj == null) && (fromObj == null)) {
        return actionRouter.addPort(pos);
      }
      break;
    case 2:
      if (fromObj instanceof PortView && toObj instanceof PortView && fromObj !== toObj) {
        return actionRouter.addLink(fromObj.port.id, toObj.port.id);
      }
  }
};

defaultFuncPos = {
  x: 220,
  y: 120
};

getJSONSync = function(url) {
  var result;
  result = null;
  $.ajax({
    type: "GET",
    url: url,
    dataType: "json",
    success: function(d) {
      return result = d;
    },
    async: false
  });
  return result;
};

addFunc = function(json) {
  var e, f, i, j, len, len1, n, ref, ref1, results;
  if (json.nodes) {
    ref = json.nodes;
    for (i = 0, len = ref.length; i < len; i++) {
      n = ref[i];
      if (n.script != null) {
        f = new Function(n.script[0], n.script[1]);
        f = actionRouter.addFunc(n.position, f, 1, n.name);
      } else if (n.src != null) {
        addFunc(getJSONSync(`files/${n.src}`));
      } else if (n.value != null) {
        actionRouter.addPort(pos, defaultFuncPos);
      }
    }
  }
  if (json.edges) {
    ref1 = json.edges;
    results = [];
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      e = ref1[j];
      results.push(actionRouter.addLinks(e));
    }
    return results;
  }
};

$("#button-plus").on("click", function() {
  return $.getJSON("files/plus.json", function(d) {
    return addFunc(d);
  });
});

$("#button-minus").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, (function(a, b) {
    return a - b;
  }), 1, "-");
});

$("#button-multi").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, (function(a, b) {
    return a * b;
  }), 1, "*");
});

$("#button-div").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, (function(a, b) {
    return a / b;
  }), 1, "/");
});

boolToNum = function(b) {
  if (b) {
    return 1;
  } else {
    return 0;
  }
};

$("#button-equal").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, (function(a, b) {
    return boolToNum(a === b);
  }), 1, "=");
});

$("#button-and").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, (function(a, b) {
    return boolToNum(a && b);
  }), 1, "and");
});

$("#button-or").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, (function(a, b) {
    return boolToNum(a || b);
  }), 1, "or");
});

$("#button-greater").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, (function(a, b) {
    return boolToNum(a > b);
  }), 1, ">");
});

$("#button-less").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, (function(a, b) {
    return boolToNum(a < b);
  }), 1, "<");
});

$("#button-if").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, function(flag, a, b) {
    if (flag) {
      return a;
    } else {
      return b;
    }
  }, 1, "if");
});

$("#button-alloc").on("click", function() {
  return actionRouter.addAllocFunc(defaultFuncPos);
});

$("#button-pointer").on("click", function() {
  return actionRouter.addPointerFunc(defaultFuncPos);
});

$("#button-step").on("click", function() {
  var p;
  p = machine.ports[0];
  return p.setValue(p.getValue() + 1);
});

$("#button-string").on("click", function() {
  return actionRouter.addPortFromString(defaultFuncPos, "Hello, world!");
});

$("#button-stdout").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, (function(a) {
    return console.log(a);
  }), 0, "stdout");
});

$("#button-tochar").on("click", function() {
  return actionRouter.addFunc(defaultFuncPos, (function(a) {
    return String.fromCharCode(a);
  }), 1, "toChar");
});


},{"./action_router.coffee":1,"./config.coffee":3,"./func.coffee":4,"./func_view.coffee":5,"./machine.coffee":8,"./point.coffee":11,"./pointer_func.coffee":12,"./port.coffee":13,"./port_view.coffee":14,"./rect.coffee":15,"./size.coffee":16,"./view_controller.coffee":17}],10:[function(require,module,exports){
var MemoryFunc, Port;

Port = require("./port.coffee");

MemoryFunc = class MemoryFunc {
  constructor(value) {
    var i, p;
    this.onChange = this.onChange.bind(this);
    this.inPorts = (function() {
      var j, results;
      results = [];
      for (i = j = 0; j <= 1; i = ++j) {
        p = new Port(true, false);
        p.index = i;
        results.push(p);
      }
      return results;
    })();
    this.inPorts[0].on("change", this.onChange);
    this.outPorts = (function() {
      var j, len, ref, results;
      ref = [0];
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        i = ref[j];
        p = new Port(false, true);
        p.index = i;
        results.push(p);
      }
      return results;
    })();
    this.inPorts[1].setValue(value);
  }

  onChange() {
    var j, len, p, ref, results;
    this.outPorts[0].setValue(this.inPorts[1].getValue());
    ref = this.inPorts;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      p = ref[j];
      // wait next input
      results.push(p.received = false);
    }
    return results;
  }

};

module.exports = MemoryFunc;


},{"./port.coffee":13}],11:[function(require,module,exports){
var Point, conf, roundGrid;

conf = require("./config.coffee");

roundGrid = function(x) {
  return Math.round(x / conf.gridSize) * conf.gridSize;
};

Point = class Point {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }

  add(v) {
    if (v instanceof Point) {
      return new Point(this.x + v.x, this.y + v.y);
    } else {
      return new Point(this.x + v, this.y + v);
    }
  }

  sub(v) {
    if (v instanceof Point) {
      return new Point(this.x - v.x, this.y - v.y);
    } else {
      return new Point(this.x - v, this.y - v);
    }
  }

  roundGrid() {
    return new Point(roundGrid(this.x), roundGrid(this.y));
  }

  copyFrom(point) {
    this.x = point.x;
    return this.y = point.y;
  }

  copy() {
    return new Point(this.x, this.y);
  }

};

module.exports = Point;


},{"./config.coffee":3}],12:[function(require,module,exports){
var PointerFunc, Port;

Port = require("./port.coffee");

PointerFunc = class PointerFunc {
  constructor(machine, actionRouter) {
    var i, p;
    this.updateLink = this.updateLink.bind(this);
    this.machine = machine;
    this.actionRouter = actionRouter;
    this.inPorts = (function() {
      var j, len, ref, results;
      ref = [0];
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        i = ref[j];
        p = new Port(true, false);
        p.index = i;
        p.on("change", this.updateLink);
        results.push(p);
      }
      return results;
    }).call(this);
    this.outPorts = (function() {
      var j, len, ref, results;
      ref = [0];
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        i = ref[j];
        p = new Port(false, true);
        p.index = i;
        results.push(p);
      }
      return results;
    })();
    this.prevId = -1;
  }

  updateLink() {
    var fromId, toPortId;
    toPortId = this.outPorts[0].id;
    if (this.prevId > 0) {
      this.actionRouter.removeLink(this.prevId, toPortId);
    }
    fromId = this.inPorts[0].getValue();
    this.actionRouter.addLink(fromId, toPortId);
    return this.prevId = this.inPorts[0].getValue();
  }

};

module.exports = PointerFunc;


},{"./port.coffee":13}],13:[function(require,module,exports){
var Port;

Port = class Port {
  constructor(canWrite, canRead) {
    this.canWrite = canWrite;
    this.canRead = canRead;
    this.value = 0;
  }

  getValue(v) {
    return this.value;
  }

  setValue(v) {
    var changed;
    changed = this.value !== v;
    this.value = v;
    if (changed) {
      this.dispatchEvent("change");
    }
    return this;
  }

};

createjs.EventDispatcher.initialize(Port.prototype);

module.exports = Port;


},{}],14:[function(require,module,exports){
var ActionRouter, Point, PortView, foreColor,
  boundMethodCheck = function(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new Error('Bound instance method accessed before binding'); } };

Point = require("./point.coffee");

ActionRouter = require("./action_router.coffee");

foreColor = "rgba(0, 0, 0, 0.4)";

PortView = class PortView extends createjs.Container {
  constructor(frame, port) {
    var idText, mouseButton;
    super();
    this.onChange = this.onChange.bind(this);
    this.setValue = this.setValue.bind(this);
    this.highlight = this.highlight.bind(this);
    this.setBounds(0, 0, frame.width, frame.height);
    this.x = frame.x;
    this.y = frame.y;
    this.background = new createjs.Shape;
    this.setBackgroundColor("rgb(245, 244, 244)");
    this.addChild(this.background);
    this.text = new createjs.Text("", "12px Consolas", foreColor);
    this.addChild(this.text);
    idText = new createjs.Text("", "12px Consolas", "rgba(0, 128, 0, 0.4)");
    idText.text = `${port.id}`;
    idText.y = 20;
    this.addChild(idText);
    this.mouseChildren = false;
    this.port = port;
    this.setValue(port.getValue());
    this.port.on("change", this.onChange);
    this.uiEnabled = true;
    mouseButton = 0;
    this.on("mousedown", (e) => {
      if (!this.uiEnabled) {
        return;
      }
      this.dragged = false;
      mouseButton = e.nativeEvent.button;
      if (mouseButton !== 0) {
        return;
      }
      return this.offset = new createjs.Point(this.x - e.stageX, this.y - e.stageY);
    });
    this.on("pressmove", (e) => {
      if (!this.uiEnabled) {
        return;
      }
      this.dragged = true;
      if (mouseButton !== 0) {
        return;
      }
      this.x = e.stageX + this.offset.x;
      return this.y = e.stageY + this.offset.y;
    });
    this.on("click", (e) => {
      if (!this.uiEnabled) {
        return;
      }
      if (this.dragged) {
        return;
      }
      this.dragged = false;
      switch (e.nativeEvent.button) {
        case 0:
          return this.port.setValue(this.port.getValue() + 1);
        case 1:
          return ActionRouter.instance.removePort(this.port.id);
        case 2:
          return this.port.setValue(this.port.getValue() - 1);
      }
    });
    this.on("dblclick", () => {});
  }

  setBackgroundColor(color) {
    var b;
    b = this.getBounds();
    return this.background.graphics.setStrokeStyle(1).beginStroke(foreColor).beginFill(color).drawRect(0, 0, b.width, b.height);
  }

  onChange(e) {
    boundMethodCheck(this, PortView);
    return this.setValue(e.target.getValue());
  }

  setValue(v) {
    boundMethodCheck(this, PortView);
    this.text.text = `${v}`;
    return this.highlight();
  }

  highlight() {
    var b, rect;
    boundMethodCheck(this, PortView);
    b = this.getBounds();
    rect = new createjs.Shape(new createjs.Graphics().beginFill("rgba(255, 0, 0, 0.2)").drawRect(b.x, b.y, b.width, b.height));
    this.addChild(rect);
    return createjs.Tween.get(rect).to({
      alpha: 0
    }, 500, createjs.Ease.getPowInOut(2)).call((e) => {
      return this.removeChild(e.target);
    });
  }

};

module.exports = PortView;


},{"./action_router.coffee":1,"./point.coffee":11}],15:[function(require,module,exports){
var Point, Rect, Size, conf;

conf = require("./config.coffee");

Point = require("./point.coffee");

Size = require("./size.coffee");

Rect = class Rect {
  constructor(x, y, width, height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.normalize();
  }

  point() {
    return new Point(this.x, this.y);
  }

  size() {
    return new Size(this.width, this.height);
  }

  static fromPoint(point, size) {
    return new Rect(point.x, point.y, size.width, size.height);
  }

  inset(dx, dy) {
    return new Rect(this.x + dx, this.y + dy, this.width - dx * 2, this.height - dy * 2);
  }

  contains(point) {
    return point.x >= this.x && point.y >= this.y && point.x <= this.x + this.width && point.y <= this.y + this.height;
  }

  setPoint(point) {
    this.x = point.x;
    return this.y = point.y;
  }

  setSize(size) {
    this.width = size.width;
    this.height = size.height;
    return this.normalize();
  }

  normalize() {
    if (this.width < 0) {
      this.x += this.width;
      this.width *= -1;
    }
    if (this.height < 0) {
      this.y += this.height;
      this.height *= -1;
    }
    if (this.width === 0) {
      this.width = conf.gridSize;
    }
    if (this.height === 0) {
      return this.height = conf.gridSize;
    }
  }

};

module.exports = Rect;


},{"./config.coffee":3,"./point.coffee":11,"./size.coffee":16}],16:[function(require,module,exports){
var Size;

Size = class Size {
  constructor(width, height) {
    this.width = width;
    this.height = height;
  }

  static fromPoint(point) {
    return new Size(point.x, point.y);
  }

};

module.exports = Size;


},{}],17:[function(require,module,exports){
var FuncView, LinkView, PortView, ViewController, conf;

PortView = require("./port_view.coffee");

FuncView = require("./func_view.coffee");

LinkView = require("./link_view.coffee");

conf = require("./config.coffee");

ViewController = class ViewController {
  constructor() {
    this.portViewForPort = this.portViewForPort.bind(this);
    this.onPortValueChanged = this.onPortValueChanged.bind(this);
    this.onPortCreated = this.onPortCreated.bind(this);
    this.onFuncCreated = this.onFuncCreated.bind(this);
    this.onLinkCreated = this.onLinkCreated.bind(this);
    this.onLinkRemoved = this.onLinkRemoved.bind(this);
    this.view = new createjs.Container();
    this.portViews = {};
    this.funcViews = {};
    this.linkViews = [];
  }

  portViewForPort(port) {
    var v;
    if (port.funcId != null) {
      v = this.funcViews[port.funcId];
      if (port.canWrite) {
        return v.inPortViews[port.index];
      }
      if (port.canRead) {
        return v.outPortViews[port.index];
      }
    } else {
      return this.portViews[port.id];
    }
  }

  onPortValueChanged(e) {
    var port, pv;
    port = e.target;
    pv = this.portViewForPort(port);
    return pv.setValue(port.getValue());
  }

  onPortCreated(portId, port, pos) {
    var frame, v;
    frame = {
      x: pos.x,
      y: pos.y,
      width: conf.gridSize,
      height: conf.gridSize
    };
    v = new PortView(frame, port);
    this.portViews[portId] = v;
    return this.view.addChild(v);
  }

  onPortRemoved(portId) {
    var v;
    v = this.portViews[portId];
    delete this.portViews[portId];
    return this.view.removeChild(v);
  }

  onFuncCreated(funcId, func, pos, name) {
    var v;
    v = new FuncView(func.inPorts, func.outPorts, name);
    v.x = pos.x;
    v.y = pos.y;
    this.funcViews[funcId] = v;
    return this.view.addChild(v);
  }

  onFuncRemoved(funcId) {
    var v;
    v = this.funcViews[funcId];
    delete this.funcViews[funcId];
    return this.view.removeChild(v);
  }

  onLinkCreated(fromPort, toPort) {
    var fromPV, toPV, v;
    fromPV = this.portViewForPort(fromPort);
    toPV = this.portViewForPort(toPort);
    v = new LinkView(fromPV, toPV);
    this.view.addChild(v);
    return this.linkViews.push(v);
  }

  onLinkRemoved(fromPortId, toPortId) {
    var i, len, ref, results, v;
    ref = this.linkViews;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      v = ref[i];
      if (v.fromPortView.port.id === fromPortId && v.toPortView.port.id === toPortId) {
        this.linkViews = _.reject(this.linkViews, function(l) {
          return l === v;
        });
        results.push(this.view.removeChild(v));
      } else {
        results.push(void 0);
      }
    }
    return results;
  }

};

module.exports = ViewController;


},{"./config.coffee":3,"./func_view.coffee":5,"./link_view.coffee":7,"./port_view.coffee":14}]},{},[9])
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCJjb2ZmZWUvYWN0aW9uX3JvdXRlci5jb2ZmZWUiLCJjb2ZmZWUvYWxsb2NfZnVuYy5jb2ZmZWUiLCJjb2ZmZWUvY29uZmlnLmNvZmZlZSIsImNvZmZlZS9mdW5jLmNvZmZlZSIsImNvZmZlZS9mdW5jX3ZpZXcuY29mZmVlIiwiY29mZmVlL2xpbmsuY29mZmVlIiwiY29mZmVlL2xpbmtfdmlldy5jb2ZmZWUiLCJjb2ZmZWUvbWFjaGluZS5jb2ZmZWUiLCJjb2ZmZWUvbWFpbi5jb2ZmZWUiLCJjb2ZmZWUvbWVtb3J5X2Z1bmMuY29mZmVlIiwiY29mZmVlL3BvaW50LmNvZmZlZSIsImNvZmZlZS9wb2ludGVyX2Z1bmMuY29mZmVlIiwiY29mZmVlL3BvcnQuY29mZmVlIiwiY29mZmVlL3BvcnRfdmlldy5jb2ZmZWUiLCJjb2ZmZWUvcmVjdC5jb2ZmZWUiLCJjb2ZmZWUvc2l6ZS5jb2ZmZWUiLCJjb2ZmZWUvdmlld19jb250cm9sbGVyLmNvZmZlZSJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTtBQ0FBLElBQUEsWUFBQSxFQUFBLFNBQUEsRUFBQSxJQUFBLEVBQUEsVUFBQSxFQUFBLFdBQUEsRUFBQSxJQUFBLEVBQUE7O0FBQUEsSUFBQSxHQUFPLE9BQUEsQ0FBUSxlQUFSOztBQUNQLElBQUEsR0FBTyxPQUFBLENBQVEsZUFBUjs7QUFDUCxXQUFBLEdBQWMsT0FBQSxDQUFRLHVCQUFSOztBQUNkLFNBQUEsR0FBWSxPQUFBLENBQVEscUJBQVI7O0FBQ1osVUFBQSxHQUFhLE9BQUEsQ0FBUSxzQkFBUjs7QUFDYixJQUFBLEdBQU8sT0FBQSxDQUFRLGlCQUFSOztBQUlEOzs7RUFBTixNQUFBLGFBQUE7SUFHRSxXQUFhLENBQUMsY0FBRCxFQUFpQixPQUFqQixDQUFBO1VBbUNiLENBQUEsZUFBQSxDQUFBLG9CQWxDRTs7Ozs7VUF3REYsQ0FBQSx3QkFBQSxDQUFBO01BeERFLElBQUMsQ0FB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LENBQUEsU0FBUyxDQUFDLElBQVgsQ0FBZ0IsQ0FBaEI7RUFMYTs7RUFPZixhQUFlLENBQUMsVUFBRCxFQUFhLFFBQWIsQ0FBQTtBQUNiLFFBQUEsQ0FBQSxFQUFBLEdBQUEsRUFBQSxHQUFBLEVBQUEsT0FBQSxFQUFBO0FBQUE7QUFBQTtJQUFBLEtBQUEscUNBQUE7O01BQ0UsSUFBRyxDQUFDLENBQUMsWUFBWSxDQUFDLElBQUksQ0FBQyxFQUFwQixLQUEwQixVQUExQixJQUF5QyxDQUFDLENBQUMsVUFBVSxDQUFDLElBQUksQ0FBQyxFQUFsQixLQUF3QixRQUFwRTtRQUNFLElBQUMsQ0FBQSxTQUFELEdBQWEsQ0FBQyxDQUFDLE1BQUYsQ0FBUyxJQUFDLENBQUEsU0FBVixFQUFxQixRQUFBLENBQUMsQ0FBRCxDQUFBO2lCQUFPLENBQUEsS0FBSztRQUFaLENBQXJCO3FCQUNiLElBQUMsQ0FBQSxJQUFJLENBQUMsV0FBTixDQUFrQixDQUFsQixHQUZGO09BQUEsTUFBQTs2QkFBQTs7SUFERixDQUFBOztFQURhOztBQXhEakI7O0FBOERBLE1BQU0sQ0FBQyxPQUFQLEdBQWlCIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIoZnVuY3Rpb24oKXtmdW5jdGlvbiByKGUsbix0KXtmdW5jdGlvbiBvKGksZil7aWYoIW5baV0pe2lmKCFlW2ldKXt2YXIgYz1cImZ1bmN0aW9uXCI9PXR5cGVvZiByZXF1aXJlJiZyZXF1aXJlO2lmKCFmJiZjKXJldHVybiBjKGksITApO2lmKHUpcmV0dXJuIHUoaSwhMCk7dmFyIGE9bmV3IEVycm9yKFwiQ2Fubm90IGZpbmQgbW9kdWxlICdcIitpK1wiJ1wiKTt0aHJvdyBhLmNvZGU9XCJNT0RVTEVfTk9UX0ZPVU5EXCIsYX12YXIgcD1uW2ldPXtleHBvcnRzOnt9fTtlW2ldWzBdLmNhbGwocC5leHBvcnRzLGZ1bmN0aW9uKHIpe3ZhciBuPWVbaV1bMV1bcl07cmV0dXJuIG8obnx8cil9LHAscC5leHBvcnRzLHIsZSxuLHQpfXJldHVybiBuW2ldLmV4cG9ydHN9Zm9yKHZhciB1PVwiZnVuY3Rpb25cIj09dHlwZW9mIHJlcXVpcmUmJnJlcXVpcmUsaT0wO2k8dC5sZW5ndGg7aSsrKW8odFtpXSk7cmV0dXJuIG99cmV0dXJuIHJ9KSgpIiwiUG9ydCA9IHJlcXVpcmUgXCIuL3BvcnQuY29mZmVlXCJcclxuRnVuYyA9IHJlcXVpcmUgXCIuL2Z1bmMuY29mZmVlXCJcclxuUG9pbnRlckZ1bmMgPSByZXF1aXJlIFwiLi9wb2ludGVyX2Z1bmMuY29mZmVlXCJcclxuQWxsb2NGdW5jID0gcmVxdWlyZSBcIi4vYWxsb2NfZnVuYy5jb2ZmZWVcIlxyXG5NZW1vcnlGdW5jID0gcmVxdWlyZSBcIi4vbWVtb3J5X2Z1bmMuY29mZmVlXCJcclxuY29uZiA9IHJlcXVpcmUgXCIuL2NvbmZpZy5jb2ZmZWVcIlxyXG5cclxuIyDjg6bjg7zjgrbjg7zjgYzooYzjgYbmir3osaHnmoTjgarli5XkvZwgKGFkZFBvcnTjgarjgakpIOOBruWFt+S9k+eahOOBquWHpueQhuOCkuihjOOBhlxyXG4jIHZpZXdDb250cm9sbGVyLCBtYWNoaW5lIOOBq+aMr+OCiuWIhuOBkeOCi+OBruOBjOODoeOCpOODs1xyXG5jbGFzcyBBY3Rpb25Sb3V0ZXJcclxuICBAaW5zdGFuY2UgPSBudWxsXHJcblxyXG4gIGNvbnN0cnVjdG9yOiAodmlld0NvbnRyb2xsZXIsIG1hY2hpbmUpIC0+XHJcbiAgICBAdmlld0NvbnRyb2xsZXIgPSB2aWV3Q29udHJvbGxlclxyXG4gICAgQG1hY2hpbmUgPSBtYWNoaW5lXHJcblxyXG4gIGFkZFBvcnQ6IChwb3MpIC0+XHJcbiAgICBwID0gbmV3IFBvcnQgdHJ1ZSwgdHJ1ZVxyXG4gICAgcG9ydElkID0gQG1hY2hpbmUuYWRkUG9ydCBwXHJcbiAgICBAdmlld0NvbnRyb2xsZXIub25Qb3J0Q3JlYXRlZCBwb3J0SWQsIHAsIHBvc1xyXG4gICAgcFxyXG5cclxuICByZW1vdmVQb3J0OiAoaWQpIC0+XHJcbiAgICBAbWFjaGluZS5yZW1vdmVQb3J0IGlkXHJcbiAgICBAdmlld0NvbnRyb2xsZXIub25Qb3J0UmVtb3ZlZCBpZFxyXG5cclxuICBhZGRGdW5jXzogKGZ1bmMsIHBvcywgbmFtZSkgLT5cclxuICAgIGZ1bmNJZCA9IEBtYWNoaW5lLmFkZEZ1bmMgZnVuY1xyXG4gICAgQHZpZXdDb250cm9sbGVyLm9uRnVuY0NyZWF0ZWQgZnVuY0lkLCBmdW5jLCBwb3MsIG5hbWVcclxuICAgIGZ1bmNcclxuXHJcbiAgcmVtb3ZlRnVuYzogKGlkKSAtPlxyXG4gICAgQG1hY2hpbmUucmVtb3ZlRnVuYyBpZFxyXG4gICAgQHZpZXdDb250cm9sbGVyLm9uRnVuY1JlbW92ZWQgaWRcclxuXHJcbiAgYWRkRnVuYzogKHBvcywgZnVuYywgb3V0TnVtID0gMSwgbmFtZSA9IG51bGwpIC0+XHJcbiAgICBmID0gbmV3IEZ1bmMgZnVuYywgb3V0TnVtXHJcbiAgICBAYWRkRnVuY18gZiwgcG9zLCBuYW1lXHJcblxyXG4gIGFkZFBvaW50ZXJGdW5jOiAocG9zKSAtPlxyXG4gICAgZiA9IG5ldyBQb2ludGVyRnVuYyBAbWFjaGluZSwgQFxyXG4gICAgQGFkZEZ1bmNfIGYsIHBvcywgXCJwb2ludGVyXCJcclxuXHJcbiAgYWRkQWxsb2NGdW5jOiAocG9zKSAtPlxyXG4gICAgZiA9IG5ldyBBbGxvY0Z1bmMgQG1hY2hpbmUsIEBcclxuICAgIEBhZGRGdW5jXyBmLCBwb3MsIFwiYWxsb2NcIlxyXG5cclxuICBhZGRMaW5rczogKGlkcykgPT5cclxuICAgIHByZXYgPSBudWxsXHJcbiAgICBmb3IgaWQgaW4gaWRzXHJcbiAgICAgIGlmIHByZXY/XHJcbiAgICAgICAgQGFkZExpbmsgcHJldiwgaWRcclxuICAgICAgcHJldiA9IGlkXHJcblxyXG4gIGFkZExpbms6IChmcm9tUG9ydElkLCB0b1BvcnRJZCkgLT5cclxuICAgIGZyb21Qb3J0ID0gQG1hY2hpbmUucG9ydHNbZnJvbVBvcnRJZF1cclxuICAgIHRvUG9ydCA9IEBtYWNoaW5lLnBvcnRzW3RvUG9ydElkXVxyXG4gICAgdG9Qb3J0LnNldFZhbHVlIGZyb21Qb3J0LmdldFZhbHVlKClcclxuICAgIEBtYWNoaW5lLmFkZExpbmsgW2Zyb21Qb3J0SWQsIHRvUG9ydElkXVxyXG4gICAgQHZpZXdDb250cm9sbGVyLm9uTGlua0NyZWF0ZWQgZnJvbVBvcnQsIHRvUG9ydFxyXG5cclxuICByZW1vdmVMaW5rOiAoZnJvbVBvcnRJZCwgdG9Qb3J0SWQpIC0+XHJcbiAgICBAbWFjaGluZS5yZW1vdmVMaW5rIFtmcm9tUG9ydElkLCB0b1BvcnRJZF1cclxuICAgIEB2aWV3Q29udHJvbGxlci5vbkxpbmtSZW1vdmVkIGZyb21Qb3J0SWQsIHRvUG9ydElkXHJcblxyXG4gICMjIGZvciBkZWJ1Z1xyXG5cclxuICAjIOaWh+Wtl+WIl+OCkuODoeODouODquOBq+iqreOBv+i+vOOCgFxyXG4gICMgW+mFjeWIl+OBruWFiOmgreOBruOCouODieODrOOCueOAgeOCteOCpOOCuuOAgemFjeWIly4uLl1cclxuICBhZGRQb3J0RnJvbVN0cmluZzogKHBvcywgc3RyaW5nKSA9PlxyXG4gICAgdmFsdWVzID0gWzAsIHN0cmluZy5sZW5ndGhdXHJcbiAgICB2YWx1ZXMgPSB2YWx1ZXMuY29uY2F0IChjLmNoYXJDb2RlQXQoMCkgZm9yIGMgaW4gc3RyaW5nKVxyXG5cclxuICAgIHBvcnRzID0gKGZvciBpLCB2IG9mIHZhbHVlc1xyXG4gICAgICBwID0gQGFkZFBvcnRcclxuICAgICAgICB4OiBwb3MueFxyXG4gICAgICAgIHk6IHBvcy55ICsgcGFyc2VJbnQoaSkgKiBjb25mLmdyaWRTaXplXHJcbiAgICAgIHAuc2V0VmFsdWUgdlxyXG4gICAgICBwXHJcbiAgICApXHJcblxyXG4gICAgcG9ydHNbMF0uc2V0VmFsdWUgcG9ydHNbMl0uaWRcclxuXHJcbm1vZHVsZS5leHBvcnRzID0gQWN0aW9uUm91dGVyXHJcbiIsIlBvcnQgPSByZXF1aXJlIFwiLi9wb3J0LmNvZmZlZVwiXHJcbmNvbmYgPSByZXF1aXJlIFwiLi9jb25maWcuY29mZmVlXCJcclxuXHJcbmNsYXNzIEFsbG9jRnVuY1xyXG4gIGNvbnN0cnVjdG9yOiAobWFjaGluZSwgYWN0aW9uUm91dGVyKSAtPlxyXG4gICAgQG1hY2hpbmUgPSBtYWNoaW5lXHJcbiAgICBAYWN0aW9uUm91dGVyID0gYWN0aW9uUm91dGVyXHJcblxyXG4gICAgQGluUG9ydHMgPSAoZm9yIGkgaW4gWzBdXHJcbiAgICAgIHAgPSBuZXcgUG9ydCh0cnVlLCBmYWxzZSlcclxuICAgICAgcC5pbmRleCA9IGlcclxuICAgICAgcC5vbiBcImNoYW5nZVwiLCBAb25DaGFuZ2VcclxuICAgICAgcFxyXG4gICAgKVxyXG5cclxuICAgIEBvdXRQb3J0cyA9IChmb3IgaSBpbiBbMF1cclxuICAgICAgcCA9IG5ldyBQb3J0KGZhbHNlLCB0cnVlKVxyXG4gICAgICBwLmluZGV4ID0gaVxyXG4gICAgICBwXHJcbiAgICApXHJcblxyXG4gIG9uQ2hhbmdlOiA9PlxyXG4gICAgcG9ydHMgPSAoZm9yIGkgaW4gWzAuLkBpblBvcnRzWzBdLmdldFZhbHVlKCkgLSAxXVxyXG4gICAgICBAYWN0aW9uUm91dGVyLmFkZFBvcnQgXHJcbiAgICAgICAgeDogMTIwXHJcbiAgICAgICAgeTogaSAqIGNvbmYuZ3JpZFNpemUgKyAxMjBcclxuICAgIClcclxuXHJcbiAgICBAb3V0UG9ydHNbMF0uc2V0VmFsdWUgcG9ydHNbMF0uaWRcclxuXHJcbiAgICAjIHdhaXQgbmV4dCBpbnB1dFxyXG4gICAgKHAucmVjZWl2ZWQgPSBmYWxzZSkgZm9yIHAgaW4gQGluUG9ydHNcclxuXHJcbm1vZHVsZS5leHBvcnRzID0gQWxsb2NGdW5jXHJcbiIsIm1vZHVsZS5leHBvcnRzID0gXHJcbiAgZ3JpZFNpemU6IDQyXHJcbiIsIlBvcnQgPSByZXF1aXJlIFwiLi9wb3J0LmNvZmZlZVwiXHJcblxyXG5jbGFzcyBGdW5jXHJcbiAgY29uc3RydWN0b3I6IChmdW5jID0gKCh4KSAtPiB4KSwgb3V0TnVtID0gMSkgLT5cclxuICAgIEBmdW5jID0gZnVuY1xyXG5cclxuICAgICMgc2V0dXAgcG9ydHNcclxuICAgIEBpblBvcnRzID0gKGZvciBpIGluIFswLi5mdW5jLmxlbmd0aCAtIDFdXHJcbiAgICAgIHAgPSBuZXcgUG9ydCh0cnVlLCBmYWxzZSlcclxuICAgICAgcC5pbmRleCA9IGlcclxuICAgICAgcC5vbiBcImNoYW5nZVwiLCBAb25DaGFuZ2VcclxuICAgICAgcFxyXG4gICAgKVxyXG4gICAgQG91dFBvcnRzID0gKGZvciBpIGluIFswLi5vdXROdW0gLSAxXVxyXG4gICAgICBwID0gbmV3IFBvcnQoZmFsc2UsIHRydWUpXHJcbiAgICAgIHAuaW5kZXggPSBpXHJcbiAgICAgIHBcclxuICAgICkgaWYgb3V0TnVtID4gMFxyXG4gICAgQG91dFBvcnRzID89IFtdXHJcblxyXG4gIG9uQ2hhbmdlOiAoZSkgPT5cclxuICAgIEB1cGRhdGVPdXRwdXQoKVxyXG5cclxuICB1cGRhdGVPdXRwdXQ6IC0+XHJcbiAgICBhcmdzID0gQGluUG9ydHMubWFwIChwKSAtPiBwLmdldFZhbHVlKClcclxuICAgIHZhbCA9IEBmdW5jLmFwcGx5IG51bGwsIGFyZ3NcclxuICAgIGlmIEBvdXRQb3J0cy5sZW5ndGggaXMgMVxyXG4gICAgICBAb3V0UG9ydHNbMF0uc2V0VmFsdWUgdmFsIGlmIHZhbD9cclxuICAgIGVsc2VcclxuICAgICAgQG91dFBvcnRzW2ldLnNldFZhbHVlKHYpIGZvciBpLCB2IG9mIHZhbCB3aGVuIHY/XHJcblxyXG5tb2R1bGUuZXhwb3J0cyA9IEZ1bmNcclxuIiwiUmVjdCA9IHJlcXVpcmUgXCIuL3JlY3QuY29mZmVlXCJcclxuUG9ydFZpZXcgPSByZXF1aXJlIFwiLi9wb3J0X3ZpZXcuY29mZmVlXCJcclxuY29uZiA9IHJlcXVpcmUgXCIuL2NvbmZpZy5jb2ZmZWVcIlxyXG5BY3Rpb25Sb3V0ZXIgPSByZXF1aXJlIFwiLi9hY3Rpb25fcm91dGVyLmNvZmZlZVwiXHJcblxyXG5jbGFzcyBGdW5jVmlldyBleHRlbmRzIGNyZWF0ZWpzLkNvbnRhaW5lclxyXG4gIGNvbnN0cnVjdG9yOiAoaW5Qb3J0cywgb3V0UG9ydHMsIG5hbWUpIC0+XHJcbiAgICBzdXBlcigpXHJcbiAgICBnID0gY29uZi5ncmlkU2l6ZeOAgC8gMlxyXG5cclxuICAgIEB0ZXh0ID0gbmV3IGNyZWF0ZWpzLlRleHQgXCJcIiwgXCIxMnB4IENvbnNvbGFzXCIsIFwicmdiYSgwLCAwLCAwLCAwLjMpXCJcclxuICAgIEB0ZXh0LnRleHQgPSBuYW1lXHJcbiAgICBAdGV4dC55ID0gLTIwXHJcbiAgICBAYWRkQ2hpbGQgQHRleHRcclxuXHJcbiAgICBAaW5Qb3J0Vmlld3MgPSAoZm9yIGksIHBvcnQgb2YgaW5Qb3J0c1xyXG4gICAgICBuZXcgUG9ydFZpZXcgbmV3IFJlY3QoMCwgaSAqIGcsIGcsIGcpLCBwb3J0XHJcbiAgICApXHJcblxyXG4gICAgQG91dFBvcnRWaWV3cyA9IChmb3IgaSwgcG9ydCBvZiBvdXRQb3J0c1xyXG4gICAgICBuZXcgUG9ydFZpZXcgbmV3IFJlY3QoZywgaSAqIGcsIGcsIGcpLCBwb3J0XHJcbiAgICApXHJcblxyXG4gICAgcG9ydFZpZXdzID0gQGluUG9ydFZpZXdzLmNvbmNhdChAb3V0UG9ydFZpZXdzKVxyXG5cclxuICAgIGZvciB2IGluIHBvcnRWaWV3c1xyXG4gICAgICB2LnNldEJhY2tncm91bmRDb2xvciBcIndoaXRlXCIgXHJcbiAgICAgIHYudWlFbmFibGVkID0gZmFsc2VcclxuICAgICAgQGFkZENoaWxkIHZcclxuXHJcbiAgICBAZHJhZ2dlZCA9IGZhbHNlXHJcbiAgICBtb3VzZUJ1dHRvbiA9IDBcclxuXHJcbiAgICBAb24gXCJtb3VzZWRvd25cIiwgKGUpID0+XHJcbiAgICAgIEBkcmFnZ2VkID0gZmFsc2VcclxuICAgICAgbW91c2VCdXR0b24gPSBlLm5hdGl2ZUV2ZW50LmJ1dHRvblxyXG4gICAgICByZXR1cm4gaWYgbW91c2VCdXR0b24gaXNudCAwXHJcbiAgICAgIEBvZmZzZXQgPSBuZXcgY3JlYXRlanMuUG9pbnQgQHggLSBlLnN0YWdlWCwgQHkgLSBlLnN0YWdlWVxyXG5cclxuICAgIEBvbiBcInByZXNzbW92ZVwiLCAoZSkgPT5cclxuICAgICAgQGRyYWdnZWQgPSB0cnVlXHJcbiAgICAgIHJldHVybiBpZiBtb3VzZUJ1dHRvbiBpc250IDBcclxuICAgICAgQHggPSBlLnN0YWdlWCArIEBvZmZzZXQueFxyXG4gICAgICBAeSA9IGUuc3RhZ2VZICsgQG9mZnNldC55XHJcblxyXG4gICAgQG9uIFwiY2xpY2tcIiwgKGUpID0+XHJcbiAgICAgIHJldHVybiBpZiBAZHJhZ2dlZFxyXG4gICAgICBpZiBlLm5hdGl2ZUV2ZW50LmJ1dHRvbiBpcyAxXHJcbiAgICAgICAgQWN0aW9uUm91dGVyLmluc3RhbmNlLnJlbW92ZUZ1bmMgQGluUG9ydFZpZXdzWzBdLnBvcnQuZnVuY0lkXHJcblxyXG5tb2R1bGUuZXhwb3J0cyA9IEZ1bmNWaWV3XHJcbiIsIlBvcnQgPSByZXF1aXJlIFwiLi9wb3J0LmNvZmZlZVwiXHJcblxyXG5jbGFzcyBMaW5rXHJcbiAgY29uc3RydWN0b3I6IChwb3J0cykgLT5cclxuICAgIEBwb3J0cyA9IFtdXHJcbiAgICBAYWRkUG9ydCBwb3J0IGZvciBwb3J0IGluIHBvcnRzXHJcblxyXG4gIGFkZFBvcnQ6IChwb3J0KSA9PlxyXG4gICAgcmV0dXJuIGlmIF8uY29udGFpbnMgQHBvcnRzLCBwb3J0XHJcbiAgICBwb3J0Lm9uIFwiY2hhbmdlXCIsIEBvbkNoYW5nZVxyXG4gICAgQHBvcnRzLnB1c2ggcG9ydFxyXG5cclxuICByZW1vdmVQb3J0OiAocG9ydCkgPT5cclxuICAgIHJldHVybiB1bmxlc3MgXy5jb250YWlucyBAcG9ydHMsIHBvcnRcclxuICAgIHBvcnQub2ZmIFwiY2hhbmdlXCIsIEBvbkNoYW5nZVxyXG4gICAgQHBvcnRzID0gXy5yZWplY3QgQHBvcnRzLCAocCkgLT4gcCBpcyBwb3J0XHJcblxyXG4gIG9uQ2hhbmdlOiAoZSkgPT5cclxuICAgIHYgPSBlLnRhcmdldC5nZXRWYWx1ZSgpXHJcbiAgICBmb3IgcG9ydCBpbiBAcG9ydHNcclxuICAgICAgcG9ydC5zZXRWYWx1ZSB2XHJcblxyXG5tb2R1bGUuZXhwb3J0cyA9IExpbmtcclxuIiwiQWN0aW9uUm91dGVyID0gcmVxdWlyZSBcIi4vYWN0aW9uX3JvdXRlci5jb2ZmZWVcIlxyXG5cclxuY29sb3IgPSBcInJnYmEoMCwgMCwgMCwgMC4yKVwiXHJcbmFycm93V2lkdGggPSA2XHJcbmFycm93SGVpZ2h0ID0gMTJcclxuXHJcbmNsYXNzIExpbmtWaWV3IGV4dGVuZHMgY3JlYXRlanMuQ29udGFpbmVyXHJcbiAgY29uc3RydWN0b3I6IChmcm9tUG9ydFZpZXcsIHRvUG9ydFZpZXcpIC0+XHJcbiAgICBzdXBlcigpXHJcbiAgICBAcGF0aCA9IG5ldyBjcmVhdGVqcy5TaGFwZSgpXHJcbiAgICBAYWRkQ2hpbGQgQHBhdGhcclxuICAgIEBmcm9tUG9ydFZpZXcgPSBmcm9tUG9ydFZpZXdcclxuICAgIEB0b1BvcnRWaWV3ID0gdG9Qb3J0Vmlld1xyXG4gICAgZnJvbVBvcnRWaWV3Lm9uIFwiY2hhbmdlXCIsIEBvbkNoYW5nZVxyXG4gICAgdG9Qb3J0Vmlldy5vbiBcImNoYW5nZVwiLCBAb25DaGFuZ2VcclxuXHJcbiAgICBAZnJvbUFycm93ID0gbmV3IGNyZWF0ZWpzLlNoYXBlKG5ldyBjcmVhdGVqcy5HcmFwaGljcygpXHJcbiAgICAgIC5iZWdpbkZpbGwgY29sb3JcclxuICAgICAgLm1vdmVUbyAwLCAwXHJcbiAgICAgIC5saW5lVG8gMCwgYXJyb3dIZWlnaHRcclxuICAgICAgLmxpbmVUbyAtYXJyb3dXaWR0aCwgYXJyb3dIZWlnaHQgLyAyXHJcbiAgICAgIC5lbmRGaWxsKClcclxuICAgIClcclxuICAgIEBhZGRDaGlsZCBAZnJvbUFycm93XHJcblxyXG4gICAgQHRvQXJyb3cgPSBuZXcgY3JlYXRlanMuU2hhcGUobmV3IGNyZWF0ZWpzLkdyYXBoaWNzKClcclxuICAgICAgLmJlZ2luRmlsbCBjb2xvclxyXG4gICAgICAubW92ZVRvIDAsIDBcclxuICAgICAgLmxpbmVUbyBhcnJvd1dpZHRoLCBhcnJvd0hlaWdodCAvIDJcclxuICAgICAgLmxpbmVUbyAwLCBhcnJvd0hlaWdodFxyXG4gICAgICAuZW5kRmlsbCgpXHJcbiAgICApXHJcbiAgICBAYWRkQ2hpbGQgQHRvQXJyb3dcclxuXHJcbiAgICBAcGF0aC5vbiBcImNsaWNrXCIsIChlKSA9PlxyXG4gICAgICBpZiBlLm5hdGl2ZUV2ZW50LmJ1dHRvbiBpcyAxXHJcbiAgICAgICAgQWN0aW9uUm91dGVyLmluc3RhbmNlLnJlbW92ZUxpbmsgZnJvbVBvcnRWaWV3LnBvcnQuaWQsIHRvUG9ydFZpZXcucG9ydC5pZFxyXG5cclxuICAgIGNyZWF0ZWpzLlRpY2tlci5vbiBcInRpY2tcIiwgQHVwZGF0ZVBhdGhcclxuXHJcbiAgb25DaGFuZ2U6IChlKSA9PlxyXG4gICAgY29uc29sZS5kaXIgZS50YXJnZXRcclxuICAgIEB1cGRhdGVQYXRoKClcclxuXHJcbiAgdXBkYXRlUGF0aDogPT5cclxuICAgIGZyb21Qb2ludCA9IEBmcm9tUG9ydFZpZXcubG9jYWxUb0dsb2JhbCBAZnJvbVBvcnRWaWV3LmdldEJvdW5kcygpLndpZHRoLCBAZnJvbVBvcnRWaWV3LmdldEJvdW5kcygpLmhlaWdodCAvIDJcclxuICAgIHRvUG9pbnQgPSBAdG9Qb3J0Vmlldy5sb2NhbFRvR2xvYmFsIDAsIEB0b1BvcnRWaWV3LmdldEJvdW5kcygpLmhlaWdodCAvIDJcclxuXHJcbiAgICBAZnJvbUFycm93LnggPSBmcm9tUG9pbnQueFxyXG4gICAgQGZyb21BcnJvdy55ID0gZnJvbVBvaW50LnkgLSBhcnJvd0hlaWdodCAvIDJcclxuXHJcbiAgICBAdG9BcnJvdy54ID0gdG9Qb2ludC54XHJcbiAgICBAdG9BcnJvdy55ID0gdG9Qb2ludC55IC0gYXJyb3dIZWlnaHQgLyAyXHJcblxyXG4gICAgQHBhdGguZ3JhcGhpY3NcclxuICAgICAgLmNsZWFyKClcclxuICAgICAgLnNldFN0cm9rZVN0eWxlIDJcclxuICAgICAgLmJlZ2luU3Ryb2tlIGNvbG9yXHJcbiAgICAgIC5tb3ZlVG8gZnJvbVBvaW50LngsIGZyb21Qb2ludC55XHJcbiAgICAgIC5saW5lVG8gdG9Qb2ludC54LCB0b1BvaW50LnlcclxuICAgICAgLmVuZFN0cm9rZSgpXHJcblxyXG5tb2R1bGUuZXhwb3J0cyA9IExpbmtWaWV3XHJcbiIsIlBvcnQgPSByZXF1aXJlIFwiLi9wb3J0LmNvZmZlZVwiXHJcbkZ1bmMgPSByZXF1aXJlIFwiLi9mdW5jLmNvZmZlZVwiXHJcbkxpbmsgPSByZXF1aXJlIFwiLi9saW5rLmNvZmZlZVwiXHJcblxyXG5jbGFzcyBNYWNoaW5lXHJcbiAgY29uc3RydWN0b3I6ICh3aWR0aCwgaGVpZ2h0KSAtPlxyXG4gICAgQGZ1bmNzID0gW11cclxuICAgIEBwb3J0cyA9IFtdXHJcbiAgICBAbGlua3MgPSBbXVxyXG5cclxuICBhZGRQb3J0OiAocCkgPT5cclxuICAgIEBwb3J0cy5wdXNoIHBcclxuICAgIHAuaWQgPSBAcG9ydHMubGVuZ3RoIC0gMVxyXG5cclxuICByZW1vdmVQb3J0OiAoaWQpID0+XHJcbiAgICBkZWxldGUgQHBvcnRzW2lkXVxyXG5cclxuICAjIHJldHVybnMgZnVuYyBpZFxyXG4gIGFkZEZ1bmM6IChmdW5jKSA9PlxyXG4gICAgQGZ1bmNzLnB1c2ggZnVuY1xyXG4gICAgZnVuY0lkID0gQGZ1bmNzLmxlbmd0aCAtIDFcclxuICAgIGZ1bmMuaWQgPSBmdW5jSWRcclxuICAgIGZvciBwIGluIGZ1bmMuaW5Qb3J0cy5jb25jYXQgZnVuYy5vdXRQb3J0c1xyXG4gICAgICBwLmZ1bmNJZCA9IGZ1bmNJZFxyXG4gICAgICBAYWRkUG9ydCBwXHJcbiAgICBmdW5jSWRcclxuXHJcbiAgcmVtb3ZlRnVuYzogKGZ1bmNJZCkgPT5cclxuICAgIGYgPSBAZnVuY3NbZnVuY0lkXVxyXG4gICAgZGVsZXRlIEBmdW5jc1tmdW5jSWRdXHJcbiAgICBmb3IgcCBpbiBmLmluUG9ydHMuY29uY2F0IGYub3V0UG9ydHNcclxuICAgICAgQHJlbW92ZVBvcnQgcC5pZFxyXG4gICAgQHBvcnRzID0gXy5yZWplY3QgQHBvcnRzLCAocCkgLT4gcD8uZnVuY0lkPyBhbmQgcC5mdW5jSWQgaXMgZnVuY0lkXHJcblxyXG4gIGZpbmRMaW5rQnlJZHM6IChpZHMpID0+XHJcbiAgICBfLmZpbmQgQGxpbmtzLCAobGluaykgLT4gXHJcbiAgICAgIF8uaW50ZXJzZWN0aW9uKGxpbmsucG9ydHMubWFwKChwKSAtPiBwLmlkKSwgaWRzKS5sZW5ndGggPiAwXHJcblxyXG4gIGFkZExpbms6IChwb3J0SWRzKSA9PlxyXG4gICAgcG9ydHMgPSBwb3J0SWRzLm1hcCAoaWQpID0+IEBwb3J0c1tpZF1cclxuICAgIGxpbmsgPSBAZmluZExpbmtCeUlkcyBwb3J0SWRzXHJcbiAgICBpZiBsaW5rP1xyXG4gICAgICBsaW5rLmFkZFBvcnQocCkgZm9yIHAgaW4gcG9ydHNcclxuICAgICAgY29uc29sZS5sb2cgbGluay5wb3J0cy5tYXAoKHApIC0+IHAuaWQpXHJcbiAgICBlbHNlXHJcbiAgICAgIGxpbmsgPSBuZXcgTGluayBwb3J0c1xyXG4gICAgICBAbGlua3MucHVzaCBsaW5rXHJcblxyXG4gIHJlbW92ZUxpbms6IChwb3J0SWRzKSA9PlxyXG4gICAgbGluayA9IEBmaW5kTGlua0J5SWRzIHBvcnRJZHNcclxuICAgIHJldHVybiB1bmxlc3MgbGluaz9cclxuICAgIHBvcnRzID0gcG9ydElkcy5tYXAgKGlkKSA9PiBAcG9ydHNbaWRdXHJcbiAgICBsaW5rLnJlbW92ZVBvcnQocCkgZm9yIHAgaW4gcG9ydHNcclxuXHJcbiAgYWxsUG9ydHM6ICgpID0+XHJcbiAgICBmdW5jUG9ydHMgPSBfLmZsYXR0ZW4oQGZ1bmNzLm1hcCAoZikgLT4gZi5wb3J0cykgXHJcbiAgICBAcG9ydHMuY29uY2F0IGZ1bmNQb3J0c1xyXG5cclxubW9kdWxlLmV4cG9ydHMgPSBNYWNoaW5lXHJcbiIsImNvbmYgPSByZXF1aXJlIFwiLi9jb25maWcuY29mZmVlXCJcclxuUG9pbnQgPSByZXF1aXJlIFwiLi9wb2ludC5jb2ZmZWVcIlxyXG5TaXplID0gcmVxdWlyZSBcIi4vc2l6ZS5jb2ZmZWVcIlxyXG5SZWN0ID0gcmVxdWlyZSBcIi4vcmVjdC5jb2ZmZWVcIlxyXG5NYWNoaW5lID0gcmVxdWlyZSBcIi4vbWFjaGluZS5jb2ZmZWVcIlxyXG5Qb3J0ID0gcmVxdWlyZSBcIi4vcG9ydC5jb2ZmZWVcIlxyXG5GdW5jID0gcmVxdWlyZSBcIi4vZnVuYy5jb2ZmZWVcIlxyXG5Qb2ludGVyRnVuYyA9IHJlcXVpcmUgXCIuL3BvaW50ZXJfZnVuYy5jb2ZmZWVcIlxyXG5Qb3J0VmlldyA9IHJlcXVpcmUgXCIuL3BvcnRfdmlldy5jb2ZmZWVcIlxyXG5GdW5jVmlldyA9IHJlcXVpcmUgXCIuL2Z1bmNfdmlldy5jb2ZmZWVcIlxyXG5WaWV3Q29udHJvbGxlciA9IHJlcXVpcmUgXCIuL3ZpZXdfY29udHJvbGxlci5jb2ZmZWVcIlxyXG5BY3Rpb25Sb3V0ZXIgPSByZXF1aXJlIFwiLi9hY3Rpb25fcm91dGVyLmNvZmZlZVwiXHJcblxyXG4jI1xyXG5cclxud2lkdGggPSA5NjBcclxuaGVpZ2h0ID0gNjQwMFxyXG5HUklEX1NJWkUgPSBjb25mLmdyaWRTaXplXHJcbkZSQU1FX0VER0VfU0laRSA9IDNcclxuRlVOQ19SQURJVVMgPSBHUklEX1NJWkUgLyAzXHJcbk1FTU9SWV9DT0xTID0gTWF0aC5yb3VuZCh3aWR0aCAvIEdSSURfU0laRSlcclxuTUVNT1JZX1JPV1MgPSBNYXRoLnJvdW5kKGhlaWdodCAvIEdSSURfU0laRSlcclxuXHJcbmNhbnZhcyA9IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkIFwiY2FudmFzXCJcclxuY3R4ID0gY2FudmFzLmdldENvbnRleHQgXCIyZFwiXHJcbnN0YWdlID0gbmV3IGNyZWF0ZWpzLlN0YWdlIFwiY2FudmFzXCJcclxuXHJcbmNyZWF0ZWpzLlRpY2tlci5zZXRGUFMgNjBcclxuY3JlYXRlanMuVGlja2VyLmFkZEV2ZW50TGlzdGVuZXIgXCJ0aWNrXCIsIHN0YWdlXHJcblxyXG5mcmFtZXMgPSBbXVxyXG5cclxuRHJhZ1N0YXRlID0gXHJcbiAgTm9uZTogMFxyXG4gIERvd246IDFcclxuICBNb3ZlOiAyXHJcblxyXG5UYXJnZXRUeXBlID1cclxuICBOb25lOiAwXHJcbiAgRnJhbWU6IDEwXHJcbiAgRnJhbWVFZGdlOiAxMVxyXG4gIENhbnZhczogMjBcclxuICBGdW5jOiAzMFxyXG5cclxuZHJhZ0V2ZW50ID0gXHJcbiAgc3RhdGU6IERyYWdTdGF0ZS5Ob25lXHJcbiAgdGFyZ2V0VHlwZTogVGFyZ2V0VHlwZS5Ob25lXHJcbiAgdGFyZ2V0OiBudWxsXHJcbiAgYnV0dG9uOiAwXHJcbiAgbW92ZWQ6IGZhbHNlXHJcbiAgc3RhcnQ6IG5ldyBQb2ludCgwLCAwKVxyXG4gIGN1cnJlbnQ6IG5ldyBQb2ludCgwLCAwKVxyXG5cclxuIyNcclxuXHJcbnZpZXdDb250cm9sbGVyID0gbmV3IFZpZXdDb250cm9sbGVyKClcclxuc3RhZ2UuYWRkQ2hpbGQgdmlld0NvbnRyb2xsZXIudmlld1xyXG5cclxubWFjaGluZSA9IG5ldyBNYWNoaW5lIHdpZHRoLCBoZWlnaHRcclxubWFjaGluZS5vblBvcnRWYWx1ZUNoYW5nZWQgPSB2aWV3Q29udHJvbGxlci5vblBvcnRWYWx1ZUNoYW5nZWRcclxuXHJcbmFjdGlvblJvdXRlciA9IG5ldyBBY3Rpb25Sb3V0ZXIgdmlld0NvbnRyb2xsZXIsIG1hY2hpbmVcclxuQWN0aW9uUm91dGVyLmluc3RhbmNlID0gYWN0aW9uUm91dGVyXHJcblxyXG5hY3Rpb25Sb3V0ZXIuYWRkUG9ydFxyXG4gIHg6IDBcclxuICB5OiAwXHJcblxyXG5kb2N1bWVudC5zdGFnZSA9IHN0YWdlXHJcblxyXG4jI1xyXG5cclxuZnJvbU9iaiA9IG51bGxcclxuXHJcbiMgZG8gbm90IHNob3cgY29udGV4dCBtZW51IG9uIGNhbnZhc1xyXG5jYW52YXMub25jb250ZXh0bWVudSA9IChlKSAtPiBlLnByZXZlbnREZWZhdWx0KClcclxuXHJcbmNhbnZhcy5vbm1vdXNlZG93biA9IChlKSAtPlxyXG4gIGZyb21PYmogPSBzdGFnZS5nZXRPYmplY3RVbmRlclBvaW50IGUubGF5ZXJYLCBlLmxheWVyWSwgMVxyXG5cclxuY2FudmFzLm9ubW91c2Vtb3ZlID0gKGUpIC0+XHJcblxyXG5jYW52YXMub25tb3VzZXVwID0gKGUpIC0+XHJcbiAgdG9PYmogPSBzdGFnZS5nZXRPYmplY3RVbmRlclBvaW50IGUubGF5ZXJYLCBlLmxheWVyWSwgMVxyXG4gIHBvcyA9IFxyXG4gICAgeDogZS5sYXllclhcclxuICAgIHk6IGUubGF5ZXJZXHJcblxyXG4gIHN3aXRjaCBlLmJ1dHRvblxyXG4gICAgd2hlbiAwXHJcbiAgICAgIGlmIG5vdCB0b09iaj8gYW5kIG5vdCBmcm9tT2JqP1xyXG4gICAgICAgIGFjdGlvblJvdXRlci5hZGRQb3J0IHBvc1xyXG4gICAgd2hlbiAyXHJcbiAgICAgIGlmIGZyb21PYmogaW5zdGFuY2VvZiBQb3J0VmlldyBhbmQgdG9PYmogaW5zdGFuY2VvZiBQb3J0VmlldyBhbmQgZnJvbU9iaiBpc250IHRvT2JqXHJcbiAgICAgICAgYWN0aW9uUm91dGVyLmFkZExpbmsgZnJvbU9iai5wb3J0LmlkLCB0b09iai5wb3J0LmlkXHJcblxyXG5kZWZhdWx0RnVuY1BvcyA9IFxyXG4gIHg6IDIyMFxyXG4gIHk6IDEyMFxyXG5cclxuZ2V0SlNPTlN5bmMgPSAodXJsKSAtPlxyXG4gIHJlc3VsdCA9IG51bGxcclxuICAkLmFqYXhcclxuICAgIHR5cGU6IFwiR0VUXCIsXHJcbiAgICB1cmw6IHVybCxcclxuICAgIGRhdGFUeXBlOiBcImpzb25cIixcclxuICAgIHN1Y2Nlc3M6IChkKSAtPiByZXN1bHQgPSBkLFxyXG4gICAgYXN5bmM6IGZhbHNlXHJcbiAgcmVzdWx0XHJcblxyXG5hZGRGdW5jID0gKGpzb24pIC0+ICAgXHJcbiAgaWYganNvbi5ub2RlcyB0aGVuIGZvciBuIGluIGpzb24ubm9kZXNcclxuICAgIGlmIG4uc2NyaXB0P1xyXG4gICAgICBmID0gbmV3IEZ1bmN0aW9uIG4uc2NyaXB0WzBdLCBuLnNjcmlwdFsxXVxyXG4gICAgICBmID0gYWN0aW9uUm91dGVyLmFkZEZ1bmMgbi5wb3NpdGlvbiwgZiwgMSwgbi5uYW1lXHJcblxyXG4gICAgZWxzZSBpZiBuLnNyYz9cclxuICAgICAgYWRkRnVuYyBnZXRKU09OU3luYyBcImZpbGVzLyN7bi5zcmN9XCJcclxuICAgIGVsc2UgaWYgbi52YWx1ZT9cclxuICAgICAgYWN0aW9uUm91dGVyLmFkZFBvcnQgcG9zLCBkZWZhdWx0RnVuY1Bvc1xyXG5cclxuICBpZiBqc29uLmVkZ2VzIHRoZW4gZm9yIGUgaW4ganNvbi5lZGdlc1xyXG4gICAgYWN0aW9uUm91dGVyLmFkZExpbmtzIGVcclxuXHJcbiQoXCIjYnV0dG9uLXBsdXNcIikub24gXCJjbGlja1wiLCAtPlxyXG4gICQuZ2V0SlNPTiBcImZpbGVzL3BsdXMuanNvblwiLCAoZCkgLT4gYWRkRnVuYyBkXHJcblxyXG4kKFwiI2J1dHRvbi1taW51c1wiKS5vbiBcImNsaWNrXCIsIC0+XHJcbiAgYWN0aW9uUm91dGVyLmFkZEZ1bmMgZGVmYXVsdEZ1bmNQb3MsICgoYSwgYikgLT4gYSAtIGIpLCAxLCBcIi1cIlxyXG5cclxuJChcIiNidXR0b24tbXVsdGlcIikub24gXCJjbGlja1wiLCAtPlxyXG4gIGFjdGlvblJvdXRlci5hZGRGdW5jIGRlZmF1bHRGdW5jUG9zLCAoKGEsIGIpIC0+IGEgKiBiKSwgMSwgXCIqXCJcclxuICBcclxuJChcIiNidXR0b24tZGl2XCIpLm9uIFwiY2xpY2tcIiwgLT5cclxuICBhY3Rpb25Sb3V0ZXIuYWRkRnVuYyBkZWZhdWx0RnVuY1BvcywgKChhLCBiKSAtPiBhIC8gYiksIDEsIFwiL1wiXHJcblxyXG5ib29sVG9OdW0gPSAoYikgLT4gaWYgYiB0aGVuIDEgZWxzZSAwXHJcblxyXG4kKFwiI2J1dHRvbi1lcXVhbFwiKS5vbiBcImNsaWNrXCIsIC0+XHJcbiAgYWN0aW9uUm91dGVyLmFkZEZ1bmMgZGVmYXVsdEZ1bmNQb3MsICgoYSwgYikgLT4gYm9vbFRvTnVtKGEgaXMgYikpLCAxLCBcIj1cIlxyXG5cclxuJChcIiNidXR0b24tYW5kXCIpLm9uIFwiY2xpY2tcIiwgLT5cclxuICBhY3Rpb25Sb3V0ZXIuYWRkRnVuYyBkZWZhdWx0RnVuY1BvcywgKChhLCBiKSAtPiBib29sVG9OdW0oYSBhbmQgYikpLCAxLCBcImFuZFwiXHJcblxyXG4kKFwiI2J1dHRvbi1vclwiKS5vbiBcImNsaWNrXCIsIC0+XHJcbiAgYWN0aW9uUm91dGVyLmFkZEZ1bmMgZGVmYXVsdEZ1bmNQb3MsICgoYSwgYikgLT4gYm9vbFRvTnVtKGEgb3IgYikpLCAxLCBcIm9yXCJcclxuXHJcbiQoXCIjYnV0dG9uLWdyZWF0ZXJcIikub24gXCJjbGlja1wiLCAtPlxyXG4gIGFjdGlvblJvdXRlci5hZGRGdW5jIGRlZmF1bHRGdW5jUG9zLCAoKGEsIGIpIC0+IGJvb2xUb051bShhID4gYikpLCAxLCBcIj5cIlxyXG5cclxuJChcIiNidXR0b24tbGVzc1wiKS5vbiBcImNsaWNrXCIsIC0+XHJcbiAgYWN0aW9uUm91dGVyLmFkZEZ1bmMgZGVmYXVsdEZ1bmNQb3MsICgoYSwgYikgLT4gYm9vbFRvTnVtKGEgPCBiKSksIDEsIFwiPFwiXHJcblxyXG4kKFwiI2J1dHRvbi1pZlwiKS5vbiBcImNsaWNrXCIsIC0+XHJcbiAgYWN0aW9uUm91dGVyLmFkZEZ1bmMgZGVmYXVsdEZ1bmNQb3MsIChmbGFnLCBhLCBiKSAtPiBcclxuICAgIGlmIGZsYWcgdGhlbiBhIGVsc2UgYlxyXG4gICwgMSwgXCJpZlwiXHJcblxyXG4kKFwiI2J1dHRvbi1hbGxvY1wiKS5vbiBcImNsaWNrXCIsIC0+XHJcbiAgYWN0aW9uUm91dGVyLmFkZEFsbG9jRnVuYyBkZWZhdWx0RnVuY1Bvc1xyXG5cclxuJChcIiNidXR0b24tcG9pbnRlclwiKS5vbiBcImNsaWNrXCIsIC0+XHJcbiAgYWN0aW9uUm91dGVyLmFkZFBvaW50ZXJGdW5jIGRlZmF1bHRGdW5jUG9zXHJcblxyXG4kKFwiI2J1dHRvbi1zdGVwXCIpLm9uIFwiY2xpY2tcIiwgLT5cclxuICBwID0gbWFjaGluZS5wb3J0c1swXVxyXG4gIHAuc2V0VmFsdWUgcC5nZXRWYWx1ZSgpICsgMVxyXG5cclxuJChcIiNidXR0b24tc3RyaW5nXCIpLm9uIFwiY2xpY2tcIiwgLT5cclxuICBhY3Rpb25Sb3V0ZXIuYWRkUG9ydEZyb21TdHJpbmcgZGVmYXVsdEZ1bmNQb3MsIFwiSGVsbG8sIHdvcmxkIVwiXHJcblxyXG4kKFwiI2J1dHRvbi1zdGRvdXRcIikub24gXCJjbGlja1wiLCAtPlxyXG4gIGFjdGlvblJvdXRlci5hZGRGdW5jIGRlZmF1bHRGdW5jUG9zLCAoKGEpIC0+IGNvbnNvbGUubG9nKGEpKSwgMCwgXCJzdGRvdXRcIlxyXG5cclxuJChcIiNidXR0b24tdG9jaGFyXCIpLm9uIFwiY2xpY2tcIiwgLT5cclxuICBhY3Rpb25Sb3V0ZXIuYWRkRnVuYyBkZWZhdWx0RnVuY1BvcywgKChhKSAtPiBTdHJpbmcuZnJvbUNoYXJDb2RlKGEpKSwgMSwgXCJ0b0NoYXJcIlxyXG4iLCJQb3J0ID0gcmVxdWlyZSBcIi4vcG9ydC5jb2ZmZWVcIlxyXG5cclxuY2xhc3MgTWVtb3J5RnVuY1xyXG4gIGNvbnN0cnVjdG9yOiAodmFsdWUpIC0+XHJcbiAgICBAaW5Qb3J0cyA9IChmb3IgaSBpbiBbMC4uMV1cclxuICAgICAgcCA9IG5ldyBQb3J0KHRydWUsIGZhbHNlKVxyXG4gICAgICBwLmluZGV4ID0gaVxyXG4gICAgICBwXHJcbiAgICApXHJcbiAgICBcclxuICAgIEBpblBvcnRzWzBdLm9uIFwiY2hhbmdlXCIsIEBvbkNoYW5nZVxyXG5cclxuICAgIEBvdXRQb3J0cyA9IChmb3IgaSBpbiBbMF1cclxuICAgICAgcCA9IG5ldyBQb3J0KGZhbHNlLCB0cnVlKVxyXG4gICAgICBwLmluZGV4ID0gaVxyXG4gICAgICBwXHJcbiAgICApXHJcblxyXG4gICAgQGluUG9ydHNbMV0uc2V0VmFsdWUgdmFsdWVcclxuXHJcbiAgb25DaGFuZ2U6ID0+XHJcbiAgICBAb3V0UG9ydHNbMF0uc2V0VmFsdWUgIEBpblBvcnRzWzFdLmdldFZhbHVlKClcclxuXHJcbiAgICAjIHdhaXQgbmV4dCBpbnB1dFxyXG4gICAgKHAucmVjZWl2ZWQgPSBmYWxzZSkgZm9yIHAgaW4gQGluUG9ydHNcclxuXHJcbm1vZHVsZS5leHBvcnRzID0gTWVtb3J5RnVuY1xyXG4iLCJjb25mID0gcmVxdWlyZSBcIi4vY29uZmlnLmNvZmZlZVwiXHJcblxyXG5yb3VuZEdyaWQgPSAoeCkgLT4gXHJcbiAgTWF0aC5yb3VuZCh4IC8gY29uZi5ncmlkU2l6ZSkgKiBjb25mLmdyaWRTaXplXHJcblxyXG5jbGFzcyBQb2ludFxyXG4gIGNvbnN0cnVjdG9yOiAoeCwgeSkgLT5cclxuICAgIEB4ID0geFxyXG4gICAgQHkgPSB5XHJcblxyXG4gIGFkZDogKHYpIC0+XHJcbiAgICBpZiB2IGluc3RhbmNlb2YgUG9pbnRcclxuICAgICAgbmV3IFBvaW50KEB4ICsgdi54LCBAeSArIHYueSlcclxuICAgIGVsc2VcclxuICAgICAgbmV3IFBvaW50KEB4ICsgdiwgQHkgKyB2KVxyXG5cclxuICBzdWI6ICh2KSAtPlxyXG4gICAgaWYgdiBpbnN0YW5jZW9mIFBvaW50XHJcbiAgICAgIG5ldyBQb2ludChAeCAtIHYueCwgQHkgLSB2LnkpXHJcbiAgICBlbHNlXHJcbiAgICAgIG5ldyBQb2ludChAeCAtIHYsIEB5IC0gdilcclxuXHJcbiAgcm91bmRHcmlkOiAtPlxyXG4gICAgbmV3IFBvaW50KHJvdW5kR3JpZChAeCksIHJvdW5kR3JpZChAeSkpXHJcblxyXG4gIGNvcHlGcm9tOiAocG9pbnQpIC0+XHJcbiAgICBAeCA9IHBvaW50LnhcclxuICAgIEB5ID0gcG9pbnQueVxyXG5cclxuICBjb3B5OiAtPiBuZXcgUG9pbnQoQHgsIEB5KVxyXG5cclxubW9kdWxlLmV4cG9ydHMgPSBQb2ludCIsIlBvcnQgPSByZXF1aXJlIFwiLi9wb3J0LmNvZmZlZVwiXHJcblxyXG5jbGFzcyBQb2ludGVyRnVuY1xyXG4gIGNvbnN0cnVjdG9yOiAobWFjaGluZSwgYWN0aW9uUm91dGVyKSAtPlxyXG4gICAgQG1hY2hpbmUgPSBtYWNoaW5lXHJcbiAgICBAYWN0aW9uUm91dGVyID0gYWN0aW9uUm91dGVyXHJcblxyXG4gICAgQGluUG9ydHMgPSAoZm9yIGkgaW4gWzBdXHJcbiAgICAgIHAgPSBuZXcgUG9ydCh0cnVlLCBmYWxzZSlcclxuICAgICAgcC5pbmRleCA9IGlcclxuICAgICAgcC5vbiBcImNoYW5nZVwiLCBAdXBkYXRlTGlua1xyXG4gICAgICBwXHJcbiAgICApXHJcblxyXG4gICAgQG91dFBvcnRzID0gKGZvciBpIGluIFswXVxyXG4gICAgICBwID0gbmV3IFBvcnQoZmFsc2UsIHRydWUpXHJcbiAgICAgIHAuaW5kZXggPSBpXHJcbiAgICAgIHBcclxuICAgIClcclxuXHJcbiAgICBAcHJldklkID0gLTFcclxuXHJcbiAgdXBkYXRlTGluazogPT5cclxuICAgIHRvUG9ydElkID0gQG91dFBvcnRzWzBdLmlkXHJcblxyXG4gICAgaWYgQHByZXZJZCA+IDBcclxuICAgICAgQGFjdGlvblJvdXRlci5yZW1vdmVMaW5rIEBwcmV2SWQsIHRvUG9ydElkXHJcblxyXG4gICAgZnJvbUlkID0gQGluUG9ydHNbMF0uZ2V0VmFsdWUoKVxyXG4gICAgQGFjdGlvblJvdXRlci5hZGRMaW5rIGZyb21JZCwgdG9Qb3J0SWRcclxuXHJcbiAgICBAcHJldklkID0gQGluUG9ydHNbMF0uZ2V0VmFsdWUoKVxyXG5cclxubW9kdWxlLmV4cG9ydHMgPSBQb2ludGVyRnVuY1xyXG4iLCJjbGFzcyBQb3J0XHJcbiAgY29uc3RydWN0b3I6IChjYW5Xcml0ZSwgY2FuUmVhZCkgLT5cclxuICAgIEBjYW5Xcml0ZSA9IGNhbldyaXRlXHJcbiAgICBAY2FuUmVhZCA9IGNhblJlYWRcclxuICAgIEB2YWx1ZSA9IDBcclxuXHJcbiAgZ2V0VmFsdWU6ICh2KSAtPiBAdmFsdWVcclxuICBzZXRWYWx1ZTogKHYpIC0+IFxyXG4gICAgY2hhbmdlZCA9IEB2YWx1ZSBpc250IHZcclxuICAgIEB2YWx1ZSA9IHZcclxuICAgIEBkaXNwYXRjaEV2ZW50KFwiY2hhbmdlXCIpIGlmIGNoYW5nZWRcclxuICAgIEBcclxuXHJcbmNyZWF0ZWpzLkV2ZW50RGlzcGF0Y2hlci5pbml0aWFsaXplIFBvcnQucHJvdG90eXBlXHJcblxyXG5tb2R1bGUuZXhwb3J0cyA9IFBvcnRcclxuIiwiUG9pbnQgPSByZXF1aXJlIFwiLi9wb2ludC5jb2ZmZWVcIlxyXG5BY3Rpb25Sb3V0ZXIgPSByZXF1aXJlIFwiLi9hY3Rpb25fcm91dGVyLmNvZmZlZVwiXHJcblxyXG5mb3JlQ29sb3IgPSBcInJnYmEoMCwgMCwgMCwgMC40KVwiXHJcblxyXG5jbGFzcyBQb3J0VmlldyBleHRlbmRzIGNyZWF0ZWpzLkNvbnRhaW5lclxyXG4gIGNvbnN0cnVjdG9yOiAoZnJhbWUsIHBvcnQpIC0+XHJcbiAgICBzdXBlcigpXHJcbiAgICBAc2V0Qm91bmRzIDAsIDAsIGZyYW1lLndpZHRoLCBmcmFtZS5oZWlnaHRcclxuICAgIEB4ID0gZnJhbWUueFxyXG4gICAgQHkgPSBmcmFtZS55XHJcblxyXG4gICAgQGJhY2tncm91bmQgPSBuZXcgY3JlYXRlanMuU2hhcGVcclxuICAgIEBzZXRCYWNrZ3JvdW5kQ29sb3IgXCJyZ2IoMjQ1LCAyNDQsIDI0NClcIlxyXG4gICAgQGFkZENoaWxkIEBiYWNrZ3JvdW5kXHJcblxyXG4gICAgQHRleHQgPSBuZXcgY3JlYXRlanMuVGV4dCBcIlwiLCBcIjEycHggQ29uc29sYXNcIiwgZm9yZUNvbG9yXHJcbiAgICBAYWRkQ2hpbGQgQHRleHRcclxuXHJcbiAgICBpZFRleHQgPSBuZXcgY3JlYXRlanMuVGV4dCBcIlwiLCBcIjEycHggQ29uc29sYXNcIiwgXCJyZ2JhKDAsIDEyOCwgMCwgMC40KVwiXHJcbiAgICBpZFRleHQudGV4dCA9IFwiI3twb3J0LmlkfVwiXHJcbiAgICBpZFRleHQueSA9IDIwXHJcbiAgICBAYWRkQ2hpbGQgaWRUZXh0XHJcblxyXG4gICAgQG1vdXNlQ2hpbGRyZW4gPSBmYWxzZVxyXG4gICAgQHBvcnQgPSBwb3J0XHJcbiAgICBAc2V0VmFsdWUgcG9ydC5nZXRWYWx1ZSgpXHJcbiAgICBAcG9ydC5vbiBcImNoYW5nZVwiLCBAb25DaGFuZ2VcclxuXHJcbiAgICBAdWlFbmFibGVkID0gdHJ1ZVxyXG4gICAgbW91c2VCdXR0b24gPSAwXHJcblxyXG4gICAgQG9uIFwibW91c2Vkb3duXCIsIChlKSA9PlxyXG4gICAgICByZXR1cm4gdW5sZXNzIEB1aUVuYWJsZWRcclxuICAgICAgQGRyYWdnZWQgPSBmYWxzZVxyXG4gICAgICBtb3VzZUJ1dHRvbiA9IGUubmF0aXZlRXZlbnQuYnV0dG9uXHJcbiAgICAgIHJldHVybiBpZiBtb3VzZUJ1dHRvbiBpc250IDBcclxuICAgICAgQG9mZnNldCA9IG5ldyBjcmVhdGVqcy5Qb2ludCBAeCAtIGUuc3RhZ2VYLCBAeSAtIGUuc3RhZ2VZXHJcblxyXG4gICAgQG9uIFwicHJlc3Ntb3ZlXCIsIChlKSA9PlxyXG4gICAgICByZXR1cm4gdW5sZXNzIEB1aUVuYWJsZWRcclxuICAgICAgQGRyYWdnZWQgPSB0cnVlXHJcbiAgICAgIHJldHVybiBpZiBtb3VzZUJ1dHRvbiBpc250IDBcclxuICAgICAgQHggPSBlLnN0YWdlWCArIEBvZmZzZXQueFxyXG4gICAgICBAeSA9IGUuc3RhZ2VZICsgQG9mZnNldC55XHJcblxyXG4gICAgQG9uIFwiY2xpY2tcIiwgKGUpID0+XHJcbiAgICAgIHJldHVybiB1bmxlc3MgQHVpRW5hYmxlZFxyXG4gICAgICByZXR1cm4gaWYgQGRyYWdnZWRcclxuICAgICAgQGRyYWdnZWQgPSBmYWxzZVxyXG4gICAgICBzd2l0Y2ggZS5uYXRpdmVFdmVudC5idXR0b25cclxuICAgICAgICB3aGVuIDAgXHJcbiAgICAgICAgICBAcG9ydC5zZXRWYWx1ZSBAcG9ydC5nZXRWYWx1ZSgpICsgMVxyXG4gICAgICAgIHdoZW4gMVxyXG4gICAgICAgICAgQWN0aW9uUm91dGVyLmluc3RhbmNlLnJlbW92ZVBvcnQgQHBvcnQuaWRcclxuICAgICAgICB3aGVuIDJcclxuICAgICAgICAgIEBwb3J0LnNldFZhbHVlIEBwb3J0LmdldFZhbHVlKCkgLSAxXHJcblxyXG4gICAgQG9uIFwiZGJsY2xpY2tcIiwgPT5cclxuXHJcbiAgc2V0QmFja2dyb3VuZENvbG9yOiAoY29sb3IpIC0+XHJcbiAgICBiID0gQGdldEJvdW5kcygpXHJcbiAgICBAYmFja2dyb3VuZC5ncmFwaGljc1xyXG4gICAgICAuc2V0U3Ryb2tlU3R5bGUgMVxyXG4gICAgICAuYmVnaW5TdHJva2UgZm9yZUNvbG9yXHJcbiAgICAgIC5iZWdpbkZpbGwgY29sb3JcclxuICAgICAgLmRyYXdSZWN0IDAsIDAsIGIud2lkdGgsIGIuaGVpZ2h0XHJcblxyXG4gIG9uQ2hhbmdlOiAoZSkgPT5cclxuICAgIEBzZXRWYWx1ZSBlLnRhcmdldC5nZXRWYWx1ZSgpXHJcblxyXG4gIHNldFZhbHVlOiAodikgPT5cclxuICAgIEB0ZXh0LnRleHQgPSBcIiN7dn1cIlxyXG4gICAgQGhpZ2hsaWdodCgpXHJcblxyXG4gIGhpZ2hsaWdodDogPT5cclxuICAgIGIgPSBAZ2V0Qm91bmRzKClcclxuICAgIHJlY3QgPSBuZXcgY3JlYXRlanMuU2hhcGUobmV3IGNyZWF0ZWpzLkdyYXBoaWNzKClcclxuICAgICAgLmJlZ2luRmlsbCBcInJnYmEoMjU1LCAwLCAwLCAwLjIpXCJcclxuICAgICAgLmRyYXdSZWN0IGIueCwgYi55LCBiLndpZHRoLCBiLmhlaWdodFxyXG4gICAgKVxyXG4gICAgQGFkZENoaWxkIHJlY3RcclxuICAgIGNyZWF0ZWpzLlR3ZWVuLmdldCByZWN0XHJcbiAgICAgIC50byB7IGFscGhhOiAwIH0sIDUwMCwgY3JlYXRlanMuRWFzZS5nZXRQb3dJbk91dCgyKVxyXG4gICAgICAuY2FsbCAoZSkgPT4gQHJlbW92ZUNoaWxkIGUudGFyZ2V0XHJcblxyXG5tb2R1bGUuZXhwb3J0cyA9IFBvcnRWaWV3XHJcbiIsImNvbmYgPSByZXF1aXJlIFwiLi9jb25maWcuY29mZmVlXCJcclxuUG9pbnQgPSByZXF1aXJlIFwiLi9wb2ludC5jb2ZmZWVcIlxyXG5TaXplID0gcmVxdWlyZSBcIi4vc2l6ZS5jb2ZmZWVcIlxyXG5cclxuY2xhc3MgUmVjdFxyXG4gIGNvbnN0cnVjdG9yOiAoeCwgeSwgd2lkdGgsIGhlaWdodCkgLT5cclxuICAgIEB4ID0geFxyXG4gICAgQHkgPSB5XHJcbiAgICBAd2lkdGggPSB3aWR0aFxyXG4gICAgQGhlaWdodCA9IGhlaWdodFxyXG4gICAgQG5vcm1hbGl6ZSgpXHJcblxyXG4gIHBvaW50OiAtPiBuZXcgUG9pbnQoQHgsIEB5KVxyXG4gIHNpemU6IC0+IG5ldyBTaXplKEB3aWR0aCwgQGhlaWdodClcclxuXHJcbiAgQGZyb21Qb2ludCA9IChwb2ludCwgc2l6ZSkgLT5cclxuICAgIG5ldyBSZWN0KHBvaW50LngsIHBvaW50LnksIHNpemUud2lkdGgsIHNpemUuaGVpZ2h0KVxyXG5cclxuICBpbnNldDogKGR4LCBkeSkgLT5cclxuICAgIG5ldyBSZWN0KEB4ICsgZHgsIEB5ICsgZHksIEB3aWR0aCAtIGR4ICogMiwgQGhlaWdodCAtIGR5ICogMilcclxuXHJcbiAgY29udGFpbnM6IChwb2ludCkgLT5cclxuICAgIChwb2ludC54ID49IEB4IGFuZFxyXG4gICAgIHBvaW50LnkgPj0gQHkgYW5kXHJcbiAgICAgcG9pbnQueCA8PSBAeCArIEB3aWR0aCBhbmRcclxuICAgICBwb2ludC55IDw9IEB5ICsgQGhlaWdodClcclxuXHJcbiAgc2V0UG9pbnQ6IChwb2ludCkgLT5cclxuICAgIEB4ID0gcG9pbnQueFxyXG4gICAgQHkgPSBwb2ludC55XHJcblxyXG4gIHNldFNpemU6IChzaXplKSAtPlxyXG4gICAgQHdpZHRoID0gc2l6ZS53aWR0aFxyXG4gICAgQGhlaWdodCA9IHNpemUuaGVpZ2h0XHJcbiAgICBAbm9ybWFsaXplKClcclxuXHJcbiAgbm9ybWFsaXplOiAtPlxyXG4gICAgaWYgQHdpZHRoIDwgMFxyXG4gICAgICBAeCArPSBAd2lkdGhcclxuICAgICAgQHdpZHRoICo9IC0xXHJcblxyXG4gICAgaWYgQGhlaWdodCA8IDBcclxuICAgICAgQHkgKz0gQGhlaWdodFxyXG4gICAgICBAaGVpZ2h0ICo9IC0xXHJcblxyXG4gICAgaWYgQHdpZHRoIGlzIDBcclxuICAgICAgQHdpZHRoID0gY29uZi5ncmlkU2l6ZVxyXG5cclxuICAgIGlmIEBoZWlnaHQgaXMgMFxyXG4gICAgICBAaGVpZ2h0ID0gY29uZi5ncmlkU2l6ZVxyXG5cclxubW9kdWxlLmV4cG9ydHMgPSBSZWN0XHJcbiIsImNsYXNzIFNpemVcclxuICBjb25zdHJ1Y3RvcjogKHdpZHRoLCBoZWlnaHQpIC0+XHJcbiAgICBAd2lkdGggPSB3aWR0aFxyXG4gICAgQGhlaWdodCA9IGhlaWdodFxyXG5cclxuICBAZnJvbVBvaW50ID0gKHBvaW50KSAtPlxyXG4gICAgbmV3IFNpemUocG9pbnQueCwgcG9pbnQueSlcclxuXHJcbm1vZHVsZS5leHBvcnRzID0gU2l6ZSIsIlBvcnRWaWV3ID0gcmVxdWlyZSBcIi4vcG9ydF92aWV3LmNvZmZlZVwiXHJcbkZ1bmNWaWV3ID0gcmVxdWlyZSBcIi4vZnVuY192aWV3LmNvZmZlZVwiXHJcbkxpbmtWaWV3ID0gcmVxdWlyZSBcIi4vbGlua192aWV3LmNvZmZlZVwiXHJcbmNvbmYgPSByZXF1aXJlIFwiLi9jb25maWcuY29mZmVlXCJcclxuXHJcbmNsYXNzIFZpZXdDb250cm9sbGVyXHJcbiAgY29uc3RydWN0b3I6IC0+XHJcbiAgICBAdmlldyA9IG5ldyBjcmVhdGVqcy5Db250YWluZXIoKVxyXG4gICAgQHBvcnRWaWV3cyA9IHt9XHJcbiAgICBAZnVuY1ZpZXdzID0ge31cclxuICAgIEBsaW5rVmlld3MgPSBbXVxyXG5cclxuICBwb3J0Vmlld0ZvclBvcnQ6IChwb3J0KSA9PlxyXG4gICAgaWYgcG9ydC5mdW5jSWQ/XHJcbiAgICAgIHYgPSBAZnVuY1ZpZXdzW3BvcnQuZnVuY0lkXVxyXG4gICAgICBpZiBwb3J0LmNhbldyaXRlXHJcbiAgICAgICAgcmV0dXJuIHYuaW5Qb3J0Vmlld3NbcG9ydC5pbmRleF1cclxuICAgICAgaWYgcG9ydC5jYW5SZWFkXHJcbiAgICAgICAgcmV0dXJuIHYub3V0UG9ydFZpZXdzW3BvcnQuaW5kZXhdXHJcbiAgICBlbHNlXHJcbiAgICAgIHJldHVybiBAcG9ydFZpZXdzW3BvcnQuaWRdXHJcblxyXG4gIG9uUG9ydFZhbHVlQ2hhbmdlZDogKGUpID0+XHJcbiAgICBwb3J0ID0gZS50YXJnZXRcclxuICAgIHB2ID0gQHBvcnRWaWV3Rm9yUG9ydChwb3J0KVxyXG4gICAgcHYuc2V0VmFsdWUgcG9ydC5nZXRWYWx1ZSgpXHJcblxyXG4gIG9uUG9ydENyZWF0ZWQ6IChwb3J0SWQsIHBvcnQsIHBvcykgPT5cclxuICAgIGZyYW1lID0gXHJcbiAgICAgIHg6IHBvcy54XHJcbiAgICAgIHk6IHBvcy55XHJcbiAgICAgIHdpZHRoOiBjb25mLmdyaWRTaXplXHJcbiAgICAgIGhlaWdodDogY29uZi5ncmlkU2l6ZVxyXG4gICAgdiA9IG5ldyBQb3J0VmlldyBmcmFtZSwgcG9ydFxyXG4gICAgQHBvcnRWaWV3c1twb3J0SWRdID0gdlxyXG4gICAgQHZpZXcuYWRkQ2hpbGQgdlxyXG5cclxuICBvblBvcnRSZW1vdmVkOiAocG9ydElkKSAtPlxyXG4gICAgdiA9IEBwb3J0Vmlld3NbcG9ydElkXVxyXG4gICAgZGVsZXRlIEBwb3J0Vmlld3NbcG9ydElkXVxyXG4gICAgQHZpZXcucmVtb3ZlQ2hpbGQgdlxyXG5cclxuICBvbkZ1bmNDcmVhdGVkOiAoZnVuY0lkLCBmdW5jLCBwb3MsIG5hbWUpID0+XHJcbiAgICB2ID0gbmV3IEZ1bmNWaWV3IGZ1bmMuaW5Qb3J0cywgZnVuYy5vdXRQb3J0cywgbmFtZVxyXG4gICAgdi54ID0gcG9zLnhcclxuICAgIHYueSA9IHBvcy55XHJcbiAgICBAZnVuY1ZpZXdzW2Z1bmNJZF0gPSB2XHJcbiAgICBAdmlldy5hZGRDaGlsZCB2XHJcblxyXG4gIG9uRnVuY1JlbW92ZWQ6IChmdW5jSWQpIC0+XHJcbiAgICB2ID0gQGZ1bmNWaWV3c1tmdW5jSWRdXHJcbiAgICBkZWxldGUgQGZ1bmNWaWV3c1tmdW5jSWRdXHJcbiAgICBAdmlldy5yZW1vdmVDaGlsZCB2XHJcblxyXG4gIG9uTGlua0NyZWF0ZWQ6IChmcm9tUG9ydCwgdG9Qb3J0KSA9PlxyXG4gICAgZnJvbVBWID0gQHBvcnRWaWV3Rm9yUG9ydCBmcm9tUG9ydFxyXG4gICAgdG9QViA9IEBwb3J0Vmlld0ZvclBvcnQgdG9Qb3J0XHJcbiAgICB2ID0gbmV3IExpbmtWaWV3IGZyb21QViwgdG9QVlxyXG4gICAgQHZpZXcuYWRkQ2hpbGQgdlxyXG4gICAgQGxpbmtWaWV3cy5wdXNoIHZcclxuXHJcbiAgb25MaW5rUmVtb3ZlZDogKGZyb21Qb3J0SWQsIHRvUG9ydElkKSA9PlxyXG4gICAgZm9yIHYgaW4gQGxpbmtWaWV3c1xyXG4gICAgICBpZiB2LmZyb21Qb3J0Vmlldy5wb3J0LmlkIGlzIGZyb21Qb3J0SWQgYW5kIHYudG9Qb3J0Vmlldy5wb3J0LmlkIGlzIHRvUG9ydElkXHJcbiAgICAgICAgQGxpbmtWaWV3cyA9IF8ucmVqZWN0IEBsaW5rVmlld3MsIChsKSAtPiBsIGlzIHZcclxuICAgICAgICBAdmlldy5yZW1vdmVDaGlsZCB2XHJcblxyXG5tb2R1bGUuZXhwb3J0cyA9IFZpZXdDb250cm9sbGVyXHJcbiJdfQ==

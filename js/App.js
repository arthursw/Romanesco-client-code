var Utils, baseUrl, libs, parameters, prefix;

Utils = {};

Utils.URL = {};

Utils.URL.getParameters = function(hash) {
  var parameters, re, tokens;
  hash = hash.replace('#', '');
  parameters = {};
  re = /[?&]?([^=]+)=([^&]*)/g;
  while (tokens = re.exec(hash)) {
    parameters[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
  }
  return parameters;
};

Utils.URL.setParameters = function(parameters) {
  var hash, name, value;
  hash = '';
  for (name in parameters) {
    value = parameters[name];
    hash += '&' + name + "=" + value;
  }
  hash = hash.replace('&', '');
  return hash;
};

window.Utils = Utils;

window.R = {};

window.P = {};

R.DajaxiceXMLHttpRequest = window.XMLHttpRequest;

window.XMLHttpRequest = window.RXMLHttpRequest;

libs = '../../libs/';

parameters = Utils.URL.getParameters(document.location.hash);

window.R.repository = {
  owner: 'arthursw',
  commit: null
};

if ((parameters['repository-owner'] != null) && (parameters['repository-commit'] != null)) {
  prefix = parameters['repository-use-cdn'] != null ? '//cdn.' : '//';
  baseUrl = prefix + 'rawgit.com/' + parameters['repository-owner'] + '/romanesco-client-code/' + parameters['repository-commit'] + '/js';
  window.R.repository = {
    owner: parameters['repository-owner'],
    commit: parameters['repository-commit']
  };
  libs = location.origin + '/static/libs/';
} else {
  baseUrl = '../static/romanesco-client-code/js';
}

requirejs.config({
  baseUrl: baseUrl,
  paths: {
    'domReady': ['//cdnjs.cloudflare.com/ajax/libs/require-domReady/2.0.1/domReady.min', libs + 'domReady'],
    'ace': ['//cdnjs.cloudflare.com/ajax/libs/ace/1.1.9/', libs + 'ace/src-min-noconflict/'],
    'underscore': ['//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min', libs + 'underscore-min'],
    'jquery': ['//code.jquery.com/jquery-2.1.3.min', 'libs/jquery-2.1.3.min'],
    'jqueryUi': ['//code.jquery.com/ui/1.11.4/jquery-ui.min', libs + 'jquery-ui.min'],
    'mousewheel': ['//cdnjs.cloudflare.com/ajax/libs/jquery-mousewheel/3.1.12/jquery.mousewheel.min', libs + 'jquery.mousewheel.min'],
    'scrollbar': ['//cdnjs.cloudflare.com/ajax/libs/malihu-custom-scrollbar-plugin/3.0.8/jquery.mCustomScrollbar.min', libs + 'jquery.mCustomScrollbar.min'],
    'tinycolor': ['//cdnjs.cloudflare.com/ajax/libs/tinycolor/1.1.2/tinycolor.min', libs + 'tinycolor.min'],
    'prefix': ['//cdnjs.cloudflare.com/ajax/libs/prefixfree/1.0.7/prefixfree.min'],
    'bootstrap': ['//maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min', libs + 'bootstrap.min'],
    'paper': ['//cdnjs.cloudflare.com/ajax/libs/paper.js/0.9.22/paper-full', libs + 'paper-full'],
    'gui': ['//cdnjs.cloudflare.com/ajax/libs/dat-gui/0.5/dat.gui', libs + 'dat.gui.min'],
    'typeahead': ['//cdnjs.cloudflare.com/ajax/libs/typeahead.js/0.10.4/typeahead.bundle.min', libs + 'typeahead.bundle.min'],
    'howler': ['//cdnjs.cloudflare.com/ajax/libs/howler/1.1.26/howler.min', libs + 'howler'],
    'spin': ['//cdnjs.cloudflare.com/ajax/libs/spin.js/2.0.1/spin.min', libs + 'spin.min'],
    'pinit': ['//assets.pinterest.com/js/pinit', libs + 'pinit'],
    'table': ['//cdnjs.cloudflare.com/ajax/libs/bootstrap-table/1.8.1/bootstrap-table.min', libs + 'table/bootstrap-table.min'],
    'zeroClipboard': ['//cdnjs.cloudflare.com/ajax/libs/zeroclipboard/2.2.0/ZeroClipboard.min', libs + 'ZeroClipboard.min'],
    'aceDiff': libs + 'ace-diff.min',
    'colorpickersliders': libs + 'bootstrap-colorpickersliders/bootstrap.colorpickersliders.nocielch',
    'requestAnimationFrame': libs + 'RequestAnimationFrame',
    'coffee': libs + 'coffee-script',
    'tween': libs + 'tween.min',
    'socketio': libs + 'socket.io',
    'oembed': libs + 'jquery.oembed',
    'jqtree': libs + 'jqtree/tree.jquery',
    'js-cookie': libs + 'js.cookie',
    'octokat': libs + 'octokat'
  },
  shim: {
    'oembed': ['jquery'],
    'mousewheel': ['jquery'],
    'scrollbar': ['jquery'],
    'jqueryUi': ['jquery'],
    'bootstrap': ['jquery'],
    'typeahead': ['jquery'],
    'js-cookie': ['jquery'],
    'jqtree': ['jquery'],
    'aceDiff': ['jquery', 'ace'],
    'colorpickersliders': {
      deps: ['jquery', 'tinycolor']
    },
    'underscore': {
      exports: '_'
    },
    'jquery': {
      exports: '$'
    }
  }
});

requirejs(['Main']);

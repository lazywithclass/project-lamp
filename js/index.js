var prelude = "module Main where\n" +
    "import Prelude\n" +
    "import Data.Foldable (fold)\n" +
    "import Data.Int\n" +
    "import Control.Monad.Eff.Console (logShow)\n" +
    "import TryPureScript\n" +
    "-- needed to have undefined\n" +
    "import Unsafe.Coerce (unsafeCoerce)\n" +
    "undefined :: forall a. a\n" +
    "undefined = unsafeCoerce unit\n" +
    "\n";

function createEditor(element) {
  var editor = ace.edit(element);
  editor.getSession().setMode("ace/mode/haskell");
  editor.setHighlightActiveLine(false);
  editor.commands.addCommand({
    name: 'evaluate',
    bindKey: {win: 'Ctrl-Enter'},
    exec: function(editor) {
      evaluate(editor);
    },
    readOnly: true // false if this command should not apply in readOnly mode
  });
  element.style.fontSize='16px';
  return editor
}

function getAllSources() {
  var sources = []
  $('.js-editor').each(function() {
    var editor = ace.edit(this)
    sources.push(editor.getValue())
    sources.push('')
  });

  return sources.join('\n')
}

function evaluate(editor) {
  editor.container.nextSibling.nextSibling.innerHTML = ''
  console.log(prelude + getAllSources())
  $.ajax({
    url: 'https://compile.purescript.org/try/compile',
    dataType: 'json',
    data: prelude + getAllSources(),
    method: 'POST',
    contentType: 'text/plain',
    success: function(res) {
      if (res.error) {
        var error = res.error;
        editor.container.nextSibling.nextSibling.innerHTML = error.contents[0].message
      } else {
        // this could be done once
        $.get('https://compile.purescript.org/try/bundle').done(function(bundle) {
          var replaced = res.js.replace(/require\("[^"]*"\)/g, function(s) {
            return"PS['" + s.substring(12, s.length - 2) + "']";
          });
          var wrapped =
              [ 'window.module = {};',
                '(function(module) {',
                replaced,
                '})(module);',
                'module.exports.main && module.exports.main();',
              ].join('\n');
          var scripts = [bundle, wrapped].join("\n");
          eval(scripts)
        })
      }
    }
  })
}

var prelude = "module Main where\n" +
    "\n" +
    "import Prelude\n" +
    "import Data.Foldable (fold)\n" +
    "import Data.Int\n" +
    "import Control.Monad.Eff.Console (logShow)\n" +
    "import TryPureScript\n" +
    "import Test.QuickCheck (class Arbitrary, quickCheck)\n" +
    "import Test.QuickCheck.Gen (chooseInt)\n" +
    "import Unsafe.Coerce (unsafeCoerce)\n" +
    "\n" +
    "undefined :: forall a. a\n" +
    "undefined = unsafeCoerce unit\n" +
    "\n" +
    "derive instance eqNat :: Eq Nat\n" +
    "instance arbNat :: Arbitrary Nat where\n" +
    "  arbitrary = do\n" +
    "    x <- chooseInt 0 (500)\n" +
    "    pure $ fromInt x\n" +
    "\n" +
    "fromInt :: Int -> Nat\n" +
    "fromInt x | x <= 0 = Zero\n" +
    "fromInt x = Add1 $ fromInt (x-1)\n" +
    "\n" +
    "plusId :: Nat -> Boolean\n" +
    "plusId n = n `plusFold` Zero == n\n" +
    "\n" +
    "timesId :: Nat -> Boolean\n" +
    "timesId n = n `timesFold` (Add1 Zero) == n\n" +
    "\n" +
    "powId :: Nat -> Boolean\n" +
    "powId n = n `pow` (Add1 Zero) == n\n" +
    "main = do quickCheck plusId\n" +
    "\n";

function createEditor(element) {
  var editor = ace.edit(element);
  editor.getSession().setMode("ace/mode/haskell");
  editor.setHighlightActiveLine(false);
  editor.commands.addCommand({
    name: 'evaluate',
    bindKey: {win: 'Ctrl-Enter', mac: 'Command-Enter'},
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
  $.ajax({
    url: 'https://compile.purescript.org/try/compile',
    dataType: 'json',
    data: prelude + getAllSources(),
    method: 'POST',
    contentType: 'text/plain',
    success: function(res) {
      var identifier = $(editor.container).data('identifier');
      if (res.error) {
        $('p.js-results.' + identifier).html(res.error.contents[0].message)
        $('img.js-nok.' + identifier).show()
      } else {

        var consoleLogRef = console.log
        window.console.log = function(result) {
          if (result === '100/100 test(s) passed.') {
            $('p.js-results.' + identifier).html('')
            $('img.js-nok.' + identifier).hide()
            $('img.js-ok.' + identifier).show()
          }
        }

        // TODO this could be done once
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

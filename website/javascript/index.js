function evaluate(editor) {
  let collector = pageCode()

  compile(getAllSources(collector), function(res) {
    var identifier = $(editor.container).data('identifier');
    if (res.error) {
      $('p.js-errors.' + identifier).html(res.error.contents[0].message)
    } else {
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
      eval(wrapped)
    }
  })
}

$(() => {
  console.log('oh hai!')

  $('.js-editor').each(function() {
    let editor = createEditor(this)
    editor.getSession().on('change', (e) => {
      let newLines = editor.getValue().split('\n').length
      $(this).css('height', (23 * (newLines - (newLines / 23))).toString())
      editor.resize()
    });
  });

  $('.js-test').click((event) => {
    var $target = $(event.target), identifier = $target.data('identifier')
    clearFeedbacks()
    let snippet = pageCode()
    getAllSources(snippet)
    snippet(`main = quickCheck $ ${identifier}`)
    compile(snippet(), (result) => {
      if (result.erorr) {
        $(`.js-errors.${identifier}`)
          .html(result.error.contents[0].message)
      } else {
        var replaced = result.js.replace(/require\("[^"]*"\)/g, function(s) {
          return"PS['" + s.substring(12, s.length - 2) + "']";
        });
        var wrapped =
            [ 'window.module = {};',
              '(function(module) {',
              replaced,
              '})(module);',
              'module.exports.main && module.exports.main();',
            ].join('\n');
        overrideConsole(`.js-results.${identifier}`)
        eval(wrapped)
        restoreConsole()
      }
    })
  })

  $('.js-go').click((event) => {
    var $target = $(event.target), identifier = $target.data('identifier')
    clearFeedbacks()
    let snippet = pageCode()
    getAllSources(snippet)
    snippet('main = logShow $ ' + $(`.js-console.${identifier}`).val()) // here
    compile(snippet(), (result) => {
      if (result.error) {
        $(`.js-errors.${identifier}`)
          .html(result.error.contents[0].message)
      } else {
        var replaced = result.js.replace(/require\("[^"]*"\)/g, function(s) {
          return"PS['" + s.substring(12, s.length - 2) + "']";
        });
        var wrapped =
            [ 'window.module = {};',
              '(function(module) {',
              replaced,
              '})(module);',
              'module.exports.main && module.exports.main();',
            ].join('\n');
        overrideConsole(`.js-results.${identifier}`)
        eval(wrapped)
        restoreConsole()
      }
    })
  })

  $('.js-console').keypress(function (e) {
    var key = e.which
    if (key == 13) {
      $(e.target).next('.js-go').click()
    }
  })
})

function pageCode() {
  let all = 'module Main where\n' +
      '\n' +
      'import Prelude\n' +
      'import Data.Foldable (fold)\n' +
      'import Data.Int\n' +
      'import Data.Tuple\n' +
      'import Data.List\n' +
      'import Data.Maybe\n' +
      'import Control.Monad.Eff.Console (logShow)\n' +
      'import Control.Monad.Eff.Exception.Unsafe\n' +
      'import TryPureScript\n' +
      'import Test.QuickCheck (class Arbitrary, quickCheck)\n' +
      'import Test.QuickCheck.Gen (chooseInt)\n' +
      'import Unsafe.Coerce (unsafeCoerce)\n' +
      '\n' +
      'undefined :: forall a. a\n' +
      'undefined = unsafeCoerce unit\n' +
      '\n' +
      'error :: forall a. String -> a\n' +
      'error = unsafeThrow\n' +
      '\n' 

  return (snippet) => {
    if (snippet == null) snippet = '\n'
    all = all.concat(snippet).concat('\n')
    return all
  }
}

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

function getAllSources(collector) {
  $('.js-editor').each(function() {
    var editor = ace.edit(this)
    collector(editor.getValue())
  });
  return collector()
}

function clearFeedbacks() {
  $('.js-ok').hide()
  $('.js-nok').hide()
  $('.js-errors').html('')
  $('.js-results').html('')
}

function compile(sources, success, failure) {
  clearFeedbacks()
  $.ajax({
    url: 'https://compile.purescript.org/try/compile',
    dataType: 'json',
    data: sources,
    method: 'POST',
    contentType: 'text/plain',
    success: success
  })
}

var consoleRef = window.console
function overrideConsole(selector) {
  window.console.log = function() {
    var args = [].slice.call(arguments)
    $(selector).html(args.join('\n'));
  }
}

function restoreConsole() {
  window.console = consoleRef
}

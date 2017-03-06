$(function() {
  console.log('oh hai!')

  $('.js-editor').each(function() {
    createEditor(this)
  });
});

function pageCode() {
  let all = 'module Main where\n' +
      '\n' +
      'import Prelude\n' +
      'import Data.Foldable (fold)\n' +
      'import Data.Int\n' +
      'import Data.Tuple\n' +
      'import Data.List\n' +
      'import Control.Monad.Eff.Console (logShow)\n' +
      'import TryPureScript\n' +
      'import Test.QuickCheck (class Arbitrary, quickCheck)\n' +
      'import Test.QuickCheck.Gen (chooseInt)\n' +
      'import Unsafe.Coerce (unsafeCoerce)\n' +
      '\n' +
      // 'undefined :: forall a. a\n' +
      // 'undefined = unsafeCoerce unit\n' +
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

function generateUuid() { 
  var d = new Date().getTime();
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    var r = (d + Math.random() * 16) % 16 | 0;
    d = Math.floor(d / 16);
    return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
  });
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

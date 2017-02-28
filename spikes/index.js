function pageCode() {
  let all = 'module Main where\n' +
      '\n' +
      'import Prelude\n' +
      'import Data.Foldable (fold)\n' +
      'import Data.Int\n' +
      'import Control.Monad.Eff.Console (logShow)\n' +
      'import TryPureScript\n' +
      'import Test.QuickCheck (class Arbitrary, quickCheck)\n' +
      'import Test.QuickCheck.Gen (chooseInt)\n' +
      'import Unsafe.Coerce (unsafeCoerce)\n' +
      '\n'

  return (snippet) => {
    if (snippet == null) snippet = '\n'
    all = all.concat(snippet).concat('\n')
    return all
  }
}

function compile(sources, success, failure) {
  $.ajax({
    url: 'https://compile.purescript.org/try/compile',
    dataType: 'json',
    data: sources,
    method: 'POST',
    contentType: 'text/plain',
    success: success
  })
}

function addToMain(expression, selector, callback) {

}

function bundle(js, success) {
  var replaced = js.replace(/require\("[^"]*"\)/g, function(s) {
    return"PS['" + s.substring(12, s.length - 2) + "']";
  });
  var wrapped = [
    'window.module = {};',
    '(function(module) {',
    replaced,
    '})(module);',
    'module.exports.main && module.exports.main();',
  ].join('\n');
  success(wrapped)
}

$(() => {
  console.log('oh hai')


  window.console.log = function() {
    window.alert(JSON.stringify(arguments))
  }
  
  $('.js-go').click(() => {
    let snippet = pageCode()
    snippet('main = logShow $ ' + $('.js-console').val())
    compile(snippet(), (result) => {
      if (result.error) {
        $('.js-errors').html(result.error.contents[0].message)
      } else {
        bundle(result.js, (scripts) => {
          console.log(scripts)
          eval(scripts)
        })
      }
    })
  })

  // $('.js-go').click(() => {
  //   let snippet = pageCode()
  //   snippet($('.js-code').val())
  //   compile(snippet(), (result) => {
  //     if (result.error) {
  //       $('.js-errors').html(result.error.contents[0].message)
  //     } else {
  //       bundle(result.js, (scripts) => {
  //         console.log(scripts)



  //         eval(scripts)
  //       })
  //     }
  //   })
  // })

})

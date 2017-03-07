/***

Deprecated?

***/

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
  $('.js-go').click((event) => {
    var $target = $(event.target)
    clearFeedbacks()
    let snippet = pageCode()
    getAllSources(snippet)
    snippet('main = logShow $ ' + $('.js-console').val())
    compile(snippet(), (result) => {
      if (result.error) {
        $('.js-errors.' + $target.data('identifier'))
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
        overrideConsole('.js-results.' + $target.data('identifier'))
        eval(wrapped)
        restoreConsole()
      }
    })
  })
})

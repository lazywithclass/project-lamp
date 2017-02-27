function evaluate(editor) {
  let collector = pageCode()
  collector("derive instance eqNat :: Eq Nat\n" +
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
            "powId n = n `powFold` (Add1 Zero) == n\n" +
            "\n")
  clearFeedbacks()

  compile(getAllSources(collector), function(res) {
    var identifier = $(editor.container).data('identifier');
    if (res.error) {
      $('p.js-results.' + identifier).html(res.error.contents[0].message)
      $('img.js-ok.' + identifier).hide()
      $('img.js-nok.' + identifier).show()
    } else {
      // TODO this could be done once
      $.get('https://compile.purescript.org/try/bundle').done(function(bundle) {
        var replaced = res.js.replace(/require\("[^"]*"\)/g, function(s) {
          return"PS['" + s.substring(12, s.length - 2) + "']";
        });
        var wrapped =
            [ 'window.module = {};',
              '(function(module) {',
              replaced,
              'window.quickCheckUtil = Test_QuickCheck.quickCheck(Test_QuickCheck.testableFunction(arbNat)(Test_QuickCheck.testableBoolean));',
              'window.plusId = plusId',
              'window.timesId = timesId',
              'window.powId = powId',
              '})(module);',
              'module.exports.main && module.exports.main();',
            ].join('\n');
        var scripts = [bundle, wrapped].join("\n");
        eval(scripts)

        try {
          window.quickCheckUtil(window.plusId)();
          $('.js-ok.plus-fold').show();
        } catch(e) {
          $('.js-nok.plus-fold').show();
        }

        try {
          window.quickCheckUtil(window.timesId)();
          $('.js-ok.times-fold').show();
        } catch(e) {
          $('.js-nok.times-fold').show();
        }

        try {
          window.quickCheckUtil(window.powId)();
          $('.js-ok.pow-fold').show();
        } catch(e) {
          $('.js-nok.pow-fold').show();
        }
      })
    }
  })
}

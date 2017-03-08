module Jekyll
  class Testable < Liquid::Tag
    #### usage
    # `testable` id#props#editor

    def count_lines(s)
      ans = 0
      len = s.length
      i   = 0
      while i < len
        ans += 1 if s[i].match(/\n/)
        i   += 1
      end
      return ans
    end

    def initialize(tag_name, text, tokens)
      super
      @text   = text.split('#')
      @id     = @text[0]                ## : Liquid::Token
      @props  = @text[1...2]
      @editor = @text[2...@text.length] ## : Array[Liquid::Token]
      @height = count_lines(@editor[0]) * 25
      if @height / 25 <= 5
        @height += 20
      end
    end

    def render(context)
      [ '<div class="js-editor hidden">',
        @props,
        '</div>',
        '<div class="js-editor" data-identifier="',
        @id,
        '" style="width: auto; height:',
        @height,
        'px;">', 
        @editor,
        '</div>',
        # js-console needs to have an identifier
        # + small loader
        '<p><input class="js-console"><button class="js-go">REPL</button></p>', 
        '<p>Your answer: <code class="js-results quicksort"></code>',
        '<code class="blinking-cursor">|</code></p>',
        '<p class="js-errors ',
        @id,
        '"></p>',
        '<img class="js-ok ',
        @id,
        '" src="../images/ok.png" />',
        '<img class="js-nok ',
        @id,
        '" src="../images/nok.png" />'
      ].join('')
    end
  end
end

Liquid::Template.register_tag('testable', Jekyll::Testable)

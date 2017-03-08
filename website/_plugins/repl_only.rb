module Jekyll
  class ReplOnly < Liquid::Tag
    #### usage
    # `repl_only` id#editor

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
      @editor = @text[1...@text.length] ## : Array[Liquid::Token]
      @height = count_lines(@editor[0]) * 25
      if @height / 25 <= 5
        @height += 20
      end

    end

    def render(context)
      [
        '<div class="js-editor" data-identifier="',
        @id,
        '" style="width: auto; height:',
        @height,
        'px;">',
        @editor,
        '</div>',
        '<p><input class="js-console ',
        @id,
        '"><button class="js-go" data-identifier="',
        @id,
        '">REPL</button></p>',
        '<p>Your answer: <code class="js-results ',
        @id,
        '"></code>',
        '<code class="blinking-cursor">|</code></p>',
        '<p class="js-errors ',
        @id,
        '"></p>'
      ].join('')
    end
  end
end

Liquid::Template.register_tag('repl_only', Jekyll::ReplOnly)

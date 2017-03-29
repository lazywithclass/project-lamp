module Jekyll
  class Testable < Liquid::Tag
    #### usage
    ###### `testable` id#props#editor
    # `testable` propname#props#editor
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
      @lines  = count_lines(@editor[0]) + 1
      @height = @lines * 21.33333396911621
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
        '<p><input class="js-console ',
        @id,
        '"><button class="js-go" data-identifier="',
        @id,
        '">EVAL</button> ',
        '<button class="js-test" data-identifier="',
        @id,
        '">TEST</button> ',
        '<br /><code>></code> ',
        '<code class="js-results ',
        @id,
        '"></code></p>',
        '<p class="js-errors ',
        @id,
        '"></p>'
      ].join('')
    end
  end
end

Liquid::Template.register_tag('testable', Jekyll::Testable)

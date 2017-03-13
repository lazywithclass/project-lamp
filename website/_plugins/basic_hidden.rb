module Jekyll
  class BasicHidden < Liquid::Tag
    #### usage
    # `basic` id#editor

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
        '<p class="js-errors ',
        @id,
        '"></p>'
      ].join('')
    end
  end
end

Liquid::Template.register_tag('basic_hidden', Jekyll::BasicHidden)

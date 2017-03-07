module Jekyll
  class Basic < Liquid::Tag
    #### usage
    # `basic` id#height#editor

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
      @editor = @text[1...@text.length] ## : Array
      @height = count_lines(@editor[0]) * 25
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
        '<p class="js-errors ',
        @id,
        '"></p>'
      ].join('')
    end
  end
end

Liquid::Template.register_tag('basic', Jekyll::Basic)

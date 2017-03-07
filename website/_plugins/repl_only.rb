module Jekyll
  class ReplOnly < Liquid::Tag
    #### usage
    # `basic` id#height#editor

    def initialize(tag_name, text, tokens)
      super
      @text   = text.split('#')
      @id     = @text[0]                ## : Liquid::Token
      @height = @text[1]                ## : Liquid::Token
      @editor = @text[2...@text.length] ## : Array
    end
    # lines * 25 = pixel height -- CAN'T MULTIPLY TOKENS!!
    # this works for now I guess
    def render(context)
      [
        '<div class="js-editor" data-identifier="',
        @id,
        '" style="width: auto; height:',
        @height,
        'px;">', 
        @editor,
        '</div>',
        '<p><input class="js-console"><button class="js-go">REPL</button></p>',
        '<p>Your answer: <code class="js-results quicksort"></code>',
        '<code class="blinking-cursor">|</code></p>',
        '<p class="js-errors ',
        @id,
        '"></p>'
      ].join('')
    end
  end
end

Liquid::Template.register_tag('repl_only', Jekyll::ReplOnly)

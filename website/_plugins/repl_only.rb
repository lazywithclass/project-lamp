module Jekyll
  class ReplOnly < Liquid::Tag

    def initialize(tag_name, text, tokens)
      # need to parse through text, so we can fix below
      super
      @text   = text.split('#')
      @id     = @text[0]
      @editor = @text[1...@text.length]
    end

    def render(context)
      [
        '<div class="js-editor" data-identifier="',
        @id,
        '" style="width: auto; height:150px;">',
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

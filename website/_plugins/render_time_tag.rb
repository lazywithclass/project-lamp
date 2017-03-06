module Jekyll
  class RenderTimeTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      # need to parse through text, so we can fix below
      super
      @text = text
    end

    def render(context)
      [
        '<div class="js-editor" data-identifier="quicksort" ',
        'style="width: auto; height:150px;">', # we can abstract this now
        @text,
        '</div>',
        '<p><input class="js-console"><button class="js-go">REPL</button></p>',
        '<p>Your answer: <code class="js-results quicksort"></code>',
        '<code class="blinking-cursor">|</code></p>',
        '<p class="js-errors quicksort"></p>' # need to pull out id
      ].join('')
    end
  end
end

Liquid::Template.register_tag('render_time', Jekyll::RenderTimeTag)


# '<input class="js-console"></input>' ,
# '<button class="js-go">REPL</button>' ,
# '<p class="js-errors quicksort"></p>' ,
# '<p>Your answer: <code class="js-results quicksort"></code>' ,
# '<code class="blinking-cursor">|</code></p>'

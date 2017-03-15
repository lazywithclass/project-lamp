# coding: utf-8
module Jekyll
  class Pagination < Liquid::Tag
    #### usage
    # `pagination` left#right

    def initialize(tag_name, text, tokens)
      super
      @text   = text.split('#')
      @left   = @text[0]
      @right  = @text[1]
    end

    def render(context)
      [
        '<div class="pagination">',
        "<a class=\"#{@left == '' ? 'hidden' : ''}\" href=\"http://project-lamp.org/#{@left}\">◀</a>",
        ' <a href="http://project-lamp.org/">◆</a> ',
        "<a class=\"#{@right == '' ? 'hidden' : ''}\" href=\"http://project-lamp.org/#{@right}\">▶</a>",
        '</div>'
      ].join('')
    end
  end
end

Liquid::Template.register_tag('pagination', Jekyll::Pagination)

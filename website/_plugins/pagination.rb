# coding: utf-8
module Jekyll
  class Pagination < Liquid::Tag
    #### usage
    # `pagination` leftChapId#rightChapId

    def initialize(tag_name, text, tokens)
      super
      @text   = text.split('#')
      @left   = @text[0] || ''
      @right  = @text[1] || ''
    end

    def render(context)
      [
        '<div class="pagination">',
        "<a class=\"#{@left == '' ? 'hidden' : ''}\" href=\"/#{@left}\">◀</a>",
        ' <a href="/">◆</a> ',
        "<a class=\"#{@right == '' ? 'hidden' : ''}\" href=\"/#{@right}\">▶</a>",
        '</div>'
      ].join('')
    end
  end
end

Liquid::Template.register_tag('pagination', Jekyll::Pagination)

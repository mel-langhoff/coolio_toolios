module ApplicationHelper
  def markdown(text)
    renderer = Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, extensions = {fenced_code_blocks: true, autolink: true, tables: true})
    markdown.render(text).html_safe
  end
end

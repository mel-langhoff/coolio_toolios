module ApplicationHelper

  def markdown(text)
  return "" if text.nil?

  html_renderer = Redcarpet::Render::HTML.new(
    filter_html: true,
    hard_wrap: true
  )

  redcarpet = Redcarpet::Markdown.new(
    html_renderer,
    fenced_code_blocks: true,
    autolink: true,
    tables: true
  )

  redcarpet.render(text.to_s).html_safe
end

  # def markdown(text)
  #   renderer = Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true)
  #   markdown = Redcarpet::Markdown.new(renderer, extensions = {fenced_code_blocks: true, autolink: true, tables: true})
  #   markdown.render(text).html_safe
  # end
end

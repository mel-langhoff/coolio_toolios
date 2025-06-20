require 'nokogiri'
class CompanyNameExtractorService
  def initialize(html)
    @doc = Nokogiri::HTML(html)
  end

  def extract
    from_meta || from_title
    # || fallback
  end

  private

  def from_meta
    @doc.at("meta[property='og:site_name']")&.[]('content')
  end

  def from_title
    title_text = @doc.at('title')&.text
    title_text[/at\s+([A-Z][\w\s&\-]+)/i, 1]
  end

  # def fallback
  #   "Unknown Company"
  # end
end

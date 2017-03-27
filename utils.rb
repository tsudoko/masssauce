require 'open-uri'

require 'nokogiri'

def find_images(url)
  r = open(url)
  return [url] if not r.meta['content-type'].downcase.start_with? 'text'

  html = Nokogiri.HTML(r.read, url)
  return html.css('meta[property="og:image"]').map { |elem| elem['content'] }
end

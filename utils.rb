require 'json'
require 'open-uri'
require 'uri'

require 'nokogiri'

module SauceNAO
  class Error < StandardError
  end

  BASE_URLS = {
    'pixiv_id' => 'http://pixiv.net/i/',
    'seiga_id' => 'http://seiga.nicovideo.jp/seiga/im',
    'danbooru_id' => 'https://danbooru.donmai.us/posts/',
    'gelbooru_id' => 'https://gelbooru.com/index.php?page=post&s=view&id=',
    'yandere_id' => 'https://yande.re/post/show/',
  }

  def self.search(url)
    params = {
      'db' => 999,
      'output_type' => 2,
      'url' => url,
    }

    r = open('https://saucenao.com/search.php?' + URI.encode_www_form(params))

    begin
      json = JSON.parse(r.read.sub(/[^{]*/, ''))
    rescue JSON::ParserError
      raise Error r.read
    end
  end
end

def find_images(url)
  r = open(url)
  return [url] if not r.meta['content-type'].downcase.start_with? 'text'

  html = Nokogiri.HTML(r.read, url)
  return html.css('meta[property="og:image"]').map { |elem| elem['content'] }
end

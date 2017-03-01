require 'json'
require 'open-uri'
require 'uri'

require 'nokogiri'

module SauceNAO
  class Error < StandardError
  end

  class RateLimit < Error
    attr_reader :duration

    def initialize(duration)
      @duration = duration
      super("Out of searches for #{timedelta_to_s duration}")
    end
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

    begin
      r = open('https://saucenao.com/search.php?' + URI.encode_www_form(params))
      json = JSON.parse(r.read.sub(/[^{]*/, ''))
    rescue OpenURI::HTTPError
      raise if json.nil?

      if json['header']['long_remaining'] >= 0
        raise RateLimit 60*60*24
      elsif json['header']['short_remaining'] >= 0
        raise RateLimit 30
      else
        raise
      end
    rescue JSON::ParserError
      raise Error r.read
    end
  end
end

def timedelta_to_s(s)
  result = ''

  m = s / 60
  h = m / 60
  d = h / 24

  s %= 60
  m %= 60
  h %= 24

  result += "#{d}d" unless d.zero?
  result += "#{h}h" unless h.zero?
  result += "#{m}m" unless m.zero?
  result += "#{s}s" unless s.zero?

  return result
end

def find_images(url)
  r = open(url)
  return [url] if not r.meta['content-type'].downcase.start_with? 'text'

  html = Nokogiri.HTML(r.read, url)
  return html.css('meta[property="og:image"]').map { |elem| elem['content'] }
end

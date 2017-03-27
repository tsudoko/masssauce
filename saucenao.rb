require 'json'
require 'open-uri'
require 'uri'

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

  def self.search(url, db: nil, dbmask: nil, dbmaski: nil)
    params = {
      'output_type' => 2,
      'url' => url,
    }

    params['db'] = db if not db.nil?
    params['dbmask'] = dbmask if not dbmask.nil?
    params['dbmaski'] = dbmaski if not dbmaski.nil?

    begin
      r = open('https://saucenao.com/search.php?' + URI.encode_www_form(params))
    rescue OpenURI::HTTPError => e
      content = e.io.read
      if content.empty?
        raise
      else
        raise Error.new(content)
      end
    end

    begin
      json = JSON.parse(r.read.sub(/[^{]*/, ''))
    rescue JSON::ParserError
      raise Error.new(r.read)
    end
  end
end

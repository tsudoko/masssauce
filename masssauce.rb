#!/usr/bin/env ruby
require 'sinatra'
require_relative './utils'
include ERB::Util

get '/' do
  erb :index
end

post '/' do
  @results = {}
  @errors = {}
  @nosauce = {}
  @notfound = []

  return erb(:index) if not params[:urls]

  params[:urls].split("\r\n").each do |url|
    begin
      images = find_images(url)
      if images.empty? then
        @notfound << url
        next
      end

      images.each do |img|
        s = SauceNAO.search(img)
        s['results'].each do |r|
          sim = r['header']['similarity']
          next if sim.to_f < params[:min_similarity].to_f

          urls = []
          ids = {}

          r['data'].each do |k, v|
            if SauceNAO::BASE_URLS.key? k then
              urls << SauceNAO::BASE_URLS[k] + v.to_s
            elsif k.end_with? '_id' and k != 'member_id' then
              ids[k] = v.to_s
            end
          end

          @results[url] = {} if not @results.key? url
          @results[url][img] = [] if not @results[url].key? img
          @results[url][img] << {:similarity => sim, :urls => urls, :ids => ids}
        end

        unless @results.key? url and @results[url].key? img then
          @nosauce[url] = [] if not @nosauce.key? url
          @nosauce[url] << img
        end
      end
    rescue StandardError => e
      @errors[url] = e
    end
  end

  erb :index
end

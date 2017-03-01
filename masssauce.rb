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

  params[:urls].split("\r\n").select { |x| not x.empty? }.each do |url|
    images = find_images(url)
    if images.empty? then
      @notfound << url
      next
    end

    images.each do |img|
      begin
        s = SauceNAO.search(img)
      rescue SauceNAO::RateLimit => e
        if e.duration > 30 then
          @errors[url] = e
        else
          STDERR.puts e
          STDERR.puts "Sleeping for #{utils.timedelta_to_s e.duration}"
          sleep e.duration
        end
      rescue StandardError => e
        @errors[url] = e
      end

      next if s.nil?

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
  end

  erb :index
end

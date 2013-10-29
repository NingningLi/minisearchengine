# -*- coding: utf-8 -*-
require "open-uri"
require "nokogiri"
require "rmmseg"
require 'set'
require "uri"

class Crawler
  #爬虫类
  RedisClient = Redis.new :host => "localhost", :port => 6379  
  RMMSeg::Dictionary.load_dictionaries

  def initialize(pages, depth=2)
    @begin_pages = pages 
    @depth = depth
  end
  
  def get_plain_text doc
    #从html文档中抽取出纯文本内容
    doc.css('script').each {|node| node.remove}
    doc.css('body').text.squeeze(" \n")
  end

  def separate_words text
    #将网页中的文字进行分词
    algor = RMMSeg::Algorithm.new(text)
    words = []
    loop do
      token = algor.next_token
      break if token.nil?
      words << token.text.force_encoding("UTF-8")
    end
    words
  end

  
  def add_to_index plain_url, doc
    #为每个网页建立索引，通过消息队列的方式实现
    RedisClient.rpush "page", {plain_url => separate_words(get_plain_text(doc))}.to_json
  end


  def add_link_ref url_from, url_to, link_text
    #添加一个网页到另一个网页的关联
  end
  
  def fetch_page page, new_pages
    #抽取单个页面中的所有链接
    p "Fetching Page: #{page}"
    begin; doc = Nokogiri::HTML(open(page))
    rescue Exception => e; p "fetching error: #{page}; message: #{e.message}"; return
    end
    add_to_index page, doc
    doc.css("a").each do |link|
      next if not link.attributes.include? "href" or link["href"] == "#"
      begin; url = URI::join(page, link["href"].split("#")[0]).to_s
      rescue; next; end
      new_pages.add(url) if url[0...4] == 'http'
      # link_text = get_plain_text link
      # add_link_ref page, url, link_text
    end
  end
  
  def crawl
    pages = @begin_pages
    @depth.times do |i|
      new_pages, threads = Set.new, []
      pages.each {|page| threads << Thread.new(page) {|url| fetch_page(url, new_pages) }}
      threads.each {|t| t.join }
      pages = new_pages
    end
  end

  def self.index_pages
    while page_entry=RedisClient.rpop("page")
      url, words = JSON.load(page_entry).first
      p "Indexing page: #{url}"
      Url.index url, words
    end
  end
end
  

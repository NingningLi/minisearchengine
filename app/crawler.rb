# -*- coding: utf-8 -*-
require "open-uri"
require "nokogiri"
require 'set'
require "uri"

class Crawler
  #爬虫类
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
    text.split(/\W/).select {|w| !w.strip.empty?}
  end

  
  def add_to_index plain_url, doc
    #为每个网页建立索引
    # return if Url.indexed? plain_url
    # Url.create(url: plain_url).index(separate_words(get_plain_text(doc)))
    p "Indexing page: #{plain_url}"
  end


  def add_link_ref url_from, url_to, link_text
    #添加一个网页到另一个网页的关联
  end
  
  def fetch_page page, new_pages
    #抽取单个页面中的所有链接
    begin; doc = Nokogiri::HTML(open(page))
    rescue Exception => e; p "fetching error: #{page}; message: #{e.message}"; return
    end
    add_to_index page, doc
    doc.css("a").each do |link|
      next if not link.attributes.include? "href" or link["href"] == "#"
      begin; url = URI::join(page, link["href"].split("#")[0]).to_s
      rescue; next; end
      new_pages.add(url) if url[0...4] == 'http' and not Url.indexed? url
      #需要手动释放链接，每个线程或者进程自己会hold一个数据库链接，并且始终不会释放，并且其他的线程需要用到，这就可以关闭掉数据库，不然如果线程多了会导致其他的线程没有数据库链接可以使用
      ActiveRecord::Base.connection.close
      # link_text = get_plain_text link
      # add_link_ref page, url, link_text
    end
  end
  
  def crawl
    pages = @begin_pages
    @depth.times do |i|
      new_pages = Set.new
      threads = []
      pages.each {|page| unless Url.indexed? page; threads << Thread.new(page) {|url| fetch_page(url, new_pages) } end; }
      threads.each {|t| t.join }
      pages = new_pages
    end
  end
end
  

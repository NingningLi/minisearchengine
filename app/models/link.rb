# -*- coding: utf-8 -*-
class Link < ActiveRecord::Base
  #链接关系表，即指明从一个链接到另一个另一个链接的链接关系
  #（示例:如果在http://www.example1.com所对应的html文档中有链接为http://www.example1.com,那么from_id即为第一个链接example1的id，to_id则为example2链接的id）
  class << self
    def index from, to
      from, to = Url.find_by_url(from), Url.find_by_url(to)
      create(:from_id => from.nil? ? nil : from.id, :to_id => to.nil? ? nil : to.id)
    end
  end
end

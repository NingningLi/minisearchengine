# -*- coding: utf-8 -*-
class Link < ActiveRecord::Base
  #链接关系表，即指明从一个链接到另一个另一个链接的链接关系
  #（示例:如果在http://www.example1.com所对应的html文档中有链接为http://www.example1.com,那么from_id即为第一个链接example1的id，to_id则为example2链接的id）
  
end

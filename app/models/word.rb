# -*- coding: utf-8 -*-
class Word < ActiveRecord::Base
  #单词表
  has_many :word_locations
  has_many :urls, :through => :word_locations
end

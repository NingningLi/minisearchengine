# -*- coding: utf-8 -*-
class Url < ActiveRecord::Base
  #url表
  has_many :word_locations

  def index words
    word_locations = []
    words.each_with_index do |plain_word, windex|
      word = Word.where(word: plain_word ).first_or_create
      word_locations << WordLocation.new(:word_id => word.id, :url_id => self.id, :location => windex)
    end
    WordLocation.import word_locations
    self.is_indexed = 1; save
  end

  def self.indexed? plain_url
    url = find_by_url(plain_url)
    url and url.is_indexed == 1
  end
end

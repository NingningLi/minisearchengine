# -*- coding: utf-8 -*-
class Url < ActiveRecord::Base
  #url表
  has_many :word_locations

  class << self
    def index url, words
      indexed, url_entry = indexed? url
      return if indexed
      if url_entry.nil?
        url_entry = Url.create(:url => url)
      end
      word_locations = []
      words.each_with_index do |plain_word, windex|
        word = Word.where(word: plain_word ).first_or_create
        word_locations << WordLocation.new(:word_id => word.id, :url_id => url_entry.id, :location => windex)
      end
      WordLocation.import word_locations
      url_entry.is_indexed = 1; url_entry.save
    end
    
    def indexed? plain_url
      url = find_by_url(plain_url)
      return (url and url.is_indexed==1), url
    end
    
  end
end

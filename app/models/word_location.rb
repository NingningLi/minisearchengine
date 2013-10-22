# -*- coding: utf-8 -*-
class WordLocation < ActiveRecord::Base
  #单词对应的url表，以及表明在url所对应的html纯文本中，所对应的单词所在的位置(即文本中第几个单词)
  belongs_to :words
  belongs_to :urls
end

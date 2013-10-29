# -*- coding: utf-8 -*-
require "uri"
class Searcher
  def get_match_rows q
    #从word_locations表中利用链接查询出所有的单词同在一个页面上的所有链接
    field_list, table_list, clause_list = 'w0.url_id', '', ''
    table_num = 0
    word_ids = []
    URI.unescape(q).force_encoding("UTF-8").split(/\s+/).each do |word|
      p word
      word_entry = Word.find_by_word(word)
      unless word_entry.nil?
        word_ids << word_entry.id
        if table_num > 0
          table_list << ","
          clause_list << " and " << "w%d.url_id=w%d.url_id and " % [table_num-1, table_num]          
        end
        field_list << ", w%d.location" % table_num
        table_list << "word_locations w%d" % table_num
        clause_list << "w%d.word_id=%d" % [table_num, word_entry.id]
        table_num += 1
      end
    end
    full_query = "select %s from %s where %s" % [field_list, table_list, clause_list]
    results = ActiveRecord::Base.connection().execute(full_query)
    rows = []
    results.each {|row| rows << row }
    return [rows, word_ids]
  end

  def normalize_scores(scores, small_is_better=false)
    #归一化函数,每个评价函数中，返回的值有的是越大表示相关度越高，有的则是相关度越小表示越高，比如对于单词频度，单词出现的次数越多表示相关度越好，而多个单词的距离越小表示相关度越好,参数small_is_better如果为true就表示距离越小的情况
    #这个函数的目的就是统一化，返回0-1，1表示最好的
    vsmall = 0.00001
    new_scores = Hash.new
    if small_is_better
      min_score = scores.values.min
      scores.keys.each {|key| new_scores[key] = min_score.to_f / [vsmall, scores[key]].max }
    else
      max_score = scores.values.max
      scores.keys.each {|key| new_scores[key] = scores[key].to_f / max_score }      
    end
    new_scores
  end
  
  def frequency_score rows
    #统计单词在某个页面的数量
    counts = rows.map{|r| [r[0], 0]}.inject({}) {|r,s| r.merge!({s[0] => s[1]})}
    rows.each {|row| counts[row[0]] += 1}
    return normalize_scores(counts)
  end

  def location_score rows
    #统计各个单词距离文档开始的位置，计算出最小的
    locations = rows.map{|r| [r[0], 1000000]}.inject({}) {|r,s| r.merge!({s[0] => s[1]})}
    rows.each {|row| loc = row[1..-1].inject(0){|sum, n| sum + n.to_i}; if loc < locations[row[0]]; locations[row[0]] = loc end}
    return normalize_scores(locations, true)
  end
  
  def distance_score rows
    if rows.count <= 2
      return rows.map{|r| [r[0], 1.0]}      
    end
    min_distance = rows.map{|r| [r[0], 1000000]}.inject({}) {|r,s| r.merge!({s[0] => s[1]})}
    rows.each do |row|
      dist = (2..row.count).to_a.map{|i| (row[i].to_i-row[i-1].to_i).abs }.inject(0){|sum, n| sum + n.to_i}
      if dist < min_distance[row[0]]
        min_distance[row[0]] = dist
      end      
    end
    return normalize_scores(min_distance, true)
  end

  def page_rank_score rows
    page_ranks, normalized_page_ranks = {}, {}
    rows.each do |row|
      page_rank = PageRank.find_by_url_id(row[0])
      page_ranks[row[0]] = page_rank.score      
    end
    max_rank = page_ranks.values.max    
    page_ranks.to_a.each do |url_id, score|
      normalized_page_ranks[url_id] = score.to_f / max_rank
    end
    normalized_page_ranks
  end
  
  def get_scored_list(rows, word_ids)
    #获取链接的评分
    total_scores = Hash.new
    rows.each {|row| total_scores[row[0]] = 0}
    weights = [
               [1.0, frequency_score(rows)],
               [1.0, location_score(rows)],
               [2, distance_score(rows)],
               [3, page_rank_score(rows)]
              ]
    weights.each {|weight, scores| total_scores.keys.each {|url| total_scores[url] += weight * scores[url]}}
    p total_scores
    total_scores
  end
  
  def query q
    #利用评分排名
    rows, word_ids = get_match_rows q
    scores = get_scored_list(rows, word_ids).to_a.sort_by {|a| a[1]}
    urls = [] 
    scores.to_a.sort_by{|s| s[1]}.reverse.map {|a| a[0]}.each {|uid| urls << Url.find(uid.to_i)}
    urls
  end
  
end

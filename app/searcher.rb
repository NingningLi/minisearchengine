class Searcher
  def get_match_rows q
    field_list, table_list, clause_list = 'w0.url_id', '', ''
    table_num = 0
    word_ids = []
    q.split(/\s+/).each do |word|
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
    return ActiveRecord::Base.connection().execute(full_query)
  end
end

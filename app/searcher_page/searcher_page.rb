
module SearcherPage
  def self.get_app
    Rack::Builder.new do
      map "/" do
        run lambda { |env|
          if env["REQUEST_METHOD"] == "POST"
            params = env["rack.input"].read().split("&").select {|s| s.start_with? "q="}
            q = params[0].split("=")[1]
            p Searcher.new.get_match_rows(q.sub("+", " "))
            return [200, {}, ["result"]]
          end
          return [200, {}, [ERB.new(File.read("#{ProjectRoot}/app/searcher_page/views/index.html.erb")).result]]
        }
      end
    end
  end
end

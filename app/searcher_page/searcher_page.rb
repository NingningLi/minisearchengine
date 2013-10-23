
module SearcherPage
  def self.get_app
    Rack::Builder.new do
      map "/" do
        run lambda { |env|
          if env["REQUEST_METHOD"] == "POST"
            params = env["rack.input"].read().split("&").select {|s| s.start_with? "q="}
            urls = Searcher.new.query(params[0].split("=")[1].gsub("+", " "))
            result_template = File.read("#{ProjectRoot}/app/searcher_page/views/result.html.erb")
            return [200, {}, [ERB.new(result_template).result(binding)]]
          end
          return [200, {}, [ERB.new(File.read("#{ProjectRoot}/app/searcher_page/views/index.html.erb")).result]]
        }
      end
    end
  end
end

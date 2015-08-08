class Kit < Sinatra::Base

  get '/todo' do
      session!

      if params[:insert] != nil and params[:insert] != ""

          query = " SELECT id, text, to_char(created_at, '[DD/MM/YYYY]') as created_at FROM todo_list where id = $1 ";
          last = @@conn.exec_params(query, [params[:insert]])

          @feedback = []

          last.each_with_index do |t, i|
              @feedback << {
                  :id => t["id"],
                  :text => t["text"],
                  :created_at => t["created_at"],
              }
          end
      end
      erb :todo
  end

  get '/new_todo' do
      session!

      text = params[:text]

      ret = @@conn.exec_params(' INSERT INTO todo_list(text) VALUES($1) returning id', [text.to_s])

      id = ret.first
      puts id.to_s
      #redirect "/"
      redirect "/todo?insert=#{id["id"]}"
  end

  get '/todo_list' do

      query = " SELECT id, text, to_char(created_at, '[DD/MM/YYYY]') as created_at FROM todo_list ";
      ret = @@conn.exec(query)

      @todos = []

      ret.each_with_index do |t, i|

          @todos << {
              :id => t["id"],
              :text => t["text"],
              :created_at => t["created_at"],
          }
          puts t

      end

      erb :todo_list
  end
end

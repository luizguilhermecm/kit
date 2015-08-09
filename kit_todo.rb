class Kit < Sinatra::Base

  get '/todo' do
      session!

      if params[:insert] != nil and params[:insert] != ""

          query = " SELECT id, text, to_char(created_at, '[DD/MM/YYYY]') as created_at FROM todo_list where id = $1 and uid = $2";
          last = @@conn.exec_params(query, [params[:insert], session[:uid]])

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
      puts "user id" + session[:uid].to_s
      ret = @@conn.exec_params(' INSERT INTO todo_list(text, uid) VALUES($1, $2) returning id', [text.to_s, session[:uid]])

      id = ret.first
      puts id.to_s
      #redirect "/"
      redirect "/todo?insert=#{id["id"]}"
  end

  get '/todo_list' do
      session!

      query = " SELECT id, text, to_char(created_at, 'DD-MM-YY') as data FROM todo_list WHERE flag_deleted = 'false' and uid = $1 ORDER BY created_at DESC ";
      ret = @@conn.exec_params(query, [session[:uid]])

      @todos = []

      ret.each_with_index do |t, i|

          @todos << {
              :id => t["id"],
              :text => t["text"],
              :created_at => t["data"],
          }
          #puts t

      end

      erb :todo_list
  end

  get '/rm_todo' do
      session!

      id = params[:id]
      query = " UPDATE todo_list SET flag_deleted = 't', deleted_at = (SELECT now()) WHERE id = $1 AND uid = $2";

      @@conn.exec_params(query , [id, session[:uid]])

      redirect "/todo_list"
  end

end

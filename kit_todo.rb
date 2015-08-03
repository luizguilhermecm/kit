class Kit < Sinatra::Base

  get '/todo' do
      session!

      if params[:insert] != nil and params[:insert] != ""
          last = @@conn.exec_params(' select * from todo_list where id = $1', [params[:insert]])

          @feedback = last.first.to_s
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
end

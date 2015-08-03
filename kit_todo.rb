class Kit < Sinatra::Base

  get '/todo' do
      session!
      erb :todo
  end

  get '/new_todo' do
      session!
      text = params[:text]
      @@conn.exec_params(' INSERT INTO todo_list(text) VALUES($1) ', [text.to_s])
      erb :xururu
  end
end

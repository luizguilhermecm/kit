class Kit < Sinatra::Base

  get '/cookbook' do
      session!

      if params[:insert] != nil and params[:insert] != ""

          query = " SELECT id, subject, description, text, to_char(created_at, '[DD/MM/YYYY]') as created_at FROM cookbook_list where id = $1 and uid = $2";
          begin
              last = @@conn.exec_params(query, params[:insert], session[:uid])
          rescue => e
              puts "***************************"
              puts session[:username]
              puts session[:uid]
              puts request.ip
              puts e
              puts "***************************"
              redirect to('/')
          end

          @feedback = []

          last.each_with_index do |t, i|
              @feedback << {
                  :id => t["id"],
                  :subject  => t["subject"],
                  :description => t["description"],
                  :text => t["text"],
                  :created_at => t["created_at"],
              }
          end
      end
      erb :cookbook_list
  end

  get '/new_cookbook' do
      session!

      text = params[:text]
      description = params[:description]
      subject = params[:subject]
      puts "user id" + session[:uid].to_s

      begin
          ret = @@conn.exec_params(' INSERT INTO cookbook_list(text, uid, subject, description) VALUES($1, $2, $3, $4) returning id', [text.to_s, session[:uid], subject, description])
      rescue => e
        puts "***************************"
        puts session[:username]
        puts session[:uid]
        puts request.ip
        puts e
        puts "***************************"
        redirect to('/')
      end

      id = ret.first
      puts id.to_s
      #redirect "/"
      redirect "/cookbook#{id["id"]}"
  end

  get '/cookbook_list' do
      session!

      query = " SELECT id, subject, description, text, to_char(created_at, 'DD-MM-YY') as data FROM cookbook_list WHERE flag_deleted = 'false' and uid = $1 ORDER BY created_at DESC ";
      begin
        ret = @@conn.exec_params(query, [session[:uid]])
      rescue => e
        puts "***************************"
        puts session[:username]
        puts session[:uid]
        puts request.ip
        puts e
        puts "***************************"
        redirect to('/')
      end



      @cookbooks = []

      ret.each_with_index do |t, i|

          @cookbooks << {
              :id => t["id"],
              :text => t["text"],
              :subject => t["subject"],
              :description => t["description"],
              :created_at => t["data"],
          }
          #puts t

      end

      erb :cookbook_list
  end

  get '/rm_cookbook' do
      session!

      id = params[:id]
      query = " UPDATE cookbook_list SET flag_deleted = 't', deleted_at = (SELECT now()) WHERE id = $1 AND uid = $2";

      begin
        @@conn.exec_params(query , [id, session[:uid]])
      rescue => e
        puts "***************************"
        puts session[:username]
        puts session[:uid]
        puts request.ip
        puts e
        puts "***************************"
      end

      redirect "/cookbook_list"
  end

end

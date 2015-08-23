class Kit < Sinatra::Base

  get '/todo' do
      session!

      @tag_list = []

      @tag_list = get_todo_tags

      if params[:insert] != nil and params[:insert] != ""

          query = " SELECT id, text, to_char(created_at, '[DD/MM/YYYY]') as created_at FROM todo_list where id = $1 and uid = $2";
          begin
              last = @@conn.exec_params(query, [params[:insert], session[:uid]])
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
      tag_id = params[:tag_id]

      begin
          ret = @@conn.exec_params(' INSERT INTO todo_list(text, uid, tag_id) VALUES($1, $2, $3) returning id', [text.to_s, session[:uid], tag_id.to_i])
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
      redirect "/todo?insert=#{id["id"]}"
  end

  get '/new_tag' do
      session!

      tag_name = params[:tag_name]
      tag_desc = params[:tag_desc]

      begin
          @@conn.exec_params(' INSERT INTO todo_tag(tag, description, user_id) VALUES($1, $2, $3) returning id', [tag_name.to_s, tag_desc.to_s, session[:uid]])
      rescue => e
        puts "***************************"
        puts session[:username]
        puts session[:uid]
        puts request.ip
        puts e
        puts "***************************"
        redirect to('/')
      end

      redirect to('/')
  end


  get '/todo_list' do
      session!

      tag_id = params[:tag_id].to_i
      puts tag_id
      if tag_id != 0
        query = " SELECT id, text, to_char(created_at, 'DD-MM-YY') as data, tag_id FROM todo_list WHERE flag_deleted = 'false' and uid = $1  and tag_id = $2 ORDER BY created_at DESC ";
      else
        query = " SELECT id, text, to_char(created_at, 'DD-MM-YY') as data, tag_id FROM todo_list WHERE flag_deleted = 'false' and uid = $1 ORDER BY created_at DESC ";
      end

      puts query;
      begin
        if tag_id != 0
            puts tag_id
            puts query
            ret = @@conn.exec_params(query, [session[:uid], tag_id])
        else
            ret = @@conn.exec_params(query, [session[:uid]])
        end
      rescue => e
        puts "***************************"
        puts session[:username]
        puts session[:uid]
        puts request.ip
        puts e
        puts "***************************"
        redirect to('/')
      end

      @tag_list = []

      @tag_list = get_todo_tags

      @todos = []

      ret.each_with_index do |t, i|

          @todos << {
              :id => t["id"],
              :text => t["text"],
              :tag_id => t["tag_id"],
              :created_at => t["data"],
          }
          #puts t

      end

      erb :todo_list
  end

  def get_todo_tags
    query = " SELECT id, tag, description FROM todo_tag WHERE user_id = $1 ORDER BY tag ASC ";
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

      todo_tag = []
      ret.each_with_index do |t, i|

          todo_tag << {
              :id => t["id"],
              :tag => t["tag"],
              :description => t["description"],
          }

      end

      return todo_tag
  end

  get '/rm_todo' do
      session!

      id = params[:id]
      query = " UPDATE todo_list SET flag_deleted = 't', deleted_at = (SELECT now()) WHERE id = $1 AND uid = $2";

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

      redirect "/todo_list"
  end

  get '/update_todo_tag/' do
      session!

      tag_id = params[:tag_id]
      todo_id = params[:todo_id]

      query = " UPDATE todo_list SET tag_id = $1 WHERE id = $2 AND uid = $3";

      begin
        @@conn.exec_params(query , [tag_id, todo_id, session[:uid]])
      rescue => e
        puts "***************************"
        puts session[:username]
        puts session[:uid]
        puts request.ip
        puts e
        puts "***************************"
      end

  end

end

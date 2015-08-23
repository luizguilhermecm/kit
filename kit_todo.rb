class Kit < Sinatra::Base

  get '/todo' do
      session!

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
      tag = params[:tag]

      begin
          ret = @@conn.exec_params(' INSERT INTO todo_list(text, uid, tag) VALUES($1, $2) returning id', [text.to_s, session[:uid], tag.to_s])
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

  get '/todo_list' do
      session!

      query = " SELECT id, text, to_char(created_at, 'DD-MM-YY') as data FROM todo_list WHERE flag_deleted = 'false' and uid = $1 ORDER BY created_at DESC ";
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

      @todo_tag = []

      @todo_tag = get_todo_tags

      @todos = []

      ret.each_with_index do |t, i|

          @todos << {
              :id => t["id"],
              :text => t["text"],
              :tag => @todo_tag,
              :created_at => t["data"],
          }
          #puts t

      end

      erb :todo_list
  end

  def get_todo_tags
    query = " SELECT DISTINCT tag FROM todo_list WHERE uid = $1 ORDER BY tag ASC ";
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
              :tag => t["tag"],
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

end

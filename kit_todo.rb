class Kit < Sinatra::Base

    attr_accessor :feedback
    #feedback = "feedback"

    get '/todo' do
        session!
        crazy_log(feedback)
        feedback = "setted at todo"
        crazy_log(feedback)
        puts feedback

        @tag_list = []

        @tag_list = get_todo_tags
        if params[:insert] != nil and params[:insert] != ""

            query = " SELECT id, text, to_char(created_at, '[DD/MM/YYYY]') as created_at, tag_id FROM todo_list where id = $1 and uid = $2";

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

            @todos = []

            last.each_with_index do |t, i|
                @todos << {
                    :id => t["id"],
                    :text => t["text"],
                    :created_at => t["created_at"],
                }
            end
        end
        erb :todo
    end

    get '/todo/new_todo' do
        session!

        text = params[:text]
        tag_id = params[:tag_id]

        begin
            #ret = @@conn.exec_params(' INSERT INTO todo_list(text, uid, tag_id) VALUES($1, $2, $3) returning id', [text.to_s, session[:uid], tag_id.to_i])
            ret = @@conn.exec_params(' INSERT INTO todo_list(text, uid) VALUES($1, $2) returning id', [text.to_s, session[:uid]])
            query_tag = "INSERT INTO todo_tags (todo_id, tag_id) VALUES ($1, $2);"

            id = ret.first
            ret = @@conn.exec_params(query_tag, [id["id"], tag_id.to_i])

        rescue => e
            puts "***************************"
            puts session[:username]
            puts session[:uid]
            puts request.ip
            puts e
            puts "***************************"
            redirect to('/')
        end

        redirect "/todo/todo_list?insert=#{id["id"]}"
    end

    get '/todo/new_tag' do
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

        redirect to('/todo/todo_tag')
    end


    get '/todo/todo_list' do
        session!

        tag_id = params[:tag_id].to_i
        insert = params[:insert].to_i

        query = " SELECT id, text, to_char(created_at, 'DD-MM-YY') as data, flag_do_it "
        query += " FROM todo_list WHERE flag_deleted = 'false' and uid = $1 "


        if tag_id != 0
            query += " AND id IN (SELECT DISTINCT todo_id FROM todo_tags WHERE tag_id = $2) "
        elsif insert != 0
            query += " AND id = #{insert} "
        else
            query += " AND flag_done = 'false' "
        end

        query += " ORDER BY flag_do_it is true DESC, created_at DESC ";

        begin
            if tag_id != 0
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

        query_tag_list = "SELECT tt.id, tt.tag FROM todo_tags tts LEFT JOIN todo_tag tt ON tts.tag_id = tt.id  WHERE tts.todo_id = $1 ;"
        ret.each_with_index do |t, i|
            todos_tags = []
            ret_tag_list = @@conn.exec_params(query_tag_list, [t["id"]])
            ret_tag_list.each do |tag|
                todos_tags << {
                    :id => tag["id"],
                    :tag => tag["tag"],
                }
            end

            @todos << {
                :id => t["id"],
                :text => t["text"],
                :tag_id => t["tag_id"],
                :created_at => t["data"],
                :flag_do_it => t["flag_do_it"],
                :todo_tag_list => todos_tags,
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

    get '/todo/set_todo_done' do
        session!

        id = params[:id]

        query = " UPDATE todo_list SET flag_done = 't', done_at = (SELECT now()) WHERE id = $1 AND uid = $2";

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

        redirect "/todo/todo_list"
    end


    get '/todo/rm_todo' do
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

        redirect "/todo/todo_list"
    end

    get '/todo/update_todo_flag_do_it/' do
        session!

        flag_do_it = params[:flag_do_it]
        todo_id = params[:todo_id]

        query = " UPDATE todo_list SET flag_do_it = NOT flag_do_it WHERE id = $1 AND uid = $2";

        puts query
        puts flag_do_it
        begin
            @@conn.exec_params(query , [todo_id, session[:uid]])
        rescue => e
            puts "***************************"
            puts session[:username]
            puts session[:uid]
            puts request.ip
            puts e
            puts "***************************"
        end

    end


    get '/todo/update_todo_tag/' do
        kit_log(KIT_LOG_INFO, 'get /todo/update_todo_tag/')
        session!

        tag_id = params[:tag_id]
        todo_id = params[:todo_id]

        kit_log(KIT_LOG_DEBUG, 'updating tag of todo', "tag_id = #{tag_id}", "todo_id = #{todo_id}")

        #query = " UPDATE todo_list SET tag_id = $1 WHERE id = $2 AND uid = $3";
        query_insert = " INSERT INTO todo_tags (todo_id, tag_id) VALUES ($1, $2); ";

        query_delete = " DELETE FROM todo_tags WHERE id = $1; ";

        query_exist = " SELECT id FROM todo_tags WHERE todo_id = $1 AND tag_id = $2 ; ";

        begin
            kit_log(KIT_LOG_DEBUG, "checking if its already exists")
            kit_log(KIT_LOG_DEBUG, "SQL", query_exist, todo_id, tag_id)
            ret = @@conn.exec_params(query_exist , [todo_id, tag_id])

            if ret.first
                kit_log(KIT_LOG_DEBUG, "yes, it exists, deleting tag")
                kit_log(KIT_LOG_DEBUG, "SQL", query_delete)
                @@conn.exec_params(query_delete, [ret.first["id"]])
            else
                kit_log(KIT_LOG_DEBUG, "no, it does not exists, inserting tag")
                kit_log(KIT_LOG_DEBUG, "SQL", query_insert)
                @@conn.exec_params(query_insert, [todo_id, tag_id])
            end

        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
        end

    end

    get '/todo/todo_tag' do
        session!

        begin

            puts "Instance method show invoked for '#{self}'"

        crazy_log("checking at tag")
        crazy_log(feedback)
        feedback = "setted at tag"
        crazy_log(feedback)
        @tag_list = []

        @tag_list = get_todo_tags

        erb :todo_tag

        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
        end
    end


end

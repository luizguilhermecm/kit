class Kit < Sinatra::Base

    module Priority
        A = 'btn-danger'
        B = 'btn-warning'
        C = 'btn-info'
        D = 'btn-success'
        E = 'btn-primary'
    end



    # main page of kit_todo feature.
    get '/todo' do
        kit_log_breadcrumb("get '/todo'", params)
        session!
        @tag_list = get_todo_tags
        redirect to('/todo/todo_list')
    end

    # method used to insert new todo
    get '/todo/new_todo' do
        kit_log_breadcrumb("get '/todo/new_todo'", params)
        session!

        text = params[:text]
        tags = params[:tags]

        query = ' INSERT INTO todo_list(text, uid) VALUES($1, $2) returning id'
        kit_log(KIT_LOG_DEBUG, "query of insert todo", query)
        begin
            ret = @@conn.exec_params(query, [text.to_s, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-58cns]")
            kit_log(KIT_LOG_ERROR, e, session)
            session[:kmsg] = "error in add on table todo_list"
            redirect request.referer
        end


            query_tag = "INSERT INTO todo_tags (todo_id, tag_id) VALUES ($1, $2);"
            kit_log(KIT_LOG_DEBUG, "query of insert tags of todo", query_tag)

            id = ret.first["id"] if ret
        begin
            tags.each do |tag|
                @@conn.exec_params(query_tag, [id, tag.to_i])
            end

        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-5888dcns]")
            kit_log(KIT_LOG_ERROR, e, session)
            session[:kmsg] = "error in add on table todo_tags"
            redirect request.referer
        end

        redirect "/todo/todo_list?insert=#{id["id"]}"
    end

    # method used to create new tags
    get '/todo/new_tag' do
        kit_log_breadcrumb("get '/todo/new_tag'", params)
        session!

        tag_name = params[:tag_name]
        tag_desc = params[:tag_desc]

        q = ' INSERT INTO todo_tag(tag, description, user_id) '
        q += ' VALUES($1, $2, $3) returning id'

        kit_log(KIT_LOG_DEBUG, "query of insert tag", q)
        begin
            @@conn.exec_params(q, [tag_name.to_s, tag_desc.to_s, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        redirect to('/todo/todo_tag')
    end


    get '/todo/todo_list' do
        kit_log_breadcrumb("get '/todo/todo_list'", params)
        session!

        tag_id = params[:tag_id].to_i
        insert = params[:insert].to_i
        list_all = params[:list_all].to_i

        query = " SELECT id, text, to_char(created_at, 'DD-MM-YY') as data, flag_do_it, "
        query += " priority FROM todo_list WHERE flag_deleted = 'false' and uid = $1 "


        if tag_id != 0
            # list one tag only
            query += " AND id IN (SELECT DISTINCT todo_id FROM todo_tags WHERE tag_id = $2) "
        elsif insert != 0
            query += " AND id = #{insert} "
        elsif list_all != 0
            # without filter
        else
            # todo list without params will list only tags checked to be listed
            query += get_is_listed_tags
        end

        query += " AND flag_done = false "
        query += " ORDER BY flag_do_it is true DESC, priority, created_at DESC ";

        begin
            if tag_id != 0
                ret = @@conn.exec_params(query, [session[:uid], tag_id])
            else
                ret = @@conn.exec_params(query, [session[:uid]])
            end
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        @tag_list = []

        @tag_list = get_todo_tags

        @todos = []

        query_tag_list = "SELECT tt.id, tt.tag, tt.label FROM todo_tags tts LEFT JOIN todo_tag tt ON tts.tag_id = tt.id  WHERE tts.todo_id = $1 ;"
        ret.each_with_index do |t, i|
            todos_tags = []
            ret_tag_list = @@conn.exec_params(query_tag_list, [t["id"]])
            ret_tag_list.each do |tag|
                todos_tags << {
                    :id => tag["id"],
                    :tag => tag["tag"],
                    :label => tag["label"],
                }
            end
            letter = get_priority_label t["priority"]
            @todos << {
                :id => t["id"],
                :text => t["text"],
                :tag_id => t["tag_id"],
                :created_at => t["data"],
                :flag_do_it => t["flag_do_it"],
                :todo_tag_list => todos_tags,
                :priority_letter => t["priority"],
                :priority => letter
            }
        end

        erb :todo_list
    end

    def get_is_listed_tags
        kit_log_breadcrumb("def get_is_listed_tags", nil)
        query = " SELECT id FROM todo_tag WHERE user_id = $1 AND is_listed = true  ";
        begin
            ret = @@conn.exec_params(query, [session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end
        query = " AND id IN (SELECT DISTINCT todo_id FROM todo_tags WHERE tag_id IN ( "
        ret.each do |tag|
            query += tag["id"]
            query += ","
        end
        # normalization of comma, add -1
        query += " -1)) "

        kit_log(KIT_LOG_DEBUG, query)
        return query
    end

    def get_todo_tags
        kit_log_breadcrumb("def get_todo_tags", nil)
        query  = " SELECT id, tag, description, is_listed, label ";
        query += " FROM todo_tag WHERE user_id = $1 ORDER BY tag ASC ";
        begin
            ret = @@conn.exec_params(query, [session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        todo_tag = []
        ret.each_with_index do |t, i|
            query  = " SELECT count(*) FROM todo_tags inner join todo_tag ";
            query += "  on todo_tags.tag_id = todo_tag.id where todo_tag.id = $1 ;";
            count = @@conn.exec_params(query, [t["id"].to_i])
            c = 0
            if count.first
                c = count.first["count"].to_i
            end
            todo_tag << {
                :id => t["id"],
                :tag => t["tag"],
                :description => t["description"],
                :is_listed => t["is_listed"],
                :label => t["label"],
                :count => c,
            }

        end
        return todo_tag
    end

    get '/todo/set_todo_done' do
        kit_log_breadcrumb("get '/todo/set_todo_done'", params)
        session!

        id = params[:id]

        query = " UPDATE todo_list SET flag_done = 't', done_at = (SELECT now()) WHERE id = $1 AND uid = $2";

        kit_log(KIT_LOG_DEBUG, query, id);
        begin
            @@conn.exec_params(query , [id, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        #puts JSON.pretty_generate(request.env)
        redirect request.referer
        #redirect "/todo/todo_list"
    end


    get '/todo/rm_todo' do
        kit_log_breadcrumb("get '/todo/rm_todo'", params)
        session!

        id = params[:id]
        query = " UPDATE todo_list SET flag_deleted = 't', deleted_at = (SELECT now()) WHERE id = $1 AND uid = $2";

        begin
            @@conn.exec_params(query , [id, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        redirect "/todo/todo_list"
    end

    get '/todo/update_todo_flag_do_it/' do
        kit_log_breadcrumb("get '/todo/update_todo_flag_do_it/'", params)
        session!

        flag_do_it = params[:flag_do_it]
        todo_id = params[:todo_id]

        query = " UPDATE todo_list SET flag_do_it = NOT flag_do_it WHERE id = $1 AND uid = $2";

        puts query
        puts flag_do_it
        begin
            @@conn.exec_params(query , [todo_id, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

    end


    get '/todo/update_todo_tag/' do
        kit_log_breadcrumb("get '/todo/update_todo_tag/'", params)
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
            redirect request.referer
        end

    end

    get '/todo/todo_tag' do
        kit_log_breadcrumb("get '/todo/todo_tag'", params)
        session!

        begin
            @tag_list = []
            @tag_list = get_todo_tags
            erb :todo_tag
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
        end
    end


    get '/todo/update_is_listed' do
        kit_log_breadcrumb("get '/todo/update_is_listed'", params)
        session!

        tag_id = params[:tag_id]
        value = params[:value]

        query= " update todo_tag set is_listed = $1 WHERE id = $2; ";

        begin
            kit_log(KIT_LOG_DEBUG, "SQL", query, tag_id, value)
            @@conn.exec_params(query, [value, tag_id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end
    end

    get '/todo/rm_tag' do
        kit_log_breadcrumb("get '/todo/rm_tag'", params)
        session!

        id = params[:id]
        querySelTag = " select * from todo_tag where todo_tag.id = $1 and todo_tag.user_id = $2";
        querySel = " select count(*) from todo_tag inner join todo_tags on todo_tag.id = todo_tags.tag_id where todo_tag.id = $1 and todo_tag.user_id = $2";

        query = " delete from todo_tag where id = $1 and user_id = $2";

        begin
            tag = @@conn.exec_params(querySelTag , [id, session[:uid]])
            ret = @@conn.exec_params(querySel , [id, session[:uid]])
            @@conn.exec_params(query , [id, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        msg = "msg"
        if tag.first
            msg = "A tag '"
            msg += tag.first["tag"].to_s
            msg += "', id = "
            msg += tag.first["id"].to_s
            msg += " foi deletada com sucesso."
        end
        if ret.first
            msg += "\t"
            count = ret.first["count"].to_s
            msg += count
            msg += ' itens foram deletados.'
        end
        session[:kmsg] = msg
        redirect request.referer
    end

    get '/todo/update_tag_label' do
        kit_log_breadcrumb("get '/todo/update_tag_label'", params)
        session!

        tag_id = params[:tag_id].to_i
        label_id = params[:label_id].to_i

        kit_log(KIT_LOG_DEBUG, "tag_id", tag_id)
        kit_log(KIT_LOG_DEBUG, "label_id", label_id)
        query = 'UPDATE todo_tag set label = $1 WHERE id = $2';
        if label_id == 0
            label = 'label-default'
        elsif label_id == 1
            label = 'label-primary'
        elsif label_id == 2
            label = 'label-success'
        elsif label_id == 3
            label = 'label-info'
        elsif label_id == 4
            label = 'label-warning'
        elsif label_id == 5
            label = 'label-danger'
        else
            label = 'label-default'
        end

        begin
            kit_log(KIT_LOG_DEBUG, "SQL", query, label, tag_id)
            @@conn.exec_params(query, [label, tag_id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

    end

    get '/todo/update_priority' do
        kit_log_breadcrumb("get '/todo/update_priority'", params)
        session!

        todo_id = params[:todo_id].to_i
        prio = params[:prio]

        kit_log(KIT_LOG_DEBUG, "todo_id", todo_id)
        kit_log(KIT_LOG_DEBUG, "prio", prio)
        query = 'UPDATE todo_list set priority = $1 WHERE id = $2';


        begin
            kit_log(KIT_LOG_DEBUG, "SQL", query, prio, todo_id)
            @@conn.exec_params(query, [prio, todo_id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
        end

    end

    def get_priority_letter p
        kit_log_breadcrumb("def get_priority_letter p", p)

        if p == Priority::A
            return 'A'
        elsif p == Priority::B
            return 'B'
        elsif p == Priority::C
            return 'C'
        elsif p == Priority::D
            return 'D'
        elsif p == Priority::E
            return 'E'
        end
    end

    def get_priority_label prio
        kit_log_breadcrumb("def get_priority_label prio", prio)

        if prio == 'E'
            label = 'btn-primary'
        elsif prio == 'D'
            label = 'btn-success'
        elsif prio == 'C'
            label = 'btn-info'
        elsif prio == 'B'
            label = 'btn-warning'
        elsif prio == 'A'
            label = 'btn-danger'
        else
            label = nil
        end
        return label
    end
end

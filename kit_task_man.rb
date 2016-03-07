class Kit < Sinatra::Base

    get '/kit_task_man' do
        kit_log(KIT_LOG_INFO, 'get /kit_task_man')
        session!
        tag_id = params[:tag_id].to_i
        @tasks_0 = []
        @tasks_0 = get_list 0, tag_id

        @tasks_1 = []
        @tasks_1 = get_list 1, tag_id

        @tasks_2 = []
        @tasks_2 = get_list 2, tag_id

        @tag_list = []
        @tag_list = get_tag_list

        erb :kit_task_man
    end

    get '/kit_task_man/edit_task' do
        id = params[:id]
        progress = params[:progress]
        color = params[:color]
        text = params[:text]
        tags = params[:tags]
        subtask = params[:subtasks]

        query_task = ' update task_main set updated_at = (select now()), text = $1, progress = $3, color = $4 where id = $2'
        begin
            @@conn.exec_params(query_task, [text.to_s, id, progress, color])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end

        query_delete_tag = ' DELETE FROM task_tag_task WHERE task_id = $1 ;'
        begin
            @@conn.exec_params(query_delete_tag, [id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end

        query_insert_tag = 'INSERT INTO task_tag_task (task_id, tag_id) VALUES ($1, $2);'

        begin
            if tags
                tags.each do |tag|
                    @@conn.exec_params(query_insert_tag, [id, tag])
                end
            end
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end

        query_delete_sub = ' DELETE FROM task_sub WHERE task_id = $1 and done = false ;'
        begin
            @@conn.exec_params(query_delete_sub, [id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end

        query_sub_insert =  "\n INSERT INTO task_sub (task_id, text) "
        query_sub_insert += "\n     SELECT $1, $2 "
        query_sub_insert += "\n         WHERE "
        query_sub_insert += "\n         NOT EXISTS ("
        query_sub_insert += "\n             SELECT 1 FROM task_sub WHERE task_id = $1 and text = $2 "
        query_sub_insert += "\n         );"


        #query_sub = 'INSERT INTO task_sub (task_id, text) VALUES ($1, $2);'
        if subtask
            kit_log(KIT_LOG_DEBUG, "query to insert sub", query_sub_insert)
            kit_log(KIT_LOG_DEBUG, "subtask not null, iterate it")
            subtask.each do |sub|
                if sub != ""
                    kit_log(KIT_LOG_DEBUG, "sub not empty", sub)
                    @@conn.exec_params(query_sub_insert, [id, sub])
                end
            end
        end

        redirect to('/kit_task_man')

    end

    get '/kit_task_man/new_task' do
        kit_log(KIT_LOG_INFO, 'get /kit_task_man/new_task')
        session!

        text = params[:text]
        tags = params[:tags]
        subtask = params[:subtasks]
        kit_log(KIT_LOG_DEBUG, "subtask", subtask)

        begin
            ret = @@conn.exec_params(' INSERT INTO task_main(text, uid) VALUES($1, $2) returning id', [text.to_s, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end

        query = ' INSERT INTO task_tag_task (task_id, tag_id) VALUES ($1, $2);'
        if tags
            tags.each do |tag|
                @@conn.exec_params(query, [ret.first['id'], tag])
            end
        end

        query_sub = ' INSERT INTO task_sub (task_id, text) VALUES ($1, $2);'
        if subtask
            kit_log(KIT_LOG_DEBUG, "Insert sub task")
            subtask.each do |sub|
                kit_log(KIT_LOG_DEBUG, sub)
                @@conn.exec_params(query_sub, [ret.first['id'], sub])
            end
        end

        redirect to('/kit_task_man')
    end

    #get '/kit_task_man/list_task' do
    def get_list status, tag_id
        kit_log(KIT_LOG_INFO, 'get /kit_task_man/list_task')
        session!
        begin
            if tag_id != 0
                kit_log(KIT_LOG_DEBUG, "tag_id not null", tag_id)
                query = 'SELECT task_main.* FROM task_main inner join task_tag_task on task_tag_task.task_id = task_main.id WHERE task_main.uid = $1 AND task_main.status = $2 AND task_tag_task.tag_id = $3 order by flag_do_it is TRUE desc, updated_at desc;'
                ret = @@conn.exec_params(query, [session[:uid], status, tag_id])
            else
                kit_log(KIT_LOG_DEBUG, "tag_id null")
                query = 'SELECT * FROM task_main WHERE uid = $1 AND status = $2 order by flag_do_it is true DESC,  updated_at desc;'
                ret = @@conn.exec_params(query, [session[:uid], status])
            end
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end
        query_tag_list = "SELECT task_tag_task.tag_id, task_tag.tag FROM task_tag_task LEFT JOIN task_tag ON task_tag.id = task_tag_task.tag_id  WHERE task_tag_task.task_id = $1 ;"

        query_sub_list = "SELECT * FROM task_sub WHERE task_id = $1 ;"

        todos = []
        ret.each_with_index do |t, i|
            task_tags = []
            tags = @@conn.exec_params(query_tag_list, [t["id"]])
            tags.each do |tag|
                task_tags << {
                    :id => tag["tag_id"],
                    :tag => tag["tag"]
                }
            end

            task_subs = []
            subs = @@conn.exec_params(query_sub_list, [t["id"]])
            subs.each do |sub|
                task_subs << {
                    :id => sub["id"],
                    :text => sub["text"],
                    :done => sub["done"],
                }
            end
            todos << {
                :id => t["id"],
                :flag_do_it => t["flag_do_it"],
                :progress => t["progress"],
                :color => t["color"],
                :text => t["text"],
                :created_at => t["created_at"],
                :task_tags => task_tags,
                :task_subs=> task_subs,
            }
        end

        crazy_log(todos)
        return todos
    end

    def get_tag_list
        kit_log(KIT_LOG_INFO, 'def get_tag_list')
        session!
        begin
            query = 'SELECT * FROM task_tag WHERE uid = $1;'
            ret = @@conn.exec_params(query, [session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end

        tags = []

        ret.each_with_index do |t, i|
            tags << {
                :id => t["id"],
                :tag => t["tag"],
                :created_at => t["created_at"],
            }
        end

        return tags
    end


    get '/kit_task_man/update_status' do
        kit_log(KIT_LOG_INFO, 'get /kit_task_man/update_status')
        session!

        id = params[:id]
        status = params[:status]
        begin
            query = 'update task_main set status = $3 where uid = $1 and id = $2;'
            @@conn.exec_params(query, [session[:uid], id, status])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end
    end

    get '/kit_task_man/get_task_info' do
        id = params[:id]

        @tag_list = []
        @tag_list = get_tag_list

        @task_info = get_task_info id
        erb :_edit_task
    end

    get '/kit_task_man/new_tag' do
        kit_log(KIT_LOG_INFO, 'get /kit_task_man/new_tag')
        session!

        tag_name = params[:tag_name]

        begin
            @@conn.exec_params(' INSERT INTO task_tag(tag, uid) VALUES($1, $2) returning id', [tag_name.to_s, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end

        redirect to('/kit_task_man')
    end

    def get_task_info id
        session!
        begin
            query = 'SELECT * FROM task_main WHERE uid = $1 AND id = $2;'
            ret = @@conn.exec_params(query, [session[:uid], id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end
        query_tag_list = "SELECT task_tag_task.tag_id, task_tag.tag FROM task_tag_task LEFT JOIN task_tag ON task_tag.id = task_tag_task.tag_id  WHERE task_tag_task.task_id = $1 ;"

        query_sub_list = "SELECT * FROM task_sub WHERE task_id = $1 ;"

        todos = []

        ret.each_with_index do |t, i|
            task_tags = []
            tags = @@conn.exec_params(query_tag_list, [t["id"]])
            tags.each do |tag|
                task_tags.push tag["tag_id"]
            end
            task_subs = []
            subs = @@conn.exec_params(query_sub_list, [t["id"]])
            subs.each do |sub|
                task_subs << {
                    :id => sub["id"],
                    :text => sub["text"],
                }
            end

            todos << {
                :id => t["id"],
                :progress => t["progress"],
                :color => t["color"],
                :text => t["text"],
                :created_at => t["created_at"],
                :task_tags => task_tags,
                :task_subs => task_subs,
            }
        end

        return todos
    end

    get '/kit_task_man/update_sub_done' do
        kit_log(KIT_LOG_INFO, "get '/kit_task_man/update_sub_done' ", params);
        id = params[:id]
        query = ' update task_sub set done = NOT done where id = $1'
        begin
            kit_log(KIT_LOG_DEBUG, query)
            @@conn.exec_params(query, [id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end
    end

    get '/kit_task_man/update_task_do_it' do
        kit_log(KIT_LOG_INFO, "get '/kit_task_man/update_task_do_it'", params)
        id = params[:id]
        query = ' update task_main set flag_do_it = NOT flag_do_it where id = $1'
        begin
            kit_log(KIT_LOG_DEBUG, query)
            @@conn.exec_params(query, [id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end
    end
    get '/kit_task_man/delete_task' do
        kit_log(KIT_LOG_INFO, "get '/kit_task_man/delete_task'", params)
        id = params[:id]
        query = ' delete from task_main where id = $1'
        begin
            kit_log(KIT_LOG_DEBUG, query)
            @@conn.exec_params(query, [id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end
        redirect to('/kit_task_man')
    end



end




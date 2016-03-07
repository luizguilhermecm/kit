class Kit < Sinatra::Base

    get '/kit_task_man' do
        kit_log(KIT_LOG_INFO, 'get /kit_task_man')
        session!
        @tasks_0 = []
        @tasks_0 = get_list 0

        @tasks_1 = []
        @tasks_1 = get_list 1

        @tasks_2 = []
        @tasks_2 = get_list 2

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
            ret = @@conn.exec_params(query_task, [text.to_s, id, progress, color])
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
    def get_list status
        kit_log(KIT_LOG_INFO, 'get /kit_task_man/list_task')
        session!
        begin
            query = 'SELECT * FROM task_main WHERE uid = $1 AND status = $2 order by updated_at desc;'
            ret = @@conn.exec_params(query, [session[:uid], status])
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
                    :id => tag["id"],
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
                :progress => t["progress"],
                :color => t["color"],
                :text => t["text"],
                :created_at => t["created_at"],
                :task_tags => task_tags,
                :task_subs=> task_subs,
            }
        end

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
            ret = @@conn.exec_params(query, [session[:uid], id, status])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end

        if request.xhr? # XHR is the X in AJAX, so this is the AJAX call
            crazy_log('if')
            @stock = "testes"
            #
            #halt 200, {stock: @stock}.to_json
        else
            crazy_log('else')
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
            ret = @@conn.exec_params(' INSERT INTO task_tag(tag, uid) VALUES($1, $2) returning id', [tag_name.to_s, session[:uid]])
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
                crazy_log(tag)
                task_tags.push tag["tag_id"]
            end
            crazy_log(task_tags)
            crazy_log(task_tags.include? '2')

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
        id = params[:id]
        begin
            @@conn.exec_params(' update task_sub set done = NOT done where id = $1', [id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end
    end

    get '/kit_task_man/delete_task' do
        id = params[:id]
        begin
            @@conn.exec_params(' delete from task_main where id = $1', [id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end
        redirect to('/kit_task_man')
    end



end




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

    get '/kit_task_man/new_task' do
        kit_log(KIT_LOG_INFO, 'get /kit_task_man/new_task')
        session!

        text = params[:text]
        tags = params[:tags]

        begin
            ret = @@conn.exec_params(' INSERT INTO task_main(text, uid) VALUES($1, $2) returning id', [text.to_s, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end

        query = ' INSERT INTO task_tag_task (task_id, tag_id) VALUES ($1, $2);'
        tags.each do |tag|
            @@conn.exec_params(query, [ret.first['id'], tag])
        end

        redirect to('/kit_task_man')
    end

    #get '/kit_task_man/list_task' do
    def get_list status
        kit_log(KIT_LOG_INFO, 'get /kit_task_man/list_task')
        session!
        begin
            query = 'SELECT * FROM task_main WHERE uid = $1 AND status = $2;'
            ret = @@conn.exec_params(query, [session[:uid], status])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/')
        end
        query_tag_list = "SELECT task_tag_task.tag_id, task_tag.tag FROM task_tag_task LEFT JOIN task_tag ON task_tag.id = task_tag_task.tag_id  WHERE task_tag_task.task_id = $1 ;"

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

            todos << {
                :id => t["id"],
                :text => t["text"],
                :created_at => t["created_at"],
                :task_tags => task_tags,
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
end




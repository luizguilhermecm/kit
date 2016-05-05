class Kit < Sinatra::Base

    get '/notebook' do
        kit_log_breadcrumb('get /notebook', params)
        session!

        erb :"notebook/notebook"
    end

    get '/notebook/update' do
        kit_log_breadcrumb('get /notebook/save_notebook', params)
        session!

        id = params[:id]
        title = params[:title]
        text = params[:text]

        if title.empty?
            kit_log(KIT_LOG_DEBUG, "title is empty")
            @title = "REQUIRED"
            @text = text
            erb :"notebook/notebook"
        else
            kit_log(KIT_LOG_DEBUG, "title not empty", title)
            insert_update id, title, text
        end

    end

    def insert_update id, title, text
        kit_log_breadcrumb('def insert_update id, title, text', id, title, text)

        if id.empty?
            kit_log(KIT_LOG_DEBUG, "insert")
            query = " insert into notebook(title, text, uid) "
            query += " VALUES ($1, $2, $3) returning id;"
        else
            kit_log(KIT_LOG_DEBUG, "update")
            query = " update notebook set "
            query += " title = $1, text = $2 "
            query += " where id = $3 and uid = $4";
        end

        begin
            if id.empty?
                kit_log(KIT_LOG_DEBUG, "insert")
                ret = @@conn.exec_params(query, [title, text, session[:uid]])
                id = ret.first["id"]
            else
                kit_log(KIT_LOG_DEBUG, "update")
                @@conn.exec_params(query, [title, text, id.to_i, session[:uid]])
            end
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-note-xguy2v8dj]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end
        redirect to("/notebook/edit?id=#{id}")
    end

    get '/notebook/list' do
        kit_log_breadcrumb('get /notebook/list', params)
        session!

        @notebooks = []
        query = " SELECT id, title, text, to_char(created_at, '[DD/MM/YYYY]') as created_at FROM notebook where uid = $1";
        begin
            notebooks = @@conn.exec_params(query, [session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-note-8cjd]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        notebooks.each_with_index do |n, i|
            @notebooks << {
                :id => n["id"],
                :title => n["title"],
                :text => n["text"],
                :created_at => n["created_at"],
            }
        end

        erb :"notebook/list"
    end

    get '/notebook/edit' do
        kit_log_breadcrumb('get /notebook/list', params)
        session!
        id = params[:id].to_i
        query = " SELECT id, title, text, to_char(created_at, '[DD/MM/YYYY]') as created_at FROM notebook where uid = $1 and id = $2";
        begin
            notebook = @@conn.exec_params(query, [session[:uid], id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-note-2rasdfh8]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        kit_log(KIT_LOG_DEBUG, notebook.first)
        n = notebook.first
        @id = n["id"]
        @title = n["title"]
        @text = n["text"]

        erb :"notebook/notebook"
    end

    get '/notebook/delete' do
        kit_log_breadcrumb('get /notebook/delete', params)
        session!
        id = params[:id].to_i
        query = " DELETE FROM notebook where uid = $1 and id = $2";
        begin
            @@conn.exec_params(query, [session[:uid], id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-note-2rasdfh8]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        redirect to("/notebook/list")
    end


end

class Kit < Sinatra::Base

    get '/notebook' do
        kit_log_breadcrumb(__method__, params)
        session!

        erb :"notebook/notebook"
    end

    get '/notebook/update' do
        kit_log_breadcrumb(__method__, params)
        session!

        id = params[:id]
        text = params[:editor]

        if text.empty?
            kit_log(KIT_LOG_DEBUG, "title is empty")
            @text = "REQUIRED"
            erb :"notebook/notebook"
        else
            kit_log(KIT_LOG_DEBUG, "title not empty", text)
            insert_update id, text
        end

    end

    post '/notebook/update' do
        kit_log_breadcrumb(__method__, params)
        session!

        id = params[:id]
        text = params[:editor]

        if text.empty?
            kit_log(KIT_LOG_DEBUG, "title is empty")
            @text = "REQUIRED"
            erb :"notebook/notebook"
        else
            kit_log(KIT_LOG_DEBUG, "title not empty", text)
            insert_update id, text
        end

    end

    def insert_update id, text
        kit_log_breadcrumb(__method__, id, text)

        if id.empty?
            kit_log(KIT_LOG_DEBUG, "insert")
            query = " insert into notebook(text, uid, title) "
            query += " VALUES ($1, $2, 'asdf') returning id;"
        else
            kit_log(KIT_LOG_DEBUG, "update")
            query = " update notebook set "
            query += " text = $1 "
            query += " where id = $2 and uid = $3";
        end

        begin
            if id.empty?
                kit_log(KIT_LOG_DEBUG, "insert")
                ret = @@conn.exec_params(query, [text, session[:uid]])
                id = ret.first["id"]
            else
                kit_log(KIT_LOG_DEBUG, "update")
                @@conn.exec_params(query, [text, id.to_i, session[:uid]])
            end
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-note-xguy2v8dj]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end
        redirect to("/notebook/edit?id=#{id}")
    end

    get '/notebook/list' do
        kit_log_breadcrumb(__method__, params)
        session!

        @notebooks = []
        query = " SELECT id, text, to_char(created_at, '[DD/MM/YYYY]') as created_at FROM notebook where uid = $1";
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
                :text => n["text"],
                :title => n["text"].lines.first,
                :created_at => n["created_at"],
            }
        end

        erb :"notebook/list"
    end

    get '/notebook/edit' do
        kit_log_breadcrumb(__method__, params)
        session!
        id = params[:id].to_i
        query = " SELECT id, text, to_char(created_at, '[DD/MM/YYYY]') as created_at FROM notebook where uid = $1 and id = $2";
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
        @text = n["text"]

        erb :"notebook/notebook"
    end

    get '/notebook/delete' do
        kit_log_breadcrumb(__method__, params)
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

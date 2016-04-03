class Kit < Sinatra::Base

    module Label
        D = 'danger'
        W = 'warning'
        I = 'info'
        S = 'success'
        P = 'primary'
    end

    get '/kit_time' do
        kit_log_breadcrumb('get /kit_time', params)
        session!
        @tag_list = get_time_tag_list
        @times = get_time_list nil

        erb :"kit_time/kit_time"
    end

    #get '/kit_time/time_list' do
    def get_time_list tag_id
        #kit_log_breadcrumb('get /kit_time/time_list', params)
        kit_log_breadcrumb('def get_time_list', tag_id)
        session!

        query = " SELECT time.id, time.uid, time.text, time.value, "
        query += " time.charge_date, time.created_at::date "
        query += " FROM time "
        query += " WHERE uid = $1 "
        query += " ORDER BY id desc "

        begin
            ret = @@conn.exec_params(query, [session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-time-xguyv8dj]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        times = []

        query_tag_list = " SELECT time_tag_time.tag_id, time_tag.tag, time_tag.label "
        query_tag_list += " FROM time_tag_time LEFT JOIN time_tag "
        query_tag_list += " ON time_tag.id = time_tag_time.tag_id  "
        query_tag_list += " WHERE time_tag_time.time_id = $1 "


        if tag_id
            query_tag_list += " AND time_tag_time = #{tag_id} "
        end

        ret.each_with_index do |t, i|
            time_tags = []
            tags = @@conn.exec_params(query_tag_list, [t["id"]])
            tags.each do |tag|
                time_tags << {
                    :id => tag["tag_id"],
                    :tag => tag["tag"],
                    :label => tag["label"],
                }
            end

            if t["value"].to_f > 0
                plus = true
                minus = false
            else
                plus = false
                minus = true
            end

            times << {
                :id => t["id"],
                :text =>  t["text"],
                :value => t["value"],
                :charge_date =>  t["charge_date"],
                :created_at =>  t["created_at"],
                :time_tags => time_tags,
                :plus => plus,
                :minus => minus,
            }
        end
        return times
    end



    def get_time_tag_list
        kit_log_breadcrumb('def get_tag_list', nil)
        session!
        begin
            query = 'SELECT * FROM time_tag WHERE uid = $1;'
            ret = @@conn.exec_params(query, [session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-timeuyv8dj]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

        tags = []

        ret.each_with_index do |t, i|
            tags << {
                :id => t["id"],
                :tag => t["tag"],
                :label => t["label"],
                :created_at => t["created_at"],
            }
        end

        return tags
    end

    get '/kit_time/new_time' do
        kit_log_breadcrumb("get '/kit_time/new_time/'", params)
        session!

        type = params[:type]
        text = params[:text]
        value = params[:value].to_f
        payment = params[:payment]
        tags = params[:tags]

        if type == 'outcome'
            value = value * -1
        end

        query =  ' INSERT INTO time(text, value, payment, uid) '
        query += ' VALUES($1, $2, $3, $4) returning id';
        begin
            ret = @@conn.exec_params(query, [text.to_s, value, payment, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-time-xasdf]")
            kit_log(KIT_LOG_ERROR, e, session)
            session[:kmsg] = "ERROR: insert new time failed."
            redirect request.referer
        end

        query_tag = ' INSERT INTO time_tag_time (time_id, tag_id) VALUES ($1, $2);'
        if tags
            tags.each do |tag|
                @@conn.exec_params(query_tag, [ret.first['id'], tag])
            end
        end

        redirect to('/kit_time')
    end

    get '/kit_time/update_time_tag/' do
        kit_log_breadcrumb("get '/kit_time/update_time_tag/'", params)
        session!

        tag_id = params[:tag_id]
        time_id = params[:time_id]

        kit_log(KIT_LOG_DEBUG, 'updating tag of time', "tag_id = #{tag_id}", "time_id = #{time_id}")

        query_insert = " INSERT INTO time_tag_time (time_id, tag_id) VALUES ($1, $2); ";

        query_delete = " DELETE FROM time_tag_time WHERE id = $1; ";

        query_exist = " SELECT id FROM time_tag_time WHERE time_id = $1 AND tag_id = $2 ; ";

        begin
            kit_log(KIT_LOG_DEBUG, "checking if its already exists")
            kit_log(KIT_LOG_DEBUG, "SQL", query_exist, time_id, tag_id)
            ret = @@conn.exec_params(query_exist , [time_id, tag_id])

            if ret.first
                kit_log(KIT_LOG_DEBUG, "yes, it exists, deleting tag")
                kit_log(KIT_LOG_DEBUG, "SQL", query_delete)
                @@conn.exec_params(query_delete, [ret.first["id"]])
            else
                kit_log(KIT_LOG_DEBUG, "no, it does not exists, inserting tag")
                kit_log(KIT_LOG_DEBUG, "SQL", query_insert)
                @@conn.exec_params(query_insert, [time_id, tag_id])
            end

        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end

    end

    get '/kit_time/rm_time' do
        kit_log_breadcrumb('get /kit_time/rm_time', params)
        session!

        time_id = params[:time_id]

        query = " DELETE FROM time WHERE id = $1 AND uid = $2"
        begin
            @@conn.exec_params(query, [time_id.to_s, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-time-asjdf]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end
        redirect request.referer
    end

    get '/kit_time/new_tag' do
        kit_log_breadcrumb('get /kit_time/new_tag', params)
        session!

        tag = params[:tag]
        label = params[:label]

        query = ' INSERT INTO time_tag(tag, label, uid) VALUES($1, $2, $3) returning id'
        begin
            @@conn.exec_params(query, [tag.to_s, label.to_s, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-time-asjdf]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect request.referer
        end
        redirect request.referer
    end


end


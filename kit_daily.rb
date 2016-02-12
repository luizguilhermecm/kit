#CREATE TABLE daily_task (
#id SERIAL PRIMARY KEY,
#text TEXT NOT NULL,
#user_id INTEGER NOT NULL,
#created_at TIMESTAMP DEFAULT now(),
#updated_at TIMESTAMP DEFAULT now(),
#is_valid BOOLEAN DEFAULT TRUE
#);
#
#CREATE TABLE daily_task_journal (
#id SERIAL PRIMARY KEY,
#daily_task_id INTEGER NOT NULL,
#action VARCHAR,
#text TEXT NOT NULL,
#created_at TIMESTAMP DEFAULT now(),
#updated_at TIMESTAMP DEFAULT now()

class Kit < Sinatra::Base

    get '/kit_daily' do
        kit_log(KIT_LOG_INFO, 'get /kit_daily')
        session!
        # if get_daily_tasks catch an error, the @daily_tasks will be
        # @daily_tasks.class : NilClass
        @daily_tasks = get_daily_tasks
        erb :kit_daily
    end

    get '/kit_daily/new_daily_task' do
        kit_log(KIT_LOG_INFO, 'get /kit_daily/new_daily_task')
        session!
        kit_log(KIT_LOG_VERBOSE, 'new daily task with text:', params['daily_task'])
        daily_task = params['daily_task']

        query = " INSERT INTO daily_task (text, user_id) VALUES ($1, $2); "

        begin
            @@conn.exec_params(query, [daily_task, session[:uid]])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-kd-8hv3]", e, session)
            @error = e.to_s
        end
        redirect to ('/kit_daily')
    end

    def get_daily_tasks
        kit_log(KIT_LOG_INFO, 'get /kit_daily/new_daily_task')
        session!

        query  = "\n SELECT daily_task.id id, "
        query += "\n        daily_task.text as text, "
        query += "\n        daily_task.created_at created_at, "
        query += "\n        daily_task.is_valid is_valid, "
        query += "\n        daily_task_journal.id journal_task_id, "
        query += "\n        daily_task_journal.text journal_text, "
        query += "\n        daily_task_journal.done done, "
        query += "\n        daily_task_journal.do_not_apply do_not_apply, "
        query += "\n        daily_task_journal.will_not_do_it will_not_do_it "
        query += "\n    FROM daily_task "
        query += "\n    LEFT JOIN daily_task_journal "
        query += "\n        ON daily_task_journal.daily_task_id = daily_task.id "
        query += "\n        AND daily_task_journal.created_at::date = now()::date "
        query += "\n    WHERE user_id = $1 "
        query += "\n        AND is_valid = $2 ; "
        begin
            kit_log(KIT_LOG_DEBUG, "query to list daily_task", query)
            ret = @@conn.exec_params(query, [session[:uid], true])
            kit_log(KIT_LOG_DEBUG, "number of task on return", ret)
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-kd-2xdDs]", e, session)
            @error = e.to_s
            return
        end

        daily_tasks = []

        kit_log(KIT_LOG_DEBUG, "inserting tasks inside daily_tasks")
        ret.each do |t|
            kit_log(KIT_LOG_DEBUG, "daily_task : id", t["id"])
            daily_tasks << {
                :id => t["id"],
                :text => t["text"],
                :created_at => t["created_at"],
                :is_valid => t["is_valid"],
                :done => t["done"],
                :do_not_apply => t["do_not_apply"],
                :will_not_do_it => t["will_not_do_it"],
                :journal_task_id => t["journal_task_id"],
                :journal_text => t["journal_text"],
            }
        end

        kit_log(KIT_LOG_DEBUG, "returning array of tasks with size:", daily_tasks.size)

        return daily_tasks
    end

    get '/kit_daily/update_task_checkbox' do
        kit_log(KIT_LOG_INFO, 'get /kit_daily/update_task_checkbox', params)
        session!

        task_id = params["task_id"]
        action = params["attr"]
        value = params["value"]

        create_journal_for_task task_id

        query  = "\n UPDATE daily_task_journal "
        query += "\n    set updated_at = now() , "
        query += "\n      #{action} = $2 "
        query += "\n      WHERE  created_at::date = now()::date "
        query += "\n                      AND daily_task_id = $1 ; "

        begin
            kit_log(KIT_LOG_DEBUG, "query", query)
            @@conn.exec_params(query, [task_id, value])
            kit_log(KIT_LOG_DEBUG, "ok")
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-kd-vkdx2]", e, session)
            @error = e.to_s
        end

    end

    get '/kit_daily/update_task_text' do
        kit_log(KIT_LOG_INFO, 'get /kit_daily/update_task_text', params)
        session!

        text = params["text"].to_s
        task_id = params["task_id"].to_i

        create_journal_for_task task_id

        query  = "\n UPDATE daily_task_journal "
        query += "\n    set updated_at = now() , "
        query += "\n      text = $2 "
        query += "\n      WHERE  created_at::date = now()::date "
        query += "\n                      AND daily_task_id = $1"

        begin
            kit_log(KIT_LOG_DEBUG, "query", query)
            @@conn.exec_params(query, [task_id, text])
            kit_log(KIT_LOG_DEBUG, "ok")
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-kd-dxBx2]", e, session)
            @error = e.to_s
        end

    end

    def create_journal_for_task task_id
        kit_log(KIT_LOG_INFO, 'def create_journal_for_task task_id', task_id)
        session!

        query  = "\n INSERT INTO daily_task_journal (daily_task_id) "
        query += "\n     SELECT $1 "
        query += "\n         WHERE "
        query += "\n         NOT EXISTS ( "
        query += "\n             SELECT 1 FROM daily_task_journal "
        query += "\n                  WHERE created_at::date = now()::date "
        query += "\n                      AND daily_task_id = $1"
        query += "\n         ); "

        begin
            kit_log(KIT_LOG_DEBUG, "query", query)
            ret = @@conn.exec_params(query, [task_id])
            kit_log(KIT_LOG_DEBUG, "ret", ret )
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-kd-3cnv@]", e, session)
            @error = e.to_s
        end

    end

    get '/kit_daily/rm_daily_task' do
        kit_log(KIT_LOG_INFO, 'get /kit_daily/rm_daily_task', params)
        session!
        query = " UPDATE daily_task SET is_valid = false WHERE id = $1 ;"
        kit_log(KIT_LOG_DEBUG, "query", query)
        kit_log(KIT_LOG_DEBUG, "with $1:", params["id"])
        begin
            crazy_log("BEFORE")
            @@conn.exec_params(query, [params["id"].to_i])
            crazy_log("AFTER")
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-kd-x3cD]", e, session)
            @error = e.to_s
        end
        redirect to ('/kit_daily')
    end

end
=begin
begin
    # code here
rescue => e
    kit_log(KIT_LOG_ERROR, "[ERROR-kd-]", e, session)
    @error = e.to_s
end
kit_log(KIT_LOG_DEBUG, "")
=end

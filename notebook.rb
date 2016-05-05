class Kit < Sinatra::Base

    get '/notebook' do
        kit_log_breadcrumb('get /notebook', params)
        session!

        erb :notebook
    end

    get '/notebook/update' do
        kit_log_breadcrumb('get /notebook/save_notebook', params)
        session!

        id = params[:id]
        title = params[:title]
        text = params[:text]

        puts id
        #puts title
        puts text

        query = " update notebook set text = $1 where id = $2 ;";
        begin
            @@conn.exec_params(query, [text, id])
        rescue => e
            puts "***************************"
            puts session[:username]
            puts session[:uid]
            puts request.ip
            puts e
            puts "***************************"
            redirect to('/')
        end


        erb :notebook
    end

    get '/notebook/list' do
        kit_log_breadcrumb('get /notebook/list', params)
        session!

        @notebooks = []
        query = " SELECT id, title, text, to_char(created_at, '[DD/MM/YYYY]') as created_at FROM notebook where uid = $1";
        begin
            notebooks = @@conn.exec_params(query, [session[:uid]])
        rescue => e
            puts "***************************"
            puts session[:username]
            puts session[:uid]
            puts request.ip
            puts e
            puts "***************************"
            redirect to('/')
        end

        notebooks.each_with_index do |n, i|
            @notebooks << {
                :id => n["id"],
                :title => n["title"],
                :text => n["text"],
                :created_at => n["created_at"],
            }
        end

        erb :notebook_list
    end
end

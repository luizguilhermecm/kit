class Kit < Sinatra::Base

    get '/frase' do
        session!

        @frases = []
        @limit = 50

        erb :frase_list
    end

    get '/fr_search_frase' do
        session!

        @mot = params[:mot].to_s.downcase.gsub(/drop/,'_drop_')
        @mot = params[:mot].to_s.downcase.gsub(/table/,'_table_')
        @mot = params[:mot].to_s.downcase.gsub(/from/,'_from_')
        @mot = params[:mot].to_s.downcase.gsub(/alter/,'_alter_')
        @mot = params[:mot].to_s.downcase.gsub(/select/,'_select_')
        @mot = params[:mot].to_s.downcase.gsub(/update/,'_update_')
        @mot = params[:mot].to_s.gsub(/'/,'\'\'')
        @limit = params[:limit].to_i

        begin
            query = "SELECT id, frase, translate FROM fr_frase WHERE lower(frase) like \'%#{@mot.downcase}%\' limit #{@limit};"
            ret = @@conn.exec_params(query)
            @mot = params[:mot].to_s.gsub(/''/,'\'')
        rescue => e
            puts "***************************"
            puts session[:username]
            puts session[:uid]
            puts request.ip
            puts e
            puts "***************************"
            redirect to('/frase')
        end

        @frases = []

        ret.each_with_index do |f, i|

            @frases << {
                :id => f["id"],
                :text => f["frase"],
                :translate => f["translate"],
            }
            #puts t

        end

        erb :frase_list
    end

    get '/update_frase' do
        session!

        translate = params[:translate].to_s
        frase_id = params[:frase_id].to_i

        translate = translate.gsub(/'/, '\'\'')
        begin
            query = "update fr_frase SET translate = $1 WHERE id = $2"
            @@conn.exec_params(query, [translate, frase_id])
        rescue => e
            puts "***************************"
            puts session[:username]
            puts session[:uid]
            puts request.ip
            puts e
            puts "***************************"
            redirect to('/frase')
        end
    end

    get '/delete_frase' do
        session!

        frase_id = params[:frase_id].to_i

        begin
            query = "delete from fr_frase WHERE id = $1"
            @@conn.exec_params(query, [frase_id])
        rescue => e
            puts "***************************"
            puts session[:username]
            puts session[:uid]
            puts request.ip
            puts e
            puts "***************************"
            redirect to('/frase')
        end
    end

end

class Kit < Sinatra::Base

    get '/frase' do
        session!

        @frases = []
        @limit = 20

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
            query = "SELECT distinct(frase) FROM fr_frase WHERE lower(frase) like \'%#{@mot.downcase}%\' limit #{@limit};"
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
                :text => f["frase"],
            }
            #puts t

        end

        erb :frase_list
    end

end

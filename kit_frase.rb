class Kit < Sinatra::Base

    get '/frase' do
        session!

        puts "log:frase"

        @frases = []
        @limit = 20

        erb :frase_list
    end

    get '/fr_search_frase' do
        session!

        @mot = params[:mot].to_s.gsub(/'/,'\'\'')
        @limit = params[:limit].to_i

        begin
            query = "SELECT frase FROM fr_frase WHERE lower(frase) like \'%#{@mot.downcase}%\' limit #{@limit};"
            puts query
            ret = @@conn.exec_params(query)
        rescue => e
            puts "***************************"
            puts session[:username]
            puts session[:uid]
            puts request.ip
            puts e
            puts "***************************"
            redirect to('/')
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

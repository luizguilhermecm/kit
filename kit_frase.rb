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
            logging e
            redirect to('/frase')
        end

        @frases = []

        begin
            query = "SELECT id, word, pt_translation, is_cognato FROM fr_words WHERE word = $1;"
            ret.each_with_index do |f, i|
                words = []
                words.concat(f["frase"].scan(/[[:word:]']+/))

                frase_words = []

                words.each do |w|
                    w = w.downcase
                    ret = @@conn.exec_params(query, [w])
                    if ret.first == nil
                        insert_word_into_db w
                        ret = @@conn.exec_params(query, [w])
                    end

                    ret.each do |r|
                        frase_words << {
                            :id => r["id"],
                            :word => r["word"],
                            :pt_translation => r["pt_translation"],
                            :is_cognato => r["is_cognato"],
                        }
                    end
                end

                @frases << {
                    :id => f["id"],
                    :text => f["frase"],
                    :translate => f["translate"],
                    :words => frase_words,
                }

            end
        rescue => e
            logging e
            redirect to('/frase')
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
            logging e
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
            logging e
            redirect to('/frase')
        end
    end

    def insert_word_into_db (param)
        begin
            target_table = "fr_words"
            nb = 1;
            param = param.gsub(/'/, '\'\'')
            #fr_words
            query = "\nUPDATE #{target_table} SET nb = nb + #{nb} WHERE lower(word) = lower('#{param}'); "
            query += " INSERT INTO #{target_table} (nb,word) "
            query += " SELECT #{nb}, lower('#{param}') "
            query += " WHERE  "
            query += " NOT EXISTS (SELECT 1 FROM #{target_table} WHERE lower(word) = lower('#{param}'))  "
            query += " RETURNING ID ;"

            @@conn.exec(query)

            #salvar_carga(query)
        rescue => e
            logging e
            rediret to('/frase')
        end
    end


    get '/update_word' do
        session!

        translate = params[:pt_translate].to_s
        word_id = params[:word_id].to_i

        translate = translate.gsub(/'/, '\'\'')
        begin
            query = "update fr_words SET pt_translation = $1 WHERE id = $2"
            @@conn.exec_params(query, [translate, word_id])
        rescue => e
            logging e
            redirect to('/frase')
        end
    end

    get '/update_word_cognato' do
        session!

        is_cognato = params[:is_cognato]
        word_id = params[:word_id].to_i

        begin
            query = "update fr_words SET is_cognato = $1 WHERE id = $2"
            @@conn.exec_params(query, [is_cognato, word_id])
        rescue => e
            logging e
            redirect to('/frase')
        end
    end

end

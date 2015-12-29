class Kit < Sinatra::Base

    get '/words' do

        kit_log(KIT_LOG_PANIC, "log level", $logging_level)
        kit_log(KIT_LOG_INFO, '/words')
        session!

        @table_list = get_table_list_word
        @target_table = "fr_words"
        @words = []
        @limit = 50
        @offset = 0

        erb :word_search
    end

    get '/frase' do
        kit_log(KIT_LOG_INFO, '/frase')
        session!

        @table_list = get_table_list_frase
        @target_table = "fr_words"
        @frases = []
        @limit = 50
        @offset = 0

        erb :frase_list
    end

    def get_table_list_word
        kit_log(KIT_LOG_INFO, 'def get_table_list_word')
        table_list = []
        table_list << { :name => "fr_words", }
        table_list << { :name => "en_words", }
        table_list << { :name => "pt_words", }
        return table_list
    end

    def get_table_list_frase
        kit_log(KIT_LOG_INFO, 'def get_table_list_frase')
        table_list = []
        table_list << { :name => "en_frase", }
        table_list << { :name => "fr_frase", }
        return table_list
    end

    get '/search_words' do
        kit_log(KIT_LOG_INFO, '/search_words')
        session!
        @table_list = get_table_list_word


        @target_table = params[:target_table]
        if @target_table == "en_words"
            @prefix = "en"
        else
            @prefix = "fr"
        end


        @mot = params[:mot].to_s.downcase

        @orderbynb = params[:orderbynb]

        if @orderbynb and @orderbynb != ""
            orderBy = "\n order by nb desc "
            kit_log(KIT_LOG_VERBOSE, "@orderbynb == true")
        else
            kit_log(KIT_LOG_VERBOSE, "@orderbynb == false")
            orderBy = " "
        end

        @pt_translation_null = params[:pt_translation_null]

        if @pt_translation_null and @pt_translation_null != ""
            where = "\n and pt_translation is null "
            kit_log(KIT_LOG_VERBOSE, "@pt_translation_null == true")
        else
            kit_log(KIT_LOG_VERBOSE, "@pt_translation_null == false")
            where = " "
        end

        @limit = params[:limit].to_i
        @offset = params[:offset].to_i

        begin
            kit_log(KIT_LOG_VERBOSE, "begin")
            query = " SELECT id, word, pt_translation, is_cognato "
            query += " FROM #{@target_table} "
            query += " WHERE lower(word) like \'%#{@mot.downcase}%\' "
            query += where
            query += orderBy
            query += " limit #{@limit} "
            query += " offset #{@offset} "
            kit_log(KIT_LOG_DEBUG, "query:", query)
            ret = @@wum_conn.exec_params(query)
            @mot = params[:mot].to_s.gsub(/''/,'\'')
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/words')
        end

        kit_log(KIT_LOG_VERBOSE, "end")
        words = []

        ret.each do |r|
            words << {
                :id => r["id"],
                :word => r["word"],
                :pt_translation => r["pt_translation"],
                :is_cognato => r["is_cognato"],
            }
        end
        @words = words

        erb :word_search
    end

    get '/fr_search_frase' do
        kit_log(KIT_LOG_INFO, '/fr_search_frase')
        session!
        @table_list = get_table_list_frase


        @target_table = params[:target_table]
        if @target_table == "en_frase"
            @prefix = "en"
        else
            @prefix = "fr"
        end

        @mot = params[:mot].to_s.downcase.gsub(/drop/,'_drop_')
        @mot = params[:mot].to_s.downcase.gsub(/table/,'_table_')
        @mot = params[:mot].to_s.downcase.gsub(/from/,'_from_')
        @mot = params[:mot].to_s.downcase.gsub(/alter/,'_alter_')
        @mot = params[:mot].to_s.downcase.gsub(/select/,'_select_')
        @mot = params[:mot].to_s.downcase.gsub(/update/,'_update_')
        @mot = params[:mot].to_s.gsub(/'/,'\'\'')

        @limit = params[:limit].to_i
        @offset = params[:offset].to_i


        @pt_translation_not_null = params[:pt_translation_not_null]

        where = "";

        if @pt_translation_not_null and @pt_translation_not_null != ""
            where += " \n and translate is not null "
            kit_log(KIT_LOG_VERBOSE, "@pt_translation_not_null == true")
        else
            kit_log(KIT_LOG_VERBOSE, "@pt_translation_not_null == false")
            where += " "
        end

        @pt_translation_null = params[:pt_translation_null]

        if @pt_translation_null and @pt_translation_null != ""
            where += " \n and translate is null "
            kit_log(KIT_LOG_VERBOSE, "@pt_translation_null == true")
        else
            kit_log(KIT_LOG_VERBOSE, "@pt_translation_null == false")
            where += " "
        end

        begin
            kit_log(KIT_LOG_VERBOSE, "begin SELECT FROM", @target_table)
            query = " SELECT id, frase, translate FROM #{@target_table} WHERE lower(frase) like \'%#{@mot.downcase}%\' "
            query += where
            query += " limit #{@limit.to_s} "
            query += " offset #{@offset.to_s} "
            kit_log(KIT_LOG_DEBUG, "query:", query)
            ret = @@wum_conn.exec_params(query)
            @mot = params[:mot].to_s.gsub(/''/,'\'')
            kit_log(KIT_LOG_VERBOSE, "end SELECT FROM", @target_table);
            kit_log(KIT_LOG_VERBOSE, "ret.fields", ret.fields)
            kit_log(KIT_LOG_DEBUG, "ret.values", ret.values)
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/frase')
        end

        @frases = []

        begin
            kit_log(KIT_LOG_VERBOSE, "begin SELECT words")
            if @target_table == "en_frase"
                query = " select w.id as id , w.pt_translation as pt_translation, w.word as word, w.is_cognato as is_cognato, "
                query += " '' as verbo, '' as conjugacao, '' as tempo from en_words w "
                query += " where w.word = $1; "
            else
                query = " select w.id as id , w.pt_translation as pt_translation, w.word as word, w.is_cognato as is_cognato, "
                query += " wv.id, v.verb as verbo, vc.conj as conjugacao, vc.tempo || ' - [v] ' || vt.verb as tempo from fr_words w "
                query += " left join fr_wv wv on wv.word_id = w.id "
                query += " left join fr_verbos v on v.id = wv.verb_id  "
                query += " left join fr_wvw wvw on wvw.word_id = w.id "
                query += " left join fr_verbos_words vw on vw.word = w.word and (v.verb is null or vw.word <> v.verb) "
                query += " left join fr_verbos v2 on v2.id = vw.verb_id and 1 <> 1 "
                query += " left join fr_verbos vt on vt.id = vw.verb_id "
                query += " left join fr_verbos_conj vc on vc.verb_id = vw.verb_id and (vc.conj like '%'''||w.word or vc.conj like '% '||w.word) "
                query += " where w.word = $1; "
            end
            #query = "SELECT id, word, pt_translation, is_cognato FROM fr_words WHERE word = $1;"
            ret.each_with_index do |f, i|
                words = []
                words.concat(f["frase"].scan(/[[:word:]']+/))

                frase_words = []

                words.each do |w|
                    w = w.to_s.downcase
                    kit_log(KIT_LOG_DEBUG, "words.each query:", query, w)
                    ret = @@wum_conn.exec_params(query, [w])
                    if ret.first == nil
                        insert_word_into_db w
                        kit_log(KIT_LOG_DEBUG, "ret.first query:", query, w)
                        ret = @@wum_conn.exec_params(query, [w])
                    end

                    ret.each do |r|
                        frase_words << {
                            :id => r["id"],
                            :word => r["word"],
                            :pt_translation => r["pt_translation"],
                            :is_cognato => r["is_cognato"],
                            :verbo => r["verbo"],
                            :conjugacao => r["conjugacao"],
                            :tempo => r["tempo"],
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
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/frase')
        end

        erb :frase_list
    end

    get '/update_frase' do
        kit_log(KIT_LOG_INFO, '/update_frase')
        session!

        translate = params[:translate].to_s
        frase_id = params[:frase_id].to_i
        @target_table = params[:target_table].to_s

        translate = translate.gsub(/'/, '\'\'')
        begin
            query = "update #{@target_table} SET translate = $1 WHERE id = $2"
            kit_log(KIT_LOG_DEBUG, "query:", query, translate, frase_id)
            @@wum_conn.exec_params(query, [translate, frase_id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/frase')
        end
    end

    get '/delete_frase' do
        kit_log(KIT_LOG_INFO, '/delete_frase')
        session!

        frase_id = params[:frase_id].to_i
        @target_table = params[:target_table].to_s

        begin
            query = "delete from #{@target_table} WHERE id = $1"
            kit_log(KIT_LOG_DEBUG, "query:", query, frase_id)
            @@wum_conn.exec_params(query, [frase_id])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/frase')
        end
    end

    def insert_word_into_db (param)
        kit_log(KIT_LOG_INFO, 'insert_word_into_db (param)', param)
        begin
            nb = 1;
            param = param.gsub(/'/, '\'\'')
            #fr_words

            if @target_table == "en_frase"

                query = "\nUPDATE en_words SET nb = nb + #{nb} WHERE lower(word) = lower('#{param}'); "
                query += " INSERT INTO  en_words (nb,word) "
                query += " SELECT #{nb}, lower('#{param}') "
                query += " WHERE  "
                query += " NOT EXISTS (SELECT 1 FROM en_words WHERE lower(word) = lower('#{param}'))  "


            else

                query = "\nUPDATE #{@target_table} SET nb = nb + #{nb} WHERE lower(word) = lower('#{param}'); "
                query += " INSERT INTO #{@target_table} (nb,word) "
                query += " SELECT #{nb}, lower('#{param}') "
                query += " WHERE  "
                query += " NOT EXISTS (SELECT 1 FROM #{@target_table} WHERE lower(word) = lower('#{param}'))  "
                query += " RETURNING ID ;"
            end

            kit_log(KIT_LOG_DEBUG, "insert_word_into_db query:", query)
            @@wum_conn.exec(query)
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR] insert_word_into_db ")
            kit_log(KIT_LOG_ERROR, e, session)
            rediret to('/frase')
        end
    end


    get '/update_word' do
        kit_log(KIT_LOG_INFO, '/update_word')
        session!

        translate = params[:pt_translate].to_s
        word_id = params[:word_id].to_i
        @target_table = params[:target_table].to_s

        if @target_table == "en_frase"
            save = @target_table
            @target_table = "en_words"
        end
        translate = translate.gsub(/'/, '\'\'')
        begin
            query = "update  #{@target_table} SET pt_translation = $1 WHERE id = $2"

            kit_log(KIT_LOG_DEBUG, "query:", query, translate, word_id)
            @@wum_conn.exec_params(query, [translate, word_id])

            @target_table = save
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/frase')
        end
    end

    get '/update_word_cognato' do
        kit_log(KIT_LOG_INFO, '/update_word_cognato')
        session!

        is_cognato = params[:is_cognato]
        word_id = params[:word_id].to_i

        @target_table = params[:target_table].to_s
        if @target_table == "en_frase"
            save = @target_table
            @target_table = "en_words"
        end

        begin
            query = "update #{@target_table} SET is_cognato = $1 WHERE id = $2"

            kit_log(KIT_LOG_DEBUG, "query:", query, is_cognato, word_id)
            @@wum_conn.exec_params(query, [is_cognato, word_id])
            @target_table = save
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR]")
            kit_log(KIT_LOG_ERROR, e, session)
            redirect to('/frase')
        end
    end

end

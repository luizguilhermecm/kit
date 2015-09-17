#!/usr/bin/env ruby
# encoding: UTF-8

require 'sinatra'
require 'sinatra/base'
require 'rubygems'
require 'pg'
require 'json'
require 'digest/md5'
require "i18n"

#require_relative 'classificador'
#require_relative 'estatistica'
#require_relative 'cards'
#require_relative 'todo_list'


I18n.enforce_available_locales = false

# logging levels
QC_LOG_DEBUG = 48
QC_LOG_VERBOSE = 40
QC_LOG_INFO = 32
QC_LOG_ERROR = 16
QC_LOG_PANIC = 0
# end logging levels



#log_level = QC_LOG_DEBUG
LOGGING_LEVEL = QC_LOG_DEBUG



def do_logging(msg, *params)
    print "[LOG] "
    puts msg.to_s
    params.each_with_index do |p, i|
        if(i == 0)
            puts "[LOG] params: "
        end
        if (p.respond_to?(:each))
            p.each_with_index do |e, k|
                puts "\t[#{k.to_s}] = #{e.to_s} "
            end
        else
            puts "\t[#{i.to_s}] = #{p.to_s} "
        end
    end
end
def qc_log(log_level, msg, *params)

    if(LOGGING_LEVEL >= log_level)
        do_logging(msg, *params)
        #    elsif(log_level == QC_LOG_ERROR)
        #        do_logging(msg, *params)
        #    elsif(log_level == QC_LOG_INFO)
        #        do_logging(msg, *params)
        #    elsif(log_level == QC_LOG_VERBOSE)
        #        do_logging(msg, *params)
        #    elsif(log_level == QC_LOG_DEBUG)
        #        do_logging(msg, *params)
        #    else
        #        do_logging("[error] log level does not exist", log_level)
    end

end


#class QuestoesApp < Sinatra::Base
class Kit < Sinatra::Base

    get '/bijqc' do
        session!

        begin
            @bancas = []

            #form
            @ano         = params[:ano]
            @prova       = params[:prova]
            @banca       = params[:banca]
            @orgao       = params[:orgao]
            @alternativa = params[:alternativa]
            @assunto     = params[:assunto]
            @disciplina  = params[:disciplina]
            @status      = params[:status]
            @mark_words   = params[:mark_words]
            @filtro_id      = params[:filtro_id]
            @filtro_iqid      = params[:filtro_iqid]
            @filtro_sql      = params[:filtro_sql]
            @filtro_and_lower_1 = params[:filtro_and_lower_1]
            @filtro_and_lower_2 = params[:filtro_and_lower_2]
            @filtro_or_lower_1 = params[:filtro_or_lower_1]
            @filtro_or_lower_2 = params[:filtro_or_lower_2]
            @per_page = params[:filtro_per_page].to_i

            if @per_page and @per_page.to_i > 0
                @limite = @per_page.to_i;
            else
                @limite = 10
            end

            filtros = []

            if params[:primeira_pagina] != "" or params[:pagina_atual] == ""
                @page = 1
            else
                @page = params[:pagina_atual].to_i
            end

            where = ""

            if @ano and @ano != "---"
                where += " and ano = #{@ano} "
            end
            if @prova and @prova != "---"
                where += " and prova = '#{@prova}' "
            end
            if @orgao and @orgao != "---"
                where += " and orgao = '#{@orgao}' "
            end
            if @banca and @banca != "---"
                where += " and banca = '#{@banca}' "
            end
            if @disciplina and @disciplina != "---"
                where += " and disciplina = '#{@disciplina}' "
            end
            if @assunto and @assunto != "---"
                where += " and assunto = '#{@assunto}' "
            end

            if @alternativa and @alternativa != ""
                operador, simbolo = " or ", "||" if @alternativa =~ /\|\|/ or @alternativa !~ /&&/
                operador, simbolo = " and ", "&&" if @alternativa =~ /&&/
                puts "**************************"
                prepared_query_palavra = " and (" + @alternativa.split(simbolo).map{|a| "((unaccent(upper(enunciado)) like '%#{I18n.transliterate(a).upcase}%') or (upper(gabarito) = 'A' and unaccent(upper(alternativa_a)) like '%#{a.upcase}%') or (upper(gabarito) = 'B' and unaccent(upper(alternativa_b)) like '%#{a.upcase}%') or (upper(gabarito) = 'C' and unaccent(upper(alternativa_c)) like '%#{a.upcase}%') or (upper(gabarito) = 'D' and unaccent(upper(alternativa_d)) like '%#{a.upcase}%') or (upper(gabarito) = 'E' and unaccent(upper(alternativa_e)) like '%#{a.upcase}%')) "}.join(operador) + ") "
                where += prepared_query_palavra
                puts "**log: palavra query: #{prepared_query_palavra}"
            end

            if @filtro_and_lower_1 and @filtro_and_lower_1 != ""
                filtros << @filtro_and_lower_1
                where += " and lower(alternativa_gabarito||enunciado) like '%#{@filtro_and_lower_1}%' "
            end
            if @filtro_and_lower_2 and @filtro_and_lower_2 != ""
                filtros << @filtro_and_lower_2
                where += " and lower(alternativa_gabarito||enunciado) like '%#{@filtro_and_lower_2}%' "
            end

            if @filtro_or_lower_1 and @filtro_or_lower_1 != ""
                filtros << @filtro_or_lower_1
                where += " or lower(alternativa_gabarito||enunciado) like '%#{@filtro_or_lower_1}%' "
            end
            if @filtro_or_lower_2 and @filtro_or_lower_2 != ""
                filtros << @filtro_or_lower_2
                where += " or lower(alternativa_gabarito||enunciado) like '%#{@filtro_or_lower_2}%' "
            end

            if @filtro_sql and @filtro_sql != ""
                where += "and " + @filtro_sql
            end
            if @filtro_id and @filtro_id != ""
                where += " and id IN (#{@filtro_id.strip.gsub(/\N/,'').gsub(/ +/,',')}) "
            end
            if @filtro_iqid and @filtro_iqid != ""
                where += " and iqid IN (#{@filtro_iqid.strip.gsub(/\N/,'').gsub(/ +/,',')}) "
            end

            if @status and @status.to_i > 0
                puts "log: status = #{@status}"
                if @status.to_i == 1
                    where += "and id IN (SELECT distinct id_questao FROM respostas)"
                elsif @status.to_i == 2
                    where += "and id IN (SELECT distinct id_questao FROM respostas WHERE acertou = 'f')"
                elsif @status.to_i == 3
                    where += "and id NOT IN (SELECT distinct id_questao FROM respostas)"
                elsif @status.to_i == 4
                    where += "and id IN (SELECT distinct id_questao FROM respostas where resposta = 'Z')"
                elsif @status.to_i == 5
                    where += " and id in (select id_questao from respostas where acertou = false and gabarito <> 'Z' and id in (select max(id) from respostas group by id_questao)) "
                else
                    puts "log: error in status value"
                end
            end

            @anos = ["---"] + @@conn.exec("select distinct ano from questoes order by 1").map{|r| r["ano"]};
            @provas = ["---"] + @@conn.exec("select distinct prova from questoes where prova <> '' order by 1").map{|r| r["prova"]};
            @orgaos = ["---"] + @@conn.exec("select distinct orgao from questoes where orgao <> '' order by 1").map{|r| r["orgao"]};
            @bancas = ["---"] + @@conn.exec("select distinct banca from questoes where banca <> '' order by 1").map{|r| r["banca"]};
            @disciplinas = ["---"] + @@conn.exec("select distinct disciplina from questoes where disciplina <> '' order by 1").map{|r| r["disciplina"]};
            @assuntos = ["---"] + @@conn.exec("select distinct assunto from questoes where assunto <> '' order by 1").map{|r| r["assunto"]};

            @sumario = {}
            @questoes = []

            erb :"bij/busca", :layout => false


        rescue => e
            puts e
        end
    end

    get '/buscar' do
        session!
        begin

            @bancas = []

            #form
            @ano         = params[:ano]
            @prova       = params[:prova]
            @banca       = params[:banca]
            @orgao       = params[:orgao]
            @alternativa = params[:alternativa]
            @assunto     = params[:assunto]
            @disciplina  = params[:disciplina]
            @status      = params[:status]
            @mark_words   = params[:mark_words]
            @filtro_id      = params[:filtro_id]
            @filtro_iqid      = params[:filtro_iqid]
            @filtro_sql      = params[:filtro_sql]
            @filtro_and_lower_1 = params[:filtro_and_lower_1]
            @filtro_and_lower_2 = params[:filtro_and_lower_2]
            @filtro_or_lower_1 = params[:filtro_or_lower_1]
            @filtro_or_lower_2 = params[:filtro_or_lower_2]
            @per_page = params[:filtro_per_page].to_i

            if @per_page and @per_page.to_i > 0
                @limite = @per_page.to_i;
            else
                @limite = 100
            end

            filtros = []

            if params[:primeira_pagina] != "" or params[:pagina_atual] == ""
                @page = 1
            else
                @page = params[:pagina_atual].to_i
            end

            where = ""

            if @ano and @ano != "---"
                where += " and ano = #{@ano} "
            end
            if @prova and @prova != "---"
                where += " and prova = '#{@prova}' "
            end
            if @orgao and @orgao != "---"
                where += " and orgao = '#{@orgao}' "
            end
            if @banca and @banca != "---"
                where += " and banca = '#{@banca}' "
            end
            if @disciplina and @disciplina != "---"
                where += " and disciplina = '#{@disciplina}' "
            end
            if @assunto and @assunto != "---"
                where += " and assunto = '#{@assunto}' "
            end

            if @alternativa and @alternativa != ""
                operador, simbolo = " or ", "||" if @alternativa =~ /\|\|/ or @alternativa !~ /&&/
                operador, simbolo = " and ", "&&" if @alternativa =~ /&&/
                puts "**************************"
                prepared_query_palavra = " and (" + @alternativa.split(simbolo).map{|a| "((unaccent(upper(enunciado)) like '%#{I18n.transliterate(a).upcase}%') or (upper(gabarito) = 'A' and unaccent(upper(alternativa_a)) like '%#{a.upcase}%') or (upper(gabarito) = 'B' and unaccent(upper(alternativa_b)) like '%#{a.upcase}%') or (upper(gabarito) = 'C' and unaccent(upper(alternativa_c)) like '%#{a.upcase}%') or (upper(gabarito) = 'D' and unaccent(upper(alternativa_d)) like '%#{a.upcase}%') or (upper(gabarito) = 'E' and unaccent(upper(alternativa_e)) like '%#{a.upcase}%')) "}.join(operador) + ") "
                where += prepared_query_palavra
                puts "**log: palavra query: #{prepared_query_palavra}"


            end

            if @filtro_and_lower_1 and @filtro_and_lower_1 != ""
                filtros << @filtro_and_lower_1
                where += " and lower(alternativa_gabarito||enunciado) like '%#{@filtro_and_lower_1}%' "
            end
            if @filtro_and_lower_2 and @filtro_and_lower_2 != ""
                filtros << @filtro_and_lower_2
                where += " and lower(alternativa_gabarito||enunciado) like '%#{@filtro_and_lower_2}%' "
            end

            if @filtro_or_lower_1 and @filtro_or_lower_1 != ""
                filtros << @filtro_or_lower_1
                where += " or lower(alternativa_gabarito||enunciado) like '%#{@filtro_or_lower_1}%' "
            end
            if @filtro_or_lower_2 and @filtro_or_lower_2 != ""
                filtros << @filtro_or_lower_2
                where += " or lower(alternativa_gabarito||enunciado) like '%#{@filtro_or_lower_2}%' "
            end

            if @filtro_sql and @filtro_sql != ""
                where += "and " + @filtro_sql
            end
            if @filtro_id and @filtro_id != ""
                where += " and id IN (#{@filtro_id.strip.gsub(/\N/,'').gsub(/ +/,',')}) "
            end
            if @filtro_iqid and @filtro_iqid != ""
                where += " and iqid IN (#{@filtro_iqid.strip.gsub(/\N/,'').gsub(/ +/,',')}) "
            end

            if @status and @status.to_i > 0
                puts "log: status = #{@status}"
                if @status.to_i == 1
                    where += "and id IN (SELECT distinct id_questao FROM respostas)"
                elsif @status.to_i == 2
                    where += "and id IN (SELECT distinct id_questao FROM respostas WHERE acertou = 'f')"
                elsif @status.to_i == 3
                    where += "and id NOT IN (SELECT distinct id_questao FROM respostas)"
                elsif @status.to_i == 4
                    where += "and id IN (SELECT distinct id_questao FROM respostas where resposta = 'Z')"
                elsif @status.to_i == 5
                    where += " and id in (select id_questao from respostas where acertou = false and gabarito <> 'Z' and id in (select max(id) from respostas group by id_questao)) "
                else
                    puts "log: error in status value"
                end
            end

            #total de questoes
            @qtde = @@conn.exec("select count(*) qtde from questoes where  1 = 1 #{where}").first['qtde'] || 0 rescue 0
            @qtde_paginas = (@qtde.to_i/@limite.to_f).ceil
            @qtde_resolvidas = @@conn.exec("select count(distinct id_questao) qtde from respostas where id_questao in ( select id from questoes where 1 = 1 #{where})").first['qtde'] || 0 rescue 0;

            # @anos = ["---"] + @@conn.exec("select distinct ano from questoes order by 1").map{|r| r["ano"]};
            @provas = ["---"] + @@conn.exec("select distinct prova from questoes where prova <> '' order by 1").map{|r| r["prova"]};
            @orgaos = ["---"] + @@conn.exec("select distinct orgao from questoes where orgao <> '' order by 1").map{|r| r["orgao"]};
            @bancas = ["---"] + @@conn.exec("select distinct banca from questoes where banca <> '' order by 1").map{|r| r["banca"]};
            @disciplinas = ["---"] + @@conn.exec("select distinct disciplina from questoes where disciplina <> '' order by 1").map{|r| r["disciplina"]};
            @assuntos = ["---"] + @@conn.exec("select distinct assunto from questoes where assunto <> '' order by 1").map{|r| r["assunto"]};

            questoes_query = "select id, qid, banca, orgao, ano, prova, prova_id, prova_nome, aplicada_em, disciplina, assunto, assunto_b, texto_associado, enunciado, alternativa_a, alternativa_b, alternativa_c, alternativa_d, alternativa_e, gabarito, link, comentario, view_count from questoes where 1 = 1 #{where} order by ano desc, iqid, id limit #{@limite} offset #{(@page - 1) * @limite}"
            questoes = @@conn.exec(questoes_query)
            puts " ----------- SQL ----------------- "
            puts questoes_query
            puts " ----------- SQL ----------------- "

=begin

   ************************************************************************************************************************

=end

            @sumario = {}

            @@conn.exec("select disciplina, count(*) qtde from questoes where 1 = 1 #{where} group by disciplina order by 2 desc").each do |sumario|
                @sumario[sumario["disciplina"]] = {
                    :qtde => sumario["qtde"],
                    :assuntos => [],
                    :qtde_resolvida => (@@conn.exec("select count(distinct id_questao) qtde from respostas where id_questao in ( select id from questoes where disciplina = '#{sumario["disciplina"]}' #{where})").first['qtde'] || 0 rescue 0)
                }
            end
            @@conn.exec("select disciplina, assunto, count(*) qtde from questoes where 1 = 1 #{where} group by disciplina, assunto order by 3 desc, 1, 2").each do |sumario|

                hash_ano_qtde = Hash[(1..5).map{|i| [(Time.now.year - i).to_i, "0"]}] # {2015 => 0, 2014 => 0, ...}
                anos_qtdes = @@conn.exec("select ano, count(*) qtde from questoes where 1 = 1 and disciplina = '#{sumario["disciplina"]}' and assunto = '#{sumario["assunto"]}' and ano between to_char(now()::date, 'yyyy')::int - 5 and to_char(now()::date, 'yyyy')::int-1 #{where} group by ano order by ano desc").map{|r| [r["ano"].to_i, r["qtde"]]}
                hash_ano_qtde = hash_ano_qtde.merge(Hash[anos_qtdes])

                @sumario[sumario["disciplina"]][:assuntos] << {
                    :qtde => sumario["qtde"],
                    :assunto => sumario["assunto"],
                    :qtde_resolvida => (@@conn.exec("select count(distinct id_questao) qtde from respostas where id_questao in ( select id from questoes where disciplina = '#{sumario["disciplina"]}' and assunto = '#{sumario["assunto"]}' #{where})").first['qtde'] || 0 rescue 0),
                    :hash_ano_qtde => hash_ano_qtde
                }
            end
=begin

   ************************************************************************************************************************

=end



            @questoes = []

            @olap_head = []

            questoes.each do |q|

                acertos_erros = @@conn.exec("select count(nullif(acertou, true)) qtde_erros, count(nullif(acertou, false)) qtde_acertos from respostas where id_questao = #{q['id']}").first

                q_words_bd = []#@@conn.exec("select words from get_words_from_id(#{q['id']})")
                q_words_candidate_bd = []#@@conn.exec("select words from get_words_candidate_from_id(#{q['id']})")
                q_words = []
                q_words_candidate = []
                marks = []

                q_words_bd.each do |w|
                    q_words << {
                        :word => w['words']
                    }
                end

                q_words_candidate_bd.each do |w|
                    q_words_candidate << {
                        :word => w['words']
                    }
                    marks << w['words']
                end


                @olap_head << {

                    :q_words => q_words,
                    :q_words_candidate => q_words_candidate
                }


                if not filtros.empty?
                    q["enunciado"] = q["enunciado"].to_s.gsub(/(#{filtros.join('|')})/i, '<mark>\1</mark>')
                    q["alternativa_a"] = q["alternativa_a"].to_s.gsub(/(#{filtros.join('|')})/i, '<mark>\1</mark>')
                    q["alternativa_b"] = q["alternativa_b"].to_s.gsub(/(#{filtros.join('|')})/i, '<mark>\1</mark>')
                    q["alternativa_c"] = q["alternativa_c"].to_s.gsub(/(#{filtros.join('|')})/i, '<mark>\1</mark>')
                    q["alternativa_d"] = q["alternativa_d"].to_s.gsub(/(#{filtros.join('|')})/i, '<mark>\1</mark>')
                    q["alternativa_e"] = q["alternativa_e"].to_s.gsub(/(#{filtros.join('|')})/i, '<mark>\1</mark>')
                end

                #        if !q_words_candidate.empty? and @mark_words
                #            puts "log: marking words"
                #           q["enunciado"] = q["enunciado"].to_s.gsub(/(#{marks.join('|')})/i, '<mark>\1</mark>')
                #           q["alternativa_gabarito"] = q["alternativa_gabarito"].to_s.gsub(/(#{marks.join('|')})/i, '<mark>\1</mark>')
                #        end
                full_name =  q["prova_id"].to_s << " - " << q["prova_nome"].to_s << " - " << q["aplicada_em"].to_s

                @questoes << {
                    :q_words => q_words,
                    :q_words_candidate => q_words_candidate,
                    :qtde_acertos => acertos_erros['qtde_acertos'],
                    :qtde_erros => acertos_erros['qtde_erros'],
                    :id => q["id"],
                    :banca => q["banca"],
                    :orgao => q["orgao"],
                    :prova => q["prova"],
                    :prova_nome => q["prova_id"].to_s << " - " << q["prova_nome"].to_s << " - " << q["aplicada_em"].to_s,
                    :ano => q["ano"],
                    :disciplina => q["disciplina"],
                    :assunto => q["assunto"],
                    :assunto_b => q["assunto_b"],
                    :texto_associado => q["texto_associado"],
                    :enunciado => q["enunciado"],
                    :alternativa_a => q["alternativa_a"],
                    :alternativa_b => q["alternativa_b"],
                    :alternativa_c => q["alternativa_c"],
                    :alternativa_d => q["alternativa_d"],
                    :alternativa_e => q["alternativa_e"],
                    :gabarito => q["gabarito"],
                    :link => q["link"],
                    :qid => q["qid"],
                    :comentario => q["comentario"],
                    :view_count => q["view_count"]
                }

            end

            erb :"bij/index", :layout => false

        rescue => e
            puts e
        end
    end

    get '/view_count/' do
        session!
        begin
            puts "log: viewer_count(#{params[:id]}, '#{Time.now}')"
            @@conn.exec("select view_count_inc('#{params[:id]}')")
        rescue => e
            puts e
        end
    end



    get '/salvar_resposta/' do
        session!
        begin
            puts "log: salvar_resposta (#{params[:id]}, '#{Time.now}', #{params[:acertou]}, '#{params[:resposta]}')"
            @@conn.exec("insert into respostas (id_questao, data, acertou, resposta) values (#{params[:id]}, '#{Time.now}', #{params[:acertou]}, '#{params[:resposta]}')")
        rescue => e
            puts e
        end
    end

=begin
  get '/insert_word/' do
      puts "log: insert_word #{params[:word]}"
    @@conn.exec("INSERT INTO word_key (word) SELECT '#{params[:word]}' WHERE NOT EXISTS (SELECT 1 FROM word_key WHERE word = '#{params[:word]}')")
    puts "log: get_word_questao id: #{params[:id]}"
    words_bd = @@conn.exec("SELECT upper(word) as word FROM ts_stat('select to_tsvector(''snk_dic'', enunciado) from questoes where id = #{params[:id]}') INTERSECT SELECT word from word_key")
    words_bd.each do |x|
        puts x
      @word_manager << {
        :word => x['word']
        }
    end
    @word_manager.each do |w|
        puts "log: words = #{w[:word]}"
    end
    @word_manager.to_json
  end
=end

    get '/organizar_nsdk/' do
        session!
        begin
            puts "log: organizar_nskd: disciplina: #{params[:disciplina]}, assunto: #{params[:assunto]}, id: #{params[:id]} }"
            @@conn.exec("update questoes set disciplina = '#{params[:disciplina]}', assunto = '#{params[:assunto]}' where id = #{params[:id]}")
        rescue => e
            puts e
        end
    end

    get '/organizar_disciplina/' do
        session!
        begin
            #@@conn.exec("update questoes set disciplina = '#{params[:disciplina]}', assunto = '#{params[:assunto]}' where id = #{params[:id]}")
            @@conn.exec("update questoes set disciplina = '#{params[:disciplina]}' where id = #{params[:id]}")
        rescue => e
            puts e
        end
    end

    get '/organizar_assunto/' do
        session!
        begin
            #@@conn.exec("update questoes set disciplina = '#{params[:disciplina]}', assunto = '#{params[:assunto]}' where id = #{params[:id]}")
            @@conn.exec("update questoes set assunto = '#{params[:assunto]}' where id = #{params[:id]}")
        rescue => e
            puts e
        end
    end

    get '/organizar_assunto_b/' do
        session!
        begin
            puts "log: organizar_assunto_b : #{params.inspect}"
            #@@conn.exec("update questoes set disciplina = '#{params[:disciplina]}', assunto = '#{params[:assunto]}' where id = #{params[:id]}")
            @@conn.exec("update questoes set assunto_b = '#{params[:assunto_b]}' where id = #{params[:id]}")
        rescue => e
            puts e
        end
    end


    get '/contador' do
        session!
        begin
            erb :"bij/contador", :layout => false
        rescue => e
            puts e
        end
    end

    get '/set_bad_flag/' do
        session!
        begin
            puts "log: flag_bad setted"
            @@conn.exec("update questoes set flag_bad = 't' where id = #{params[:id]}");
        rescue => e
            puts e
        end
    end

    get '/set_check_flag/' do
        session!
        begin
            puts "log: flag_check setted"
            @@conn.exec("update questoes set flag_check = 't' where id = #{params[:id]}");
            erb :"bij/index", :layout => false

        rescue => e
            puts e
        end
    end


    get '/snk_comentario/' do
        session!
        begin
            @@conn.exec("insert into comentario_snk (id, comentario) values (#{params[:id]},'#{params[:snk_comment]}')")
        rescue => e
            puts e
        end
    end

    get '/snk_word/' do
        session!
        begin
            params[:hot_keys].split(", ").each do |hk|
                @@conn.exec("insert into hot_keys (id, hot_key) values (#{params[:id]},'#{hk}')")
            end
        rescue => e
            puts e
        end
    end

    get '/insert_key_word/' do
        session!
        begin
            puts "log: insert_key_word #{params[:word]}"
            #@@conn.exec("INSERT INTO word_key (word) SELECT '#{params[:word]}' WHERE NOT EXISTS (SELECT 1 FROM word_key WHERE word = '#{params[:word]}')")
            #@@conn.exec("select insert_word_key('#{params[:word]}')")
        rescue => e
            puts e
        end
    end


    get '/insert_hot_key_word/' do
        session!
        begin
            puts "log: insert_hot_key_word #{params[:id]} #{params[:word]}"
            @@conn.exec("insert into hot_keys (id, hot_key) values (#{params[:id]},'#{params[:word]}')")
            #@@conn.exec("INSERT INTO word_key (word) SELECT '#{params[:word]}' WHERE NOT EXISTS (SELECT 1 FROM word_key WHERE word = '#{params[:word]}')")
        rescue => e
            puts e
        end
    end

    get '/insert_stop_word/' do
        session!
        begin
            puts "log: insert_stop_word #{params[:word]}"
            @@conn.exec("select insert_word_stop('#{params[:word]}')")
            #@@conn.exec("INSERT INTO word_stop (word) SELECT '#{params[:word]}' WHERE NOT EXISTS (SELECT 1 FROM word_key WHERE word = '#{params[:word]}')")
        rescue => e
            puts e
        end
    end

    get '/buscar_nsdk/' do
        puts "log: buscar_nsdk: id: #{params[:id]}, disciplina: #{params[:disciplina]}, assunto: #{params[:assunto]}"
        where = " and (" + params[:term].split(" ").map{|e| " unaccent(upper(assunto_disciplina)) like '%#{I18n.transliterate(e).upcase}%' "}.join(" and ") + ") "

        @assuntos_auto = @@conn.exec("select assunto_disciplina, assunto, disciplina from (
            select distinct assunto || ' [' || disciplina || ']' assunto_disciplina, assunto, disciplina from questoes where assunto <> ''
        ) a where 1 = 1 #{where} order by 1
                                     ").map do |r|
                                     {:assunto => r["assunto"], :disciplina => r["disciplina"],  :label => r["assunto_disciplina"], :value =>  r["assunto_disciplina"]}
        end
        @assuntos_auto.to_json
    end


#    get '/buscar_nsdk/' do
#        session!
#        begin
#            puts "log: buscar_nsdk: id: #{params[:id]}, disciplina: #{params[:disciplina]}, assunto: #{params[:assunto]}"
#            where = " and (" + params[:term].split(" ").map{|e| " unaccent(upper(assunto_disciplina)) like '%#{I18n.transliterate(e).upcase}%' "}.join(" and ") + ") "
#
#            @assuntos_auto = @@conn.exec("select assunto_disciplina, assunto, disciplina from (select distinct assunto || ' [' || disciplina || ']' assunto_disciplina, assunto, disciplina from questoes where assunto <> '') a where 1 = 1 #{where} order by 1 ").map do |r| {
#                :assunto => r["assunto"], :disciplina => r["disciplina"],  :label => r["assunto_disciplina"], :value =>  r["assunto_disciplina"]
#            }
#    end
#    @assuntos_auto.to_json
#        rescue => e
#            puts e
#        end
#  end

    get '/buscar_assunto/' do
        session!
        begin
            puts params.inspect
            where = " and (" + params[:term].split(" ").map{|e| " unaccent(upper(assunto)) like '%#{I18n.transliterate(e).upcase}%' "}.join(" and ") + ") "
            where_b = " and (" + params[:term].split(" ").map{|e| " unaccent(upper(assunto_b)) like '%#{I18n.transliterate(e).upcase}%' "}.join(" and ") + ") "

            puts "log: buscar_assunto : where: #{where}"
            puts "log: buscar_assunto : where_b: #{where_b}"
            @assuntos_auto = @@conn.exec("select distinct assunto from (select assunto from questoes where disciplina = '#{params[:disciplina_id]}' and 1 = 1 #{where} UNION select assunto_b as assunto from questoes where disciplina = '#{params[:disciplina_id]}' and 1 = 1 #{where_b} )q order by assunto asc
                                         ").map do |r|
                {:assunto => r["assunto"], :disciplina => r["disciplina"],  :label => r["assunto"], :value =>  r["assunto"]}
            end
            @assuntos_auto.to_json
        rescue => e
            puts e
        end

    end


    get '/buscar_disciplina/' do
        session!
        begin
            where = " and (" + params[:term].split(" ").map{|e| " unaccent(upper(disciplina)) like '%#{I18n.transliterate(e).upcase}%' "}.join(" and ") + ") "
            @assuntos_auto = @@conn.exec("select distinct disciplina from questoes where 1 = 1 #{where} order by disciplina asc
                                         ").map do |r|
                {:assunto => r["disciplina"], :disciplina => r["disciplina"],  :label => r["disciplina"], :value =>  r["disciplina"]}
            end
            @assuntos_auto.to_json
        rescue => e
            puts e
        end

    end

    get '/buscar_prova/' do
        session!
        begin
            where = " and (" + params[:term].split(" ").map{|e| " unaccent(upper(toda_prova)) like '%#{I18n.transliterate(e).upcase}%' "}.join(" and ") + ") "
            @prova_auto = @@conn.exec("select toda_prova, qtde, ano, banca, orgao, prova from (
            select '[' || banca || '-' || ano  || '] [' ||  orgao || '] ' || prova toda_prova, count(*) qtde, ano, banca, orgao, prova from questoes group by ano, prova, orgao, banca
        ) a where 1 = 1 #{where} order by 1
                                      ").map do |r|
                {
                    :label => r["toda_prova"] + " (#{r["qtde"]} questões)",
                    :value =>  r["toda_prova"],
                    :banca => r["banca"],
                    :prova => r["prova"],
                    :orgao => r["orgao"],
                    :ano => r["ano"],
                }
            end
            @prova_auto.to_json
        rescue => e
            puts e
        end

    end

    get '/buscar_word/' do
        session!
        begin
            where = " and (" + params[:term].split(" ").map{|e| " unaccent(upper(disciplina)) like '%#{I18n.transliterate(e).upcase}%' "}.join(" and ") + ") "

            @word_auto = @@conn.exec("select (word || ' - ' || ndoc) as word from stat_total where word = lower('#{params[:term]}')
                                     ").map do |r|
                {:word => r["word"], :word => r["word"],  :label => r["word"], :value =>  r["word"]}
            end
            @word_auto.to_json
        rescue => e
            puts e
        end

    end


    get '/on_change_filtro' do
        session!
        begin
            carregar_filtros(params[:filtro]).to_json
        rescue => e
            puts e
        end

    end

    def carregar_filtros(filtro_atual)
        begin
            filtros = ["banca", "ano", "orgao", "prova", "disciplina", "assunto"]

            if filtro_atual and params[filtro_atual.to_sym] and params[filtro_atual.to_sym] != "---"
                where = " #{filtro_atual} = '#{params[filtro_atual.to_sym]}' "
            else
                where = " 1 = 1 "
            end

            retorno = {:filtro => filtro_atual}
            filtros.each do |filtro|
                where2 = filtros.select{|x| x != filtro}.map{|x| " and #{x} = '#{params[x.to_sym]}' " if params[x.to_sym] and params[x.to_sym] != "---"}.join("")
                where3 = filtro != "ano" ? " and #{filtro} <> '' " : ""

                retorno[(filtro + "s").to_sym] = gerar_options_select(
                    params[filtro.to_sym],
                    @@conn.exec("select distinct #{filtro} from questoes where #{where} #{where2} #{where3} order by 1").map{|r| r[filtro]}
                )
            end

            retorno
        rescue => e
            puts e
        end

    end

    def gerar_options_select(valor_anterior, array)
        (["---"] + array).map{|i| "<option val='#{i}' #{"selected='true'" if valor_anterior.to_s == i}>#{i}</option>"}
    end

    get '/carregar_texto_associado' do
        session!
        begin
            texto_associado = @@conn.exec("select texto_associado from questoes where qid = 'Q' || (
      select max(replace(qid, 'Q', '')::int) from questoes where replace(qid, 'Q', '')::int <= #{params[:qid].gsub(/\D/, '')} and texto_associado <> ''
    )").first["texto_associado"]

            {:texto_associado => texto_associado}.to_json
        rescue => e
            puts e
        end

    end

run! if app_file == $0

end

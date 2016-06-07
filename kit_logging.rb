# logging levels

KIT_LOG_DEBUG   = 48  # o mais verboso possivel
KIT_LOG_VERBOSE = 40
KIT_LOG_INFO    = 32
KIT_LOG_ERROR   = 16
KIT_LOG_PANIC   = 0 # loga o mínimo possível
# end logging levels

class Kit < Sinatra::Base
    # inline error logging
    # params:
    #   e : exception
    #   session : sinatra session
    #   method : name of the method where rescue occured
    #   redirect : if will be done "redirect request.referer"
    def kit_rescue e, session, method, redirect
            kit_log(KIT_LOG_ERROR, "[ERROR] [#{method}]")
            kit_log(KIT_LOG_ERROR, e, session)
            if redirect
                redirect request.referer
            end
    end

    def log_request request
        puts JSON.pretty_generate(request.env).green
    end
    def request_log request
        puts JSON.pretty_generate(request.env).green
    end


    def get_log_head_string
        if $logging_level == KIT_LOG_DEBUG
            return "\n[LOG:48] "
        elsif $logging_level == KIT_LOG_VERBOSE
            return "\n[LOG:40] "
        elsif $logging_level == KIT_LOG_INFO
            return "\n[LOG:32] "
        elsif $logging_level == KIT_LOG_ERROR
            return "\n[LOG:16] "
        elsif $logging_level == KIT_LOG_PANIC
            return "\n[LOG:0] "
        else
            return "\n[LOG:-1] "
        end
    end

    def do_logging(msg, *params)
        log_string = get_log_head_string
        log_string += msg.to_s
        params.each_with_index do |p, i|
            if(i == 0 and params.size == 1)
                #puts "[LOG] params: "
            end
            if (p.respond_to?(:each))
                p.each_with_index do |e, k|
                    log_string += "\n-\t[#{k.to_s}] = #{e.to_s} "
                end
            else
                log_string += "\n-\t[#{i.to_s}] = #{p.to_s} "
            end
        end
        log_string = check_log_hash log_string
        puts log_string
        open("./log.txt", 'a') { |f| f << log_string << "\n"}
    end

    def check_log_hash m
        hash = Digest::MD5.hexdigest(m)
        if hash == session[:log_hash]
            return "..."
        else
            session[:log_hash] = hash
        end
        return m
    end


    def kit_log(log_level, msg, *params)
        begin
            if($logging_level >= log_level)
                do_logging(msg, *params)
            end
        rescue => e
            puts "*[LOG_ERROR] error while logging the follow param"
            puts "-\t[log_level] = #{log_level}"
            puts "-\t[msg] = #{msg}"
            puts "-\t[printing error object]"
            puts e
        end
    end

    def kit_log_breadcrumb(source, requet_params, *params)
        begin
            if requet_params.class == Hash
                kit_log(KIT_LOG_INFO, "source: #{source}",
                        "detail of params attribute:",
                        "params.class: #{requet_params.class}",
                        "params.size #{requet_params.size if requet_params.respond_to? :size}", requet_params, *params)
            elsif requet_params
                kit_log(KIT_LOG_INFO, "source: #{source}",
                        requet_params, *params)
            else
                kit_log(KIT_LOG_INFO, "source: #{source}",
                        *params)
            end

            rescue => e
                puts "*[LOG_ERROR] error while logging the follow param"
                puts "-\t[log_level] = #{log_level}"
                puts "-\t[msg] = #{msg}"
            puts "-\t[printing error object]"
            puts e
        end
    end



    def log_crazy(*params)
        crazy_log params
    end

    def crazy_log(*params)
        log_string = "."
        params.each_with_index do |p, i|
            if(i == 0 and params.size == 1)
                #puts "[LOG] params: "
            end
            if (p.respond_to?(:each))
                p.each_with_index do |e, k|
                    log_string += "\n-\t[#{k.to_s}] = #{e.to_s} "
                end
            else
                log_string += "\n-\t[#{i.to_s}] = #{p.to_s} "
            end
        end

        puts "*********".red
        puts "\n\n\n"
        puts "*********".green
        puts log_string.yellow
        puts "*********".green
        puts "\n\n\n"
        puts "*********".red

    end
end

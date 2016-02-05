# logging levels

KIT_LOG_DEBUG   = 48  # o mais verboso possivel
KIT_LOG_VERBOSE = 40
KIT_LOG_INFO    = 32
KIT_LOG_ERROR   = 16
KIT_LOG_PANIC   = 0 # loga o mínimo possível
# end logging levels

class Kit < Sinatra::Base

    def get_log_head_string
        if $logging_level == KIT_LOG_DEBUG
            return "[LOG:48] "
        elsif $logging_level == KIT_LOG_VERBOSE
            return "[LOG:40] "
        elsif $logging_level == KIT_LOG_INFO
            return "[LOG:32] "
        elsif $logging_level == KIT_LOG_ERROR
            return "[LOG:16] "
        elsif $logging_level == KIT_LOG_PANIC
            return "[LOG:0] "
        else
            return "[LOG:-1] "
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

        puts log_string
        open("./log.txt", 'a') { |f| f << log_string << "\n"}
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

        puts "*********"
        puts "\n\n\n"
        puts "*********"
        puts log_string
        puts "*********"
        puts "\n\n\n"
        puts "*********"

    end
end

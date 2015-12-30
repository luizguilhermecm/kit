# logging levels

KIT_LOG_DEBUG   = 48  # o mais verboso possivel
KIT_LOG_VERBOSE = 40
KIT_LOG_INFO    = 32
KIT_LOG_ERROR   = 16
KIT_LOG_PANIC   = 0 # loga o mínimo possível
# end logging levels

class Kit < Sinatra::Base
def do_logging(msg, *params)
    print "[LOG] "
    puts msg.to_s
    params.each_with_index do |p, i|
        if(i == 0 and params.size == 1)
            #puts "[LOG] params: "
        end
        if (p.respond_to?(:each))
            p.each_with_index do |e, k|
                puts "-\t[#{k.to_s}] = #{e.to_s} "
            end
        else
            puts "-\t[#{i.to_s}] = #{p.to_s} "
        end
    end
end

def kit_log(log_level, msg, *params)
    begin
    if($logging_level >= log_level)
        do_logging(msg, *params)
    end
    rescue => e
        puts e
    end
end
end

class Kit < Sinatra::Base

    get '/kit_files' do
        kit_log(KIT_LOG_INFO, 'get /kit_files')
        session!
        @files = list_uploaded_files ''
        @dirs = list_directories ''
        erb :kit_files
    end

    def list_directory dirname
        kit_log(KIT_LOG_INFO, 'def list_directory', dirname)
        puts "\n\n OK"
        @files = list_uploaded_files dirname
        @dirs = list_directories dirname
        @full_path = dirname
        erb :kit_files
    end


    post '/kit_files/create_directory' do
        kit_log(KIT_LOG_INFO, 'get /kit_files/create_directory')
        session!
        kit_log(KIT_LOG_VERBOSE, 'Creating new directory with path', params['path'])
        path0 = params['path']
        path = params['path']

        kit_log(KIT_LOG_VERBOSE, 'Checking given path for ...', '^\/', '*', '&', '`', '~', '(', ')', '?', '<', '>', ':', "\"", "\'", ";", "|", '\\', '^')
        #/a*&`~()?<>"'|\:^
        path = path.gsub(/^\//, '')
        #path = path.gsub(/\//, '')
        path = path.gsub(/\*/, '')
        path = path.gsub(/\&/, '')
        path = path.gsub(/`/, '')
        path = path.gsub(/~/, '')
        path = path.gsub(/\(/, '')
        path = path.gsub(/\)/, '')
        path = path.gsub(/\?/, '')
        path = path.gsub(/</, '')
        path = path.gsub(/>/, '')
        path = path.gsub(/:/, '')
        path = path.gsub(/"/, '')
        path = path.gsub(/'/, '')
        path = path.gsub(/;/, '')
        path = path.gsub(/\|/, '')
        path = path.gsub(/\\/, '')
        path = path.gsub(/\^/, '')

        kit_log(KIT_LOG_VERBOSE, 'path checked', 'given path: ' + path0, 'result path: ' + path)

        create_directory path
        erb :kit_files
    end


    post "/kit_files/upload" do
        kit_log(KIT_LOG_INFO, 'post /kit_files/upload')
        session!
        kit_log(KIT_LOG_VERBOSE, 'uploading file', params)
        begin
            check_directory_exists
            full_path = params["full_path"]
            if File.exist?("uploads/#{session[:username]}/#{full_path}/" + params['file'][:filename])
                File.open("uploads/#{session[:username]}/#{full_path}/X" + params['file'][:filename], "w") do |f|
                    f.write(params['file'][:tempfile].read)
                end
            else
            File.open("uploads/#{session[:username]}/#{full_path}/" + params['file'][:filename], "w") do |f|
                f.write(params['file'][:tempfile].read)
            end
            end
        rescue => e
            kit_log(KIT_LOG_PANIC, "[ERROR-kf34d]", e, session)
            redirect to('/kit_files')
        end
        redirect to('/kit_files')
    end

    def check_directory_exists
        kit_log(KIT_LOG_INFO, 'def check_directory_exists')

        if File.directory?("./uploads/#{session[:username]}")
            kit_log(KIT_LOG_DEBUG, 'directory exists', "./uploads/#{session[:username]}")
        else
            create_user_directory
        end
    end

    def create_directory path
        kit_log(KIT_LOG_INFO, 'def create_directory', "./uploads/#{session[:username]}/#{path}" )
        begin
            Dir.mkdir("./uploads/#{session[:username]}/#{path}")
        rescue => e
            kit_log(KIT_LOG_PANIC,
                    "[ERROR-kf3c3d] while creating a new directory", params, e, session)
            @error = e.to_s
            erb :kit_files
        end
    end

    def create_user_directory
        kit_log(KIT_LOG_INFO, 'def create_user_directory', "./uploads/#{session[:username]}")
        begin
            Dir.mkdir("./uploads/#{session[:username]}")
        rescue => e
            kit_log(KIT_LOG_PANIC,
                    "[ERROR-kfvc2d] while creating a new directory for user",
                    e, session)
            redirect to('/kit_files')
        end
    end

    def list_directories dirname
        kit_log(KIT_LOG_INFO, 'def list_directories')

        all = Dir.glob("./uploads/#{session[:username]}/#{dirname}/*").map{|f| f.split(session[:username]+'/').last}
        kit_log(KIT_LOG_DEBUG, "list of files in ./uploads/#{session[:username]}/#{dirname}/", all)

        dirs = []
        all.each do |f|
            if File.directory?("./uploads/#{session[:username]}/#{f}")
                kit_log(KIT_LOG_DEBUG, "#{f} : is a directory")
                dirs << f
            else
                kit_log(KIT_LOG_DEBUG, "#{f} : is a file")
            end
        end
        return dirs
    end

    def list_uploaded_files dirname
        kit_log(KIT_LOG_INFO, 'def list_uploaded_files')

        all = Dir.glob("./uploads/#{session[:username]}/#{dirname}/*").map{|f| f.split(session[:username]+'/').last}
        kit_log(KIT_LOG_DEBUG, "list of files in ./uploads/#{session[:username]}/#{dirname}/", all)

        files = []
        all.each do |f|
            if File.directory?("./uploads/#{session[:username]}/#{f}")
                kit_log(KIT_LOG_DEBUG, "#{f} : is a directory")
            else
                kit_log(KIT_LOG_DEBUG, "#{f} : is a file")
                files << f.gsub(/^\//,'')
            end
        end
        return files
    end

    get '/kit_files/:username/*' do |username, filename|
        kit_log(KIT_LOG_INFO, 'get /kit_files/:username/:filename', filename)

        if File.directory?("./uploads/#{session[:username]}/#{filename}")
            list_directory filename
        else
            kit_log(KIT_LOG_VERBOSE, 'download of', filename)
            send_file "./uploads/#{username}/#{filename}",
                :filename => filename, :type => 'Application/octet-stream'
        end
        kit_log(KIT_LOG_VERBOSE, 'download done')
        erb :kit_files
    end

#    get '/kit_files/delete/:filename' do |filename|
#        kit_log(KIT_LOG_INFO, 'get /kit_files/delete/:filename', filename)
#        session!
#        File.rename("./uploads/#{session[:username]}/#{filename}",
#                    "./uploads/.#{filename}")
#        redirect to('/kit_files')
#    end

end

class Kit < Sinatra::Base

    get '/kit_files' do
        kit_log(KIT_LOG_INFO, 'get /kit_files')
        session!
        @list = list_uploaded_files
        erb :kit_files
    end

    post "/kit_files/upload" do
        kit_log(KIT_LOG_INFO, 'post /kit_files/upload')
        session!
        kit_log(KIT_LOG_VERBOSE, 'uploading file', params['file'])
        begin
            check_directory_exists
            if File.exist?("uploads/#{session[:username]}/" + params['file'][:filename])
                File.open("uploads/#{session[:username]}/X" + params['file'][:filename], "w") do |f|
                    f.write(params['file'][:tempfile].read)
                end
            else
            File.open("uploads/#{session[:username]}/" + params['file'][:filename], "w") do |f|
                f.write(params['file'][:tempfile].read)
            end
            end
        rescue => e
            kit_log(KIT_LOG_PANIC, "[ERROR]", e, session)
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

    def create_user_directory
        kit_log(KIT_LOG_INFO, 'def create_user_directory', "./uploads/#{session[:username]}")
        begin
            Dir.mkdir("./uploads/#{session[:username]}")
        rescue => e
            kit_log(KIT_LOG_PANIC,
                    "[ERROR] while creating a new directory for user",
                    e, session)
            redirect to('/kit_files')
        end
    end

    def list_uploaded_files
        kit_log(KIT_LOG_INFO, 'def list_uploaded_files')

        files = Dir.glob("./uploads/#{session[:username]}/*").map{|f| f.split('/').last}
        kit_log(KIT_LOG_DEBUG, "list of files in ./uploads/#{session[:username]}", files)
        return files
    end

    get '/kit_files/:username/:filename' do |username, filename|
        kit_log(KIT_LOG_INFO, 'get /kit_files/:username/:filename', filename)
        send_file "./uploads/#{username}/#{filename}",
            :filename => filename, :type => 'Application/octet-stream'
    end

    get '/kit_files/delete/:filename' do |filename|
        kit_log(KIT_LOG_INFO, 'get /kit_files/delete/:filename', filename)
        session!
        File.rename("./uploads/#{session[:username]}/#{filename}",
                    "./uploads/.#{filename}")
        redirect to('/kit_files')
    end


end

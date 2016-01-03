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
            if File.exist?('uploads/' + params['file'][:filename])
                File.open('uploads/X' + params['file'][:filename], "w") do |f|
                    f.write(params['file'][:tempfile].read)
                end
            else
            File.open('uploads/' + params['file'][:filename], "w") do |f|
                f.write(params['file'][:tempfile].read)
            end
            end
        rescue => e
            kit_log(KIT_LOG_PANIC, "[ERROR]", e, session)
            redirect to('/kit_files')
        end
        redirect to('/kit_files')
    end

    def list_uploaded_files
        kit_log(KIT_LOG_INFO, 'def list_uploaded_files')
        session!
        files = Dir.glob("./uploads/*").map{|f| f.split('/').last}
        kit_log(KIT_LOG_DEBUG, 'list of files in ./uploads', files)
        return files
    end

    get '/kit_files/download/:filename' do |filename|
        kit_log(KIT_LOG_INFO, 'get /kit_files/download/:filename', filename)
        session!
        send_file "./uploads/#{filename}", :filename => filename, :type => 'Application/octet-stream'
    end

    get '/kit_files/delete/:filename' do |filename|
        kit_log(KIT_LOG_INFO, 'get /kit_files/delete/:filename', filename)
        session!
        File.rename("./uploads/#{filename}", "./uploads/.#{filename}")
        redirect to('/kit_files')
    end


end

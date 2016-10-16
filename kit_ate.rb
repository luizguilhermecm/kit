class Kit < Sinatra::Base


    get '/ate' do
        kit_log_breadcrumb(__method__, params)
        path = "views/ate"
        list_given_path path
        kit_log(KIT_LOG_DEBUG, "Next: xxxrender")
        erb :"ate/ate"
    end

    get '/ate/render' do
        kit_log_breadcrumb(__method__, params)
        file = params['file']
        erb :"ate/#{file}"
    end

    get '/contador' do
        erb :"ate/contador"
    end

    def list_given_path path
        kit_log_breadcrumb(__method__, path)

        erb_extension = ".erb"

        @files = []
        @files = get_file_list_at_path path

        kit_log(KIT_LOG_DEBUG, "Next: get only .erb files")

        @erbs = []
        @erbs = get_only_given_extension erb_extension
        kit_log(KIT_LOG_DEBUG, "Next: render")
    end

    def get_only_given_extension ext
        kit_log_breadcrumb(__method__, ext)
        files = []
        kit_log(KIT_LOG_DEBUG, "list of files in at_files ", @files)
        begin
            @files.each do |f|
                kit_log(KIT_LOG_DEBUG, "each", f)
                f_ext = File.extname f
                kit_log(KIT_LOG_DEBUG, "each", f_ext)
                if ext.eql? f_ext
                    erbname = File.basename(f, ext)
                    if erbname.eql? "ate"
                        next;
                    end
                    files << erbname
                end
                kit_log(KIT_LOG_DEBUG, "10------")
            end
                kit_log(KIT_LOG_DEBUG, "20------")
        rescue => e
            puts "*****"
            kit_log(KIT_LOG_DEBUG, e);
        end
                kit_log(KIT_LOG_DEBUG, "20------")
        return files;
    end



    def get_file_list_at_path path
        kit_log_breadcrumb(__method__, path)

        all_itens_at_path = Dir.glob("./#{path}/*").map{|f| f.split(path+'/').last}
        kit_log(KIT_LOG_DEBUG, "list of files in ./#{path}/", all_itens_at_path)

        files = []
        all_itens_at_path.each do |f|
            if File.directory?("./#{path}/#{f}")
                kit_log(KIT_LOG_DEBUG, "#{f} : is a directory")
            else
                kit_log(KIT_LOG_DEBUG, "#{f} : is a file")
                files << f.gsub(/^\//,'')
            end
        end
        kit_log(KIT_LOG_DEBUG, "returning files at path", files)
        return files
    end




end

        #kit_log_breadcrumb(__method__, params)
        #redirect to('/kit_todo/list')
        #redirect request.referer
        # session!
        #begin
        #    @@conn.exec_params(q, [tag_name.to_s, tag_desc.to_s, session[:uid]])
        #rescue => e
        #    self.kit_rescue e, session, "38cswhsA", true
        #end
        #kit_log(KIT_LOG_DEBUG, query, id);



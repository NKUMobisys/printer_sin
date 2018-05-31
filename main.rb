require 'sinatra'
require 'tilt/erubis'
# require 'byebug'
require 'json'

set :bind, '0.0.0.0'
set :server, %w[puma]

get '/' do
  erb :main
end


post '/print' do
    def build_lpcmd(opts, file)
        opt = "-o scaling=100"
        if copy = opts["copy"]
            opt += " -n #{copy} -o Collate=True"
        end
        if page = opts["page"]
            opt += " -P \"#{page}\" "
        end
        if double_sides = opts["double_sides"]
          opt += " -o sides=two-sided-long-edge"
        end
        "lp #{opt} '#{file}'"
    end

    password = params[:password]
    if password != 'mobi'
        status 403
        body "Wrong password #{password}"
        return
    end
    tempfile = params[:file][:tempfile]
    filename = params[:file][:filename]


    unless filename[-3..-1].match(/(jpg|pdf|gif|txt)/)
	status 403
	body "Wrong file type(Need pdf, txt, jpg, gif)"
	return
    end


    storage_name = "#{__dir__}/public/uploads/#{filename}.#{Time.now.to_i}"
    FileUtils.cp(tempfile, storage_name)
    print_cmd = build_lpcmd(params, storage_name)
    puts print_cmd
    output = ""
    output = `#{print_cmd}`
    Thread.new do
      sleep 15
      FileUtils.rm(storage_name)
    end
    # "<h2>Print submitted!</h2><br>lp output:<br>[#{output}]"
    {lpoutput: output}.to_json
end

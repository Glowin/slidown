require 'sinatra'
require 'open-uri'
require_relative 'parser'
require_relative 'builder'
require_relative 'generator'

base_path = 'file_repo'

# Simulate network lag
before do
  sleep 0
end

# upload the file
post '/:user/:topic/upload' do
  @user = params[:user]
  @topic = params[:topic]

  unless params[:file] &&
       (tmpfile = params[:file][:tempfile]) &&
       (name = params[:file][:filename])
    @error = 'No file selected'
    erb :upload
  end
  @file_content = ''
  while blk = tmpfile.read(65536)
    # here you would write it to its final location
    @file_content << blk
  end

  parser = MarkdownParser.new(@file_content)
  builder = Builder.new parser.parse
  generator = Generator.new base_path, @user, @topic, 'guide'
  generator.generate builder.build_tree

  redirect "/#{@user}/#{@topic}"
end

get '/:user/:topic/upload' do
  @user = params[:user]
  @topic = params[:topic]

  erb :upload
end

# 选择角色
get '/:user/:topic' do
  @user = params[:user]
  @topic = params[:topic]

  erb open('templates/login.html.erb').read
end

post '/:user/:topic' do
  @user = params[:user]
  @topic = params[:topic]

  role = params[:role]
  response.set_cookie 'slidown_role', role

  redirect "/#{@user}/#{@topic}/1"
end

get '/:user/:topic/:page' do
  user = params[:user]
  topic = params[:topic]
  page = params[:page]
  File.read(File.join("#{base_path}/#{user}/#{topic}", "#{page}.html"))
end

__END__

@@upload
<%= @error %>
<form action='/<%= @user %>/<%= @topic %>/upload' enctype="multipart/form-data" method='POST'>
    <input name="file" type="file" />
    <input type="submit" value="Upload" />
</form>
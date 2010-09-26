require 'sinatra'
require 'erb'
require 'open-uri'

set :public, File.dirname(__FILE__) + '/public'
set :views, File.dirname(__FILE__) + '/templates'

run Sinatra::Application

get '/' do
  erb :index
end

get '/kosmix_proxy.js' do
  "#{params[:callback] || 'callback'}(#{get_kosmix_response(params[:url])});"
end

get '/widget.js' do
<<WIDGET_JS
var url = location.href;
kosmix_jQuery.getJSON("#{request_host}/kosmix_proxy.js?callback=?&url=" + url, function(data) {
  console.log(data);
  if (typeof(data.error) != 'undefined') {
    alert('error:' + data.error);
  } else {
    kosmix_jQuery("#kosmix_widget").html("");
    kosmix_jQuery("#kosmix_widget").append("<ul>");
    for (var i in data.mentions) {
      kosmix_jQuery("#kosmix_widget").append("<li style='display:inline;padding:10px;'>" + data.mentions[i].EntityName + "</li>");
    }
    kosmix_jQuery("#kosmix_widget").append("</ul>");
  }


});
WIDGET_JS
end

get '/embed.html' do
  get_embed_code
end
# / => Get the embed code
# /v1/embed.js => the embed code

helpers do
  def get_embed_code
    <<EMBED_CODE
    <div id="kosmix_widget" style="height:200px;"><img src="#{request_host}/status.gif"/></div>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.1/jquery.min.js" type="text/JavaScript"></script>
    <script t ype="text/javascript">var kosmix_jQuery = jQuery.noConflict(true);</script>
    <script type="text/javascript" src="#{request_host}/widget.js"></script>
EMBED_CODE
  end
  def request_host
    ret = "http://#{@request.host}"
    ret = "#{ret}:#{@request.port}" if @request.port.to_i != 80
  end
  def get_kosmix_response(url)
    url = "http://www.metacafe.com/watch/5199459/hereafter_movie_trailer/" if @request.host == "127.0.0.1"
    kosmix_api_key = "1e8e8a509409d1efaff73195baf254"
    kosmix_url = "http://api.kosmix.com/annotate/v1?url=#{url}&key=#{kosmix_api_key}"
    result = open(kosmix_url).read
  end
end
require 'sinatra'
require 'erb'
require 'net/http'
require 'uri'
require 'cgi'

set :public, File.dirname(__FILE__) + '/public'
set :views, File.dirname(__FILE__) + '/templates'

run Sinatra::Application

get '/' do
  erb :index
end

get '/kosmix_proxy.js' do
  "#{params[:callback] || 'callback'}(#{get_kosmix_response(params[:text])});"
end

get '/widget.js' do
<<WIDGET_JS
var text = encodeURI(kosmix_jQuery('body').html());
kosmix_jQuery.getJSON("#{request_host}/kosmix_proxy.js?callback=?&text=" + text, function(data) {
  console.log(data);
  kosmix_jQuery("#kosmix_widget").html("");
  if (typeof(data) != 'undefined' && typeof(data.error) != 'undefined') {
    kosmix_jQuery("#kosmix_widget").html('An error occured:' + data.error);
  } else if (typeof(data) != 'undefined'){
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
    ret
  end
  def get_kosmix_response(text)
    if @request.host == "127.0.0.1"
      text = "Hereafter tells the story of three people who are touched by death in different ways. George (Matt Damon) is a blue-collar
American who has a special connection to the afterlife. On the other side of the world, Marie (CÈcile De France), a French journalist,
has a near-death experience that shakes her reality. And when Marcus, a London schoolboy, loses the person closest to him, he desperately needs answers. Each
on a path in search of the truth, their lives will intersect, forever changed by what they believe might-or must-exist in the hereafter."
    end
    text = CGI::escape(text)
    kosmix_api_key = "1e8e8a509409d1efaff73195baf254"
    kosmix_url = "http://api.kosmix.com/annotate/v1?text=#{text}&key=#{kosmix_api_key}"
    uri = URI.parse(kosmix_url)
    res = Net::HTTP.start(uri.host, uri.port) {|http|
      http.get("#{uri.path}?#{uri.query}")
    }
    res.body
  end
end
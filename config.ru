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
var text = encodeURI(kosmix_jQuery('p').html());
kosmix_jQuery.getJSON("#{request_host}/kosmix_proxy.js?callback=?&text=" + text, function(data) {
  console.log(data);
  kosmix_jQuery("#kosmix_widget").html("");
  if (typeof(data) != 'undefined' && typeof(data.error) != 'undefined') {
    kosmix_jQuery("#kosmix_widget").html('An error occured:' + data.error);
  } else if (typeof(data) != 'undefined'){
    kosmix_jQuery("#kosmix_widget").append("<ul>");
    for (var i in data.mentions) {
      console.log(data.mentions[i].EntityName + " : " + data.mentions[i].EntityScore);
      if (data.mentions[i].EntityScore > 0.80) {
        kosmix_jQuery("#kosmix_widget").append("<li style='display:inline;padding:10px;'>" + data.mentions[i].EntityName + "</li>");
      }
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
      text = "The 2009 Lamar Hunt U.S. Open Cup Final was played on September 2, 2009, at Robert F. Kennedy Memorial Stadium in Washington, D.C.
      The match determined the winner of the 2009 edition of the Lamar Hunt U.S. Open Cup, a tournament open to amateur and professional soccer
       teams affiliated with the United States Soccer Federation. This was the 96th edition of the oldest competition in United States soccer.
       The match was won by Seattle Sounders FC, who defeated D.C. United 2–1. Seattle became the second expansion team in Major League Soccer
       history to win the tournament in their inaugural season. D.C. United entered the tournament as the competition's defending champions.
       Both Sounders FC and D.C. United had to play through two qualification rounds for MLS teams before entering the official tournament.
       Prior to the final, there was a public dispute between the owners of the two clubs regarding the selection of D.C. United to host it at their home field,
       RFK Stadium. As the tournament champions, Sounders FC earned a berth in the preliminary round of the 2010–11 CONCACAF Champions League.
       The club also received a $100,000 cash prize, while D.C. United received $50,000 as the runner-up."
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
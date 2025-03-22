package util;

#if !js
#end
import haxe.Http;


class ApiRequest
{
    final http: Http;
    final params: Map<String, String>;

    var resp: String = null;

    @:allow(util.ApiRequestBuilder)
    function new(http: Http, params: Map<String, String>)
    {
        this.http = http;
        this.params = params;

        http.onData = (data: String) ->
        {
            resp = data;
        };
        http.onError = (msg: String) ->
        {
            throw msg;
        };
    }

    public function getUrl(): String
    {
        var url: String = http.url + '?';

        for (name => value in params)
        {
            url += '$name=$value&';
        }

        return url;
    }

    #if js
    #else
    public function send(): String
    {
        http.request(false);

        return resp;
    }
    #end
}

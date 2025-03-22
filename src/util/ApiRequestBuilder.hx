package util;

import haxe.Http;


class ApiRequestBuilder
{
    final http: Http;
    final params: Map<String, String>;

    public function new(url: String)
    {
        http = new Http(url);
        http.setHeader('Accept', 'application/json, text/javascript, */*; q=0.01');
        http.setHeader('Host', 'skiplagged.com');
        http.setHeader('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; rv:123.0) Gecko/20100101 Firefox/123.0');

        params = [ ];
    }

    public inline function set(name: String, value: String): ApiRequestBuilder
    {
        http.setParameter(name, value);
        params.set(name, value);

        return this;
    }

    public function build(): ApiRequest
    {
        return new ApiRequest(http, params);
    }
}

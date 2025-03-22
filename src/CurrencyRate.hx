import haxe.Http;
import haxe.Json;
import types.Currency;


class CurrencyRate
{
    static var currency: Currency = Usd;
    static var currencyRate: Float = 1.0;

    public static function load()
    {
        var defaultCurrency: String = Sys.getEnv("AIRFLAIR_DEFAULT_CURRENCY");
        if (defaultCurrency == null)
        {
            return;
        }

        currency = Currency.parse(defaultCurrency);
        currencyRate = getRate(currency);
    }

    public static function formatPrice(price: Int): String
    {
        var symbol: String = currency.symbol();
        var priceEur: Int = Math.round(price * currencyRate);
        return '${Std.string(priceEur).lpad(' ', 3)}${symbol}';
    }

    static function getRate(currency: Currency): Float
    {
        var apiKey: String = Sys.getEnv("FREECURRENCYAPI_KEY");
        if (apiKey == null)
        {
            throw 'missing env variable: FREECURRENCYAPI_KEY';
        }

        var currencyCode: String = currency;

        var http: Http = new Http("https://api.freecurrencyapi.com/v1/latest");
        http.setParameter('apikey', apiKey);

        var rate: Null<Float> = null;

        http.onData = (resp: String) ->
        {
            var respObj = Json.parse(resp);
            rate = Reflect.field(respObj.data, currencyCode);
        };
        http.onError = (err: String) ->
        {
            throw 'fetch rates error: ${err}';
        };

        http.request(false);

        return rate;
    }
}

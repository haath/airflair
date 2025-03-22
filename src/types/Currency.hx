package types;

enum abstract Currency(String) to String
{
    var Usd = "USD";
    var Eur = "EUR";

    public function symbol(): String
    {
        return
            switch (cast(this, Currency))
            {
                case Usd:
                    '$';
                case Eur:
                    '€';
            }
    }

    public static function parse(str: String): Currency
    {
        return
            switch (str.toLowerCase())
            {
                case "usd":
                    Usd;

                case "eur":
                    Eur;

                default:
                    throw 'unsupported currency: ${str}';
            }
    }
}

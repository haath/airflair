package types;

typedef AirlineData =
{
    var prefix: String;
    var name: String;
}

@:forward
abstract Airline(AirlineData) from AirlineData
{
    @:op(a == b)
    public static function eq(a: Airline, b: Airline): Bool
    {
        return a.prefix == b.prefix;
    }
}

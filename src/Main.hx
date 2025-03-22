import cli.FlightsCli;


class Main
{
    static function main()
    {
        var cli: FlightsCli = new FlightsCli(Sys.args());
        cli.run();
    }
}

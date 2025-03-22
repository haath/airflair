package util;

import types.FlightLeg;


class Util
{
    public static function parseLocalDate(str: String): Date
    {
        // "2024-05-01T14:05:00+03:00
        var expr: EReg = ~/(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):\d\d([+-])(\d\d):(\d\d)/;

        if (!expr.match(str))
        {
            Sys.println('failed to parse date: $str');
            Sys.exit(-3);
        }

        return new Date(
            Std.parseInt(expr.matched(1)),
            Std.parseInt(expr.matched(2)) - 1,
            Std.parseInt(expr.matched(3)),
            Std.parseInt(expr.matched(4)),
            Std.parseInt(expr.matched(5)),
            0,
        );
    }

    public static function parseTimeZone(str: String): Float
    {
        // "2024-05-01T14:05:00+03:00
        var expr: EReg = ~/(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):\d\d([+-])(\d\d):(\d\d)/;

        if (!expr.match(str))
        {
            Sys.println('failed to parse date: $str');
            Sys.exit(-3);
        }

        var sign: String = expr.matched(6);
        var hours: Int = Std.parseInt(expr.matched(7));
        var minutes: Int = Std.parseInt(expr.matched(8));

        var timezone: Float = hours + (minutes / 60);

        return sign == '+' ? timezone : -timezone;
    }

    public static function layoverHours(inboundLeg: FlightLeg, outboundLeg: FlightLeg): Float
    {
        var diffMs: Float = outboundLeg.departure.getTime() - inboundLeg.arrival.getTime();
        var diffHours: Float = diffMs / (60 * 60 * 1000);
        return diffHours;
    }
}

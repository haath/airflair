package types;

import types.FlightLeg;

using DateTools;
using StringTools;


typedef OneWayFlightData =
{
    var id: String;
    var legs: Array<FlightLeg>;
    var price: Int;
}

@:forward
abstract OneWayFlight(OneWayFlightData) from OneWayFlightData to OneWayFlightData
{
    public var origin(get, never): String;
    public var destination(get, never): String;

    public var departureDate(get, never): ShortDate;
    public var departureTimeFormatted(get, never): String;
    public var departureTime(get, never): Float;

    public var arrivalDate(get, never): ShortDate;
    public var arrivalTimeFormatted(get, never): String;
    public var arrivalTime(get, never): Float;

    public var priceFormatted(get, never): String;
    public var durationFormatted(get, never): String;

    inline function get_origin(): String
    {
        return this.legs[0].origin;
    }

    inline function get_destination(): String
    {
        return this.legs[this.legs.length - 1].destination;
    }

    inline function get_departureDate(): ShortDate
    {
        return ShortDate.fromDate(this.legs[0].departure);
    }

    inline function get_arrivalDate(): ShortDate
    {
        return ShortDate.fromDate(this.legs[this.legs.length - 1].arrival);
    }

    inline function get_departureTime(): Float
    {
        return this.legs[0].departure.getTime();
    }

    inline function get_arrivalTime(): Float
    {
        return this.legs[this.legs.length - 1].arrival.getTime();
    }

    inline function get_departureTimeFormatted(): String
    {
        return this.legs[0].departure.format('%H:%M');
    }

    function get_arrivalTimeFormatted(): String
    {
        var arrivalTimeStr: String = this.legs[this.legs.length - 1].arrival.format('%H:%M');

        var startDate: ShortDate = ShortDate.fromDate(this.legs[0].departure);
        var endDate: ShortDate = ShortDate.fromDate(this.legs[this.legs.length - 1].arrival);
        var daysDiff: Int = 0;
        while (startDate < endDate)
        {
            daysDiff++;
            startDate = startDate.nextDay();
        }

        if (daysDiff > 0)
        {
            arrivalTimeStr += ' (+$daysDiff)';
        }

        return arrivalTimeStr;
    }

    inline function get_priceFormatted(): String
    {
        return CurrencyRate.formatPrice(this.price);
    }

    function get_durationFormatted(): String
    {
        var durationMs: Float = this.legs.legsDuration();
        var durationFormatted: String = durationMs.timeToHoursString().lpad(' ', 7);
        return durationFormatted;
    }

    public function toString(detailed: Bool = false): String
    {
        var depDate: String = this.legs[0].departure.format("%Y-%m-%d");
        var str: String = '$depDate $departureTimeFormatted ${origin} -> ${destination} $arrivalTimeFormatted | ${priceFormatted} | ';

        str += this.legs.legsToString();

        if (detailed)
        {
            for (leg in this.legs)
            {
                str += '\n\t${leg.toDetailedString()}';
            }
            str += '\n';
        }

        return str;
    }

    public function toShortString(printDayOfWeek: Bool = false): String
    {
        var depDate: String = printDayOfWeek ? departureDate.toDowString() : departureDate.toString();
        var depTime: String = departureTimeFormatted;
        var arrTime: String = arrivalTimeFormatted;

        return '$depDate ~ $depTime .. $arrTime';
    }
}

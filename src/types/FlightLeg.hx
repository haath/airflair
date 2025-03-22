package types;

import types.Airline;


typedef FlightLegData =
{
    var flightNr: String;
    var airline: Airline;

    var origin: String;
    var destination: String;

    var originTimeZone: Float;
    var destinationTimeZone: Float;

    var departure: Date;
    var arrival: Date;
}

@:forward
abstract FlightLeg(FlightLegData) from FlightLegData
{
    public var duration(get, never): Float;
    public var departureUtc(get, never): Date;
    public var arrivalUtc(get, never): Date;

    function get_duration(): Float
    {
        var dep: Date = this.departure;
        var depTz: Float = this.originTimeZone;
        var arr: Date = this.arrival;
        var arrTz: Float = this.destinationTimeZone;

        var depUtc: Date = dep.delta(-depTz * 60 * 60 * 1000);
        var arrUtc: Date = arr.delta(-arrTz * 60 * 60 * 1000);

        return arrUtc.getTime() - depUtc.getTime();
    }

    inline function get_departureUtc(): Date
    {
        return this.departure.delta(-this.originTimeZone * 60 * 60 * 1000);
    }

    inline function get_arrivalUtc(): Date
    {
        return this.arrival.delta(-this.destinationTimeZone * 60 * 60 * 1000);
    }

    public function toString(): String
    {
        var dep: String = this.departure.format("%H:%M");
        var arr: String = this.arrival.format("%H:%M");

        return '$dep ${this.origin}..${this.destination} $arr';
    }

    public function toDetailedString(): String
    {
        var airline: String = this.airline.name;
        var dep: String = this.departure.format("%H:%M");
        var arr: String = this.arrival.format("%H:%M");

        return '$dep ${this.origin}..${this.destination} $arr (${duration.timeToHoursString()}) - $airline';
    }
}

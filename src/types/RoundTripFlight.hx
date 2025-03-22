package types;

import types.FlightLeg;

using DateTools;
using StringTools;


typedef RoundTripFlightData =
{
    var outboundId: String;
    var outbound: Array<FlightLeg>;
    var inboundId: String;
    var inbound: Array<FlightLeg>;
    var price: Int;
}

@:forward
abstract RoundTripFlight(RoundTripFlightData) from RoundTripFlightData to RoundTripFlightData
{
    public var origin(get, never): String;
    public var destination(get, never): String;
    public var departingDurationHours(get, never): Float;
    public var returningDurationHours(get, never): Float;
    public var priceFormatted(get, never): String;

    inline function get_origin(): String
    {
        return this.outbound[0].origin;
    }

    inline function get_destination(): String
    {
        return this.outbound[this.outbound.length - 1].destination;
    }

    inline function get_departingDurationHours(): Float
    {
        var diffMs: Float = this.outbound[this.outbound.length - 1].arrival.getTime() - this.outbound[0].departure.getTime();
        var diffHours: Float = diffMs / (60 * 60 * 1000);

        return Math.round(diffHours * 10) / 10;
    }

    inline function get_returningDurationHours(): Float
    {
        var diffMs: Float = this.inbound[this.inbound.length - 1].arrival.getTime() - this.inbound[0].departure.getTime();
        var diffHours: Float = diffMs / (60 * 60 * 1000);

        return Math.round(diffHours * 10) / 10;
    }

    inline function get_priceFormatted(): String
    {
        return CurrencyRate.formatPrice(this.price);
    }

    public function getOutbound(): OneWayFlight
    {
        return {
            id: this.outboundId,
            legs: this.outbound,
            price: 0
        };
    }

    public function getInbound(): OneWayFlight
    {
        return {
            id: this.inboundId,
            legs: this.inbound,
            price: 0
        };
    }

    public function getNofDays(): Int
    {
        var outboundTime: Float = getOutbound().departureDate.toDate().getTime();
        var inboundTime: Float = getInbound().departureDate.toDate().getTime();

        return Math.round((inboundTime - outboundTime) / (24 * 60 * 60 * 1000));
    }

    public function toString(detailed: Bool = false): String
    {
        var depDate: String = this.outbound[0].departure.format("%Y-%m-%d");
        var retDate: String = this.inbound[0].departure.format("%Y-%m-%d");
        var str: String = '$depDate ${origin} <-> ${destination} $retDate | ${priceFormatted} | ';

        str += this.outbound.legsToString();

        str += " | ";

        str += this.inbound.legsToString();

        if (detailed)
        {
            for (leg in this.outbound)
            {
                str += '\n\t${leg.toDetailedString()}';
            }
            str += '\n';
            for (leg in this.inbound)
            {
                str += '\n\t${leg.toDetailedString()}';
            }
            str += '\n';
        }

        return str;
    }
}

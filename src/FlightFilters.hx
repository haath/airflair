import types.Airline;
import types.FlightLeg;
import util.Util;


typedef FlightFiltersData =
{
    var maxStops: Null<Int>;
    var maxDurationHours: Null<Float>;
    var maxLayoverHours: Null<Float>;
    var singleAirline: Bool;
    var selfTransfers: Bool;
    var overnightLayovers: Bool;
}

@:forward
abstract FlightFilters(FlightFiltersData) from FlightFiltersData
{
    public static function init(): FlightFilters
    {
        return {
            maxStops: null,
            maxDurationHours: null,
            maxLayoverHours: 12,
            singleAirline: false,
            selfTransfers: false,
            overnightLayovers: true,
        };
    }

    public function matchesLegs(legs: Array<FlightLeg>): Bool
    {
        // number of stops
        if ((this.maxStops != null) && (legs.length > this.maxStops + 1))
        {
            return false;
        }

        // total duration
        var diffMs: Float = legs[ legs.length - 1 ].arrival.getTime() - legs[ 0 ].departure.getTime();
        var diffHours: Float = diffMs / (60 * 60 * 1000);
        if ((this.maxDurationHours != null) && (diffHours > this.maxDurationHours))
        {
            return false;
        }

        // layover duration
        var layoverHours: Float = 0;
        for (i in 0...legs.length - 1)
        {
            layoverHours += Util.layoverHours(legs[ i ], legs[ i + 1 ]);
        }
        if ((this.maxLayoverHours != null) && (layoverHours > this.maxLayoverHours))
        {
            return false;
        }

        // single airline
        if (this.singleAirline)
        {
            var airline: Airline = legs[ 0 ].airline;

            for (leg in legs)
            {
                if (leg.airline != airline)
                {
                    return false;
                }
            }
        }

        // self-transfers are layovers where you need to change the airport
        if (!this.selfTransfers)
        {
            for (i in 0...legs.length - 1)
            {
                var layoverArrival: String = legs[ i ].destination;
                var layoverDeparture: String = legs[ i + 1 ].origin;

                if (layoverArrival != layoverDeparture)
                {
                    return false;
                }
            }
        }

        // overnight layovers are night layovers of at least 4h
        if (!this.overnightLayovers)
        {
            for (i in 0...legs.length - 1)
            {
                var layoverHours: Float = Util.layoverHours(legs[ i ], legs[ i + 1 ]);
                var arrivalHour: Float = legs[ i ].arrival.getHours();
                var midLayover: Float = arrivalHour + (layoverHours / 2.0) - 24;
                var isLateArrival: Bool = (arrivalHour >= 23) || (arrivalHour <= 5) || (midLayover >= 1 && midLayover <= 4);

                if (isLateArrival && (layoverHours >= 4.0))
                {
                    return false;
                }
            }
        }

        return true;
    }
}

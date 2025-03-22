package util;

import types.Airline;
import types.FlightLeg;
import types.OneWayFlight;


class Extensions
{
    public static function legsToString(legs: Array<FlightLeg>): String
    {
        var str: String = '';

        if (legs.length == 1)
        {
            str += 'direct';
        }
        else
        {
            for (i in 0...legs.length)
            {
                if (i > 0)
                {
                    str += '- ';
                }

                var leg: FlightLeg = legs[ i ];
                str += '${leg} ';
            }
        }

        return str;
    }

    public static function legsDuration(legs: Array<FlightLeg>): Float
    {
        var depUtc: Date = legs[ 0 ].departureUtc;
        var arrUtc: Date = legs[ legs.length - 1 ].arrivalUtc;

        return arrUtc.getTime() - depUtc.getTime();
    }

    public static function legsAirlinesList(legs: Array<FlightLeg>): String
    {
        var uniqueAirlines: Map<String, Airline> = [ ];
        for (leg in legs)
        {
            uniqueAirlines.set(leg.airline.prefix, leg.airline);
        }

        var names: Array<String> = [ ];
        for (_ => airline in uniqueAirlines)
        {
            names.push(airline.name);
        }

        return names.join(', ');
    }

    public static function flightsUnique(flights: Array<OneWayFlight>): Array<OneWayFlight>
    {
        var flightSet: Map<String, OneWayFlight> = [ ];
        for (flight in flights)
        {
            flightSet.set(flight.id, flight);
        }
        var uniqueFlights: Array<OneWayFlight> = [ ];
        for (_ => flight in flightSet)
        {
            uniqueFlights.push(flight);
        }
        return uniqueFlights;
    }

    public static function timeToHoursString(time: Float): String
    {
        var timeInHours: Float = time / (60 * 60 * 1000);

        var hours: Int = Math.floor(timeInHours);
        var minutes: Int = Math.round((timeInHours - hours) * 60);

        return '${Std.string(hours).lpad(' ', 2)}h ${Std.string(minutes).lpad(' ', 2)}min';
    }
}

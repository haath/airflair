package types;

import cli.ProgressBar;
import types.OneWayFlight;


typedef MultiStopFlightData =
{
    var flights: Array<OneWayFlight>;
}

@:forward
abstract MultiStopFlight(MultiStopFlightData) from MultiStopFlightData
{
    public var price(get, never): Int;
    public var priceFormatted(get, never): String;

    inline function get_price(): Int
    {
        var sum: Int = 0;
        for (flight in this.flights)
        {
            if (flight != null)
            {
                sum += flight.price;
            }
        }
        return sum;
    }

    inline function get_priceFormatted(): String
    {
        return CurrencyRate.formatPrice(price);
    }

    public static function allCombinations(itinerary: Array<String>, allFlights: Array<OneWayFlight>, selfTransfer: Map<Int, Bool>): Array<MultiStopFlight>
    {
        final nofLegs: Int = itinerary.length - 1;

        // introduce some limit to the number of flights to consider per-leg,
        // since the following algorithm is recursive
        final legFlightLimit: Int = switch (nofLegs)
            {
                case 1:
                    500;
                case 2:
                    200;
                case 3:
                    100;
                case 4:
                    50;
                default:
                    10;
            }

        /**
         * First create a lookup table.
         *
         * Where `lookup[origin][destination]` shall contain all flights between those two points.
         */
        var legFlights: Map<String, Map<String, Array<OneWayFlight>>> = [];
        for (i in 0...nofLegs)
        {
            final origin: String = itinerary[i];
            final destination: String = itinerary[i + 1];

            if (!legFlights.exists(origin))
            {
                legFlights.set(origin, []);
            }
            if (legFlights[origin].exists(destination))
            {
                // already added flights for this leg
                continue;
            }

            final flights: Array<OneWayFlight> = allFlights.filter(f -> (f.origin == origin) && (f.destination == destination));

            flights.sort((a, b) -> a.price < b.price ? -1 : 1);

            legFlights[origin].set(destination, flights.slice(0, legFlightLimit));
        }

        /**
         * Then start creating all combinations.
         */
        var allFlightCombinations: Array<Array<OneWayFlight>> = [];
        allCombinationsRecursive(allFlightCombinations, [], itinerary, 0, legFlights, selfTransfer);

        var trips: Array<MultiStopFlight> = allFlightCombinations.map(flights ->
        {
            flights: flights
        });
        trips.sort((a, b) -> a.price < b.price ? -1 : 1);
        return trips;
    }

    static function allCombinationsRecursive(acc: Array<Array<OneWayFlight>>, trip: Array<OneWayFlight>, itinerary: Array<String>, leg: Int,
            legFlights: Map<String, Map<String, Array<OneWayFlight>>>, selfTransfer: Map<Int, Bool>)
    {
        if (leg == itinerary.length - 1)
        {
            acc.push(trip);
            return;
        }

        if (selfTransfer.exists(leg + 1))
        {
            allCombinationsRecursive(acc, trip.concat([null]), itinerary, leg + 1, legFlights, selfTransfer);
            return;
        }

        final origin: String = itinerary[leg];
        final destination: String = itinerary[leg + 1];
        var progress: ProgressBar = leg == 0 ? new ProgressBar('compiling itineraries') : null;

        final flights: Array<OneWayFlight> = legFlights[origin][destination];
        for (i in 0...flights.length)
        {
            if (leg == 0)
            {
                progress.print((i + 1) / flights.length);
            }

            var flight: OneWayFlight = flights[i];

            // check if this flight is later than the arrival of the previous flight in the current trip
            if (trip.length > 0)
            {
                var prevFlight: OneWayFlight = trip[trip.length - 1];
                if (prevFlight != null)
                {
                    var layoverTime: Float = flight.departureTime - prevFlight.arrivalTime;

                    if (layoverTime < (45 * 60 * 1000))
                    {
                        continue;
                    }
                }
            }

            allCombinationsRecursive(acc, trip.concat([flight]), itinerary, leg + 1, legFlights, selfTransfer);
        }

        if (leg == 0)
        {
            progress.done();
        }
    }
}

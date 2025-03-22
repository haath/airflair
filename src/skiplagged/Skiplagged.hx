package skiplagged;

import haxe.Json;
import types.Airline;
import types.AirportHint;
import types.FlightLeg;
import types.OneWayFlight;
import types.RoundTripFlight;
import util.ApiRequest;
import util.ApiRequestBuilder;
import util.Util;


class Skiplagged
{
    static inline var BaseUrl: String = "https://skiplagged.com/";
    static inline var ApiSearchUrl: String = BaseUrl + "/api/search.php";
    static inline var ApiAirportSearchUrl: String = BaseUrl + "/api/hint.php";

    public function new()
    {
    }

    public function searchAirports(query: String): Array<AirportHint>
    {
        var req: ApiRequest = new ApiRequestBuilder(ApiAirportSearchUrl).set("term", query).build();

        var resp: Dynamic = Json.parse(req.send());

        return resp.hints;
    }

    public function searchOneWay(origin: String, destination: String, departureDate: String): ApiRequest
    {
        var req: ApiRequest = new ApiRequestBuilder(ApiSearchUrl).set("from", origin).set("to", destination).set("depart", departureDate).build();

        return req;
    }

    public function searchRoundTrip(origin: String, destination: String, departureDate: String, returnDate: String): ApiRequest
    {
        var req: ApiRequest = new ApiRequestBuilder(
            ApiSearchUrl
        ).set("from", origin).set("to", destination).set("depart", departureDate).set("return", returnDate).build();

        return req;
    }

    public static function parseOneWay(resp: Dynamic): Array<OneWayFlight>
    {
        var flightsLookup: Map<String, Array<FlightLeg>> = parseFlightLookup(resp);

        var flights: Array<OneWayFlight> = [ ];

        for (flight in cast(resp.depart, Array<Dynamic>))
        {
            var flightArr = cast(flight, Array<Dynamic>);
            var priceArr = cast(flightArr[ 0 ], Array<Dynamic>);

            var flightId: String = flightArr[ 3 ];
            var price: Float = priceArr[ 0 ] / 100;

            var flight: OneWayFlight =
            {
                id: flightId,
                legs: flightsLookup[ flightId ],
                price: Math.round(price)
            };

            flights.push(flight);
        }

        return flights;
    }

    public static function parseRoundTrip(resp: Dynamic): Array<RoundTripFlight>
    {
        var flightsLookup: Map<String, Array<FlightLeg>> = parseFlightLookup(resp);

        var returningFlights = cast(Reflect.field(resp, "return"), Array<Dynamic>);

        var flights: Array<RoundTripFlight> = [ ];

        for (departingFlight in cast(resp.depart, Array<Dynamic>))
        {
            var flightArr = cast(departingFlight, Array<Dynamic>);
            var depFlightId: String = flightArr[ 3 ];
            var departingLegs: Array<FlightLeg> = flightsLookup[ depFlightId ];
            var depPriceArr = cast(flightArr[ 0 ], Array<Dynamic>);
            if (depPriceArr.length < 2)
            {
                continue;
            }
            var depPrice: Float = depPriceArr[ 1 ] / 100;

            for (retFlight in returningFlights)
            {
                var retFlightArr = cast(retFlight, Array<Dynamic>);
                var retFlightId: String = retFlightArr[ 3 ];
                var retLegs: Array<FlightLeg> = flightsLookup[ retFlightId ];
                var retPriceArr = cast(retFlightArr[ 0 ], Array<Dynamic>);
                var retPrice: Float = retPriceArr[ 0 ] / 100;

                var flight: RoundTripFlight =
                {
                    outboundId: depFlightId,
                    outbound: departingLegs,
                    inboundId: retFlightId,
                    inbound: retLegs,
                    price: Math.round(depPrice + retPrice)
                };

                flights.push(flight);
            }
        }

        return flights;
    }

    public static function collectOneWay(results: Array<Dynamic>): Array<OneWayFlight>
    {
        var flights: Array<OneWayFlight> = [ ];

        for (res in results)
        {
            var resFlights = parseOneWay(res);

            flights = flights.concat(resFlights);
        }

        flights.flightsUnique().sort((a, b) -> a.price < b.price ? -1 : 1);

        return flights;
    }

    public static function collectRoundTrip(results: Array<Dynamic>): Array<RoundTripFlight>
    {
        var flights: Array<RoundTripFlight> = [ ];

        for (res in results)
        {
            flights = flights.concat(parseRoundTrip(res));
        }

        flights.sort((a, b) -> a.price < b.price ? -1 : 1);

        return flights;
    }

    static function parseFlightLookup(resp: Dynamic): Map<String, Array<FlightLeg>>
    {
        var flightsLookup: Map<String, Array<FlightLeg>> = [ ];
        var airlines: Map<String, Airline> = parseAirlineLookup(resp);

        for (flightId in Reflect.fields(resp.flights))
        {
            var flightArr: Array<Dynamic> = cast Reflect.field(resp.flights, flightId);

            var legs: Array<FlightLeg> = [ ];
            for (legData in cast(flightArr[ 0 ], Array<Dynamic>))
            {
                var flightNr: String = legData[ 0 ];
                var airline: Airline = airlines[ flightNr.substr(0, 2) ];

                var leg: FlightLeg =
                {
                    flightNr: flightNr,
                    airline: airline,

                    origin: legData[ 1 ],
                    destination: legData[ 3 ],

                    originTimeZone: Util.parseTimeZone(legData[ 2 ]),
                    destinationTimeZone: Util.parseTimeZone(legData[ 4 ]),

                    departure: Util.parseLocalDate(legData[ 2 ]),
                    arrival: Util.parseLocalDate(legData[ 4 ]),
                };
                legs.push(leg);
            }

            flightsLookup.set(flightId, legs);
        }
        return flightsLookup;
    }

    static function parseAirlineLookup(resp: Dynamic): Map<String, Airline>
    {
        var airlines: Map<String, Airline> = [ ];

        for (prefix in Reflect.fields(resp.airlines))
        {
            var name = Reflect.field(resp.airlines, prefix);

            airlines.set(prefix,
                {
                    prefix: prefix,
                    name: name
                });
        }

        return airlines;
    }
}

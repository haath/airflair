package cli;

import haxe.Json;
import hxargs.Args;
import skiplagged.Skiplagged;
import types.AirportHint;
import types.MultiStopFlight;
import types.OneWayFlight;
import types.RoundTripFlight;
import types.ShortDate;
import util.TablePrinter;


class FlightsCli
{
    var skiplagged: Skiplagged = new Skiplagged();
    var positionalArgs: Array<String> = [];

    var help: Bool = false;
    var helpExtended: Bool = false;

    var airportSearch: Null<String> = null;

    var departFrom: ShortDate = null;
    var departTo: ShortDate = null;
    var returnFrom: ShortDate = null;
    var returnTo: ShortDate = null;

    var tripDaysFrom: Null<Int> = null;
    var tripDaysTo: Null<Int> = null;

    var stayDays: Map<Int, Int> = [];
    var untilDate: Map<Int, ShortDate> = [];
    var selfTransfer: Map<Int, Bool> = [];

    var filters: FlightFilters = FlightFilters.init();
    var printCount: Int = 10;
    var detailed: Bool = false;
    var verbose: Bool = false;
    var nofThreads: Int = 10;
    var preliminary: Bool = false;
    var printDayOfWeek: Bool = false;
    var json: Bool = false;

    public function new(args: Array<String>)
    {
        var argHandler = Args.generate([

            @doc("Search for an airport code.")
            ["search"] => (query: String) ->
            {
                airportSearch = query;
            },

            @doc("Depart on a specific date.")
            ["-d", "--depart"] => (yyyymmdd: String) ->
            {
                departFrom = ShortDate.fromString(yyyymmdd);
                departTo = ShortDate.fromString(yyyymmdd);
            },
            @doc("Depart on any day in a date range starting from this date.")
            ["-df", "--depart-from"] => (yyyymmdd: String) ->
            {
                departFrom = ShortDate.fromString(yyyymmdd);
            },
            @doc("Depart on any day in a date range up to this date.")
            ["-dt", "--depart-to"] => (yyyymmdd: String) ->
            {
                departTo = ShortDate.fromString(yyyymmdd);
            },

            @doc("Return on a specific date.")
            ["-r", "--return"] => (yyyymmdd: String) ->
            {
                returnFrom = ShortDate.fromString(yyyymmdd);
                returnTo = ShortDate.fromString(yyyymmdd);
            },
            @doc("Return on any day in a date range starting from this date.")
            ["-rf", "--return-from"] => (yyyymmdd: String) ->
            {
                returnFrom = ShortDate.fromString(yyyymmdd);
            },
            @doc("Return on any day in a date range up to this date.")
            ["-rt", "--return-to"] => (yyyymmdd: String) ->
            {
                returnTo = ShortDate.fromString(yyyymmdd);
            },

            @doc("Return after a specific number of days from the departure.")
            ["--days"] => (days: Int) ->
            {
                tripDaysFrom = days;
                tripDaysTo = days;
            },
            @doc("Return after a range of days from the departure.")
            ["--days-from"] => (days: Int) ->
            {
                tripDaysFrom = days;
            },
            @doc("Return after a range of days from the departure.")
            ["--days-to"] => (days: Int) ->
            {
                tripDaysTo = days;
            },

            @doc("Stay at the destination preceding this parameter for a number of days .")
            ["-s", "--stay"] => (days: Int) ->
            {
                if (positionalArgs.length < 2)
                {
                    Sys.println('the --stay parameter can only be given after the second airport code');
                }
                stayDays.set(positionalArgs.length, days);
            },
            @doc("Stay at the destination preceding this parameter until this date.")
            ["-u", "--until"] => (yyyymmdd: String) ->
            {
                if (positionalArgs.length < 2)
                {
                    Sys.println('the --stay parameter can only be given after the second airport code');
                }
                untilDate.set(positionalArgs.length, ShortDate.fromString(yyyymmdd));
            },
            @doc("Self-transfer from the destination preceding this parameter to the next one.")
            ["-t", "--transfer"] => () ->
            {
                if (positionalArgs.length < 2)
                {
                    Sys.println('the --transfer parameter can only be given after the second airport code');
                }
                selfTransfer.set(positionalArgs.length, true);
            },

            @doc("Maximum number of stops for a single leg.")
            ["--max-stops"] => (stops: Int) ->
            {
                filters.maxStops = stops;
            },

            @doc("Only consider direct flights. (same as: --max-stops 0)")
            ["--direct"] => () ->
            {
                filters.maxStops = 0;
            },

            @doc("Maximum duration in hours of a single leg.")
            ["--max-duration"] => (hours: Float) ->
            {
                filters.maxDurationHours = hours;
            },

            @doc("Maximum total layover hours of a single leg.")
            ["--max-layover"] => (hours: Float) ->
            {
                filters.maxLayoverHours = hours;
            },

            @doc("Only consider legs with the same airline.")
            ["--same-airline"] => () ->
            {
                filters.singleAirline = true;
            },

            @doc("Reject layovers of 4h or more between 23:00 and 5:00.")
            ["--no-overnight"] => () ->
            {
                filters.overnightLayovers = false;
            },

            @doc("Allow self-transfers during layovers.")
            ["--self-transfer"] => () ->
            {
                filters.selfTransfers = true;
            },

            @doc("Accept preliminary search results instead of waiting.")
            ["-p", "--preliminary"] => () ->
            {
                preliminary = true;
            },

            @doc("The number of threads to use. (default: 10)")
            ["-w"] => (workers: Int) ->
            {
                nofThreads = workers;
            },

            @doc("Number of results to print. (default: 10")
            ["-c", "--count"] => (count: Int) ->
            {
                printCount = count;
            },

            @doc("Print out additional details for each trip.")
            ["--detailed"] => () ->
            {
                detailed = true;
            },

            @doc("Print dates as 'Day DD.MM' instead of the default 'YYYY-MM-DD'.")
            ["--dow"] => () ->
            {
                printDayOfWeek = true;
            },

            @doc("Print out the flights in JSON format.")
            ["--json"] => () ->
            {
                json = true;
            },

            @doc("Print more details to the output.")
            ["-v", "--verbose"] => () ->
            {
                verbose = true;
            },

            @doc("Print this help message and exit.")
            ["-h", "--help"] => () ->
            {
                help = true;
                helpExtended = true;
            },

            _ => (arg: String) ->
            {
                positionalArgs.push(arg);
            }
        ]);

        argHandler.parse(args);

        if (airportSearch != null)
        {
            var airportHints: Array<AirportHint> = skiplagged.searchAirports(airportSearch);
            for (hint in airportHints)
            {
                Sys.println(hint.toString());
            }
            Sys.exit(0);
        }

        for (posArg in positionalArgs)
        {
            if (!~/^\w\w\w$/.match(posArg) && !help)
            {
                Sys.println('argument not a 3-character IATA airport code: $posArg');
                help = true;
            }
        }

        if (positionalArgs.length == 2)
        {
            validateSimpleTripParams();
        }
        else if (positionalArgs.length > 2)
        {
            validateMultiTripParams();
        }
        else
        {
            Sys.println('need at least 2 airport codes');
            help = true;
        }

        if ((departFrom == null || departTo == null) && !help)
        {
            Sys.println('missing departure dates');
            help = true;
        }

        if ((nofThreads <= 0) && !help)
        {
            Sys.println('number of threads must be greater than 0');
            help = true;
        }

        if (help)
        {
            Sys.println('Usage: airflair [from IATA] [to IATA]');
            Sys.println(argHandler.getDoc());

            if (helpExtended)
            {
                Sys.println(examplesText());
                Sys.exit(0);
            }

            Sys.exit(1);
        }
    }

    function validateSimpleTripParams()
    {
        final origin: String = positionalArgs[0];
        final destination: String = positionalArgs[1];

        if ((origin == destination) && !help)
        {
            Sys.println('origin same as destination');
            help = true;
        }

        if ((tripDaysFrom != null && tripDaysTo == null) || (tripDaysFrom == null && tripDaysTo != null))
        {
            Sys.println('upper or lower trip days missing');
            help = true;
        }
        if ((((returnFrom != null) || (returnTo != null)) && (tripDaysFrom != null || tripDaysTo != null)) && !help)
        {
            Sys.println('either trip dates or return dates should be given, not both');
            help = true;
        }
    }

    function validateMultiTripParams()
    {
        var nofLegs: Int = positionalArgs.length - 1;

        // verify that no two consecutive airports are the same
        for (i in 0...nofLegs)
        {
            final origin: String = positionalArgs[i];
            final destination: String = positionalArgs[i + 1];

            if (origin == destination)
            {
                Sys.println('origin "$origin" same as destination "$destination"');
                help = true;
            }
        }

        // verify that only one of --stay and --until were given
        for (i in 1...nofLegs - 1)
        {
            final origin: String = positionalArgs[i];
            final destination: String = positionalArgs[i + 1];

            var legParamCnt: Int = 0;
            if (stayDays.exists(i + 1))
            {
                legParamCnt++;
            }
            if (untilDate.exists(i + 1))
            {
                legParamCnt++;
            }
            if (selfTransfer.exists(i + 1))
            {
                legParamCnt++;
            }

            if (legParamCnt != 1)
            {
                Sys.println('expected exactly one of --stay, --until or --transfer for leg $origin -> $destination, but neither was set');
                help = true;
            }
        }

        // verify that --until doesn't expect dates in the past
        var departureDates: Array<ShortDate> = ShortDate.getAllDates(departFrom, departTo);
        for (i in 0...nofLegs)
        {
            if (i > 0)
            {
                if (stayDays.exists(i + 1))
                {
                    departureDates = departureDates.map(d -> d.addDays(stayDays[i + 1]));
                }
                else if (untilDate.exists(i + 1))
                {
                    for (d in departureDates)
                    {
                        if (untilDate[i + 1] < d)
                        {
                            Sys.println('the given --until date (${untilDate[i + 1]}) is earlier than the previous leg departure ($d)');
                            help = true;
                        }
                    }
                    departureDates = [untilDate[i + 1]];
                }
                else if (selfTransfer.exists(i + 1))
                {
                    // no issue
                }
                else
                {
                    throw 'unreachable';
                }
            }
        }

        // verify that no round trip was requested
        if ((tripDaysFrom != null) || (tripDaysTo != null) || (returnFrom != null) || (returnTo != null))
        {
            Sys.println('round-trips are not supported for multi-stop itineraries');
            help = true;
        }
    }

    public function run()
    {
        CurrencyRate.load();

        if (positionalArgs.length == 2)
        {
            runSimpleTrip();
        }
        else
        {
            runMultiTrip();
        }
    }

    function runSimpleTrip()
    {
        var threadPool: ThreadPool = new ThreadPool(nofThreads, preliminary);
        final origin: String = positionalArgs[0];
        final destination: String = positionalArgs[1];
        final departureDates = ShortDate.getAllDates(departFrom, departTo);
        final returnDates = ShortDate.getAllDates(returnFrom, returnTo);
        final roundTrip: Bool = (returnDates != null) || (tripDaysFrom != null || tripDaysTo != null);

        if (roundTrip)
        {
            findRoundTripFlights(threadPool, origin, destination, departureDates, returnDates);
        }
        else
        {
            findOneWayFlights(threadPool, origin, destination, departureDates);
        }
        threadPool.stop();
    }

    function runMultiTrip()
    {
        var nofLegs: Int = positionalArgs.length - 1;
        var threadPool: ThreadPool = new ThreadPool(nofThreads, preliminary);

        var departureDates: Array<ShortDate> = ShortDate.getAllDates(departFrom, departTo);

        for (i in 0...nofLegs)
        {
            final origin: String = positionalArgs[i];
            final destination: String = positionalArgs[i + 1];
            if (i > 0)
            {
                if (stayDays.exists(i + 1))
                {
                    departureDates = departureDates.map(d -> d.addDays(stayDays[i + 1]));
                }
                else if (untilDate.exists(i + 1))
                {
                    departureDates = [untilDate[i + 1]];
                }
                else if (selfTransfer.exists(i + 1))
                {
                    // self-transfer from origin to destination
                    // no flights needed
                    continue;
                }
                else
                {
                    throw 'unreachable';
                }
            }

            for (departureDate in departureDates)
            {
                if (verbose)
                {
                    Sys.println('$origin -> $destination: $departureDate');
                }
                threadPool.add(skiplagged.searchOneWay(origin, destination, departureDate));
            }
        }

        var allFlights: Array<OneWayFlight> = Skiplagged.collectOneWay(threadPool.collect()).filter(f -> filters.matchesLegs(f.legs));

        var trips: Array<MultiStopFlight> = MultiStopFlight.allCombinations(positionalArgs, allFlights, selfTransfer);

        if (json)
        {
            Sys.println(Json.stringify(trips, null, '  '));
            return;
        }

        var tableHeader: Array<String> = ['PRICE'];
        for (i in 0...nofLegs)
        {
            if (selfTransfer.exists(i + 1))
            {
                // don't add a column for self-transfers
                continue;
            }

            final origin: String = positionalArgs[i];
            final destination: String = positionalArgs[i + 1];

            tableHeader.push('$origin..$destination');
        }
        var table: TablePrinter = new TablePrinter(tableHeader, detailed ? 3 : null);
        printCount = printCount <= trips.length ? printCount : trips.length;
        for (i in 0...printCount)
        {
            var trip: MultiStopFlight = trips[i];

            var row: Array<String> = [trip.priceFormatted];

            for (l in 0...nofLegs)
            {
                if (selfTransfer.exists(l + 1))
                {
                    // don't add a column for self-transfers
                    continue;
                }

                var flight: OneWayFlight = trip.flights[l];

                row.push(flight.toShortString(printDayOfWeek));
            }

            table.addRow(row);

            if (detailed)
            {
                var row: Array<String> = [''];
                for (l in 0...nofLegs)
                {
                    if (selfTransfer.exists(l + 1))
                    {
                        // don't add a column for self-transfers
                        continue;
                    }

                    var flight: OneWayFlight = trip.flights[l];

                    row.push(flight.legs.legsToString());
                }
                table.addRow(row);

                var row: Array<String> = [''];
                for (l in 0...nofLegs)
                {
                    if (selfTransfer.exists(l + 1))
                    {
                        // don't add a column for self-transfers
                        continue;
                    }

                    var flight: OneWayFlight = trip.flights[l];

                    row.push(flight.legs.legsAirlinesList());
                }
                table.addRow(row);
            }
        }

        Sys.println(table.toString());
    }

    function findOneWayFlights(threadPool: ThreadPool, origin: String, destination: String, departureDates: Array<ShortDate>)
    {
        for (departureDate in departureDates)
        {
            if (verbose)
            {
                Sys.println('$origin -> $destination: $departureDate');
            }
            threadPool.add(skiplagged.searchOneWay(origin, destination, departureDate));
        }

        var table: TablePrinter = new TablePrinter(['PRICE', 'DATE', 'DEPARTURE', 'ARRIVAL', 'DURATION', 'TRIP'], detailed ? 2 : null);

        var flights = Skiplagged.collectOneWay(threadPool.collect()).filter(f -> filters.matchesLegs(f.legs));

        if (json)
        {
            Sys.println(Json.stringify(flights, null, '  '));
            return;
        }

        printCount = printCount <= flights.length ? printCount : flights.length;
        for (i in 0...printCount)
        {
            var flight: OneWayFlight = flights[i];

            var depDateStr: String = printDayOfWeek ? flight.departureDate.toDowString() : flight.departureDate.toString();

            table.addRow([
                flight.priceFormatted,
                depDateStr,
                flight.departureTimeFormatted,
                flight.arrivalTimeFormatted,
                flight.durationFormatted,
                flight.legs.legsToString()
            ]);
            if (detailed)
            {
                table.addRow(['', '', '', '', '', flight.legs.legsAirlinesList()]);
            }
        }

        Sys.println(table.toString());
    }

    function findRoundTripFlights(threadPool: ThreadPool, origin: String, destination: String, departureDates: Array<ShortDate>, returnDates: Array<ShortDate>)
    {
        for (departureDate in departureDates)
        {
            if (returnDates != null)
            {
                for (returnDate in returnDates)
                {
                    if (verbose)
                    {
                        Sys.println('$origin <-> $destination: $departureDate -> $returnDate');
                    }
                    threadPool.add(skiplagged.searchRoundTrip(origin, destination, departureDate, returnDate));
                }
            }
            else
            {
                for (returnDate in ShortDate.getAllReturnDatesInRange(departureDate, tripDaysFrom, tripDaysTo))
                {
                    if (verbose)
                    {
                        Sys.println('$origin <-> $destination: $departureDate -> $returnDate');
                    }
                    threadPool.add(skiplagged.searchRoundTrip(origin, destination, departureDate, returnDate));
                }
            }
        }

        var table: TablePrinter = new TablePrinter(['PRICE', 'OUTBOUND', '', 'INBOUND', '', '#DAYS'], detailed ? 3 : null);
        var flights: Array<RoundTripFlight> = Skiplagged.collectRoundTrip(threadPool.collect())
            .filter(f -> filters.matchesLegs(f.outbound) && filters.matchesLegs(f.inbound));

        if (json)
        {
            Sys.println(Json.stringify(flights, null, '  '));
            return;
        }

        printCount = printCount <= flights.length ? printCount : flights.length;
        for (i in 0...printCount)
        {
            var flight: RoundTripFlight = flights[i];
            var outbound: OneWayFlight = flight.getOutbound();
            var inbound: OneWayFlight = flight.getInbound();

            var outboundDepDateStr: String = printDayOfWeek ? outbound.departureDate.toDowString() : outbound.departureDate.toString();
            var inboundDepDateStr: String = printDayOfWeek ? inbound.departureDate.toDowString() : inbound.departureDate.toString();

            table.addRow([
                flight.priceFormatted,
                '$outboundDepDateStr ~ ${outbound.departureTimeFormatted} .. ${outbound.arrivalTimeFormatted}',
                outbound.durationFormatted,
                '$inboundDepDateStr ~ ${inbound.departureTimeFormatted} .. ${inbound.arrivalTimeFormatted}',
                inbound.durationFormatted,
                flight.getNofDays()
            ]);
            if (detailed)
            {
                table.addRow(['', outbound.legs.legsToString(), '', inbound.legs.legsToString(), '', '']);
                table.addRow([
                    '',
                    outbound.legs.legsAirlinesList(),
                    '',
                    inbound.legs.legsAirlinesList(),
                    '',
                    ''
                ]);
            }
        }

        Sys.println(table.toString());
    }

    function examplesText(): String
    {
        return '
== Dates ==

The following date formats are supported:

* YYYY-MM-DD
* DD.MM (current year)
* YYYYMMDD
* DD.MM.YYYY
* MM-DD (current year)
* DD/MM/YYYY
* DD/MM (current year)


== Examples ==

One-way trips from Amsterdam to Athens in the first two weeks of March

$ airflair AMS ATH --depart-from 01.03 --depart-to 15.03

Round-trips from Amsterdam to Athens on specific dates

$ airflair AMS ATH --depart 01.03 --return 12.03

Round-trips with a specific departure date, but a variety of return dates

$ airflair AMS ATH --depart 01.03 --return-from 05.03 --return-to 08.03

Round-trips spanning a specified number of days

$ airflair AMS ATH --depart-from 01.03 --depart-to 03.03 --days 5
$ airflair AMS ATH --depart 01.03 --days-from 5 --days-to 7

Multi-leg trip: travel from Amsterdam to Athens on the first weekend in March, stay for 5 days, then travel to Warsaw, and on the 12th return to Amsterdam

$ airflair AMS --depart-from 01.03 --depart-to 03.03 \\
              ATH --stay 5 \\
              WAW --until 12.03 \\
              AMS
        ';
    }
}

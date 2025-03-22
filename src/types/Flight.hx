package types;

import types.OneWayFlight;
import types.RoundTripFlight;


enum Flight
{
    OneWay(f: OneWayFlight);
    RoundTrip(f: RoundTripFlight);
}

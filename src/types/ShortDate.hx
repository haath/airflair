package types;

import util.parsedate.DotDateParser;
import util.parsedate.IsoDateParser;
import util.parsedate.JointIsoDateParser;
import util.parsedate.ShortDateParser;
import util.parsedate.SlashDateParser;
import util.parsedate.TruncDotDateParser;
import util.parsedate.TruncIsoDateParser;
import util.parsedate.TruncSlashDateParser;

using DateTools;
using StringTools;


typedef ShortDateData =
{
    var year: Int;
    var month: Int;
    var date: Int;
}

@:forward
abstract ShortDate(ShortDateData) from ShortDateData
{
    @:op(a < b)
    public static function lt(a: ShortDate, b: ShortDate): Bool
    {
        return (a.year < b.year)
            || ((a.year == b.year) && (a.month < b.month))
            || ((a.year == b.year) && (a.month == b.month) && (a.date < b.date));
    }

    @:op(a == b)
    public static function eq(a: ShortDate, b: ShortDate): Bool
    {
        return (a.year == b.year) && (a.month == b.month) && (a.date == b.date);
    }

    @:op(a <= b)
    public static function leq(a: ShortDate, b: ShortDate): Bool
    {
        return (a < b) || (a == b);
    }

    public static function fromString(str: String): ShortDate
    {
        var parsers: Array<ShortDateParser> = [
            new IsoDateParser(),
            new TruncIsoDateParser(),
            new JointIsoDateParser(),
            new DotDateParser(),
            new TruncDotDateParser(),
            new SlashDateParser(),
            new TruncSlashDateParser()
        ];

        for (parser in parsers)
        {
            var date: Null<ShortDate> = parser.parse(str);
            if (date != null)
            {
                if (date < ShortDate.today())
                {
                    throw 'date given is in the past: $date';
                }

                return date;
            }
        }

        var supportedFormatsList: String = parsers.map(p -> '* ' + p.description()).join('\n');
        throw 'invalid date: $str, supported formats:\n$supportedFormatsList\n';
    }

    public static function fromDate(date: Date): ShortDate
    {
        return {
            year: date.getFullYear(),
            month: date.getMonth(),
            date: date.getDate()
        }
    }

    @:to
    public function toDate(): Date
    {
        return new Date(this.year, this.month, this.date, 0, 0, 0);
    }

    @:to
    public function toString(): String
    {
        return '${Std.string(this.year).lpad('0', 4)}-${Std.string(this.month + 1).lpad('0', 2)}-${Std.string(this.date).lpad('0', 2)}';
    }

    public function toDowString(): String
    {
        var dow: String = switch (toDate().getDay())
            {
                case 0:
                    'Sun';
                case 1:
                    'Mon';
                case 2:
                    'Tue';
                case 3:
                    'Wed';
                case 4:
                    'Thu';
                case 5:
                    'Fri';
                case 6:
                    'Sat';

                default:
                    '???';
            };

        return '$dow ${Std.string(this.date).lpad('0', 2)}.${Std.string(this.month + 1).lpad('0', 2)}';
    }

    public function nextDay(): ShortDate
    {
        return addDays(1);
    }

    public function addDays(days: Int): ShortDate
    {
        var nextDay: ShortDate = fromDate(Date.fromTime(toDate().getTime() + (days * 24 * 60 * 60 * 1000)));
        return nextDay;
    }

    public static function today(): ShortDate
    {
        return fromDate(Date.now());
    }

    public static function getAllDates(from: ShortDate, to: ShortDate): Array<ShortDate>
    {
        if (to == null || from == null)
        {
            return null;
        }

        if (to < from)
        {
            throw 'invalid date range: ${from.toString()} -> ${to.toString()}';
        }

        var dates: Array<ShortDate> = [ ];

        var cur: ShortDate = from;

        while (cur < to)
        {
            dates.push(cur);
            cur = cur.nextDay();
        }

        dates.push(to);

        return dates;
    }

    public static function getAllReturnDatesInRange(from: ShortDate, minDays: Int, maxDays: Int): Array<ShortDate>
    {
        if (minDays > maxDays)
        {
            throw 'invalid trip days range: $minDays -> $maxDays';
        }

        var dates: Array<ShortDate> = [ ];

        var cur: ShortDate = from.addDays(minDays);
        dates.push(cur);
        for (_ in 0...(maxDays - minDays))
        {
            cur = cur.nextDay();
            dates.push(cur);
        }

        return dates;
    }
}

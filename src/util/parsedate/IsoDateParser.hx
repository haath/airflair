package util.parsedate;

import types.ShortDate;


class IsoDateParser implements ShortDateParser
{
    public function new()
    {
    }

    public function parse(str: String): Null<ShortDate>
    {
        var expr: EReg = ~/^(\d\d\d\d)-(\d\d)-(\d\d)/;
        return
            if (expr.match(str))
            {
                {
                    year: Std.parseInt(expr.matched(1)),
                    month: Std.parseInt(expr.matched(2)) - 1,
                    date: Std.parseInt(expr.matched(3)),
                }
            }
            else
            {
                null;
            }
    }

    public function description(): String
    {
        return 'YYYY-MM-DD';
    }
}

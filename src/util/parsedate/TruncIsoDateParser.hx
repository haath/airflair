package util.parsedate;

import types.ShortDate;


class TruncIsoDateParser implements ShortDateParser
{
    public function new()
    {
    }

    public function parse(str: String): Null<ShortDate>
    {
        var expr: EReg = ~/^(\d\d)-(\d\d)/;
        return
            if (expr.match(str))
            {
                {
                    year: Date.now().getFullYear(),
                    month: Std.parseInt(expr.matched(1)) - 1,
                    date: Std.parseInt(expr.matched(2)),
                };
            }
            else
            {
                null;
            }
    }

    public function description(): String
    {
        return 'DD.MM (current year)';
    }
}

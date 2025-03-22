package util.parsedate;

import types.ShortDate;


interface ShortDateParser
{
    function parse(str: String): Null<ShortDate>;

    function description(): String;
}

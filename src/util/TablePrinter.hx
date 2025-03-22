package util;

class TablePrinter
{
    final header: Array<Dynamic>;
    final rows: Array<Array<Dynamic>>;
    final separateEvery: Null<Int>;

    public function new(header: Array<Dynamic>, ?separateEvery: Int)
    {
        this.header = header;
        rows = [];
        this.separateEvery = separateEvery;
    }

    public function addRow(row: Array<Dynamic>): TablePrinter
    {
        if (header.length != row.length)
        {
            throw 'table has ${header.length} columns, but the given row has ${row.length} columns';
        }

        rows.push(row);

        return this;
    }

    public function toString(): String
    {
        var rows: Array<Array<String>> = [header.map(v -> Std.string(v))].concat(rows.map(r -> r.map(v -> Std.string(v))));

        var columnLengths: Array<Int> = [for (_ in 0...rows[0].length) 0];
        for (r in 0...rows.length)
        {
            for (c in 0...rows[r].length)
            {
                var length: Int = rows[r][c].length;

                if (length > columnLengths[c])
                {
                    columnLengths[c] = length;
                }
            }
        }

        var str: String = '';

        str += rowSeparator(columnLengths, '┌', '┬', '┐');

        for (r in 0...rows.length)
        {
            for (c in 0...rows[r].length)
            {
                var columnLength: Int = columnLengths[c];
                var text: String = '${rows[r][c]}';
                var textPadded: String = if (r == 0)
                        text.lpad(' ', 2 + Std.int(columnLength / 2)).rpad(' ', columnLength)
                    else
                        text.rpad(' ', columnLength);

                str += '│ $textPadded ';
            }

            str += '│\n';

            var addSeparator: Bool = r == 0;

            if ((separateEvery != null) && ((r % separateEvery) == 0))
            {
                addSeparator = true;
            }

            if (addSeparator && (r < rows.length - 1))
            {
                str += rowSeparator(columnLengths, '├', '┼', '┤');
            }
        }
        str += rowSeparator(columnLengths, '└', '┴', '┘');

        return str;
    }

    function rowSeparator(columnLengths: Array<Int>, left: String, mid: String, right: String): String
    {
        var str = '';
        str += left;
        for (c in 0...header.length)
        {
            if (c > 0)
            {
                str += mid;
            }
            var columnLength: Int = columnLengths[c];
            for (_ in 0...columnLength + 2)
            {
                str += '─';
            }
        }
        str += right;
        str += '\n';
        return str;
    }
}

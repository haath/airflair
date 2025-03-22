# airflair



# Dates

The following date formats are supported:

* YYYY-MM-DD
* DD.MM (current year)
* YYYYMMDD
* DD.MM.YYYY
* MM-DD (current year)
* DD/MM/YYYY
* DD/MM (current year)


# Examples

One-way trips from Amsterdam to Athens in the first two weeks of March

```
$ airflair AMS ATH --depart-from 01.03 --depart-to 15.03
```

Round-trips from Amsterdam to Athens on specific dates

```
$ airflair AMS ATH --depart 01.03 --return 12.03
```

Round-trips with a specific departure date, but a variety of return dates

```
$ airflair AMS ATH --depart 01.03 --return-from 05.03 --return-to 08.03
```

Round-trips spanning a specified number of days

```
$ airflair AMS ATH --depart-from 01.03 --depart-to 03.03 --days 5
```

```
$ airflair AMS ATH --depart 01.03 --days-from 5 --days-to 7
```

Multi-leg trip: travel from Amsterdam to Athens on the first weekend in March, stay for 5 days, then travel to Warsaw, and on the 12th return to Amsterdam

```
$ airflair AMS --depart-from 01.03 --depart-to 03.03 \
              ATH --stay 5 \
              WAW --until 12.03 \
              AMS
```

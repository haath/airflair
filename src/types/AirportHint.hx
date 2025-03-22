package types;

typedef AirportHintData =
{
    var value: String;
    var name: String;
    var location: String;
}

@:forward
abstract AirportHint(AirportHintData) from AirportHintData
{
    public function toString(): String
    {
        return '${this.value}: ${this.name} - ${this.location}';
    }
}

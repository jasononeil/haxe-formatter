package haxeFormatter;

typedef Configuration = {
    @:optional var imports:ImportConfiguration;
}

typedef ImportConfiguration = {
    @:optional var sort:Bool;
}
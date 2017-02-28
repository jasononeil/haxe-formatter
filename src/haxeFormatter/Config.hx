package haxeFormatter;

typedef Config = {
    @:optional var imports:ImportConfig;
    @:optional var padding:PaddingConfig;
}

typedef ImportConfig = {
    @:optional var sort:Bool;
}

typedef PaddingConfig = {
    @:optional var typeHintColon:SpacingPolicy;
    @:optional var functionTypeArrow:SpacingPolicy;
}

@:enum abstract SpacingPolicy(String) {
    var Before = "before";
    var After = "after";
    var Both = "both";
    var None = "none";
    var Ignore = "ignore";
}
package haxeFormatter;

typedef Config = {
    @:optional var imports:ImportConfig;
    @:optional var padding:PaddingConfig;
}

typedef ImportConfig = {
    @:optional var sort:Bool;
}

typedef PaddingConfig = {
    @:optional var typeHintColon:SpacePadding;
}

typedef SpacePadding = {
    @:optional var before:WhitespacePolicy;
    @:optional var after:WhitespacePolicy;
}

@:enum abstract WhitespacePolicy(String) {
    var Add = "add";
    var Remove = "remove";
    var Keep = "keep";
}
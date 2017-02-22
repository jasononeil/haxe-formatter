package haxeFormatter;

typedef Configuration = {
    @:optional var imports:ImportConfiguration;
    @:optional var padding:PaddingConfiguration;
}

typedef ImportConfiguration = {
    @:optional var sort:Bool;
}

typedef PaddingConfiguration = {
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
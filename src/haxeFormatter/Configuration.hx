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
    @:optional var after:OptionalBool;
    @:optional var before:OptionalBool;
}

@:enum abstract OptionalBool(Null<Bool>) to Bool from Bool {
    var Yes = true;
    var No = false;
    var Ignore = null;
}
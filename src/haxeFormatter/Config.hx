package haxeFormatter;

typedef Config = {
    @:optional var baseConfig:BaseConfig;
    @:optional var imports:ImportConfig;
    @:optional var padding:PaddingConfig;
}

typedef ImportConfig = {
    @:optional var sort:Bool;
}

typedef PaddingConfig = {
    @:optional var typeHintColon:SpacingPolicy;
    @:optional var functionTypeArrow:SpacingPolicy;
    @:optional var binaryOperator:BinaryOperatorConfig;
    @:optional var parenInner:InsertOrRemove;
    @:optional var beforeParenAfterKeyword:InsertOrRemove;
}

typedef BinaryOperatorConfig = {
    @:optional var defaultPadding:SpacingPolicy;
    @:optional var padded:Array<String>;
    @:optional var unpadded:Array<String>;
}

@:enum abstract SpacingPolicy(String) {
    var Before = "before";
    var After = "after";
    var Both = "both";
    var None = "none";
    var Ignore = "ignore";
}

@:enum abstract InsertOrRemove(String) {
    var Insert = "insert";
    var Remove = "remove";
    var Ignore = "ignore";

    public function toSpacingPolicy():SpacingPolicy return switch (this) {
        case InsertOrRemove.Ignore: SpacingPolicy.Ignore;
        case Insert: Both;
        case Remove: None;
        case _: null;
    }
}

@:enum abstract BaseConfig(String) to String {
    static var configs:Map<String, Config> = [
        Default => {
            imports: {
                sort: true
            },
            padding: {
                typeHintColon: None,
                functionTypeArrow: None,
                binaryOperator: {
                    defaultPadding: Both,
                    padded: [],
                    unpadded: ["..."]
                },
                parenInner: Remove,
                beforeParenAfterKeyword: Insert
            }
        },
        Noop => {
            imports: {
                sort: false
            },
            padding: {
                typeHintColon: Ignore,
                functionTypeArrow: Ignore,
                binaryOperator: {
                    defaultPadding: Ignore,
                    padded: [],
                    unpadded: []
                },
                parenInner: Ignore,
                beforeParenAfterKeyword: Ignore
            }
        }
    ];

    var Default = "default";
    var Noop = "noop";

    public function get():Config {
        return configs[this];
    }
}
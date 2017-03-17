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
    @:optional var typeHintColon:TwoSidedPadding;
    @:optional var functionTypeArrow:TwoSidedPadding;
    @:optional var binaryOperator:BinaryOperatorConfig;
    @:optional var parenInner:OneSidedPadding;
    @:optional var beforeParenAfterKeyword:OneSidedPadding;
    @:optional var comma:CommaPaddingConfig;
}

typedef BinaryOperatorConfig = {
    @:optional var defaultPadding:TwoSidedPadding;
    @:optional var padded:Array<String>;
    @:optional var unpadded:Array<String>;
}

typedef CommaPaddingConfig = {
    @:optional var defaultPadding:TwoSidedPadding;
    @:optional var propertyAccess:TwoSidedPadding;
}

@:enum abstract TwoSidedPadding(String) {
    var Before = "before";
    var After = "after";
    var Both = "both";
    var None = "none";
    var Ignore = "ignore";
}

@:enum abstract OneSidedPadding(String) {
    var Insert = "insert";
    var Remove = "remove";
    var Ignore = "ignore";

    public function toTwoSidedPadding():TwoSidedPadding return switch (this) {
        case OneSidedPadding.Ignore: TwoSidedPadding.Ignore;
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
                beforeParenAfterKeyword: Insert,
                comma: {
                    defaultPadding: After,
                    propertyAccess: None
                }
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
                beforeParenAfterKeyword: Ignore,
                comma: {
                    defaultPadding: Ignore,
                    propertyAccess: Ignore
                }
            }
        }
    ];

    var Default = "default";
    var Noop = "noop";

    public function get():Config {
        return configs[this];
    }
}
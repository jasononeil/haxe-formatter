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
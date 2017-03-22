package haxeFormatter;

typedef Config = {
    @:optional var baseConfig:BaseConfig;
    @:optional var imports:ImportConfig;
    @:optional var padding:PaddingConfig;
    @:optional var indent:IndentConfig;
    @:optional var newlineCharacter:NewlineCharacter;
    @:optional var brackets:BracketConfig;
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

typedef IndentConfig = {
    @:optional var whitespace:String;
    @:optional var indentSwitches:Bool;
}

typedef BracketConfig = {
    @:optional var newlineBeforeOpening:OptionalBool;
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

@:enum abstract NewlineCharacter(String) {
    var Auto = "auto";
    var LF = "lf";
    var CRLF = "crlf";

    public function getCharacter():String {
        return switch (this) {
            case LF: "\n";
            case CRLF: "\r\n";
            case _: throw "can't call getCharacter() on " + this;
        }
    }
}

@:enum abstract OptionalBool(String) {
    var Yes = "yes";
    var No = "no";
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
                },
                parenInner: Remove,
                beforeParenAfterKeyword: Insert,
                comma: {
                    defaultPadding: After,
                    propertyAccess: None
                }
            },
            indent: {
                whitespace: "\t",
                indentSwitches: true
            },
            newlineCharacter: Auto,
            brackets: {
                newlineBeforeOpening: No
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
            },
            indent: {
                whitespace: null,
                indentSwitches: true
            },
            newlineCharacter: Auto,
            brackets: {
                newlineBeforeOpening: Ignore
            }
        }
    ];

    var Default = "default";
    var Noop = "noop";

    public function get():Config {
        return configs[this];
    }
}
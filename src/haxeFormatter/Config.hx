package haxeFormatter;

typedef Config = {
    @:optional var baseConfig:BaseConfig;
    @:optional var imports:ImportConfig;
    @:optional var padding:PaddingConfig;
    @:optional var indent:IndentConfig;
    @:optional var newlineCharacter:NewlineCharacter;
    @:optional var braces:BraceConfig;
}

typedef ImportConfig = {
    @:optional var sort:Bool;
}

typedef PaddingConfig = {
    @:optional var colon:ColonPaddingConfig;
    @:optional var functionTypeArrow:TwoSidedPadding;
    @:optional var unaryOperator:OneSidedPadding;
    @:optional var binaryOperator:BinaryOperatorConfig;
    @:optional var assignment:TwoSidedPadding;
    @:optional var insideBrackets:InsideBracketsPaddingConfig;
    @:optional var beforeParenAfterKeyword:OneSidedPadding;
    @:optional var comma:CommaPaddingConfig;
}

typedef ColonPaddingConfig = {
    @:optional var typeHint:TwoSidedPadding;
}

typedef BinaryOperatorConfig = {
    @:optional var defaultPadding:TwoSidedPadding;
    @:optional var padded:Array<String>;
    @:optional var unpadded:Array<String>;
}

typedef InsideBracketsPaddingConfig = {
    @:optional var parens:OneSidedPadding;
    @:optional var braces:OneSidedPadding;
    @:optional var square:OneSidedPadding;
    @:optional var angle:OneSidedPadding;
}

typedef CommaPaddingConfig = {
    @:optional var defaultPadding:TwoSidedPadding;
    @:optional var propertyAccess:TwoSidedPadding;
}

typedef IndentConfig = {
    @:optional var whitespace:String;
    @:optional var indentSwitches:Bool;
}

typedef BraceConfig = {
    @:optional var newlineBeforeOpening:NewlineBeforeOpeningConfig;
    @:optional var newlineBeforeElse:OneSidedPadding;
}

typedef NewlineBeforeOpeningConfig = {
    @:optional var type:OneSidedPadding;
    @:optional var field:OneSidedPadding;
    @:optional var block:OneSidedPadding;
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

@:enum abstract BaseConfig(String) to String {
    static var configs:Map<String, Config> = [
        Default => {
            imports: {
                sort: true
            },
            padding: {
                colon: {
                    typeHint: None
                },
                functionTypeArrow: None,
                unaryOperator: Remove,
                binaryOperator: {
                    defaultPadding: Both,
                    padded: [],
                    unpadded: ["..."]
                },
                assignment: Both,
                insideBrackets: {
                    parens: Remove,
                    braces: Remove,
                    square: Remove,
                    angle: Remove
                },
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
            braces: {
                newlineBeforeOpening: {
                    type: Remove,
                    field: Remove,
                    block: Remove
                },
                newlineBeforeElse: Remove
            }
        },
        Noop => {
            imports: {
                sort: false
            },
            padding: {
                colon: {
                    typeHint: Ignore
                },
                functionTypeArrow: Ignore,
                unaryOperator: Ignore,
                binaryOperator: {
                    defaultPadding: Ignore,
                    padded: [],
                    unpadded: []
                },
                assignment: Ignore,
                insideBrackets: {
                    parens: Ignore,
                    braces: Ignore,
                    square: Ignore,
                    angle: Ignore
                },
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
            braces: {
                newlineBeforeOpening: {
                    type: Ignore,
                    field: Ignore,
                    block: Ignore
                },
                newlineBeforeElse: Ignore
            }
        }
    ];

    var Default = "default";
    var Noop = "noop";

    public function get():Config {
        return configs[this];
    }
}
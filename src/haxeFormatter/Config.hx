package haxeFormatter;

typedef Config = {
    @:optional var baseConfig:BaseConfig;
    @:optional var imports:ImportConfig;
    @:optional var padding:PaddingConfig;
    @:optional var indent:IndentConfig;
    @:optional var newlineCharacter:NewlineCharacter;
    @:optional var braces:BraceConfig;
    @:optional var hexadecimalLiterals:LetterCase;
}

typedef ImportConfig = {
    @:optional var sort:Bool;
}

typedef PaddingConfig = {
    @:optional var colon:ColonPaddingConfig;
    @:optional var functionTypeArrow:TwoSidedPadding;
    @:optional var unaryOperator:FormattingOperation;
    @:optional var binaryOperator:BinaryOperatorConfig;
    @:optional var assignment:TwoSidedPadding;
    @:optional var insideBrackets:InsideBracketsPaddingConfig;
    @:optional var beforeParenAfterKeyword:FormattingOperation;
    @:optional var comma:CommaPaddingConfig;
    @:optional var questionMark:QuestionMarkPaddingConfig;
    @:optional var beforeSemicolon:FormattingOperation;
    @:optional var beforeDot:FormattingOperation;
    @:optional var afterStructuralExtension:FormattingOperation;
}

typedef ColonPaddingConfig = {
    @:optional var typeHint:TwoSidedPadding;
    @:optional var objectField:TwoSidedPadding;
    @:optional var caseAndDefault:TwoSidedPadding;
    @:optional var typeCheck:TwoSidedPadding;
    @:optional var ternary:TwoSidedPadding;
}

typedef BinaryOperatorConfig = {
    @:optional var defaultPadding:TwoSidedPadding;
    @:optional var padded:Array<String>;
    @:optional var unpadded:Array<String>;
}

typedef InsideBracketsPaddingConfig = {
    @:optional var parens:FormattingOperation;
    @:optional var braces:FormattingOperation;
    @:optional var square:FormattingOperation;
    @:optional var angle:FormattingOperation;
}

typedef CommaPaddingConfig = {
    @:optional var defaultPadding:TwoSidedPadding;
    @:optional var propertyAccess:TwoSidedPadding;
}

typedef QuestionMarkPaddingConfig = {
    @:optional var ternary:TwoSidedPadding;
    @:optional var optional:FormattingOperation;
}

typedef IndentConfig = {
    @:optional var whitespace:String;
    @:optional var indentSwitches:Bool;
}

typedef BraceConfig = {
    @:optional var newlineBeforeOpening:NewlineBeforeOpeningConfig;
    @:optional var newlineBeforeElse:FormattingOperation;
}

typedef NewlineBeforeOpeningConfig = {
    @:optional var type:FormattingOperation;
    @:optional var field:FormattingOperation;
    @:optional var block:FormattingOperation;
}

@:enum abstract TwoSidedPadding(String) {
    var Before = "before";
    var After = "after";
    var Both = "both";
    var None = "none";
    var Ignore = "ignore";

    public function inverted():TwoSidedPadding return switch (this) {
        case Ignore: Ignore;
        case Before: After;
        case After: Before;
        case None: Both;
        case Both: None;
        case _: null;
    }
}

@:enum abstract FormattingOperation(String) {
    var Insert = "insert";
    var Remove = "remove";
    var Ignore = "ignore";

    public function inverted():FormattingOperation return switch (this) {
        case FormattingOperation.Ignore: Ignore;
        case Insert: Remove;
        case Remove: Insert;
        case _: null;
    }

    public function toTwoSidedPadding():TwoSidedPadding return switch (this) {
        case FormattingOperation.Ignore: TwoSidedPadding.Ignore;
        case Insert: Both;
        case Remove: None;
        case _: null;
    }
}

@:enum abstract LetterCase(String) {
    var UpperCase = "upperCase";
    var LowerCase = "lowerCase";
    var Ignore = "ignore";

    public function inverted():LetterCase return switch (this) {
        case Ignore: Ignore;
        case LowerCase: UpperCase;
        case UpperCase: LowerCase;
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
                    typeHint: None,
                    objectField: After,
                    caseAndDefault: After,
                    typeCheck: Both,
                    ternary: Both
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
                },
                questionMark: {
                    ternary: Both,
                    optional: Remove
                },
                beforeSemicolon: Remove,
                beforeDot: Remove,
                afterStructuralExtension: Insert
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
            },
            hexadecimalLiterals: UpperCase
        },
        Noop => {
            imports: {
                sort: false
            },
            padding: {
                colon: {
                    typeHint: Ignore,
                    objectField: Ignore,
                    caseAndDefault: Ignore,
                    typeCheck: Ignore,
                    ternary: Ignore
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
                },
                questionMark: {
                    ternary: Ignore,
                    optional: Ignore
                },
                beforeSemicolon: Ignore,
                beforeDot: Ignore,
                afterStructuralExtension: Ignore
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
            },
            hexadecimalLiterals: Ignore
        }
    ];

    var Default = "default";
    var Noop = "noop";

    public function get():Config {
        return configs[this];
    }
}
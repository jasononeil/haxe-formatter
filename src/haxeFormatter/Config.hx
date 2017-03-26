package haxeFormatter;

import hxParser.ParseTree.FieldModifier;

typedef Config = {
    @:optional var baseConfig:BaseConfig;
    @:optional var imports:ImportConfig;
    @:optional var padding:PaddingConfig;
    @:optional var indent:IndentConfig;
    @:optional var newlineCharacter:NewlineCharacter;
    @:optional var braces:BraceConfig;
    @:optional var hexadecimalLiterals:LetterCase;
    @:optional var fieldModifierOrder:Array<Modifier>;
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
    @:optional var questionMark:QuestionMarkPaddingConfig;
    @:optional var beforeSemicolon:OneSidedPadding;
    @:optional var beforeDot:OneSidedPadding;
    @:optional var beforeOpeningBrace:OneSidedPadding;
    @:optional var beforeElse:OneSidedPadding;
    @:optional var afterStructuralExtension:OneSidedPadding;
    @:optional var afterClosingParen:OneSidedPadding;
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
    @:optional var parens:OneSidedPadding;
    @:optional var braces:OneSidedPadding;
    @:optional var square:OneSidedPadding;
    @:optional var angle:OneSidedPadding;
}

typedef CommaPaddingConfig = {
    @:optional var defaultPadding:TwoSidedPadding;
    @:optional var propertyAccess:TwoSidedPadding;
}

typedef QuestionMarkPaddingConfig = {
    @:optional var ternary:TwoSidedPadding;
    @:optional var optional:OneSidedPadding;
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

@:enum abstract OneSidedPadding(String) {
    var SingleSpace = "singleSpace";
    var NoSpace = "noSpace";
    var Keep = "keep";

    public function inverted():OneSidedPadding return switch (this) {
        case Keep: Keep;
        case SingleSpace: NoSpace;
        case NoSpace: SingleSpace;
        case _: null;
    }
}

@:enum abstract TwoSidedPadding(String) {
    var SpaceBefore = "spaceBefore";
    var SpaceAfter = "spaceAfter";
    var SpacesAround = "spacesAround";
    var NoSpaces = "noSpaces";
    var Keep = "keep";

    public function inverted():TwoSidedPadding return switch (this) {
        case Keep: Keep;
        case SpaceBefore: SpaceAfter;
        case SpaceAfter: SpaceBefore;
        case NoSpaces: SpacesAround;
        case SpacesAround: NoSpaces;
        case _: null;
    }
}

@:enum abstract FormattingOperation(String) {
    var Insert = "insert";
    var Remove = "remove";
    var Keep = "ignore";

    public function inverted():FormattingOperation return switch (this) {
        case FormattingOperation.Keep: Keep;
        case Insert: Remove;
        case Remove: Insert;
        case _: null;
    }
}

@:enum abstract LetterCase(String) {
    var UpperCase = "upperCase";
    var LowerCase = "lowerCase";
    var Keep = "ignore";

    public function inverted():LetterCase return switch (this) {
        case Keep: Keep;
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

@:enum abstract Modifier(String) {
    var Static = "static";
    var Macro = "macro";
    var Public = "public";
    var Private = "private";
    var Override = "override";
    var Dynamic = "dynamic";
    var Inline = "inline";

    function new(modifier) this = modifier;

    @:from static function fromFieldModifier(modifier:FieldModifier):Modifier {
        return new Modifier(modifier.getName().toLowerCase());
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
                    typeHint: NoSpaces,
                    objectField: SpaceAfter,
                    caseAndDefault: SpaceAfter,
                    typeCheck: SpacesAround,
                    ternary: SpacesAround
                },
                functionTypeArrow: NoSpaces,
                unaryOperator: NoSpace,
                binaryOperator: {
                    defaultPadding: SpacesAround,
                    padded: [],
                    unpadded: ["..."]
                },
                assignment: SpacesAround,
                insideBrackets: {
                    parens: NoSpace,
                    braces: NoSpace,
                    square: NoSpace,
                    angle: NoSpace
                },
                beforeParenAfterKeyword: SingleSpace,
                comma: {
                    defaultPadding: SpaceAfter,
                    propertyAccess: SpaceAfter
                },
                questionMark: {
                    ternary: SpacesAround,
                    optional: NoSpace
                },
                beforeSemicolon: NoSpace,
                beforeDot: NoSpace,
                beforeOpeningBrace: SingleSpace,
                beforeElse: SingleSpace,
                afterStructuralExtension: SingleSpace,
                afterClosingParen: SingleSpace
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
            hexadecimalLiterals: UpperCase,
            fieldModifierOrder: [
                Override,
                Public,
                Private,
                Static,
                Macro,
                Dynamic,
                Inline
            ]
        },
        Noop => {
            imports: {
                sort: false
            },
            padding: {
                colon: {
                    typeHint: Keep,
                    objectField: Keep,
                    caseAndDefault: Keep,
                    typeCheck: Keep,
                    ternary: Keep
                },
                functionTypeArrow: Keep,
                unaryOperator: Keep,
                binaryOperator: {
                    defaultPadding: Keep,
                    padded: [],
                    unpadded: []
                },
                assignment: Keep,
                insideBrackets: {
                    parens: Keep,
                    braces: Keep,
                    square: Keep,
                    angle: Keep
                },
                beforeParenAfterKeyword: Keep,
                comma: {
                    defaultPadding: Keep,
                    propertyAccess: Keep
                },
                questionMark: {
                    ternary: Keep,
                    optional: Keep
                },
                beforeSemicolon: Keep,
                beforeDot: Keep,
                beforeOpeningBrace: Keep,
                beforeElse: Keep,
                afterStructuralExtension: Keep,
                afterClosingParen: Keep
            },
            indent: {
                whitespace: null,
                indentSwitches: true
            },
            newlineCharacter: Auto,
            braces: {
                newlineBeforeOpening: {
                    type: Keep,
                    field: Keep,
                    block: Keep
                },
                newlineBeforeElse: Keep
            },
            hexadecimalLiterals: Keep,
            fieldModifierOrder: []
        }
    ];

    var Default = "default";
    var Noop = "noop";

    public function get():Config {
        return configs[this];
    }
}
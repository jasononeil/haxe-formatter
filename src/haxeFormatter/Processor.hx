package haxeFormatter;

import haxe.ds.ArraySort;
import haxeFormatter.Config;
import hxParser.ParseTree;
import hxParser.Printer.print;
import hxParser.StackAwareWalker;
import hxParser.WalkStack;

enum SpacingLocation {
    Before;
    After;
}

class Processor extends StackAwareWalker {
    var config:Config;
    var prevToken:Token;

    var padding(get,never):PaddingConfig;

    inline function get_padding() return config.padding;

    public function new(config:Config) {
        this.config = config;
    }

    override function walkFile_decls(elems:Array<Decl>, stack:WalkStack) {
        super.walkFile_decls(elems, stack);
        if (config.imports.sort)
            sortImports(elems);
    }

    override function walkToken(token:Token, stack:WalkStack) {
        super.walkToken(token, stack);
        padInsideBrackets(token, stack);

        switch (token.text) {
            case '{':
                handleOpeningBracket(token, stack);
            case ',':
                handleComma(token, stack);
            case ';':
                padSpace(padding.beforeSemicolon.toTwoSidedPadding(), Before, token.prevToken);
            case _:
        }

        prevToken = token;
    }

    function padInsideBrackets(token:Token, stack:WalkStack) {
        var insideBracketsConfig = getInsideBracketsConfig(token.text);

        inline function padOpening()
            padSpace(insideBracketsConfig, After, token);

        inline function padClosing()
            padSpace(insideBracketsConfig, Before, prevToken);

        inline function inTypeParams()
            return stack.match(Edge(_, Node(TypePathParameters(_), _))) ||
            stack.match(Edge(_, Node(TypeDeclParameters(_), _)));

        switch (token.text) {
            case '(' | '{' | '[': padOpening();
            case ')' | '}' | ']': padClosing();
            case '<' if (inTypeParams()): padOpening();
            case '>' if (inTypeParams()): padClosing();
            case _:
        }
    }

    function getInsideBracketsConfig(token:String):TwoSidedPadding {
        var insideBrackets = padding.insideBrackets;
        var padding = switch (token) {
            case '(' | ')': insideBrackets.parens;
            case '{' | '}': insideBrackets.braces;
            case '[' | ']': insideBrackets.square;
            case '<' | '>': insideBrackets.angle;
            case _: null;
        }
        return if (padding != null) padding.toTwoSidedPadding() else null;
    }

    function handleOpeningBracket(token:Token, stack:WalkStack) {
        var newlineConfigs = config.braces.newlineBeforeOpening;
        var newlineConfig:FormattingOperation = switch (stack.getDepth()) {
            case Block: newlineConfigs.block;
            case Field: newlineConfigs.field;
            case Decl: newlineConfigs.type;
            case Unknown: Ignore;
        }

        switch (newlineConfig) {
            case Insert:
                prevToken.trailingTrivia = [makeNewlineTrivia()];
                token.leadingTrivia = [];
            case Remove:
                prevToken.trailingTrivia = [];
                token.leadingTrivia = [new Trivia(" ")];
            case Ignore:
        }
    }

    function handleComma(token:Token, stack:WalkStack) {
        var comma = padding.comma;
        var config = comma.defaultPadding;
        switch (stack) {
            case Edge(_, Node(ClassField_Property(_, _, _, _, _, _, _, _, _, _, _, _), _)):
                config = comma.propertyAccess;
            case _:
        }
        padSpaces(config, token);
    }

    function makeNewlineTrivia():Trivia {
        return new Trivia(config.newlineCharacter.getCharacter());
    }

    function sortImports(decls:Array<Decl>) {
        var firstImport = getFirstImportDecl(decls);
        if (firstImport == null)
            return;

        var importToken = getImportToken(firstImport);
        var leadingTrivia = importToken.leadingTrivia;
        importToken.leadingTrivia = [];

        ArraySort.sort(decls, function(decl1, decl2) return switch [decl1, decl2] {
            case [ImportDecl(i1), ImportDecl(i2)]:
                Reflect.compare(print(i1.path), print(i2.path));

            case [UsingDecl(u1), UsingDecl(u2)]:
                Reflect.compare(print(u1.path), print(u2.path));

            case [ImportDecl(_), UsingDecl(_)]: -1;
            case [UsingDecl(_), ImportDecl(_)]: 1;

            case [ImportDecl(_), _]: -1;
            case [_, ImportDecl(_)]: 1;

            case [UsingDecl(_), _]: -1;
            case [_, UsingDecl(_)]: 1;
            case _: 0;
        });

        getImportToken(decls[0]).leadingTrivia = leadingTrivia;
    }

    function getFirstImportDecl(decls:Array<Decl>):Decl {
        for (decl in decls) {
            if (decl.match(ImportDecl(_)) || decl.match(UsingDecl(_)))
                return decl;
        }
        return null;
    }

    function getImportToken(decl:Decl):Token {
        return switch (decl) {
            case ImportDecl({importKeyword: _import}): _import;
            case UsingDecl({usingKeyword: _using}): _using;
            case _: expected("using or import");
        }
    }

    override function walkTypeHint(node:TypeHint, stack:WalkStack) {
        super.walkTypeHint(node, stack);
        padSpaces(padding.colon.typeHint, node.colon);
    }

    override function walkObjectField(node:ObjectField, stack:WalkStack) {
        super.walkObjectField(node, stack);
        padSpaces(padding.colon.objectField, node.colon);
    }

    override function walkCase_Case(caseKeyword:Token, patterns:CommaSeparated<Expr>, guard:Null<Guard>, colon:Token, body:Array<BlockElement>, stack:WalkStack) {
        super.walkCase_Case(caseKeyword, patterns, guard, colon, body, stack);
        padSpaces(padding.colon.caseAndDefault, colon);
    }

    override function walkCase_Default(defaultKeyword:Token, colon:Token, body:Array<BlockElement>, stack:WalkStack) {
        super.walkCase_Default(defaultKeyword, colon, body, stack);
        padSpaces(padding.colon.caseAndDefault, colon);
    }

    override function walkExpr_ECheckType(parenOpen:Token, expr:Expr, colon:Token, type:ComplexType, parenClose:Token, stack:WalkStack) {
        super.walkExpr_ECheckType(parenOpen, expr, colon, type, parenClose, stack);
        padSpaces(padding.colon.typeCheck, colon);
    }

    override function walkExpr_ETernary(exprCond:Expr, questionMark:Token, exprThen:Expr, colon:Token, exprElse:Expr, stack:WalkStack) {
        super.walkExpr_ETernary(exprCond, questionMark, exprThen, colon, exprElse, stack);
        padSpaces(padding.questionMark.ternary, questionMark);
        padSpaces(padding.colon.ternary, colon);
    }

    override function walkComplexType_Optional(questionMark:Token, type:ComplexType, stack:WalkStack) {
        super.walkComplexType_Optional(questionMark, type, stack);
        padOptional(questionMark);
    }

    override function walkFunctionArgument(node:FunctionArgument, stack:WalkStack) {
        super.walkFunctionArgument(node, stack);
        padOptional(node.questionMark);
    }

    override function walkAnonymousStructureField(node:AnonymousStructureField, stack:WalkStack) {
        super.walkAnonymousStructureField(node, stack);
        padOptional(node.questionMark);
    }

    override function walkNEnumFieldArg(node:NEnumFieldArg, stack:WalkStack) {
        super.walkNEnumFieldArg(node, stack);
        padOptional(node.questionMark);
    }

    inline function padOptional(questionMark:Token) {
        padSpace(padding.questionMark.optional.toTwoSidedPadding(), After, questionMark);
    }

    override function walkStructuralExtension(node:StructuralExtension, stack:WalkStack) {
        super.walkStructuralExtension(node, stack);
        padSpace(padding.afterStructuralExtension.toTwoSidedPadding(), After, node.gt);
    }

    override function walkAssignment(node:Assignment, stack:WalkStack) {
        super.walkAssignment(node, stack);
        padSpaces(padding.assignment, node.assign);
    }

    override function walkComplexType_Function(typeLeft:ComplexType, arrow:Token, typeRight:ComplexType, stack:WalkStack) {
        super.walkComplexType_Function(typeLeft, arrow, typeRight, stack);
        padSpaces(padding.functionTypeArrow, arrow);
    }

    override function walkExpr_EBinop(exprLeft:Expr, op:Token, exprRight:Expr, stack:WalkStack) {
        var binopConfig = padding.binaryOperator;
        var spacing = binopConfig.defaultPadding;
        if (binopConfig.padded.has(op.text)) spacing = Both;
        if (binopConfig.unpadded.has(op.text)) spacing = None;

        padSpaces(spacing, op);
        super.walkExpr_EBinop(exprLeft, op, exprRight, stack);
    }

    override function walkExpr_EUnaryPostfix(expr:Expr, op:Token, stack:WalkStack) {
        padSpace(padding.unaryOperator.toTwoSidedPadding(), After, op.prevToken);
        super.walkExpr_EUnaryPostfix(expr, op, stack);
    }

    override function walkExpr_EUnaryPrefix(op:Token, expr:Expr, stack:WalkStack) {
        padSpace(padding.unaryOperator.toTwoSidedPadding(), Before, op);
        super.walkExpr_EUnaryPrefix(op, expr, stack);
    }

    override function walkExpr_EIf(ifKeyword:Token, parenOpen:Token, exprCond:Expr, parenClose:Token, exprThen:Expr, exprElse:Null<ExprElse>, stack:WalkStack) {
        super.walkExpr_EIf(ifKeyword, parenOpen, exprCond, parenClose, exprThen, exprElse, stack);
        padKeywordParen(ifKeyword);
    }

    override function walkExprElse(node:ExprElse, stack:WalkStack) {
        switch (config.braces.newlineBeforeElse) {
            case Insert:
                prevToken.trailingTrivia = [makeNewlineTrivia()];
            case Remove if (prevToken.text == '}'):
                prevToken.trailingTrivia = [];
                node.elseKeyword.leadingTrivia = [new Trivia(" ")];
            case _:
        }
        super.walkExprElse(node, stack);
    }

    override function walkExpr_EFor(forKeyword:Token, parenOpen:Token, exprIter:Expr, parenClose:Token, exprBody:Expr, stack:WalkStack) {
        super.walkExpr_EFor(forKeyword, parenOpen, exprIter, parenClose, exprBody, stack);
        padKeywordParen(forKeyword);
    }

    override function walkExpr_EWhile(whileKeyword:Token, parenOpen:Token, exprCond:Expr, parenClose:Token, exprBody:Expr, stack:WalkStack) {
        super.walkExpr_EWhile(whileKeyword, parenOpen, exprCond, parenClose, exprBody, stack);
        padKeywordParen(whileKeyword);
    }

    override function walkExpr_ESwitch(switchKeyword:Token, expr:Expr, braceOpen:Token, cases:Array<Case>, braceClose:Token, stack:WalkStack) {
        super.walkExpr_ESwitch(switchKeyword, expr, braceOpen, cases, braceClose, stack);
        padKeywordParen(switchKeyword);
    }

    override function walkNDotIdent_PDotIdent(name:Token, stack:WalkStack) {
        super.walkNDotIdent_PDotIdent(name, stack);
        padSpace(padding.beforeDot.toTwoSidedPadding(), Before, name.prevToken);
    }

    override function walkImportMode_IAll(dotStar:Token, stack:WalkStack) {
        super.walkImportMode_IAll(dotStar, stack);
        padSpace(padding.beforeDot.toTwoSidedPadding(), Before, dotStar.prevToken);
    }

    override function walkLiteral_PLiteralInt(token:Token, stack:WalkStack) {
        super.walkLiteral_PLiteralInt(token, stack);
        if (config.hexadecimalLiterals == Ignore) return;
        var hexRegex = ~/0x([0-9a-fA-F]+)/;
        if (hexRegex.match(token.text)) {
            var literal = hexRegex.matched(1);
            token.text = '0x${switch (config.hexadecimalLiterals) {
                case UpperCase: literal.toUpperCase();
                case LowerCase: literal.toLowerCase();
                case Ignore: throw "unexpected Ignore";
            }}';
        }
    }

    function padKeywordParen(keyword:Token) {
        padSpace(padding.beforeParenAfterKeyword.toTwoSidedPadding(), After, keyword);
    }

    function padSpaces(padding:TwoSidedPadding, token:Token) {
        var prevToken = token.prevToken;
        if (prevToken != null) padSpace(padding, Before, prevToken);
        padSpace(padding, After, token);
    }

    function padSpace(padding:TwoSidedPadding, location:SpacingLocation, token:Token) {
        if (token == null)
            return;

        var trivia = token.trailingTrivia;
        if (trivia == null)
            trivia = [];

        if (trivia.length > 0 && trivia[0].text.isNewline())
            return;

        if (trivia.length > 0 && trivia[0].text.isWhitespace())
            trivia[0].text = getPadding(padding, location, trivia[0].text)
        else
            trivia.insert(0, new Trivia(getPadding(padding, location, "")));

        token.trailingTrivia = trivia;
    }

    function getPadding(padding:TwoSidedPadding, location:SpacingLocation, whitespace:String):String {
        return switch [padding, location] {
            case [Ignore, _]: whitespace;
            case [Both, _], [Before, Before], [After, After]: " ";
            case _: "";
        }
    }

    inline function expected(what:String) {
        return throw '$what expected';
    }
}
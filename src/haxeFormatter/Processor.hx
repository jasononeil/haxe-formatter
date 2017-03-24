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
            case _:
        }

        prevToken = token;
    }

    function padInsideBrackets(token:Token, stack:WalkStack) {
        var insideBracketsConfig = getInsideBracketsConfig(token.text);

        inline function padOpening()
            token.trailingTrivia = padSpace(insideBracketsConfig, After, token.trailingTrivia);

        inline function padClosing()
            prevToken.trailingTrivia = padSpace(insideBracketsConfig, Before, prevToken.trailingTrivia);

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
        var insideBrackets = config.padding.insideBrackets;
        var padding = switch (token) {
            case '(' | ')': insideBrackets.parens;
            case '{' | '}': insideBrackets.braces;
            case '[' | ']': insideBrackets.square;
            case '<' | '>': insideBrackets.angle;
            case _: null;
        }
        return if (padding != null) padding.toTwoSidedPadding()
        else null;
    }

    function handleOpeningBracket(token:Token, stack:WalkStack) {
        var newlineConfigs = config.brackets.newlineBeforeOpening;
        var newlineConfig:OptionalBool = switch (stack.getDepth()) {
            case Block: newlineConfigs.block;
            case Field: newlineConfigs.field;
            case Decl: newlineConfigs.type;
            case Unknown: Ignore;
        }

        switch (newlineConfig) {
            case Yes:
                prevToken.trailingTrivia = [makeNewlineTrivia()];
                token.leadingTrivia = [];
            case No:
                prevToken.trailingTrivia = [];
                token.leadingTrivia = [new Trivia(" ")];
            case Ignore:
        }
    }

    function handleComma(token:Token, stack:WalkStack) {
        var comma = config.padding.comma;
        var config = comma.defaultPadding;
        switch (stack) {
            case Edge(_, Node(ClassField_Property(_, _, _, _, _, _, _, _, _, _, _, _), _)):
                config = comma.propertyAccess;
            case _:
        }
        padSpaces(config, prevToken, token);
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
            case ImportDecl( {importKeyword: _import}): _import;
            case UsingDecl( {usingKeyword: _using}): _using;
            case _: expected("using or import");
        }
    }

    override function walkTypeHint(node:TypeHint, stack:WalkStack) {
        padSpaces(config.padding.typeHintColon, prevToken, node.colon);
        super.walkTypeHint(node, stack);
    }

    override function walkComplexType_Function(typeLeft:ComplexType, arrow:Token, typeRight:ComplexType, stack:WalkStack) {
        walkComplexType(typeLeft, stack);
        padSpaces(config.padding.functionTypeArrow, prevToken, arrow);
        super.walkComplexType_Function(typeLeft, arrow, typeRight, stack);
    }

    override function walkExpr_EBinop(exprLeft:Expr, op:Token, exprRight:Expr, stack:WalkStack) {
        walkExpr(exprLeft, stack);

        var binopConfig = config.padding.binaryOperator;
        var spacing = binopConfig.defaultPadding;
        if (binopConfig.padded.has(op.text)) spacing = Both;
        if (binopConfig.unpadded.has(op.text)) spacing = None;

        padSpaces(spacing, prevToken, op);
        super.walkExpr_EBinop(exprLeft, op, exprRight, stack);
    }

    override function walkExpr_EUnaryPostfix(expr:Expr, op:Token, stack:WalkStack) {
        walkExpr(expr, stack); // no need for this once tokens are doubly linked, just use op.prevToken then
        padSpace(config.padding.unaryOperator.toTwoSidedPadding(), After, prevToken.trailingTrivia);
        super.walkExpr_EUnaryPostfix(expr, op, stack);
    }

    override function walkExpr_EUnaryPrefix(op:Token, expr:Expr, stack:WalkStack) {
        padSpace(config.padding.unaryOperator.toTwoSidedPadding(), Before, op.trailingTrivia);
        super.walkExpr_EUnaryPrefix(op, expr, stack);
    }

    override function walkExpr_EIf(ifKeyword:Token, parenOpen:Token, exprCond:Expr, parenClose:Token, exprThen:Expr, exprElse:Null<ExprElse>, stack:WalkStack) {
        super.walkExpr_EIf(ifKeyword, parenOpen, exprCond, parenClose, exprThen, exprElse, stack);
        padKeywordParen(ifKeyword);
    }

    override function walkExprElse(node:ExprElse, stack:WalkStack) {
        switch (config.brackets.newlineBeforeElse) {
            case Yes:
                prevToken.trailingTrivia = [makeNewlineTrivia()];
            case No:
                prevToken.trailingTrivia = [];
                node.elseKeyword.leadingTrivia = [new Trivia(" ")];
            case Ignore:
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

    function padKeywordParen(keyword:Token) {
        keyword.trailingTrivia = padSpace(config.padding.beforeParenAfterKeyword.toTwoSidedPadding(), After, keyword.trailingTrivia);
    }

    function padSpaces(padding:TwoSidedPadding, leftToken:Token, rightToken:Token) {
        leftToken.trailingTrivia = padSpace(padding, Before, leftToken.trailingTrivia);
        rightToken.trailingTrivia = padSpace(padding, After, rightToken.trailingTrivia);
    }

    function padSpace(padding:TwoSidedPadding, location:SpacingLocation, trivia:Array<Trivia>):Array<Trivia> {
        if (trivia == null)
            trivia = [];

        if (trivia.length > 0 && trivia[0].text.isNewline())
            return trivia;

        if (trivia.length > 0 && trivia[0].text.isWhitespace())
            trivia[0].text = getPadding(padding, location, trivia[0].text);
        else
            trivia.insert(0, new Trivia(getPadding(padding, location, "")));

        return trivia;
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
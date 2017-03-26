package haxeFormatter;

import haxe.ds.ArraySort;
import haxeFormatter.Config;
import hxParser.ParseTree;
import hxParser.Printer.print;
import hxParser.StackAwareWalker;
import hxParser.WalkStack;
using util.TokenPaddingTools;

class Processor extends StackAwareWalker {
    var config:Config;
    var prevToken:Token;

    var padding(get, never):PaddingConfig;

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
                if (token.prevToken != null && !['{', '(', '[', '<'].has(token.prevToken.text))
                    token.padBefore(padding.beforeOpeningBrace);
            case ')':
                token.padAfter(padding.afterClosingParen);
            case ',':
                handleComma(token, stack);
            case ';':
                token.padBefore(padding.beforeSemicolon);
            case 'else':
                token.padBefore(padding.beforeElse);
            case _:
        }

        prevToken = token;
    }

    function padInsideBrackets(token:Token, stack:WalkStack) {
        var insideBracketsConfig = getInsideBracketsConfig(token.text);

        inline function padOpening()
            token.padAfter(insideBracketsConfig);

        inline function padClosing()
            token.padBefore(insideBracketsConfig);

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

    function getInsideBracketsConfig(token:String):FormattingOperation {
        var insideBrackets = padding.insideBrackets;
        return switch (token) {
            case '(' | ')': insideBrackets.parens;
            case '{' | '}': insideBrackets.braces;
            case '[' | ']': insideBrackets.square;
            case '<' | '>': insideBrackets.angle;
            case _: null;
        }
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
                token.leadingTrivia = [];
            case Ignore:
        }
    }

    function handleComma(token:Token, stack:WalkStack) {
        var config = padding.comma.defaultPadding;
        if (stack.match(Edge(_, Node(ClassField_Property(_, _, _, _, _, _, _, _, _, _, _, _), _))))
            config = padding.comma.propertyAccess;
        token.padAround(config);
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
        node.colon.padAround(padding.colon.typeHint);
    }

    override function walkObjectField(node:ObjectField, stack:WalkStack) {
        super.walkObjectField(node, stack);
        node.colon.padAround(padding.colon.objectField);
    }

    override function walkCase_Case(caseKeyword:Token, patterns:CommaSeparated<Expr>, guard:Null<Guard>, colon:Token, body:Array<BlockElement>, stack:WalkStack) {
        super.walkCase_Case(caseKeyword, patterns, guard, colon, body, stack);
        colon.padAround(padding.colon.caseAndDefault);
    }

    override function walkCase_Default(defaultKeyword:Token, colon:Token, body:Array<BlockElement>, stack:WalkStack) {
        super.walkCase_Default(defaultKeyword, colon, body, stack);
        colon.padAround(padding.colon.caseAndDefault);
    }

    override function walkExpr_ECheckType(parenOpen:Token, expr:Expr, colon:Token, type:ComplexType, parenClose:Token, stack:WalkStack) {
        super.walkExpr_ECheckType(parenOpen, expr, colon, type, parenClose, stack);
        colon.padAround(padding.colon.typeCheck);
    }

    override function walkExpr_ETernary(exprCond:Expr, questionMark:Token, exprThen:Expr, colon:Token, exprElse:Expr, stack:WalkStack) {
        super.walkExpr_ETernary(exprCond, questionMark, exprThen, colon, exprElse, stack);
        questionMark.padAround(padding.questionMark.ternary);
        colon.padAround(padding.colon.ternary);
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
        questionMark.padAfter(padding.questionMark.optional);
    }

    override function walkStructuralExtension(node:StructuralExtension, stack:WalkStack) {
        super.walkStructuralExtension(node, stack);
        node.gt.padAfter(padding.afterStructuralExtension);
    }

    override function walkAssignment(node:Assignment, stack:WalkStack) {
        super.walkAssignment(node, stack);
        node.assign.padAround(padding.assignment);
    }

    override function walkComplexType_Function(typeLeft:ComplexType, arrow:Token, typeRight:ComplexType, stack:WalkStack) {
        super.walkComplexType_Function(typeLeft, arrow, typeRight, stack);
        arrow.padAround(padding.functionTypeArrow);
    }

    override function walkExpr_EBinop(exprLeft:Expr, op:Token, exprRight:Expr, stack:WalkStack) {
        var binopConfig = padding.binaryOperator;
        var spacing = binopConfig.defaultPadding;
        if (binopConfig.padded.has(op.text)) spacing = Both;
        if (binopConfig.unpadded.has(op.text)) spacing = None;

        op.padAround(spacing);
        super.walkExpr_EBinop(exprLeft, op, exprRight, stack);
    }

    override function walkExpr_EUnaryPostfix(expr:Expr, op:Token, stack:WalkStack) {
        super.walkExpr_EUnaryPostfix(expr, op, stack);
        op.padBefore(padding.unaryOperator);
    }

    override function walkExpr_EUnaryPrefix(op:Token, expr:Expr, stack:WalkStack) {
        super.walkExpr_EUnaryPrefix(op, expr, stack);
        op.padAfter(padding.unaryOperator);
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
                node.elseKeyword.leadingTrivia = [];
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
        name.padBefore(padding.beforeDot);
    }

    override function walkImportMode_IAll(dotStar:Token, stack:WalkStack) {
        super.walkImportMode_IAll(dotStar, stack);
        dotStar.padBefore(padding.beforeDot);
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

    override function walkClassField_Function(annotations:NAnnotations, modifiers:Array<FieldModifier>, functionKeyword:Token, name:Token, params:Null<TypeDeclParameters>, parenOpen:Token, args:Null<CommaSeparated<FunctionArgument>>, parenClose:Token, typeHint:Null<TypeHint>, expr:MethodExpr, stack:WalkStack) {
        super.walkClassField_Function(annotations, modifiers, functionKeyword, name, params, parenOpen, args, parenClose, typeHint, expr, stack);
        sortModifiers(modifiers);
    }

    override function walkClassField_Variable(annotations:NAnnotations, modifiers:Array<FieldModifier>, varKeyword:Token, name:Token, typeHint:Null<TypeHint>, assignment:Null<Assignment>, semicolon:Token, stack:WalkStack) {
        super.walkClassField_Variable(annotations, modifiers, varKeyword, name, typeHint, assignment, semicolon, stack);
        sortModifiers(modifiers);
    }

    override function walkClassField_Property(annotations:NAnnotations, modifiers:Array<FieldModifier>, varKeyword:Token, name:Token, parenOpen:Token, read:Token, comma:Token, write:Token, parenClose:Token, typeHint:Null<TypeHint>, assignment:Null<Assignment>, semicolon:Token, stack:WalkStack) {
        super.walkClassField_Property(annotations, modifiers, varKeyword, name, parenOpen, read, comma, write, parenClose, typeHint, assignment, semicolon, stack);
        sortModifiers(modifiers);
    }

    function sortModifiers(modifiers:Array<FieldModifier>) {
        inline function getRank(modifier:FieldModifier):Int {
            var rank = config.fieldModifierOrder.indexOf(modifier.getName().toLowerCase());
            return if (rank == -1) 100 else rank;
        }

        ArraySort.sort(modifiers, function(modifier1, modifier2) return getRank(modifier1) - getRank(modifier2));
    }

    inline function padKeywordParen(keyword:Token) {
        keyword.padAfter(padding.beforeParenAfterKeyword);
    }

    inline function expected(what:String) {
        return throw '$what expected';
    }
}
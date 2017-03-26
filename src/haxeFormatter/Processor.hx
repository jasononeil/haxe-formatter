package haxeFormatter;

import haxeFormatter.Config;
import haxeFormatter.util.ImportSorter;
import haxeFormatter.util.ModifierSorter;
import haxeFormatter.util.NewlineFormatter;
import hxParser.ParseTree;
import hxParser.StackAwareWalker;
import hxParser.WalkStack;
using haxeFormatter.util.TokenFormattingTools;
using haxeFormatter.util.TokenPaddingTools;

class Processor extends StackAwareWalker {
    var config:Config;
    var padding:PaddingConfig;

    public function new(config:Config) {
        this.config = config;
        padding = config.padding;
    }

    override function walkFile_decls(elems:Array<Decl>, stack:WalkStack) {
        super.walkFile_decls(elems, stack);
        ImportSorter.sort(elems, config.imports);
    }

    override function walkToken(token:Token, stack:WalkStack) {
        super.walkToken(token, stack);
        token.padToken(stack, padding);
        if (token.text == '{') NewlineFormatter.formatOpeningBrace(token, stack, config);
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
        questionMark.padOptional(padding);
    }

    override function walkFunctionArgument(node:FunctionArgument, stack:WalkStack) {
        super.walkFunctionArgument(node, stack);
        node.questionMark.padOptional(padding);
    }

    override function walkAnonymousStructureField(node:AnonymousStructureField, stack:WalkStack) {
        super.walkAnonymousStructureField(node, stack);
        node.questionMark.padOptional(padding);
    }

    override function walkNEnumFieldArg(node:NEnumFieldArg, stack:WalkStack) {
        super.walkNEnumFieldArg(node, stack);
        node.questionMark.padOptional(padding);
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
        super.walkExpr_EBinop(exprLeft, op, exprRight, stack);
        op.padBinop(padding);
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
        ifKeyword.padKeywordParen(padding);
    }

    override function walkExprElse(node:ExprElse, stack:WalkStack) {
        super.walkExprElse(node, stack);
        node.elseKeyword.padBefore(padding.beforeElse);
        NewlineFormatter.formatBeforeElse(node.elseKeyword, config);
    }

    override function walkExpr_EFor(forKeyword:Token, parenOpen:Token, exprIter:Expr, parenClose:Token, exprBody:Expr, stack:WalkStack) {
        super.walkExpr_EFor(forKeyword, parenOpen, exprIter, parenClose, exprBody, stack);
        forKeyword.padKeywordParen(padding);
    }

    override function walkExpr_EWhile(whileKeyword:Token, parenOpen:Token, exprCond:Expr, parenClose:Token, exprBody:Expr, stack:WalkStack) {
        super.walkExpr_EWhile(whileKeyword, parenOpen, exprCond, parenClose, exprBody, stack);
        whileKeyword.padKeywordParen(padding);
    }

    override function walkExpr_ESwitch(switchKeyword:Token, expr:Expr, braceOpen:Token, cases:Array<Case>, braceClose:Token, stack:WalkStack) {
        super.walkExpr_ESwitch(switchKeyword, expr, braceOpen, cases, braceClose, stack);
        switchKeyword.padKeywordParen(padding);
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
        token.formatHexLiteral(config.hexadecimalLiterals);
    }

    override function walkClassField_Function(annotations:NAnnotations, modifiers:Array<FieldModifier>, functionKeyword:Token, name:Token, params:Null<TypeDeclParameters>, parenOpen:Token, args:Null<CommaSeparated<FunctionArgument>>, parenClose:Token, typeHint:Null<TypeHint>, expr:MethodExpr, stack:WalkStack) {
        super.walkClassField_Function(annotations, modifiers, functionKeyword, name, params, parenOpen, args, parenClose, typeHint, expr, stack);
        ModifierSorter.sort(modifiers, config.fieldModifierOrder);
    }

    override function walkClassField_Variable(annotations:NAnnotations, modifiers:Array<FieldModifier>, varKeyword:Token, name:Token, typeHint:Null<TypeHint>, assignment:Null<Assignment>, semicolon:Token, stack:WalkStack) {
        super.walkClassField_Variable(annotations, modifiers, varKeyword, name, typeHint, assignment, semicolon, stack);
        ModifierSorter.sort(modifiers, config.fieldModifierOrder);
    }

    override function walkClassField_Property(annotations:NAnnotations, modifiers:Array<FieldModifier>, varKeyword:Token, name:Token, parenOpen:Token, read:Token, comma:Token, write:Token, parenClose:Token, typeHint:Null<TypeHint>, assignment:Null<Assignment>, semicolon:Token, stack:WalkStack) {
        super.walkClassField_Property(annotations, modifiers, varKeyword, name, parenOpen, read, comma, write, parenClose, typeHint, assignment, semicolon, stack);
        ModifierSorter.sort(modifiers, config.fieldModifierOrder);
    }
}
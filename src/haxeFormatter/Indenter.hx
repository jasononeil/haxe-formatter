package haxeFormatter;

import hxParser.ParseTree;
import hxParser.WalkStack;

class Indenter {
    var config:Config;
    var indentLevel:Int = 0;
    var noBlockExpressions:Int = 0;

    public function new(config:Config) {
        this.config = config;
    }

    public function reindent(prevToken:Token, token:Token, stack:WalkStack) {
        inline function indentTrivia()
            reindentTrivia(token.leadingTrivia, indentLevel);

        inline function indentToken()
            reindentToken(prevToken, token);

        inline function indent() {
            indentTrivia();
            indentToken();
        }

        inline function isSwitchEdge(edge:String):Bool
            return stack.match(Edge(edge, Node(Expr_ESwitch(_, _, _, _, _), _)));

        function indentNoBlockExpr(expr:Expr) {
            if (!expr.match(EBlock(_, _, _))) {
                noBlockExpressions++;
                indentLevel++;
            }
        }

        function dedentNoBlockExpr() {
            if (noBlockExpressions > 0) {
                indentLevel -= noBlockExpressions;
                noBlockExpressions = 0;
            }
        }

        switch (token.text) {
            case '{' | '[':
                indent();
                indentLevel++;
                if (!config.indent.indentSwitches && isSwitchEdge("braceOpen")) indentLevel--;
            case '}' | ']':
                if (config.indent.indentSwitches && isSwitchEdge("braceClose")) indentLevel--;
                indentTrivia();
                indentLevel--;
                indentToken();
            case ')':
                switch (stack) {
                    case Edge("parenClose", Node(kind, _)):
                        switch (kind) {
                            case Expr_EIf(_, _, _, _, exprBody, _),
                                Expr_EFor(_, _, _, _, exprBody),
                                Expr_EWhile(_, _, _, _, exprBody):
                                indentNoBlockExpr(exprBody);
                            case Catch(node):
                                indentNoBlockExpr(node.expr);
                            case _:
                        }
                    case _:
                }
                indent();
            case ';':
                dedentNoBlockExpr();
                indent();
            case 'else':
                dedentNoBlockExpr();
                switch (stack) {
                    case Edge("elseKeyword", Node(ExprElse({ elseKeyword:_, expr:expr }), _)):
                        indent();
                        indentNoBlockExpr(expr);
                    case _:
                        indent();
                }
            case 'try':
                switch (stack) {
                    case Edge("tryKeyword", Node(Expr_ETry(_, exprBody, _), _)):
                        indent();
                        indentNoBlockExpr(exprBody);
                    case _:
                        indent();
                }
            case 'catch' | 'while':
                dedentNoBlockExpr();
                indent();
            case 'do':
                switch (stack) {
                    case Edge("doKeyword", Node(Expr_EDo(_, exprBody, _), _)):
                        indent();
                        indentNoBlockExpr(exprBody);
                    case _:
                        indent();
                }
            case 'function':
                switch (stack) {
                    case Edge("functionKeyword", Node(kind, _)):
                        switch (kind) {
                            case ClassField_Function(_, _, _, _, _, _, _, _, _, expr):
                                indent();
                                switch (expr) {
                                    case Expr(expr, _):
                                        indent();
                                        indentNoBlockExpr(expr);
                                    case _:
                                        indent();
                                }
                            case Expr_EFunction(_, fun) | BlockElement_InlineFunction(_, _, fun, _):
                                indent();
                                indentNoBlockExpr(fun.expr);
                            case _:
                                indent();
                        }
                    case _:
                        indent();
                }
            case _:
                switch (stack) {
                    case Edge("caseKeyword", Node(Case_Case(_, _, _, _, _), Element(index, _))):
                        if (index > 0) indentLevel--;
                        indent();
                        indentLevel++;
                    case _:
                        indent();
                }
        }
    }

    function reindentToken(prevToken:Token, token:Token) {
        if (prevToken == null) return;

        var prevLastTrivia = prevToken.trailingTrivia[prevToken.trailingTrivia.length - 1];
        if (prevLastTrivia == null || !prevLastTrivia.text.isNewline()) return;

        var indent = config.indent.whitespace.times(indentLevel);
        var lastTrivia = token.leadingTrivia[token.leadingTrivia.length - 1];
        if (lastTrivia != null && lastTrivia.text.isTabOrSpace())
            lastTrivia.text = indent;
        else
            token.leadingTrivia.push(new Trivia(indent));
    }

    function reindentTrivia(leadingTrivia:Array<Trivia>, indentLevel:Int) {
        var indent = config.indent.whitespace.times(indentLevel);
        var prevTrivia:Trivia = null;
        var afterNewline = true;
        var i = 0;
        while (i < leadingTrivia.length) {
            var trivia = leadingTrivia[i];
            if (trivia.text.isNewline())
                afterNewline = true;

            if (afterNewline && (trivia.text.startsWith("//") || trivia.text.startsWith("/*") || trivia.text.startsWith("#"))) {
                if (prevTrivia != null && prevTrivia.text.isTabOrSpace())
                    prevTrivia.text = indent;
                else {
                    leadingTrivia.insert(i, new Trivia(indent));
                    i++;
                }
            }

            if (!trivia.text.isWhitespace()) {
                afterNewline = false;
            }

            prevTrivia = trivia;
            i++;
        }
    }
}
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
        inline function indentToken()
            reindentToken(prevToken, token, indentLevel);

        inline function isSwitchEdge(edge:String):Bool
            return stack.match(Edge(edge, Node(Expr_ESwitch(_,_,_,_,_), _)));

        function indentNoBlockExpr(expr:Expr) {
            if (!expr.match(EBlock(_,_,_))) {
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
                indentToken();
                indentLevel++;
                if (!config.indent.indentSwitches && isSwitchEdge("braceOpen")) indentLevel--;
            case '}' | ']':
                if (config.indent.indentSwitches && isSwitchEdge("braceClose")) indentLevel--;
                indentLevel--;
                reindentToken(prevToken, token, indentLevel + 1);
            case ')':
                switch (stack) {
                    case Edge("parenClose", Node(kind, _)):
                        switch (kind) {
                            case Expr_EIf(_,_,_,_,exprBody,_),
                                Expr_EFor(_,_,_,_,exprBody),
                                Expr_EWhile(_,_,_,_,exprBody):
                                indentNoBlockExpr(exprBody);
                            case Catch(node):
                                indentNoBlockExpr(node.expr);
                            case _:
                        }
                    case _:
                }
                indentToken();
            case ';':
                dedentNoBlockExpr();
                indentToken();
            case 'else':
                dedentNoBlockExpr();
                switch (stack) {
                    case Edge("elseKeyword", Node(ExprElse({ elseKeyword:_, expr:expr }), _)):
                        indentToken();
                        indentNoBlockExpr(expr);
                    case _:
                        indentToken();
                }
            case 'try':
                switch (stack) {
                    case Edge("tryKeyword", Node(Expr_ETry(_,exprBody,_), _)):
                        indentToken();
                        indentNoBlockExpr(exprBody);
                    case _:
                        indentToken();
                }
            case 'catch' | 'while':
                dedentNoBlockExpr();
                indentToken();
            case 'do':
                switch (stack) {
                    case Edge("doKeyword", Node(Expr_EDo(_,exprBody,_), _)):
                        indentToken();
                        indentNoBlockExpr(exprBody);
                    case _:
                        indentToken();
                }
            case 'function':
                switch (stack) {
                    case Edge("functionKeyword", Node(kind, _)):
                        switch (kind) {
                            case ClassField_Function(_,_,_,_,_,_,_,_,_,expr):
                                indentToken();
                                switch (expr) {
                                    case Expr(expr, _):
                                        indentToken();
                                        indentNoBlockExpr(expr);
                                    case _:
                                        indentToken();
                                }
                            case Expr_EFunction(_,fun) | BlockElement_InlineFunction(_,_,fun,_):
                                indentToken();
                                indentNoBlockExpr(fun.expr);
                            case _:
                                indentToken();
                        }
                    case _:
                        indentToken();
                }
            case _:
                switch (stack) {
                    case Edge("caseKeyword", Node(Case_Case(_,_,_,_,_), Element(index, _))):
                        if (index > 0) indentLevel--;
                        indentToken();
                        indentLevel++;
                    case _:
                        indentToken();
                }
        }
    }

    function reindentToken(prevToken:Token, token:Token, triviaIndent:Int) {
        var triviaIndent = config.indent.whitespace.times(triviaIndent);
        var prevTrivia:Trivia = null;
        var afterNewline = true;
        var i = 0;
        while (i < token.leadingTrivia.length) {
            var trivia = token.leadingTrivia[i];

            var isWhitespace = trivia.text.isWhitespace();
            if (trivia.text.isNewline()) afterNewline = true;

            if (afterNewline && !isWhitespace)
                if (prevTrivia != null && prevTrivia.text.isTabOrSpace())
                    prevTrivia.text = triviaIndent;
                else {
                    token.leadingTrivia.insert(i, new Trivia(triviaIndent));
                    i++;
                }

            if (!isWhitespace) afterNewline = false;

            prevTrivia = trivia;
            i++;
        }

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
}
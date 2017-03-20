package haxeFormatter;

import hxParser.ParseTree;
import hxParser.StackAwareWalker;
import hxParser.WalkStack;

@:forward(pop, push)
abstract IndentHierarchy(Array<Int>) from Array<Int> {
    public function depthFor(line:Int):Int {
        var depth = 0;
        var lastLine = -1;
        for (line in this) {
            // don't double-indent (e.g. `function() return switch [...]`
            // indents twice in one line, but we ignore one of them)
            if (line != lastLine) depth++;
            lastLine = line;
        }
        return depth;
    }
}

class Indenter extends StackAwareWalker {
    var config:Config;
    var prevToken:Token;
    var indentHierarchy:IndentHierarchy = [];
    var noBlockExpressions:Int = 0;
    var line:Int = 0;
    var lastNoBlockExprLine:Int;
    var firstTokenInLine:Token;

    public function new(config:Config) {
        this.config = config;
    }

    override function walkToken(token:Token, stack:WalkStack) {
        super.walkToken(token, stack);

        if (config.indent.whitespace != null)
            reindent(token, stack);

        prevToken = token;
    }

    inline function incrementIndentLevel()
        indentHierarchy.push(line);

    inline function decrementIndentLevel()
        indentHierarchy.pop();

    public function reindent(token:Token, stack:WalkStack) {
        inline function indentTrivia()
            reindentTrivia(prevToken, token.leadingTrivia);

        inline function indentToken()
            reindentToken(prevToken, token);

        inline function indent() {
            indentTrivia();
            indentToken();
        }

        inline function isSwitchEdge(edge:String):Bool
            return stack.match(Edge(edge, Node(Expr_ESwitch(_, _, _, _, _), _)));

        function indentNoBlockExpr(expr:Expr) {
            if (!expr.match(EBlock(_, _, _)) && lastNoBlockExprLine != line) {
                lastNoBlockExprLine = line;
                noBlockExpressions++;
                indentHierarchy.push(line);
            }
        }

        function dedentNoBlockExpr() {
            if (noBlockExpressions > 0) {
                for (i in 0...noBlockExpressions)
                    indentHierarchy.pop();
                noBlockExpressions = 0;
            }
        }

        function updateLine(trivias:Array<Trivia>)
            for (trivia in trivias)
                if (trivia.text.isNewline())
                    line++;

        updateLine(token.leadingTrivia);

        switch (token.text) {
            case '{' | '[' | '(':
                indent();
                incrementIndentLevel();
                if (!config.indent.indentSwitches && isSwitchEdge("braceOpen")) decrementIndentLevel();
            case '}' | ']' | ')':
                if (config.indent.indentSwitches && isSwitchEdge("braceClose")) decrementIndentLevel();
                indentTrivia();
                decrementIndentLevel();
                indentToken();

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
            case ';':
                dedentNoBlockExpr();
                indent();
            case 'else':
                dedentNoBlockExpr();
                switch (stack) {
                    case Edge("elseKeyword", Node(ExprElse({ elseKeyword:_, expr:expr }), _)):
                        indent();
                        if (!expr.match(EIf(_, _, _, _, _, _)))
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
                    case Edge("caseKeyword", Node(Case_Case(_, _, _, _, _), Element(index, _))) |
                        Edge("defaultKeyword", Node(Case_Default(_, _, _), Element(index, _))):
                        if (index > 0) decrementIndentLevel();
                        indent();
                        incrementIndentLevel();
                    case Edge(_, Node(Metadata_WithArgs(_, _, _), _)):
                        // ( is part of the metadata token, so the previous ( case doesn't trigger
                        indent();
                        incrementIndentLevel();
                    case _:
                        indent();
                }
        }

        updateLine(token.trailingTrivia);
    }

    function reindentToken(prevToken:Token, token:Token) {
        if (prevToken == null) return;

        // stop modifying the first-in-line token's trivia if there was any non-dedent character
        inline function isNonDedentChar(token:Token):Bool
            return ![')', ']', '}', ';'].has(token.text);

        if (isNonDedentChar(prevToken) || isNonDedentChar(token))
            firstTokenInLine = null;

        // after newline?
        var prevLastTrivia = prevToken.trailingTrivia[prevToken.trailingTrivia.length - 1];
        if (prevLastTrivia != null && prevLastTrivia.text.isNewline())
            firstTokenInLine = token;

        if (firstTokenInLine == null) return;

        // has non-whitespace leading trivia in same line?
        var i = firstTokenInLine.leadingTrivia.length;
        while (i-- > 0) {
            var trivia = firstTokenInLine.leadingTrivia[i];
            if (trivia.text.isNewline())
                break;
            else if (!trivia.text.isWhitespace())
                return;
        }

        var indent = config.indent.whitespace.times(indentHierarchy.depthFor(line));
        var lastTrivia = firstTokenInLine.leadingTrivia[firstTokenInLine.leadingTrivia.length - 1];
        if (lastTrivia != null && lastTrivia.text.isTabOrSpace())
            lastTrivia.text = indent;
        else
            firstTokenInLine.leadingTrivia.push(new Trivia(indent));
    }

    function reindentTrivia(prevToken:Token, leadingTrivia:Array<Trivia>) {
        var afterNewline = false;
        if (prevToken != null)
            for (trivia in prevToken.trailingTrivia)
                if (trivia.text.isNewline())
                    afterNewline = true;

        var indent = config.indent.whitespace.times(indentHierarchy.depthFor(line));
        var prevTrivia:Trivia = null;
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
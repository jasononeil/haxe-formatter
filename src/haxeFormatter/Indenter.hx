package haxeFormatter;

import hxParser.ParseTree;
import hxParser.StackAwareWalker;
import hxParser.WalkStack;

private typedef Indent = {
    var line:Int;
    var token:Token;
    var kind:IndentKind;
}

private enum IndentKind {
    /**
        A "regular" indent - `(`, `[`...
    **/
    Normal;
    /**
        A "single-expr" indent (an `if ()` without braces for instance.
        On dedent, all `SingleExpr` indents in a row are cleared.
    **/
    SingleExpr;
    /**
        Dedented "as collateral damage" along with any other dedent.
    **/
    Weak;
    /**
        Can only be cleared by a strong dedent.
    **/
    Strong;
}

private abstract IndentStack(Array<Indent>) from Array<Indent> {
    public var top(get,never):Indent;

    function get_top() return this.last();

    public function depthFor(line:Int):Int {
        var depth = 0;
        var prevIndent:Indent = null;
        for (indent in this) {
            // don't double-indent (e.g. `function() return switch [...]`
            // indents twice in one line, but we ignore one of them)
            if (prevIndent == null || indent.line != prevIndent.line) depth++;
            prevIndent = indent;
        }
        return depth;
    }

    public function indent(line:Int, token:Token, kind:IndentKind) {
        if (top != null && top.kind == Weak && top.line == line) this.pop();
        this.push({line: line, token: token, kind: kind});
        dump("indent");
    }

    public function dedent(kind:IndentKind, dedentToken:Token) {
        if (top == null) return;

        clearAllOfKind(Weak);
        clearAllOfKind(SingleExpr);
        switch (kind) {
            case Strong:
                var popped = this.pop();
                if (popped != null) {
                    clearAll(function(indent) {
                        return indent.kind == SingleExpr && indent.line == popped.line;
                    });
                }
            case Normal if (top.kind != Strong):
                this.pop();
            case _:
        }
        dump('dedent ($kind) by ${dedentToken.text}');
    }

    inline function clearAllOfKind(kind:IndentKind) {
        return clearAll(function(indent) return indent.kind == kind);
    }

    function clearAll(shouldClear:Indent->Bool) {
        var i = this.length;
        while (i-- > 0) {
            if (shouldClear(this[i])) this.pop();
            else break;
        }
    }

    function toString() {
        var s = "";
        var prefix = "  ";
        for (indent in this) {
            s += '$prefix${indent.token.text} - ${indent.line},${indent.kind}\n';
            prefix += "  ";
        }
        return if (s == "") "  <none>\n" else s;
    }

    function dump(description:String) {
        // Sys.println('$description\n${toString()}');
    }
}

class Indenter extends StackAwareWalker {
    var config:Config;
    var prevToken:Token;
    var indentStack:IndentStack = [];
    var line:Int = 0;
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

    public function reindent(token:Token, stack:WalkStack) {
        inline function indent(kind:IndentKind)
            indentStack.indent(line, token, kind);

        function indentSingleExpr(expr:Expr) {
            if (!expr.match(EBlock(_, _, _)))
                indent(SingleExpr);
        }

        inline function dedent(kind:IndentKind)
            indentStack.dedent(kind, token);

        inline function applyTriviaIndent()
            reindentTrivia(prevToken, token.leadingTrivia);

        inline function applyTokenIndent()
            reindentToken(prevToken, token);

        inline function applyIndent() {
            applyTriviaIndent();
            applyTokenIndent();
        }

        inline function isSwitchEdge(edge:String):Bool
            return stack.match(Edge(edge, Node(Expr_ESwitch(_, _, _, _, _), _)));

        function updateLine(trivias:Array<Trivia>)
            for (trivia in trivias)
                if (trivia.text.isNewline())
                    line++;

        updateLine(token.leadingTrivia);

        switch (token.text) {
            case '{':
                applyIndent();
                indent(Strong);
                if (!config.indent.indentSwitches && isSwitchEdge("braceOpen")) dedent(Strong);
            case '}':
                if (config.indent.indentSwitches && isSwitchEdge("braceClose")) dedent(Strong);
                applyTriviaIndent();
                dedent(Strong);
                applyTokenIndent();
            case '[' | '(':
                applyIndent();
                indent(Normal);
            case ']' | ')':
                applyTriviaIndent();
                dedent(Normal);
                applyTokenIndent();

                switch (stack) {
                    case Edge("parenClose", Node(kind, _)):
                        switch (kind) {
                            case Expr_EIf(_, _, _, _, exprBody, _),
                                Expr_EFor(_, _, _, _, exprBody),
                                Expr_EWhile(_, _, _, _, exprBody):
                                indentSingleExpr(exprBody);
                            case Catch(node):
                                indentSingleExpr(node.expr);
                            case _:
                        }
                    case _:
                }
            case ';' | ',':
                dedent(SingleExpr);
                applyIndent();
            case 'else':
                dedent(SingleExpr);
                switch (stack) {
                    case Edge("elseKeyword", Node(ExprElse({elseKeyword: _, expr: expr}), _)):
                        applyIndent();
                        if (!expr.match(EIf(_, _, _, _, _, _)))
                            indentSingleExpr(expr);
                    case _:
                        applyIndent();
                }
            case 'try':
                switch (stack) {
                    case Edge("tryKeyword", Node(Expr_ETry(_, exprBody, _), _)):
                        applyIndent();
                        indentSingleExpr(exprBody);
                    case _:
                        applyIndent();
                }
            case 'catch' | 'while':
                dedent(SingleExpr);
                applyIndent();
            case 'do':
                switch (stack) {
                    case Edge("doKeyword", Node(Expr_EDo(_, exprBody, _), _)):
                        applyIndent();
                        indentSingleExpr(exprBody);
                    case _:
                        applyIndent();
                }
            case 'function':
                switch (stack) {
                    case Edge("functionKeyword", Node(kind, _)):
                        switch (kind) {
                            case ClassField_Function(_, _, _, _, _, _, _, _, _, expr):
                                applyIndent();
                                switch (expr) {
                                    case Expr(expr, _):
                                        applyIndent();
                                        indentSingleExpr(expr);
                                    case _:
                                        applyIndent();
                                }
                            case Expr_EFunction(_, fun) | BlockElement_InlineFunction(_, _, fun, _):
                                applyIndent();
                                indentSingleExpr(fun.expr);
                            case _:
                                applyIndent();
                        }
                    case _:
                        applyIndent();
                }
            case _:
                switch (stack) {
                    case Edge("caseKeyword", Node(Case_Case(_, _, _, _, _), Element(index, _))) |
                        Edge("defaultKeyword", Node(Case_Default(_, _, _), Element(index, _))):
                        applyTriviaIndent();
                        if (index > 0) dedent(Normal);
                        applyTokenIndent();
                        indent(Normal);
                    case Edge(_, Node(Metadata_WithArgs(_, _, _), _)):
                        // ( is part of the metadata token, so the previous ( case doesn't trigger
                        applyIndent();
                        indent(Normal);
                    case Edge("op", Node(Expr_EBinop(_, op, _), _)):
                        switch (op.text) {
                            case '==' | '!=' | '>=' | '<=': // nothing to do here
                            case op if (op.has('=')):
                                indent(Weak);
                            case _:
                        }
                        applyIndent();
                    case Edge("assign", Node(Assignment(_), _)):
                        indent(Weak);
                        applyIndent();
                    case _:
                        applyIndent();
                }
        }

        updateLine(token.trailingTrivia);
    }

    function reindentToken(prevToken:Token, token:Token) {
        if (prevToken == null) return;

        // stop modifying the first-in-line token's trivia if there was any non-dedent character
        inline function isNonDedentChar(token:Token):Bool
            return ![')', ']', '}'].has(token.text);

        if (isNonDedentChar(prevToken) || isNonDedentChar(token))
            firstTokenInLine = null;

        // after newline?
        var prevLastTrivia = prevToken.trailingTrivia.last();
        if (prevLastTrivia != null && prevLastTrivia.text.isNewline())
            firstTokenInLine = token;

        if (firstTokenInLine == null)
            return;

        token = firstTokenInLine;

        // has non-whitespace leading trivia in same line?
        var i = token.leadingTrivia.length;
        while (i-- > 0) {
            var trivia = token.leadingTrivia[i];
            if (trivia.text.isNewline())
                break;
            else if (!trivia.text.isWhitespace())
                return;
        }

        if (indentStack.top != null && indentStack.top.token.text == '(' && token.text == '{')
            indentStack.dedent(Normal, token);

        var indent = config.indent.whitespace.times(indentStack.depthFor(line));
        var lastTrivia = token.leadingTrivia.last();
        if (lastTrivia != null && lastTrivia.text.isTabOrSpace())
            lastTrivia.text = indent;
        else
            token.leadingTrivia.push(new Trivia(indent));
    }

    function reindentTrivia(prevToken:Token, leadingTrivia:Array<Trivia>) {
        var afterNewline = false;
        if (prevToken != null)
            for (trivia in prevToken.trailingTrivia)
                if (trivia.text.isNewline())
                    afterNewline = true;

        var indent = config.indent.whitespace.times(indentStack.depthFor(line));
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

            if (!trivia.text.isWhitespace())
                afterNewline = false;

            prevTrivia = trivia;
            i++;
        }
    }
}
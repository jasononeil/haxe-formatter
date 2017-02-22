package haxeFormatter;

import haxeFormatter.Configuration;
import hxParser.JsonParser;
import hxParser.Printer.print;

class Processor {
    var config:Configuration;
    var numDecls:Int;
    var curNode:String;
    var prevNode:String;
    var parentNodes:Array<String>;
    var prevToken:TreeKind;

    public function new(config:Configuration) {
        this.config = config;
    }

    public function process(tree:Tree, parentNodes:Array<String>):Tree {
        this.parentNodes = parentNodes;
        numDecls = 0;
        return {
            kind: processTreeKind(tree.kind),
            start: tree.start,
            end: tree.end
        };
    }

    function processTreeKind(kind:TreeKind):TreeKind {
        switch (kind) {
            case Node(name, children):
                curNode = name;
                var result = processNode(name, children);
                prevNode = name;
                return result;
            case Token(token, trivia):
                var result = processToken(token, trivia);
                prevToken = kind;
                return result;
        }
    }

    function processNode(name:String, children:Array<Tree>):TreeKind {
        switch (name) {
            case "decls":
                if (numDecls == 0 && config.imports.sort)
                    children = sortImports(children);
                numDecls++;
            case _:
        }
        return Node(name, children.map(process.bind(_, parentNodes.concat([name]))));
    }

    function processToken(token:String, trivia:Trivia):TreeKind {
        switch (token) {
            case ":": processColon(token, trivia);
            case _:
        }
        return Token(token, trivia);
    }

    function processColon(token:String, trivia:Trivia) {
        if (curNode != "type_hint") {
            return;
        }

        var before = config.padding.typeHintColon.before;
        var parentNode = parentNodes.idx(-2);
        if (parentNode.has("class_field") || parentNode.has("function")) {
            switch (prevToken) {
                case Token(")",trivia):
                    trivia.trailing = applySpacePadding(before, trivia.trailing);
                case _:
            }
        }
        if (prevNode.has("dollar_ident"))
            switch (prevToken) {
                case Token(_,trivia):
                    trivia.trailing = applySpacePadding(before, trivia.trailing);
                case _:
                    unexpected("Node");
        }

        trivia.trailing = applySpacePadding(config.padding.typeHintColon.after, trivia.trailing);
    }

    function applySpacePadding(padding:WhitespacePolicy, trivia:Array<PlacedToken>):Array<PlacedToken> {
        if (trivia == null)
            trivia = [];

        inline function mkToken(token:String):PlacedToken
            return mkPlacedToken(getSpacePadding(padding, token));

        if (trivia.length > 0 && trivia[0].token.isWhitespace())
            trivia[0] = mkToken(trivia[0].token);
        else
            trivia.insert(0, mkToken(""));

        return trivia;
    }

    function mkPlacedToken(token:String):PlacedToken {
        return {
            start: 0,
            end: 0,
            token: token
        }
    }

    function getSpacePadding(padding:WhitespacePolicy, whitespace:String):String {
        return switch (padding) {
            case Add: " ";
            case Remove: "";
            case Keep | null: whitespace;
        }
    }

    function sortImports(importDecls:Array<Tree>):Array<Tree> {
        if (importDecls.length == 0)
            return importDecls;

        var firstTrivia = getImportTrivia(importDecls[0].kind);
        var leadingTrivia = firstTrivia.leading;
        firstTrivia.leading = null;

        // TODO: consider Token("using")
        importDecls.sort(function(tree1, tree2) return switch[tree1.kind, tree2.kind] {
            case [Node("decl", [{kind: Token("import",_)},name1,_]), Node("decl", [{kind:Token("import",_)},name2,_])]:
                Reflect.compare(print(name1), print(name2));
            case [Node("decl", [{kind: Token("import",_)},_,_]),_]: -1;
            case [_,Node("decl", [{kind: Token("import",_)},_,_])]: 1;
            case _: 0;
        });

        getImportTrivia(importDecls[0].kind).leading = leadingTrivia;
        return importDecls;
    }

    function getImportTrivia(treeKind:TreeKind):Trivia {
        return switch (treeKind) {
            case Node(name, children) if (children.length > 0): switch (children[0].kind) {
                case Token(token, trivia) if (token == "import" || token == "using"):
                    trivia;
                case _: null;
            }
            case _: null;
        }
    }

    inline function unexpected(what:String) {
        throw 'Unexpected $what';
    }
}
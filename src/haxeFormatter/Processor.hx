package haxeFormatter;

import haxeFormatter.Config;
import hxParser.JResult;
import hxParser.Printer.print;
import hxParser.Tree;

enum SpacingLocation {
    Before;
    After;
}

class Processor {
    var config:Config;
    var curNode:String;
    var prevNode:String;
    var parentNodes:Array<String>;
    var prevToken:TreeKind;

    public function new(config:Config) {
        this.config = config;
    }

    public function process(tree:Tree, parentNodes:Array<String>):Tree {
        this.parentNodes = parentNodes;
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
                if (config.imports.sort)
                    children = sortImports(children);
            case _:
        }
        return Node(name, children.map(process.bind(_, parentNodes.concat([name]))));
    }

    function processToken(token:String, trivia:JTrivia):TreeKind {
        switch (token) {
            case ":": processColon(token, trivia);
            case _:
        }
        return Token(token, trivia);
    }

    function processColon(token:String, trivia:JTrivia) {
        if (curNode != "type_hint")
            return;

        var padding = config.padding.typeHintColon;
        var parentNode = parentNodes.idx(-2);
        if (parentNode.has("class_field") || parentNode.has("function")) {
            switch (prevToken) {
                case Token(")",trivia):
                    trivia.trailing = applySpacePadding(padding, Before, trivia.trailing);
                case _:
            }
        }
        if (prevNode.has("dollar_ident"))
            switch (prevToken) {
                case Token(_,trivia):
                    trivia.trailing = applySpacePadding(padding, Before, trivia.trailing);
                case _:
                    unexpected("Node");
        }

        trivia.trailing = applySpacePadding(padding, After, trivia.trailing);
    }

    function applySpacePadding(padding:SpacingPolicy, location:SpacingLocation, trivia:Array<JPlacedToken>):Array<JPlacedToken> {
        if (trivia == null)
            trivia = [];

        inline function mkToken(token:String):JPlacedToken
            return mkPlacedToken(getSpacePadding(padding, location, token));

        if (trivia.length > 0 && trivia[0].token.isWhitespace())
            trivia[0] = mkToken(trivia[0].token);
        else
            trivia.insert(0, mkToken(""));

        return trivia;
    }

    function mkPlacedToken(token:String):JPlacedToken {
        return {
            start: 0,
            end: 0,
            token: token
        }
    }

    function getSpacePadding(padding:SpacingPolicy, location:SpacingLocation, whitespace:String):String {
        return switch [padding, location] {
            case [Ignore, _]: whitespace;
            case [Both, _], [Before, Before], [After, After]: " ";
            case _: "";
        }
    }

    function sortImports(decls:Array<Tree>):Array<Tree> {
        var firstImport = getFirstImportDecl(decls);
        if (firstImport == null)
            return decls;

        var firstTrivia = getImportTrivia(firstImport);
        var leadingTrivia = firstTrivia.leading;
        firstTrivia.leading = null;

        // TODO: consider Token("using")
        decls.sort(function(tree1, tree2) return switch[tree1.kind, tree2.kind] {
            case [Node("import_decl", [{kind: Token("import",_)},name1,_]), Node("import_decl", [{kind:Token("import",_)},name2,_])]:
                Reflect.compare(print(name1), print(name2));
            case [Node("import_decl", [{kind: Token("import",_)},_,_]),_]: -1;
            case [_,Node("import_decl", [{kind: Token("import",_)},_,_])]: 1;
            case _: 0;
        });

        getImportTrivia(decls[0].kind).leading = leadingTrivia;
        return decls;
    }

    function getFirstImportDecl(decls:Array<Tree>):TreeKind {
        for (decl in decls) {
            switch (decl.kind) {
                case Node(name,children) if (name == "import_decl" || name == "using_decl"):
                    return decl.kind;
                case _:
            }
        }
        return null;
    }

    function getImportTrivia(treeKind:TreeKind):JTrivia {
        return switch (treeKind) {
            case Node(name, children) if (children.length > 0): switch (children[0].kind) {
                case Token(token, trivia) if (token == "import" || token == "using"):
                    trivia;
                case _: unexpected("");
            }
            case _: unexpected("");
        }
    }

    inline function unexpected(what:String) {
        return throw 'Unexpected $what';
    }
}
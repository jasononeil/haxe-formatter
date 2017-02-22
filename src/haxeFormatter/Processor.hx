package haxeFormatter;

import haxeFormatter.Printer.print;
import hxParser.JsonParser;

class Processor {
    var config:Configuration;
    var numDecls:Int;

    public function new(config:Configuration) {
        this.config = config;
    }

    public function process(tree:Tree):Tree {
        numDecls = 0;
        return {
            kind: processTreeKind(tree.kind),
            start: tree.start,
            end: tree.end
        };
    }

    function processTreeKind(kind:TreeKind) {
        return switch (kind) {
            case Node(name, children): processNode(name, children);
            case Token(token, trivia): processToken(token, trivia);
        }
    }

    function processNode(name:String, children:Array<Tree>):TreeKind {
        switch (name) {
            case "decls":
                var sort = config.imports.sort;
                if (numDecls == 0 && (sort == null || sort))
                    children = sortImports(children);
                numDecls++;
            case _:
        }
        return Node(name, children.map(process));
    }

    function processToken(token:String, trivia:Trivia<Tree>):TreeKind {
        return Token(token, trivia);
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

    function getImportTrivia(treeKind:TreeKind):Trivia<Tree> {
        return switch (treeKind) {
            case Node(name, children) if (children.length > 0): switch (children[0].kind) {
                case Token(token, trivia) if (token == "import" || token == "using"):
                    trivia;
                case _: null;
            }
            case _: null;
        }
    }
}
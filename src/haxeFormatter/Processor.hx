package haxeFormatter;

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

    public function new(config:Config) {
        this.config = config;
    }

    override public function walkFile(node:File, stack:WalkStack) {
        super.walkFile(node, stack);
    }

    override function walkFile_decls(elems:Array<Decl>, stack:WalkStack) {
        super.walkArray(elems, stack, walkDecl);
        if (config.imports.sort)
            sortImports(elems);
    }

    function sortImports(decls:Array<Decl>) {
        var firstImport = getFirstImportDecl(decls);
        if (firstImport == null)
            return;

        var importToken = getImportToken(firstImport);
        var leadingTrivia = importToken.leadingTrivia;
        importToken.leadingTrivia = [];

        decls.sort(function(decl1, decl2) return switch[decl1, decl2] {
            case [ImportDecl(_,path1,_), ImportDecl(_,path2,_)]:
                Reflect.compare(print(path1), print(path2));

            case [UsingDecl(_,path1,_), UsingDecl(_,path2,_)]:
                Reflect.compare(print(path1), print(path2));

            case [ImportDecl(_,_,_), UsingDecl(_,_,_)]: -1;
            case [UsingDecl(_,_,_), ImportDecl(_,_,_)]: 1;

            case [ImportDecl(_,_,_), _]: -1;
            case [_, ImportDecl(_,_,_)]: 1;

            case [UsingDecl(_,_,_), _]: -1;
            case [_, UsingDecl(_,_,_)]: 1;
            case _: 0;
        });

        getImportToken(decls[0]).leadingTrivia = leadingTrivia;
    }

    function getFirstImportDecl(decls:Array<Decl>):Decl {
        for (decl in decls) {
            if (decl.match(ImportDecl(_,_,_)) || decl.match(UsingDecl(_,_,_)))
                return decl;
        }
        return null;
    }

    function getImportToken(decl:Decl):Token {
        return switch (decl) {
            case ImportDecl(_import,_,_): _import;
            case UsingDecl(_using,_,_): _using;
            case _: expected("using or import");
        }
    }

    override public function walkClassField(node:ClassField, stack:WalkStack) {
        super.walkClassField(node, stack);
    }

    override function walkTypeHint(node:TypeHint, stack:WalkStack) {
        var padding = config.padding.typeHintColon;

        inline function adjustTrivia(token:Token, location:SpacingLocation)
            token.trailingTrivia = applySpacePadding(padding, location, token.trailingTrivia);

        switch (stack) {
            case Edge("typeHint", Node(node,_)): switch (node) {
                case ClassField_Function(_,_,_,_,_,_,_,parenClose,_,_):
                    adjustTrivia(parenClose, Before);
                case ClassField_Variable(_,_,_,name,_,_,_):
                    adjustTrivia(name, Before);
                case ClassField_Property(_,_,_,_,_,_,_,_,parenClose,_,_,_):
                    adjustTrivia(parenClose, Before);
                case Function(node):
                    adjustTrivia(node.parenClose, Before);
                case FunctionArgument(node):
                    adjustTrivia(node.name, Before);
                case _:
            }
            case _:
        }

        adjustTrivia(node.colon, After);
    }

    function applySpacePadding(padding:SpacingPolicy, location:SpacingLocation, trivia:Array<Trivia>):Array<Trivia> {
        if (trivia == null)
            trivia = [];

        if (trivia.length > 0 && trivia[0].text.isWhitespace())
            trivia[0].text = getSpacePadding(padding, location, trivia[0].text);
        else
            trivia.insert(0, new Trivia(getSpacePadding(padding, location, ""), 0, 0));

        return trivia;
    }

    function getSpacePadding(padding:SpacingPolicy, location:SpacingLocation, whitespace:String):String {
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
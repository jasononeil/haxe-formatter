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
    var prevToken:Token;

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
        prevToken = token;
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

    override function walkTypeHint(node:TypeHint, stack:WalkStack) {
        var padding = config.padding.typeHintColon;
        padSpaces(config.padding.typeHintColon, prevToken, node.colon);
        super.walkTypeHint(node, stack);
    }

    override function walkComplexType_Function(typeLeft:ComplexType, arrow:Token, typeRight:ComplexType, stack:WalkStack) {
        walkComplexType(typeLeft, stack);
        padSpaces(config.padding.functionTypeArrow, prevToken, arrow);
        super.walkComplexType_Function(typeLeft, arrow, typeRight, stack);
    }

    function padSpaces(padding:SpacingPolicy, leftToken:Token, rightToken) {
        leftToken.trailingTrivia = padSpace(padding, Before, leftToken.trailingTrivia);
        rightToken.trailingTrivia = padSpace(padding, After, rightToken.trailingTrivia);
    }

    function padSpace(padding:SpacingPolicy, location:SpacingLocation, trivia:Array<Trivia>):Array<Trivia> {
        if (trivia == null)
            trivia = [];

        if (trivia.length > 0 && trivia[0].text.isWhitespace())
            trivia[0].text = getPadding(padding, location, trivia[0].text);
        else
            trivia.insert(0, new Trivia(getPadding(padding, location, "")));

        return trivia;
    }

    function getPadding(padding:SpacingPolicy, location:SpacingLocation, whitespace:String):String {
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
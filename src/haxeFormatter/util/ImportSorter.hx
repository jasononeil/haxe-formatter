package haxeFormatter.util;

import haxe.ds.ArraySort;
import hxParser.ParseTree;
import hxParser.Printer.print;

class ImportSorter {
    public static function sort(decls:Array<Decl>) {
        var firstImport = getFirstImportDecl(decls);
        if (firstImport == null)
            return;

        var importToken = getImportToken(firstImport);
        var leadingTrivia = importToken.leadingTrivia;
        importToken.leadingTrivia = [];

        ArraySort.sort(decls, function(decl1, decl2) return switch [decl1, decl2] {
            case [ImportDecl(i1), ImportDecl(i2)]:
                Reflect.compare(print(i1.path), print(i2.path));

            case [UsingDecl(u1), UsingDecl(u2)]:
                Reflect.compare(print(u1.path), print(u2.path));

            case [ImportDecl(_), UsingDecl(_)]: -1;
            case [UsingDecl(_), ImportDecl(_)]: 1;

            case [ImportDecl(_), _]: -1;
            case [_, ImportDecl(_)]: 1;

            case [UsingDecl(_), _]: -1;
            case [_, UsingDecl(_)]: 1;
            case _: 0;
        });

        getImportToken(decls[0]).leadingTrivia = leadingTrivia;
    }

    static function getFirstImportDecl(decls:Array<Decl>):Decl {
        for (decl in decls) {
            if (decl.match(ImportDecl(_)) || decl.match(UsingDecl(_)))
                return decl;
        }
        return null;
    }

    static function getImportToken(decl:Decl):Token {
        return switch (decl) {
            case ImportDecl({importKeyword: _import}): _import;
            case UsingDecl({usingKeyword: _using}): _using;
            case _: throw "expected using or import";
        }
    }
}
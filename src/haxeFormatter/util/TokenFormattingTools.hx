package haxeFormatter.util;

import hxParser.ParseTree.Token;
import haxeFormatter.Config.LetterCase;

class TokenFormattingTools {
    public static function formatHexLiteral(hexLiteral:Token, letterCase:LetterCase) {
        if (letterCase == Ignore) return;
        var hexRegex = ~/0x([0-9a-fA-F]+)/;
        if (hexRegex.match(hexLiteral.text)) {
            var literal = hexRegex.matched(1);
            hexLiteral.text = '0x${switch (letterCase) {
                case UpperCase: literal.toUpperCase();
                case LowerCase: literal.toLowerCase();
                case Ignore: throw "unexpected Ignore";
            }}';
        }
    }
}
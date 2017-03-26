package haxeFormatter.formatting;

import hxParser.ParseTree.Token;
import haxeFormatter.Config.LetterCase;

class TokenFormattingTools {
    public static function formatHexLiteral(hexLiteral:Token, letterCase:LetterCase) {
        if (letterCase == Keep) return;
        var hexRegex = ~/0x([0-9a-fA-F]+)/;
        if (hexRegex.match(hexLiteral.text)) {
            var literal = hexRegex.matched(1);
            hexLiteral.text = '0x${switch (letterCase) {
                case UpperCase: literal.toUpperCase();
                case LowerCase: literal.toLowerCase();
                case Keep: throw "unexpected Keep";
            }}';
        }
    }
}
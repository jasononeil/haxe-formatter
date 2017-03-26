package util;

import haxeFormatter.Config.FormattingOperation;
import haxeFormatter.Config.TwoSidedPadding;
import hxParser.ParseTree.Token;
import hxParser.ParseTree.Trivia;
using util.TokenPaddingTools;

class TokenPaddingTools {
    public static function padBefore(token:Token, operation:FormattingOperation) {
        if (token.prevToken != null) token.prevToken.padAfter(operation);
    }

    public static function padAround(token:Token, padding:TwoSidedPadding) {
        token.padBefore(switch (padding) {
            case Before | Both: Insert;
            case After | None: Remove;
            case Ignore: FormattingOperation.Ignore;
        });

        token.padAfter(switch (padding) {
            case After | Both: Insert;
            case Before | None: Remove;
            case Ignore: FormattingOperation.Ignore;
        });
    }

    public static function padAfter(token:Token, operation:FormattingOperation) {
        if (token == null)
            return;

        var trivia = token.trailingTrivia;
        if (trivia == null)
            trivia = [];

        if (trivia.length > 0 && trivia[0].text.isNewline())
            return;

        if (trivia.length > 0 && trivia[0].text.isWhitespace())
            trivia[0].text = getPadding(operation, trivia[0].text)
        else
            trivia.insert(0, new Trivia(getPadding(operation, "")));

        token.trailingTrivia = trivia;
    }

    static function getPadding(operation:FormattingOperation, current:String):String {
        return switch (operation) {
            case Ignore: current;
            case Insert: " ";
            case Remove: "";
        }
    }
}
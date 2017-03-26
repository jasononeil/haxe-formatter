package haxeFormatter.util;

import haxeFormatter.Config.FormattingOperation;
import haxeFormatter.Config.TwoSidedPadding;
import hxParser.ParseTree.Token;
import hxParser.ParseTree.Trivia;
using haxeFormatter.util.TokenPaddingTools;

class TokenPaddingTools {
    public static inline function padBefore(token:Token, operation:FormattingOperation) {
        token.prevToken.padAfter(operation);
    }

    public static function padAround(token:Token, padding:TwoSidedPadding) {
        if (padding == Ignore)
            return;

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
        if (operation == Ignore || token == null)
            return;

        var trivia = token.trailingTrivia;
        if (trivia == null)
            trivia = [];

        if (trivia.length > 0 && trivia[0].text.isNewline())
            return;

        var spacing = if (operation == Insert) " " else "";
        if (trivia.length > 0 && trivia[0].text.isWhitespace())
            trivia[0].text = spacing
        else
            trivia.insert(0, new Trivia(spacing));

        token.trailingTrivia = trivia;
    }
}
package haxeFormatter.formatting;

import haxeFormatter.Config;
import hxParser.ParseTree;
import hxParser.WalkStack;
using haxeFormatter.formatting.TokenPaddingTools;

class TokenPaddingTools {
    public static inline function padBefore(token:Token, padding:OneSidedPadding) {
        token.prevToken.padAfter(padding);
    }

    public static function padAround(token:Token, padding:TwoSidedPadding) {
        if (padding == Keep)
            return;

        token.padBefore(switch (padding) {
            case SpaceBefore | SpacesAround: SingleSpace;
            case SpaceAfter | NoSpaces: NoSpace;
            case Keep: OneSidedPadding.Keep;
        });

        token.padAfter(switch (padding) {
            case SpaceAfter | SpacesAround: SingleSpace;
            case SpaceBefore | NoSpaces: NoSpace;
            case Keep: OneSidedPadding.Keep;
        });
    }

    public static function padAfter(token:Token, padding:OneSidedPadding) {
        if (padding == Keep || token == null)
            return;

        var trivia = token.trailingTrivia;
        if (trivia == null)
            trivia = [];

        if (trivia.length > 0 && trivia[0].text.isNewline())
            return;

        var spacing = if (padding == SingleSpace) " " else "";
        if (trivia.length > 0 && trivia[0].text.isWhitespace())
            trivia[0].text = spacing
        else
            trivia.insert(0, new Trivia(spacing));

        token.trailingTrivia = trivia;
    }

    public static function padToken(token:Token, stack:WalkStack, padding:PaddingConfig) {
        token.padInsideBrackets(stack, padding);

        switch (token.text) {
            case '{': token.padBeforeOpeningBrace(padding);
            case ')': token.padAfter(padding.afterClosingParen);
            case ',': token.padComma(stack, padding);
            case ';': token.padBefore(padding.beforeSemicolon);
            case _:
        }
    }

    public static function padInsideBrackets(token:Token, stack:WalkStack, padding:PaddingConfig) {
        inline function padOpening() token.padAfter(getInsideBracketsConfig(token.text, padding));
        inline function padClosing() token.padBefore(getInsideBracketsConfig(token.text, padding));

        inline function inTypeParams()
            return stack.match(Edge(_, Node(TypePathParameters(_), _))) || stack.match(Edge(_, Node(TypeDeclParameters(_), _)));

        switch (token.text) {
            case '(' | '{' | '[': padOpening();
            case ')' | '}' | ']': padClosing();
            case '<' if (inTypeParams()): padOpening();
            case '>' if (inTypeParams()): padClosing();
            case _:
        }
    }

    static function getInsideBracketsConfig(token:String, padding:PaddingConfig):OneSidedPadding {
        var insideBrackets = padding.insideBrackets;
        return switch (token) {
            case '(' | ')': insideBrackets.parens;
            case '{' | '}': insideBrackets.braces;
            case '[' | ']': insideBrackets.square;
            case '<' | '>': insideBrackets.angle;
            case _: null;
        }
    }

    public static inline function padKeywordParen(keyword:Token, padding:PaddingConfig) {
        keyword.padAfter(padding.beforeParenAfterKeyword);
    }

    public static function padComma(comma:Token, stack:WalkStack, padding:PaddingConfig) {
        var config = padding.comma.defaultPadding;
        if (stack.match(Edge(_, Node(ClassField_Property(_, _, _, _, _, _, _, _, _, _, _, _), _))))
            config = padding.comma.propertyAccess;
        comma.padAround(config);
    }

    public static function padBeforeOpeningBrace(openingBrace:Token, padding:PaddingConfig) {
        if (openingBrace.prevToken != null && !['{', '(', '[', '<'].has(openingBrace.prevToken.text))
            openingBrace.padBefore(padding.beforeOpeningBrace);
    }

    public static inline function padOptional(questionMark:Token, padding:PaddingConfig) {
        questionMark.padAfter(padding.questionMark.optional);
    }

    public static function padBinop(op:Token, padding:PaddingConfig) {
        var binopConfig = padding.binaryOperator;
        var spacing = binopConfig.defaultPadding;
        if (binopConfig.padded.has(op.text)) spacing = SpacesAround;
        if (binopConfig.unpadded.has(op.text)) spacing = NoSpaces;

        op.padAround(spacing);
    }
}
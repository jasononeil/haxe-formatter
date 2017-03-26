package haxeFormatter.formatting;

import haxeFormatter.Config.FormattingOperation;
import hxParser.ParseTree.Token;
import hxParser.ParseTree.Trivia;
import hxParser.WalkStack;

class NewlineFormatter {
    public static function formatOpeningBrace(openingBrace:Token, stack:WalkStack, config:Config) {
        var newlineConfigs = config.braces.newlineBeforeOpening;
        var newlineConfig:FormattingOperation = switch (stack.getDepth()) {
            case Block: newlineConfigs.block;
            case Field: newlineConfigs.field;
            case Decl: newlineConfigs.type;
            case Unknown: Keep;
        }

        var prevToken = openingBrace.prevToken;
        switch (newlineConfig) {
            case Insert:
                prevToken.trailingTrivia = [makeNewlineTrivia(config)];
                openingBrace.leadingTrivia = [];
            case Remove:
                prevToken.trailingTrivia = [];
                openingBrace.leadingTrivia = [];
            case Keep:
        }
    }

    public static function formatBeforeElse(elseKeyword:Token, config:Config) {
        var prevToken = elseKeyword.prevToken;
        switch (config.braces.newlineBeforeElse) {
            case Insert:
                prevToken.trailingTrivia = [makeNewlineTrivia(config)];
            case Remove if (prevToken.text == '}'):
                prevToken.trailingTrivia = [];
                elseKeyword.leadingTrivia = [];
            case _:
        }
    }

    static function makeNewlineTrivia(config:Config):Trivia {
        return new Trivia(config.newlineCharacter.getCharacter());
    }
}
package haxeFormatter;

import hxParser.JsonParser;

class Processor {
    var config:Configuration;

    public function new(config:Configuration) {
        this.config = config;
    }

    public function process(tree:Tree):Tree {
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

    function processNode(name:String, children:Array<Tree>) {
        return Node(name, children);
    }

    function processToken(token:String, trivia:Trivia<Tree>) {
        return Token(token, trivia);
    }
}
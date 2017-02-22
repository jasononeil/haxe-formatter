package haxeFormatter;

import hxParser.JsonParser;
import hxParser.HxParser;
import util.Result;
using Lambda;

class HaxeFormatter {
    var config:Configuration;

    public function new(config:Configuration) {
        this.config = config;
    }

    public function format(code:String):Result<String> {
        var parsed = HxParser.parse(code);
        var data:JNodeBase = null;
        switch (parsed) {
            case Success(d): data = d;
            case Failure(reason): Failure(reason);
        }

        var tree:Tree = JsonParser.parse(data);
        tree = processTree(tree);
        return Success(printTree(tree));
    }

    function processTree(tree:Tree):Tree {
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

    function printTree(tree:Tree) {
        var haxeBuf = new StringBuf();
        function loop(tree:Tree) {
            switch (tree.kind) {
                case Node(_, children): children.iter(loop);
                case Token(token, trivia):
                    if (trivia == null) haxeBuf.add(token)
                    else {
                        if (trivia.leading != null) trivia.leading.iter(loop);
                        if (!trivia.implicit && !trivia.inserted && token != "<eof>") haxeBuf.add(token);
                        if (trivia.trailing != null) trivia.trailing.iter(loop);
                    }
            }
        }
        loop(tree);
        return haxeBuf.toString();
    }
}